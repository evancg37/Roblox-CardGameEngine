b = script.Parent
event_giveCard = game.ReplicatedStorage:WaitForChild("GiveCard")
event_getCommons = game.ReplicatedStorage:WaitForChild("GetGameCommons")
event_getOtherPlayerInfo = game.ReplicatedStorage:WaitForChild("GetPlayerInfo")
event_offerCard = game.ReplicatedStorage:WaitForChild("OfferCardAnimation")
event_takeTurn = game.ReplicatedStorage:WaitForChild("PlayerTakeTurn")
event_getGameInfo = game.ReplicatedStorage:WaitForChild("GetGameInfo")
folder = b:WaitForChild("Game")
guiHand = b:WaitForChild("GuiHand")
activity = b:WaitForChild("Activity")
acceptCards = b:WaitForChild("AcceptCards")
moneyInPot = b:WaitForChild("MoneyInPot")
bettingWindow = b:WaitForChild("BettingWindow")
raisingWindow = b:WaitForChild("RaisingWindow")
myMoney = b:WaitForChild("MyMoney")

otherhand1gui = b:WaitForChild("OtherPlayerHand1")
otherplayer1name = b:WaitForChild("OtherPlayerName1")
otherhand2gui = b:WaitForChild("OtherPlayerHand2")
otherplayer2name = b:WaitForChild("OtherPlayerName2")
otherhand3gui = b:WaitForChild("OtherPlayerHand3")
otherplayer3name = b:WaitForChild("OtherPlayerName3")

localplayer = game.Players.LocalPlayer

decal_card_backing = "http://www.roblox.com/asset/?id=1292681064"

hand = {}
guiHandPositions = {}
guiCommonsPositions = {}
othersCards = {}

cardFile = require(game.ReplicatedStorage.CardFile)

-------------------------------------------------------------------------------
--Card template settings

card_other_temp = Instance.new("ImageButton")
card_other_temp.BackgroundTransparency = 1
card_other_temp.AutoButtonColor = false
card_other_temp.Draggable = false
card_other_temp.AnchorPoint = Vector2.new(0.5, 0.5)

card_temp_background = Instance.new("ImageLabel")
card_temp_background.BackgroundColor3 = Color3.new(255, 0, 0)
card_temp_background.Size = UDim2.new(0.9, 0, 0.9, 0)
card_temp_background.AnchorPoint = Vector2.new(0.5, 0.5)
card_temp_background.Position = UDim2.new(0.5, 0, 0.5, 0)
card_temp_background.Parent = card_other_temp

card_temp = Instance.new("TextButton")
card_temp.AutoButtonColor = false
card_temp.AnchorPoint = Vector2.new(0.5, 0.5)
card_temp.Draggable = false
card_temp.BackgroundColor3 = Color3.new(255, 255, 255)
card_temp.BorderColor3 = Color3.new(255, 0, 0)
card_temp.BorderSizePixel = 2

card_size_common = UDim2.new(0.1, 0, 0.5, 0)
card_size_medium = UDim2.new(0.2, 0, 0.56, 0)
card_size_hand = UDim2.new(0.16, 0, 0.8, 0)
card_size_hand_hover = card_size_hand + UDim2.new(0, 5, 0, 10)
card_size_other = UDim2.new(0.23, 0, 0.75, 0)
other_card_push_anim = UDim2.new(0, 0, 0, -60)

-------------------------------------------------------------------------------
--Animation settings

hand_middle = UDim2.new(0.5, 0, 0.5, 0)
anim_takeCard = {UDim2.new(0, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Linear, 0.1, true}

function anim_hoverCard(card)
	local mouse_entering = card.MouseEnter:Connect(function() card:TweenSize(card_size_hand_hover, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.04, false) end)
	local mouse_leaving = card.MouseLeave:Connect(function() card:TweenSize(card_size_hand, Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.04, true) end)
	return mouse_entering, mouse_leaving
end

function anim_lockCard(card, index)
	card:TweenSizeAndPosition(card_size_hand, guiHandPositions[index], Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.1, true)
end

function anim_hand_refresh()
	for key, x in pairs(guiHand:GetChildren()) do
		x:TweenSizeAndPosition(card_size_hand, guiHandPositions[key], Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.1, true)
	end
end

-------------------------------------------------------------------------------
--Gui behavior

function gui_pokerEnable()
	guiHand.Visible = true
	otherhand1gui.Visible = true
	otherhand2gui.Visible = true
	otherhand3gui.Visible = true
	otherplayer1name.Visible = true
	otherplayer2name.Visible = true
	otherplayer3name.Visible = true
	activity.Visible = true
	myMoney.Visible = true
	moneyInPot.Visible = true
	print "Poker Gui enabled."
end

function gui_renderCard(id, size, position, zindex, color) --Size = 1,2,3
	local card
	local cardinfo = cardFile[cardFile.toCardId(id)]
	
	if color == nil then color = 1 end
	if position == nil then position = UDim2.new(0.5, 0, 0.5, 0) end
	if size == nil then size = card_size_medium end
	
	if id == 0 then 
		card = card_other_temp:Clone()
		card.Image = decal_card_backing
	else card = card_temp:Clone()
		card.Text = cardinfo.name
		if cardinfo.color == 0 then --Recolor from red to black if black
			card.BorderColor3 = Color3.new(0, 0, 0)
		end
	end 
	
	card.Position = UDim2.new(0.5, 0, 0.5, 0)
	card.ZIndex = zindex
	card.Parent = folder
	card.Name = "Card"..id
	card:TweenSizeAndPosition(size, position, Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.14, true)
	
	return card
end

function gui_hideCard(card)
	card.Visible = false
end

function gui_restoreCard(card)
	card.Visible = true
end

function gui_renderOtherPlayerCards()
	otherhand1gui:ClearAllChildren()
	otherhand2gui:ClearAllChildren()
	otherhand3gui:ClearAllChildren()
	othersCards = {}
	local players = event_getOtherPlayerInfo:InvokeServer()
	for i = 1, #players do --For every player (number of found numbers of cards)
		if i == 1 then --For player 1 out of 3
			print (players[1].name .. " has " .. players[1].numhand .. " cards.")
			gui_renderOtherCardsIntoHand(otherhand1gui, players[1].numhand )
			otherplayer1name.Text = players[1].name
			otherplayer1name.Name = players[1].name
		elseif i == 2 then
			print (players[2].name .. " has " .. players[2].numhand .. " cards.")
			gui_renderOtherCardsIntoHand(otherhand2gui, players[2].numhand)
			otherplayer2name.Text = players[2].name
			otherplayer1name.Name = players[2].name
		elseif i == 3 then
			print (players[3].name .. " has " .. players[3].numhand .. " cards.")
			gui_renderOtherCardsIntoHand(otherhand3gui, players[3].numhand)
			otherplayer3name.Text = players[3].name
			otherplayer1name.Name = players[3].name
		else
			print "impossible"
		end
	end
end

function gui_renderOtherCardsIntoHand(otherhand, num)
	local mult = (1/(num + 1))
	for i = 1, num do
		local pos = UDim2.new(mult * i, 0, 0.5, 0)
		local card = gui_renderCard(0, card_size_other, pos, 4)
		card.Parent = otherhand
		local cardobject = {gui=card,pos=pos}
		table.insert(othersCards, cardobject)
	end
end

function calculateGuiHandPositions()
	guiHandPositions = {}
	local mult = (1/(#hand + 1))
	for i = 1, #hand do
		guiHandPositions[i] = UDim2.new(mult * i, 0, 0.5, 0)
	end
end

function calculateGuiCommonPositions(num)
	num = 5 --locking to 5 for now
	guiCommonsPositions = {}
	local mult = (1/(num +1))
	for i = 1, num do
		guiCommonsPositions[i] = UDim2.new(mult * i, 0, 0.43, 0)
	end
end

-------------------------------------------------------------------------------
--Animation methods

function anim_newCommon(card, id) --card is the value of the card, id is the number of the card in commons
	calculateGuiCommonPositions()
	local card = gui_renderCard(card, card_size_common, guiCommonsPositions[id], 3)
	card.Parent = activity
end

function anim_common_refresh()
	local commons = event_getCommons:InvokeServer()
	if not commons then
		print "commons not found in anim_common_refresh" return
	end
	local num = #commons
	
	activity:ClearAllChildren()
	calculateGuiCommonPositions(num)
	
	for i = 1, num do
		local card = gui_renderCard(commons[i], card_size_common, guiCommonsPositions[i], 3)
		card.Parent = activity
	end
end

function anim_cardToHand(card)
	card.Size = UDim2.new(0.3, 0, 2.4, 0) --Arbitrary for reparenting anim
	card.Position = UDim2.new(0.5, 0, 0.5, -200)
	card.Parent = guiHand
	card.ZIndex = 5
	local event1, event2 = anim_hoverCard(card)
	anim_setUpDragCard(card, #hand, event1, event2)

	calculateGuiHandPositions()
	anim_hand_refresh()
end

function anim_setUpDragCard(card, index, event1, event2)
	local localdrag = false
	local broadcast_drag = false
	print ("Set up card " .. index)
	card.DragBegin:Connect(function(init) --Other player offer card anim broadcast
		localdrag = true
		while localdrag do 
			wait() 
			if (card.Position.Y.Offset < -110 and card.Position.X.Offset < 500 and card.Position.X.Offset > -500) then
				if not broadcast_drag then
					broadcast_drag = true
					event_offerCard:FireServer(index, true)
				end
			else
				if broadcast_drag then
					broadcast_drag = false
					event_offerCard:FireServer(index, false)
				end
			end
		end
	end)
	card.DragStopped:Connect(function(x, y) 
		localdrag = false
		anim_lockCard(card, index) 
		--[[
		if not checkIfInBounds(x, y, acceptCards) then --Make acceptance checking more specific later

		else
			event1:Disconnect()
			event2:Disconnect()
			local value = tonumber(card.Text)
			print ("Card " .. value .. " accepted.")
			game_takeCard(value) --The game server takes the card away
			anim_giveCard(card) --The animation destroys the card
		--end
		]]--
	end)
	card.Draggable = true
end

function anim_giveCard(card)
	card:TweenSize(anim_takeCard[1], anim_takeCard[2], anim_takeCard[3], anim_takeCard[4], anim_takeCard[5], 
		function() 
			card:Destroy() 
			calculateGuiHandPositions() 
			anim_hand_refresh() 
		end
	)
end

function checkIfInBounds(x, y, figure)
	if x >= figure.AbsolutePosition.X and x <= figure.AbsolutePosition.X + figure.AbsoluteSize.X then
		if y >= figure.AbsolutePosition.Y and y <= figure.AbsolutePosition.Y + figure.AbsoluteSize.Y then
			return true
		end
	end
	return false
end

function anim_otherPlayerOfferCard(playerobject, num, direction) --the command we get back from the server
	local c
		
	if playerobject.name == otherplayer1name.Text then
		c = otherhand1gui:GetChildren()
	elseif playerobject.name == otherplayer2name.Text then
		c = otherhand2gui:GetChildren()
	elseif playerobject.name == otherplayer3name.Text then
		c = otherhand3gui:GetChildren()
	else
		print "not happening"
	end
	--get # of other players from server
	--order them and each one is otherhandgui123

	local card = c[num]
	local cardobject = cardObjectLookup(card) --card is guicard
	local card_opos = cardobject.pos
	
	if direction == true then
		card:TweenPosition(card_opos + other_card_push_anim, Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.07, false)
	else
		card:TweenPosition(card_opos, Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.12, true)		
	end
end

b.OtherPlayerOfferAnimation.OnClientEvent:Connect(anim_otherPlayerOfferCard)

-------------------------------------------------------------------------------
--Game behavior

function game_takeCard(id)
	local success = tableFindRemove(hand, id)
	if not success then
		print ("Could not remove card " .. id .. ", card not found in hand.")
	else
		print ("Removed card " .. id .. " from " .. localplayer.Name .. "'s hand")
	end
	event_giveCard:FireServer(id)
end

function game_receiveCard(id)
	print (localplayer.Name .. " is receiving card " .. id)
	table.insert(hand, id)
	
	local card = gui_renderCard(id, card_size_medium, nil, 10)
	wait(1)
	anim_cardToHand(card)
end

b.ReceiveCard.OnClientEvent:Connect(game_receiveCard)

function game_updateCards()
	gui_renderOtherPlayerCards()
end

function game_newCommon(card, id)
	anim_newCommon(card, id)
end

b.UpdateCards.OnClientEvent:Connect(game_updateCards)
b.NewCommonCard.OnClientEvent:Connect(game_newCommon)

function hand_searchHand(id)
	for key, value in pairs(hand) do
		if value == id then
			return key
		end
	end
end

function updateMoneyAmounts()
	local me = event_getOtherPlayerInfo:InvokeServer(true)
	local gameobject = event_getGameInfo:InvokeServer()
	myMoney.Text = "$"..me.money
	moneyInPot.Text = "Pot: $"..gameobject.pot
end

function poker_takeTurn(gameobject)
	print ("Turn time")
	updateMoneyAmounts()
	local playerinfo = event_getOtherPlayerInfo:InvokeServer(true) --invoke GetPlayerInfo with true, for self player object
	bettingWindow.Visible = true
	bettingWindow.CallButton.Text = "Call $"..gameobject.call
	
	local event1
	local event2
	local event3
	local interiorevent1
	local interiorevent2
	
	local waiting = true
	if gameobject.call > playerinfo.money then --player can only fold. half the other buttons.
		bettingWindow.CallButton.BackgroundTransparency = 0.3
		bettingWindow.RaiseButton.BackgroundTransparency = 0.3
		
	else --The player can do anything.
		
		event1 = bettingWindow.CallButton.MouseButton1Down:Connect(function()  --the player has chosen to call
			waiting = false
			event_takeTurn:FireServer("call", gameobject.call) --calling to the game server takes mode (call), amount (0), player, gameobject
		end)
		
		event2 = bettingWindow.RaiseButton.MouseButton1Down:Connect(function() --the player has chosen to raise
			raisingWindow.Visible = true
			
			interiorevent1 = raisingWindow.RaiseButton.MouseButton1Down:Connect(function() --the player has pressed raise
				waiting = false
				local raiseamount = tonumber(raisingWindow.RaiseAmount.Text)
				event_takeTurn:FireServer("raise", raiseamount)
			end)
			
			interiorevent2 = raisingWindow.AllInButton.MouseButton1Down:Connect(function()
				waiting = false
				event_takeTurn:FireServer("raise", playerinfo.money)
			end)
	
		end)
	end

	event3 = bettingWindow.FoldButton.MouseButton1Down:Connect(function() --The player has chosen to fold.
		waiting = false
		event_takeTurn:FireServer("fold")
	end)
	
	while true do --wait for any of the actions to be taken.
		wait()
		if waiting then

		else
			if event1 then event1:Disconnect() end
			if event2 then event2:Disconnect() end
			if event3 then event3:Disconnect() end
			if interiorevent1 then interiorevent1:Disconnect() end
			if interiorevent2 then interiorevent2:Disconnect() end
			bettingWindow.Visible = false
			raisingWindow.Visible = false
			updateMoneyAmounts()
			break
		end
	end
end

b.YourTurn.OnClientEvent:Connect(poker_takeTurn)

function cardObjectLookup(card) --card is gui card
	for _, cardobject in pairs(othersCards) do
		if cardobject.gui == card then
			return cardobject
		end
	end
	return false
end

function tableFindRemove(t, x)
	for key, value in pairs(t) do
		if value == x then
			table.remove(t, key)
			return true
		end
	end
	return false
end

function initiate_game(mode)
	if not mode then mode = "poker" end
	
	if mode == "poker" then 
		gui_pokerEnable()
	end
end

b.InitiateGame.OnClientEvent:Connect(initiate_game)

while true do
	wait(3)
	updateMoneyAmounts()
end