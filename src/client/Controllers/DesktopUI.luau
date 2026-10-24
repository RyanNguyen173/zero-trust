--!strict
-- "BloxOS" parody desktop shell: RoMail client + RoNotes sticky, replacing TicketDebugUI.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local Config = require(Shared:WaitForChild("Config"))

type ClientTicket = Types.ClientTicket
type GameState = Types.GameState
type DecisionType = Types.DecisionType
type ShiftSummary = Types.ShiftSummary

local DesktopUI = {}

local player = Players.LocalPlayer
local submitDecision: RemoteEvent
local startShift: RemoteEvent
local nextDay: RemoteEvent
local gameStateSync: RemoteEvent

local screenGui: ScreenGui
local mailWindow: Frame
local mailListPane: ScrollingFrame
local mailReadingPane: Frame
local taskbarClockLabel: TextLabel
local roNotesText: TextLabel
local summaryModal: Frame
local mailOpen = false
local selectedTicketId: string? = nil
local lastTicketSignature = ""
local rejectedTickets: { [string]: ClientTicket } = {}
local activeMailFolder: "Inbox" | "Trash" = "Inbox"
local latestTickets: { ClientTicket } = {}
local inboxFolderButton: TextButton
local trashFolderButton: TextButton
local roNotesWidget: Frame
local renderMailList: (ScrollingFrame, { ClientTicket }, boolean) -> ()

local directoryWindow: Frame
local directoryContentPane: ScrollingFrame
local directoryOpen = false
local activeDirectoryTab: "Employees" | "Vendors" = "Employees"
local employeesTabButton: TextButton
local vendorsTabButton: TextButton

local topZIndex = 10
local hasAutoOpenedThisShift = false
local mailTaskbarUnderline: Frame
local directoryTaskbarUnderline: Frame

local FONT = Enum.Font.GothamBold

local function formatClock(shiftMinutes: number): string
	local totalMinutes = math.floor(shiftMinutes) % (24 * 60)
	local hour24 = math.floor(totalMinutes / 60)
	local minute = totalMinutes % 60
	local suffix = if hour24 >= 12 then "PM" else "AM"
	local hour12 = hour24 % 12
	if hour12 == 0 then
		hour12 = 12
	end
	return string.format("%02d:%02d %s", hour12, minute, suffix)
end

local DAY_NAMES = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday" }

local function dayName(day: number): string
	return DAY_NAMES[math.clamp(day, 1, #DAY_NAMES)]
end

local function bringToFront(window: Frame): ()
	topZIndex += 1
	window.ZIndex = topZIndex
end

local function makeDraggable(window: Frame, titlebar: Frame): ()
	local dragging = false
	local dragStart = Vector2.new()
	local startPosition = UDim2.new()

	titlebar.Active = true
	titlebar.InputBegan:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragStart = Vector2.new(input.Position.X, input.Position.Y)
			startPosition = window.Position
			bringToFront(window)

			local connection: RBXScriptConnection
			connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					connection:Disconnect()
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
			window.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end
	end)
end

local function updateTaskbarIndicators(): ()
	if mailTaskbarUnderline then
		mailTaskbarUnderline.Visible = mailOpen
	end
	if directoryTaskbarUnderline then
		directoryTaskbarUnderline.Visible = directoryOpen
	end
end

local function setMailOpen(open: boolean): ()
	mailOpen = open
	mailWindow.Visible = open
	if open then
		bringToFront(mailWindow)
	end
	updateTaskbarIndicators()
end

local function setDirectoryOpen(open: boolean): ()
	directoryOpen = open
	directoryWindow.Visible = open
	if open then
		bringToFront(directoryWindow)
	end
	updateTaskbarIndicators()
end

local function addCorner(instance: Instance, radius: number): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
	return corner
end

local function addStroke(instance: Instance, thickness: number): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Transparency = 0.5
	stroke.Parent = instance
	return stroke
end

-- Uploaded directly via the Roblox asset-upload path (not a catalog/Decal reference, which
-- failed with "Asset type does not match requested type" in this place -- see commit history).
local ICON_ASSETS = {
	["RoMail"] = "rbxassetid://80543479804706",
	["RoNotes"] = "rbxassetid://101150679876451",
	["Directory"] = "rbxassetid://135447785371503",
}

local function makeIconImage(parent: Instance, assetId: string, zIndex: number): ImageLabel
	local image = Instance.new("ImageLabel")
	image.Size = UDim2.new(0, 36, 0, 36)
	image.BackgroundTransparency = 1
	image.Image = assetId
	image.ZIndex = zIndex
	image.Parent = parent
	return image
end

local function buildSpeakerIcon(parent: Instance, zIndex: number): Frame
	local icon = Instance.new("TextButton")
	icon.Size = UDim2.new(0, 20, 0, 20)
	icon.BackgroundTransparency = 1
	icon.Text = ""
	icon.ZIndex = zIndex
	icon.Parent = parent

	local body = Instance.new("Frame")
	body.Size = UDim2.new(0, 6, 0, 8)
	body.Position = UDim2.new(0, 1, 0, 6)
	body.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
	body.ZIndex = zIndex
	body.Parent = icon
	addCorner(body, 1)

	local waves: { Frame } = {}
	for i = 1, 2 do
		local wave = Instance.new("Frame")
		wave.Size = UDim2.new(0, 2, 0, 2 + i * 3)
		wave.AnchorPoint = Vector2.new(0, 0.5)
		wave.Position = UDim2.new(0, 7 + i * 3, 0.5, 0)
		wave.Rotation = 25
		wave.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
		wave.ZIndex = zIndex
		wave.Parent = icon
		addCorner(wave, 1)
		table.insert(waves, wave)
	end

	-- Wire up to MusicController for mute toggle
	local Controllers = script.Parent
	if Controllers then
		local musicModule = Controllers:FindFirstChild("MusicController")
		if musicModule and musicModule:IsA("ModuleScript") then
			local MusicController = require(musicModule)
			MusicController.registerSpeakerWaves(waves)
			icon.MouseButton1Click:Connect(function()
				MusicController.toggleMute()
			end)
		end
	end

	return icon :: any
end

local function buildWifiIcon(parent: Instance, zIndex: number): Frame
	local icon = Instance.new("Frame")
	icon.Size = UDim2.new(0, 16, 0, 16)
	icon.BackgroundTransparency = 1
	icon.ZIndex = zIndex
	icon.Parent = parent

	for i = 1, 3 do
		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0, 2, 0, 3 + i * 3)
		bar.AnchorPoint = Vector2.new(0, 1)
		bar.Position = UDim2.new(0, 2 + i * 4, 1, 0)
		bar.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
		bar.ZIndex = zIndex
		bar.Parent = icon
		addCorner(bar, 1)
	end

	return icon
end

local function buildDiamondLogo(parent: Instance, zIndex: number, size: number): Frame
	local diamond = Instance.new("Frame")
	diamond.Size = UDim2.new(0, size, 0, size)
	diamond.AnchorPoint = Vector2.new(0.5, 0.5)
	diamond.Position = UDim2.new(0.5, 0, 0.5, 0)
	diamond.Rotation = 45
	diamond.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	diamond.ZIndex = zIndex
	diamond.Parent = parent
	addCorner(diamond, 3)
	return diamond
end

local function buildDummyFace(parent: Instance, zIndex: number): Frame
	local face = Instance.new("Frame")
	face.Size = UDim2.new(0, 56, 0, 56)
	face.Position = UDim2.new(0, 10, 0, 10)
	face.BackgroundColor3 = Color3.fromRGB(255, 214, 89)
	face.ZIndex = zIndex
	face.Parent = parent
	addCorner(face, 28)
	addStroke(face, 1.5)

	local eyeLeft = Instance.new("Frame")
	eyeLeft.Size = UDim2.new(0, 6, 0, 6)
	eyeLeft.Position = UDim2.new(0.3, 0, 0.38, 0)
	eyeLeft.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	eyeLeft.ZIndex = zIndex + 1
	eyeLeft.Parent = face
	addCorner(eyeLeft, 3)

	local eyeRight = eyeLeft:Clone()
	eyeRight.Position = UDim2.new(0.62, 0, 0.38, 0)
	eyeRight.Parent = face

	local mouth = Instance.new("Frame")
	mouth.Size = UDim2.new(0.4, 0, 0, 4)
	mouth.Position = UDim2.new(0.3, 0, 0.65, 0)
	mouth.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	mouth.ZIndex = zIndex + 1
	mouth.Parent = face
	addCorner(mouth, 2)

	local collar = Instance.new("Frame")
	collar.Size = UDim2.new(0, 46, 0, 10)
	collar.Position = UDim2.new(0, 15, 0, 60)
	collar.BackgroundColor3 = Color3.fromRGB(70, 130, 220)
	collar.ZIndex = zIndex
	collar.Parent = parent
	addCorner(collar, 3)

	return face
end

local function bounce(button: GuiButton, shrinkDelta: number?): ()
	local originalSize = button.Size
	local delta = shrinkDelta or 4
	local activeTween: Tween? = nil

	local function playTween(targetSize: UDim2, duration: number, style: Enum.EasingStyle): ()
		if activeTween then
			activeTween:Cancel()
		end
		local tween =
			TweenService:Create(button, TweenInfo.new(duration, style), { Size = targetSize })
		activeTween = tween
		tween:Play()
	end

	button.MouseButton1Down:Connect(function()
		playTween(originalSize - UDim2.new(0, delta, 0, delta), 0.08, Enum.EasingStyle.Quad)
	end)

	button.MouseButton1Up:Connect(function()
		playTween(originalSize, 0.12, Enum.EasingStyle.Back)
	end)

	button.MouseLeave:Connect(function()
		playTween(originalSize, 0.12, Enum.EasingStyle.Back)
	end)
end

local function formatAmount(amount: number?): string
	if amount == nil then
		return "N/A"
	end
	return string.format("$%d", amount)
end

local function makeLabel(parent: Instance, text: string, position: UDim2, size: UDim2): TextLabel
	local label = Instance.new("TextLabel")
	label.Text = text
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(235, 235, 245)
	label.Font = FONT
	label.TextSize = 16
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function makeChunkyButton(
	parent: Instance,
	text: string,
	color: Color3,
	position: UDim2,
	size: UDim2,
	onClick: () -> (),
	shrinkDelta: number?
): TextButton
	local button = Instance.new("TextButton")
	button.Text = text
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = color
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = FONT
	button.TextSize = 16
	button.Parent = parent
	addCorner(button, 8)
	addStroke(button, 1.5)
	bounce(button, shrinkDelta)
	button.MouseButton1Click:Connect(onClick)
	return button
end

local function addMinimizeGlyph(button: GuiButton, zIndex: number): ()
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 14, 0, 3)
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Position = UDim2.new(0.5, 0, 0.5, 0)
	bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	bar.ZIndex = zIndex
	bar.Parent = button
	addCorner(bar, 1)
end

local function addMaximizeGlyph(button: GuiButton, zIndex: number): ()
	local square = Instance.new("Frame")
	square.Size = UDim2.new(0, 14, 0, 11)
	square.AnchorPoint = Vector2.new(0.5, 0.5)
	square.Position = UDim2.new(0.5, 0, 0.5, 0)
	square.BackgroundTransparency = 1
	square.ZIndex = zIndex
	square.Parent = button

	local outline = Instance.new("UIStroke")
	outline.Thickness = 2
	outline.Color = Color3.fromRGB(255, 255, 255)
	outline.Parent = square
end

local function addCloseGlyph(button: GuiButton, zIndex: number): ()
	local barA = Instance.new("Frame")
	barA.Size = UDim2.new(0, 16, 0, 3)
	barA.AnchorPoint = Vector2.new(0.5, 0.5)
	barA.Position = UDim2.new(0.5, 0, 0.5, 0)
	barA.Rotation = 45
	barA.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	barA.ZIndex = zIndex
	barA.Parent = button
	addCorner(barA, 1)

	local barB = barA:Clone()
	barB.Rotation = -45
	barB.Parent = button
end

local function renderReadingPane(
	readingPane: Frame,
	ticket: ClientTicket?,
	isTrashView: boolean?
): ()
	for _, child in readingPane:GetChildren() do
		child:Destroy()
	end

	if not ticket then
		local placeholder = makeLabel(
			readingPane,
			"Select a ticket from the list.",
			UDim2.new(0, 10, 0, 10),
			UDim2.new(1, -20, 0, 24)
		)
		placeholder.ZIndex = 7
		return
	end

	local face = buildDummyFace(readingPane, 7)
	face.ZIndex = 7
	local senderLabel = makeLabel(
		readingPane,
		"From: " .. ticket.sender,
		UDim2.new(0, 75, 0, 10),
		UDim2.new(1, -85, 0, 20)
	)
	senderLabel.ZIndex = 7
	local typeLabel = makeLabel(
		readingPane,
		"Subject: " .. ticket.ticketType,
		UDim2.new(0, 75, 0, 32),
		UDim2.new(1, -85, 0, 20)
	)
	typeLabel.ZIndex = 7

	local amountBanner = Instance.new("Frame")
	amountBanner.Size = UDim2.new(1, -20, 0, 30)
	amountBanner.Position = UDim2.new(0, 10, 0, 76)
	amountBanner.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
	amountBanner.ZIndex = 7
	amountBanner.Parent = readingPane
	addCorner(amountBanner, 6)
	local amountLabel = makeLabel(
		amountBanner,
		string.format("Amount Requested: %s", formatAmount(ticket.amount)),
		UDim2.new(0, 10, 0, 0),
		UDim2.new(1, -20, 1, 0)
	)
	amountLabel.ZIndex = 8

	local bodyScroll = Instance.new("ScrollingFrame")
	bodyScroll.Size = UDim2.new(1, -20, 1, -166)
	bodyScroll.Position = UDim2.new(0, 10, 0, 116)
	bodyScroll.BackgroundTransparency = 1
	bodyScroll.BorderSizePixel = 0
	bodyScroll.ScrollBarThickness = 6
	bodyScroll.ZIndex = 7
	bodyScroll.Parent = readingPane

	local bodyFont = Enum.Font.Gotham
	local bodyTextSize = 15
	local bodyWidth = bodyScroll.AbsoluteSize.X
	if bodyWidth <= 0 then
		-- AbsoluteSize isn't populated until the frame has rendered at least once;
		-- fall back to a reasonable estimate so the first render still sizes correctly.
		bodyWidth = 380
	end
	local textBounds = TextService:GetTextSize(
		ticket.message,
		bodyTextSize,
		bodyFont,
		Vector2.new(bodyWidth - 8, math.huge)
	)

	local body = Instance.new("TextLabel")
	body.Size = UDim2.new(1, -8, 0, textBounds.Y)
	body.BackgroundTransparency = 1
	body.TextColor3 = Color3.fromRGB(220, 220, 230)
	body.Font = bodyFont
	body.TextSize = bodyTextSize
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.Text = ticket.message
	body.ZIndex = 7
	body.Parent = bodyScroll

	bodyScroll.CanvasSize = UDim2.new(0, 0, 0, textBounds.Y + 10)

	if isTrashView then
		local approveButton = makeChunkyButton(
			readingPane,
			"[Approve]",
			Color3.fromRGB(46, 125, 50),
			UDim2.new(0, 10, 1, -46),
			UDim2.new(0, 140, 0, 36),
			function()
				submitDecision:FireServer(ticket.id, "Approve")
				rejectedTickets[ticket.id] = nil
				selectedTicketId = nil
				renderReadingPane(readingPane, nil)
				if activeMailFolder == "Trash" then
					local list = {}
					for _, remaining in rejectedTickets do
						table.insert(list, remaining)
					end
					table.sort(list, function(a, b)
						return a.id < b.id
					end)
					renderMailList(mailListPane, list, true)
				end
			end
		)
		approveButton.ZIndex = 7
	else
		local approveButton = makeChunkyButton(
			readingPane,
			"[Approve]",
			Color3.fromRGB(46, 125, 50),
			UDim2.new(0, 10, 1, -46),
			UDim2.new(0, 140, 0, 36),
			function()
				submitDecision:FireServer(ticket.id, "Approve")
			end
		)
		approveButton.ZIndex = 7

		local rejectButton = makeChunkyButton(
			readingPane,
			"[Reject]",
			Color3.fromRGB(198, 40, 40),
			UDim2.new(0, 160, 1, -46),
			UDim2.new(0, 140, 0, 36),
			function()
				submitDecision:FireServer(ticket.id, "Reject")
				rejectedTickets[ticket.id] = ticket
			end
		)
		rejectButton.ZIndex = 7
	end
end

function renderMailList(listPane: ScrollingFrame, tickets: { ClientTicket }, isTrash: boolean): ()
	for _, child in listPane:GetChildren() do
		child:Destroy()
	end

	for index, ticket in tickets do
		local card = Instance.new("TextButton")
		card.Name = ticket.id
		card.Size = UDim2.new(1, -10, 0, 50)
		card.Position = UDim2.new(0, 5, 0, (index - 1) * 55)
		card.BackgroundColor3 = if ticket.id == selectedTicketId
			then Color3.fromRGB(55, 60, 80)
			else Color3.fromRGB(38, 42, 56)
		card.Text = ""
		card.ZIndex = 7
		card.Parent = listPane
		addCorner(card, 6)

		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, 8, 0, 8)
		dot.Position = UDim2.new(0, 6, 0, 6)
		dot.BackgroundColor3 = if isTrash
			then Color3.fromRGB(226, 94, 94)
			else Color3.fromRGB(94, 160, 226)
		dot.ZIndex = 8
		addCorner(dot, 4)
		dot.Parent = card

		local senderLabel =
			makeLabel(card, ticket.sender, UDim2.new(0, 20, 0, 2), UDim2.new(1, -30, 0, 20))
		senderLabel.ZIndex = 8

		if isTrash then
			local tagLabel = makeLabel(
				card,
				string.format("[REJECTED] %s", formatAmount(ticket.amount)),
				UDim2.new(0, 20, 0, 24),
				UDim2.new(1, -30, 0, 20)
			)
			tagLabel.TextColor3 = Color3.fromRGB(230, 90, 90)
			tagLabel.TextSize = 12
			tagLabel.ZIndex = 8
		else
			local amountPill = Instance.new("Frame")
			amountPill.Size = UDim2.new(0, 70, 0, 18)
			amountPill.Position = UDim2.new(1, -80, 0, 24)
			amountPill.BackgroundColor3 = Color3.fromRGB(230, 140, 40)
			amountPill.ZIndex = 8
			amountPill.Parent = card
			addCorner(amountPill, 9)

			local amountLabel = makeLabel(
				amountPill,
				formatAmount(ticket.amount),
				UDim2.new(0, 6, 0, 0),
				UDim2.new(1, -12, 1, 0)
			)
			amountLabel.TextSize = 12
			amountLabel.TextXAlignment = Enum.TextXAlignment.Center
			amountLabel.ZIndex = 9
		end

		card.MouseButton1Click:Connect(function()
			selectedTicketId = ticket.id
			renderReadingPane(mailReadingPane, ticket, isTrash)
			for _, sibling in listPane:GetChildren() do
				if sibling:IsA("TextButton") then
					sibling.BackgroundColor3 = if sibling.Name == ticket.id
						then Color3.fromRGB(55, 60, 80)
						else Color3.fromRGB(38, 42, 56)
				end
			end
		end)
	end

	listPane.CanvasSize = UDim2.new(0, 0, 0, #tickets * 55)
end

local function setMailFolder(folder: "Inbox" | "Trash"): ()
	activeMailFolder = folder
	inboxFolderButton.BackgroundColor3 = if folder == "Inbox"
		then Color3.fromRGB(45, 50, 65)
		else Color3.fromRGB(24, 26, 36)
	trashFolderButton.BackgroundColor3 = if folder == "Trash"
		then Color3.fromRGB(45, 50, 65)
		else Color3.fromRGB(24, 26, 36)

	selectedTicketId = nil
	renderReadingPane(mailReadingPane, nil)

	if folder == "Inbox" then
		renderMailList(mailListPane, latestTickets, false)
	else
		local list = {}
		for _, ticket in rejectedTickets do
			table.insert(list, ticket)
		end
		table.sort(list, function(a, b)
			return a.id < b.id
		end)
		renderMailList(mailListPane, list, true)
	end
end

local function buildMailWindow(): (Frame, ScrollingFrame, Frame)
	local NORMAL_SIZE = UDim2.new(0.925, -260, 0.85, 0)
	local NORMAL_POSITION = UDim2.new(0.075, 0, 0.03, 0)
	local MAXIMIZED_SIZE = UDim2.new(1, -10, 1, -54)
	local MAXIMIZED_POSITION = UDim2.new(0, 5, 0, 5)
	local maximized = false

	local window = Instance.new("Frame")
	window.Name = "RoMailWindow"
	-- Right edge pinned 260px from the screen edge, clearing RoNotesWidget (220px wide, 20px margin).
	window.Size = NORMAL_SIZE
	window.Position = NORMAL_POSITION
	window.BackgroundColor3 = Color3.fromRGB(30, 33, 44)
	window.Visible = false
	window.ZIndex = 5
	window.Active = true
	addCorner(window, 10)
	addStroke(window, 1.5)

	window.InputBegan:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			bringToFront(window)
		end
	end)

	local titlebar = Instance.new("Frame")
	titlebar.Size = UDim2.new(1, 0, 0, 36)
	titlebar.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	titlebar.ZIndex = 6
	titlebar.Parent = window
	addCorner(titlebar, 10)
	makeDraggable(window, titlebar)

	local titleIcon = makeIconImage(titlebar, ICON_ASSETS["RoMail"], 7)
	titleIcon.Size = UDim2.new(0, 22, 0, 22)
	titleIcon.Position = UDim2.new(0, 8, 0, 7)

	local titleLabel = makeLabel(
		titlebar,
		"RoMail - Local Business Inc.",
		UDim2.new(0, 38, 0, 0),
		UDim2.new(1, -168, 1, 0)
	)
	titleLabel.ZIndex = 7

	local closeButton = makeChunkyButton(
		titlebar,
		"",
		Color3.fromRGB(198, 40, 40),
		UDim2.new(1, -40, 0, 3),
		UDim2.new(0, 30, 0, 30),
		function()
			setMailOpen(false)
		end,
		2
	)
	closeButton.ZIndex = 7
	addCloseGlyph(closeButton, 8)

	local minimizeButton = makeChunkyButton(
		titlebar,
		"",
		Color3.fromRGB(230, 170, 50),
		UDim2.new(1, -110, 0, 3),
		UDim2.new(0, 30, 0, 30),
		function()
			setMailOpen(false)
		end,
		2
	)
	minimizeButton.ZIndex = 7
	addMinimizeGlyph(minimizeButton, 8)

	local maximizeButton = makeChunkyButton(
		titlebar,
		"",
		Color3.fromRGB(90, 96, 110),
		UDim2.new(1, -75, 0, 3),
		UDim2.new(0, 30, 0, 30),
		function()
			maximized = not maximized
			if maximized then
				window.Size = MAXIMIZED_SIZE
				window.Position = MAXIMIZED_POSITION
			else
				window.Size = NORMAL_SIZE
				window.Position = NORMAL_POSITION
			end
		end,
		2
	)
	maximizeButton.ZIndex = 7
	addMaximizeGlyph(maximizeButton, 8)

	local folderPane = Instance.new("Frame")
	folderPane.Size = UDim2.new(0.15, 0, 1, -36)
	folderPane.Position = UDim2.new(0, 0, 0, 36)
	folderPane.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
	folderPane.ZIndex = 6
	folderPane.Parent = window

	inboxFolderButton = Instance.new("TextButton")
	inboxFolderButton.Size = UDim2.new(1, -20, 0, 26)
	inboxFolderButton.Position = UDim2.new(0, 10, 0, 10)
	inboxFolderButton.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
	inboxFolderButton.Text = ""
	inboxFolderButton.ZIndex = 6
	inboxFolderButton.Parent = folderPane
	addCorner(inboxFolderButton, 4)
	local inboxLabel =
		makeLabel(inboxFolderButton, "Inbox", UDim2.new(0, 8, 0, 0), UDim2.new(1, -16, 1, 0))
	inboxLabel.ZIndex = 7
	inboxFolderButton.MouseButton1Click:Connect(function()
		setMailFolder("Inbox")
	end)

	trashFolderButton = Instance.new("TextButton")
	trashFolderButton.Size = UDim2.new(1, -20, 0, 26)
	trashFolderButton.Position = UDim2.new(0, 10, 0, 40)
	trashFolderButton.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
	trashFolderButton.Text = ""
	trashFolderButton.ZIndex = 6
	trashFolderButton.Parent = folderPane
	addCorner(trashFolderButton, 4)
	local trashLabel =
		makeLabel(trashFolderButton, "Trash", UDim2.new(0, 8, 0, 0), UDim2.new(1, -16, 1, 0))
	trashLabel.ZIndex = 7
	trashFolderButton.MouseButton1Click:Connect(function()
		setMailFolder("Trash")
	end)

	local listPane = Instance.new("ScrollingFrame")
	listPane.Size = UDim2.new(0.35, 0, 1, -36)
	listPane.Position = UDim2.new(0.15, 0, 0, 36)
	listPane.BackgroundColor3 = Color3.fromRGB(28, 31, 42)
	listPane.ZIndex = 6
	listPane.Parent = window

	local readingPane = Instance.new("Frame")
	readingPane.Size = UDim2.new(0.5, 0, 1, -36)
	readingPane.Position = UDim2.new(0.5, 0, 0, 36)
	readingPane.BackgroundColor3 = Color3.fromRGB(33, 36, 48)
	readingPane.ZIndex = 6
	readingPane.Parent = window

	renderReadingPane(readingPane, nil)

	return window, listPane, readingPane
end

local function renderDirectoryContent(): ()
	for _, child in directoryContentPane:GetChildren() do
		child:Destroy()
	end

	local entries = if activeDirectoryTab == "Employees"
		then Config.COMPANY_DIRECTORY.staff
		else Config.COMPANY_DIRECTORY.vendors

	for index, entry in entries do
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, -10, 0, 70)
		card.Position = UDim2.new(0, 5, 0, (index - 1) * 75)
		card.BackgroundColor3 = Color3.fromRGB(28, 31, 42)
		card.ZIndex = 7
		card.Parent = directoryContentPane
		addCorner(card, 6)

		local nameLabel =
			makeLabel(card, entry.name, UDim2.new(0, 10, 0, 6), UDim2.new(1, -20, 0, 20))
		nameLabel.ZIndex = 8

		local info = Instance.new("TextLabel")
		info.Size = UDim2.new(1, -20, 0, 40)
		info.Position = UDim2.new(0, 10, 0, 28)
		info.BackgroundTransparency = 1
		info.Font = Enum.Font.Code
		info.TextSize = 13
		info.TextColor3 = Color3.fromRGB(110, 220, 140)
		info.TextXAlignment = Enum.TextXAlignment.Left
		info.TextYAlignment = Enum.TextYAlignment.Top
		info.TextWrapped = true
		info.Text = if activeDirectoryTab == "Employees"
			then string.format("%s\n%s | %s", entry.title, entry.email, entry.phone)
			else string.format(
				"%s\nRouting: %s | Acct: %s",
				entry.email,
				entry.routing,
				entry.account
			)
		info.ZIndex = 8
		info.Parent = card
	end

	directoryContentPane.CanvasSize = UDim2.new(0, 0, 0, #entries * 75)
end

local function setDirectoryTab(tab: "Employees" | "Vendors"): ()
	activeDirectoryTab = tab
	employeesTabButton.BackgroundColor3 = if tab == "Employees"
		then Color3.fromRGB(55, 60, 80)
		else Color3.fromRGB(38, 42, 56)
	vendorsTabButton.BackgroundColor3 = if tab == "Vendors"
		then Color3.fromRGB(55, 60, 80)
		else Color3.fromRGB(38, 42, 56)
	renderDirectoryContent()
end

local function buildDirectoryWindow(): Frame
	local window = Instance.new("Frame")
	window.Name = "DirectoryWindow"
	window.Size = UDim2.new(0.5, 0, 0.7, 0)
	window.Position = UDim2.new(0.25, 0, 0.15, 0)
	window.BackgroundColor3 = Color3.fromRGB(30, 33, 44)
	window.Visible = false
	window.ZIndex = 5
	window.Active = true
	addCorner(window, 10)
	addStroke(window, 1.5)

	window.InputBegan:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			bringToFront(window)
		end
	end)

	local titlebar = Instance.new("Frame")
	titlebar.Size = UDim2.new(1, 0, 0, 36)
	titlebar.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	titlebar.ZIndex = 6
	titlebar.Parent = window
	addCorner(titlebar, 10)
	makeDraggable(window, titlebar)

	local titleIcon = makeIconImage(titlebar, ICON_ASSETS["Directory"], 7)
	titleIcon.Size = UDim2.new(0, 22, 0, 22)
	titleIcon.Position = UDim2.new(0, 8, 0, 7)

	local titleLabel = makeLabel(
		titlebar,
		"Company Directory - Verified Contacts",
		UDim2.new(0, 38, 0, 0),
		UDim2.new(1, -98, 1, 0)
	)
	titleLabel.ZIndex = 7

	local closeButton = makeChunkyButton(
		titlebar,
		"",
		Color3.fromRGB(198, 40, 40),
		UDim2.new(1, -40, 0, 3),
		UDim2.new(0, 30, 0, 30),
		function()
			setDirectoryOpen(false)
		end,
		2
	)
	closeButton.ZIndex = 7
	addCloseGlyph(closeButton, 8)

	local minimizeButton = makeChunkyButton(
		titlebar,
		"",
		Color3.fromRGB(230, 170, 50),
		UDim2.new(1, -75, 0, 3),
		UDim2.new(0, 30, 0, 30),
		function()
			setDirectoryOpen(false)
		end,
		2
	)
	minimizeButton.ZIndex = 7
	addMinimizeGlyph(minimizeButton, 8)

	local tabHeader = Instance.new("Frame")
	tabHeader.Size = UDim2.new(1, 0, 0, 36)
	tabHeader.Position = UDim2.new(0, 0, 0, 36)
	tabHeader.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
	tabHeader.ZIndex = 6
	tabHeader.Parent = window

	employeesTabButton = makeChunkyButton(
		tabHeader,
		"[Employees]",
		Color3.fromRGB(55, 60, 80),
		UDim2.new(0, 10, 0, 3),
		UDim2.new(0, 160, 0, 30),
		function()
			setDirectoryTab("Employees")
		end
	)
	employeesTabButton.ZIndex = 7

	vendorsTabButton = makeChunkyButton(
		tabHeader,
		"[Approved Vendors]",
		Color3.fromRGB(38, 42, 56),
		UDim2.new(0, 180, 0, 3),
		UDim2.new(0, 180, 0, 30),
		function()
			setDirectoryTab("Vendors")
		end
	)
	vendorsTabButton.ZIndex = 7

	local contentPane = Instance.new("ScrollingFrame")
	contentPane.Size = UDim2.new(1, 0, 1, -72)
	contentPane.Position = UDim2.new(0, 0, 0, 72)
	contentPane.BackgroundColor3 = Color3.fromRGB(28, 31, 42)
	contentPane.ZIndex = 6
	contentPane.Parent = window

	directoryContentPane = contentPane
	renderDirectoryContent()

	return window
end

local function buildWallpaper(): Frame
	local wallpaper = Instance.new("Frame")
	wallpaper.Name = "BloxWallpaper"
	wallpaper.Size = UDim2.new(1, 0, 1, 0)
	wallpaper.BackgroundColor3 = Color3.fromRGB(10, 18, 30)
	wallpaper.ZIndex = 1

	if Config.WALLPAPER_ASSET_ID ~= "" then
		local image = Instance.new("ImageLabel")
		image.Size = UDim2.new(1, 0, 1, 0)
		image.BackgroundTransparency = 1
		image.Image = Config.WALLPAPER_ASSET_ID
		image.ScaleType = Enum.ScaleType.Crop
		image.ZIndex = 1
		image.Parent = wallpaper
		return wallpaper
	end

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 22, 38)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 44, 56)),
	})
	gradient.Rotation = 90
	gradient.Parent = wallpaper

	local studColumns, studRows = 8, 5
	local studDiameter = 60
	for col = 0, studColumns - 1 do
		for row = 0, studRows - 1 do
			local stud = Instance.new("Frame")
			stud.Size = UDim2.new(0, studDiameter, 0, studDiameter)
			stud.AnchorPoint = Vector2.new(0.5, 0.5)
			stud.Position = UDim2.new((col + 0.5) / studColumns, 0, (row + 0.5) / studRows, 0)
			stud.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			stud.BackgroundTransparency = 0.9
			stud.ZIndex = 1
			stud.Parent = wallpaper
			addCorner(stud, studDiameter // 2)
		end
	end

	return wallpaper
end

local function buildDesktopIcons(): Frame
	local column = Instance.new("Frame")
	column.Name = "DesktopIcons"
	column.Size = UDim2.new(0, 90, 1, -44)
	column.BackgroundTransparency = 1
	column.ZIndex = 2

	local icons = { "RoMail", "RoNotes", "Directory" }
	for index, iconName in icons do
		local iconButton = Instance.new("TextButton")
		iconButton.Size = UDim2.new(0, 80, 0, 70)
		iconButton.Position = UDim2.new(0, 5, 0, (index - 1) * 85 + 10)
		iconButton.BackgroundColor3 = Color3.fromRGB(28, 34, 48)
		iconButton.BackgroundTransparency = 1
		iconButton.Text = ""
		iconButton.ZIndex = 2
		iconButton.Parent = column

		iconButton.MouseEnter:Connect(function()
			TweenService:Create(iconButton, TweenInfo.new(0.15), { BackgroundTransparency = 0.8 })
				:Play()
		end)
		iconButton.MouseLeave:Connect(function()
			TweenService:Create(iconButton, TweenInfo.new(0.15), { BackgroundTransparency = 1 })
				:Play()
		end)

		local badge = makeIconImage(iconButton, ICON_ASSETS[iconName], 3)
		badge.Position = UDim2.new(0.5, -18, 0, 6)

		local caption =
			makeLabel(iconButton, iconName, UDim2.new(0, 2, 0, 46), UDim2.new(1, -4, 0, 20))
		caption.TextSize = 12
		caption.TextXAlignment = Enum.TextXAlignment.Center
		caption.TextStrokeTransparency = 0.5
		caption.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		caption.ZIndex = 2

		if iconName == "RoMail" then
			iconButton.MouseButton1Click:Connect(function()
				setMailOpen(not mailOpen)
			end)
		elseif iconName == "Directory" then
			iconButton.MouseButton1Click:Connect(function()
				setDirectoryOpen(not directoryOpen)
			end)
		elseif iconName == "RoNotes" then
			iconButton.MouseButton1Click:Connect(function()
				roNotesWidget.Visible = not roNotesWidget.Visible
			end)
		end
	end

	return column
end

local function buildTaskbar(): (Frame, TextLabel)
	local taskbar = Instance.new("Frame")
	taskbar.Name = "Taskbar"
	taskbar.Size = UDim2.new(1, 0, 0, 44)
	taskbar.Position = UDim2.new(0, 0, 1, -44)
	taskbar.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
	taskbar.ZIndex = 3
	addStroke(taskbar, 1)

	local startButton = Instance.new("TextButton")
	startButton.Size = UDim2.new(0, 90, 0, 34)
	startButton.Position = UDim2.new(0, 5, 0, 5)
	startButton.BackgroundColor3 = Color3.fromRGB(70, 130, 220)
	startButton.Text = ""
	startButton.ZIndex = 3
	startButton.Parent = taskbar
	addCorner(startButton, 8)
	addStroke(startButton, 1.5)

	local startIconHolder = Instance.new("Frame")
	startIconHolder.Size = UDim2.new(0, 34, 0, 34)
	startIconHolder.BackgroundTransparency = 1
	startIconHolder.ZIndex = 3
	startIconHolder.Parent = startButton
	buildDiamondLogo(startIconHolder, 4, 16)

	local startLabel =
		makeLabel(startButton, "Log Off", UDim2.new(0, 38, 0, 0), UDim2.new(1, -42, 1, 0))
	startLabel.TextSize = 12
	startLabel.ZIndex = 4

	startButton.MouseButton1Click:Connect(function()
		screenGui.Enabled = false
	end)

	local mailAppButton = Instance.new("TextButton")
	mailAppButton.Size = UDim2.new(0, 60, 0, 34)
	mailAppButton.Position = UDim2.new(0, 100, 0, 5)
	mailAppButton.BackgroundColor3 = Color3.fromRGB(40, 44, 56)
	mailAppButton.Text = ""
	mailAppButton.ZIndex = 3
	mailAppButton.Parent = taskbar
	addCorner(mailAppButton, 6)
	local mailAppIcon = makeIconImage(mailAppButton, ICON_ASSETS["RoMail"], 4)
	mailAppIcon.Size = UDim2.new(0, 22, 0, 22)
	mailAppIcon.Position = UDim2.new(0, 6, 0, 6)
	local mailAppLabel =
		makeLabel(mailAppButton, "Mail", UDim2.new(0, 30, 0, 0), UDim2.new(1, -36, 1, 0))
	mailAppLabel.TextSize = 12
	mailAppLabel.ZIndex = 4
	mailTaskbarUnderline = Instance.new("Frame")
	mailTaskbarUnderline.Size = UDim2.new(0, 40, 0, 2)
	mailTaskbarUnderline.Position = UDim2.new(0, 10, 1, -3)
	mailTaskbarUnderline.BackgroundColor3 = Color3.fromRGB(94, 160, 226)
	mailTaskbarUnderline.Visible = false
	mailTaskbarUnderline.ZIndex = 4
	mailTaskbarUnderline.Parent = mailAppButton
	mailAppButton.MouseButton1Click:Connect(function()
		setMailOpen(not mailOpen)
	end)

	local directoryAppButton = Instance.new("TextButton")
	directoryAppButton.Size = UDim2.new(0, 80, 0, 34)
	directoryAppButton.Position = UDim2.new(0, 165, 0, 5)
	directoryAppButton.BackgroundColor3 = Color3.fromRGB(40, 44, 56)
	directoryAppButton.Text = ""
	directoryAppButton.ZIndex = 3
	directoryAppButton.Parent = taskbar
	addCorner(directoryAppButton, 6)
	local directoryAppIcon = makeIconImage(directoryAppButton, ICON_ASSETS["Directory"], 4)
	directoryAppIcon.Size = UDim2.new(0, 22, 0, 22)
	directoryAppIcon.Position = UDim2.new(0, 6, 0, 6)
	local directoryAppLabel =
		makeLabel(directoryAppButton, "Directory", UDim2.new(0, 30, 0, 0), UDim2.new(1, -36, 1, 0))
	directoryAppLabel.TextSize = 12
	directoryAppLabel.ZIndex = 4
	directoryTaskbarUnderline = Instance.new("Frame")
	directoryTaskbarUnderline.Size = UDim2.new(0, 60, 0, 2)
	directoryTaskbarUnderline.Position = UDim2.new(0, 10, 1, -3)
	directoryTaskbarUnderline.BackgroundColor3 = Color3.fromRGB(94, 160, 226)
	directoryTaskbarUnderline.Visible = false
	directoryTaskbarUnderline.ZIndex = 4
	directoryTaskbarUnderline.Parent = directoryAppButton
	directoryAppButton.MouseButton1Click:Connect(function()
		setDirectoryOpen(not directoryOpen)
	end)

	local wifiIcon = buildWifiIcon(taskbar, 4)
	wifiIcon.Position = UDim2.new(1, -150, 0, 14)

	local speakerIcon = buildSpeakerIcon(taskbar, 4)
	speakerIcon.Position = UDim2.new(1, -128, 0, 14)

	local clockLabel =
		makeLabel(taskbar, "09:00 AM", UDim2.new(1, -110, 0, 10), UDim2.new(0, 100, 0, 24))
	clockLabel.TextXAlignment = Enum.TextXAlignment.Right
	clockLabel.ZIndex = 3

	return taskbar, clockLabel
end

local function buildRoNotes(): (Frame, TextLabel)
	local note = Instance.new("Frame")
	note.Name = "RoNotesWidget"
	note.Size = UDim2.new(0, 220, 0, 220)
	note.Position = UDim2.new(1, -240, 0, 20)
	note.BackgroundColor3 = Color3.fromRGB(255, 247, 160)
	note.ZIndex = 2
	addCorner(note, 4)
	addStroke(note, 1)

	local tape = Instance.new("Frame")
	tape.Size = UDim2.new(0, 50, 0, 16)
	tape.Position = UDim2.new(0.5, -25, 0, -8)
	tape.BackgroundColor3 = Color3.fromRGB(220, 220, 210)
	tape.BackgroundTransparency = 0.3
	tape.Rotation = -3
	tape.ZIndex = 2
	tape.Parent = note

	local header =
		makeLabel(note, "Shift Red Flags", UDim2.new(0, 8, 0, 6), UDim2.new(1, -16, 0, 20))
	header.TextColor3 = Color3.fromRGB(40, 40, 20)
	header.ZIndex = 2

	local body = Instance.new("TextLabel")
	body.Name = "GuidelinesText"
	body.Size = UDim2.new(1, -16, 1, -34)
	body.Position = UDim2.new(0, 8, 0, 30)
	body.BackgroundTransparency = 1
	body.TextColor3 = Color3.fromRGB(40, 40, 20)
	body.Font = Enum.Font.Gotham
	body.TextSize = 12
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.ZIndex = 2
	body.Parent = note

	return note, body
end

local function buildModal(): Frame
	local modal = Instance.new("Frame")
	modal.Name = "Modal"
	modal.Size = UDim2.new(0, 400, 0, 260)
	modal.Position = UDim2.new(0.5, -200, 0.5, -130)
	modal.BackgroundColor3 = Color3.fromRGB(30, 33, 44)
	modal.Visible = false
	modal.ZIndex = 10
	addCorner(modal, 10)
	addStroke(modal, 1.5)
	return modal
end

local function renderModal(modal: Frame, state: GameState): ()
	for _, child in modal:GetChildren() do
		child:Destroy()
	end

	if state.phase == "Lobby" then
		modal.Visible = true
		makeLabel(
			modal,
			"Local Business Inc. - Tier 1",
			UDim2.new(0, 10, 0, 10),
			UDim2.new(1, -20, 0, 24)
		).ZIndex =
			10
		makeLabel(
			modal,
			string.format("%s - Day %d", dayName(state.day), state.day),
			UDim2.new(0, 10, 0, 40),
			UDim2.new(1, -20, 0, 24)
		).ZIndex =
			10
		makeLabel(
			modal,
			string.format(
				"Quota: Process %d, Catch %d",
				state.quota.minProcessed,
				state.quota.minScams
			),
			UDim2.new(0, 10, 0, 70),
			UDim2.new(1, -20, 0, 24)
		).ZIndex =
			10
		local clockIn = makeChunkyButton(
			modal,
			"[Clock In]",
			Color3.fromRGB(70, 160, 70),
			UDim2.new(0, 10, 0, 200),
			UDim2.new(0, 160, 0, 36),
			function()
				startShift:FireServer()
			end
		)
		clockIn.ZIndex = 10
	elseif state.phase == "Summary" and state.lastSummary then
		local summary = state.lastSummary :: ShiftSummary
		modal.Visible = true
		makeLabel(
			modal,
			string.format("%s - Day %d Summary", dayName(state.day), state.day),
			UDim2.new(0, 10, 0, 10),
			UDim2.new(1, -20, 0, 24)
		).ZIndex =
			10
		makeLabel(
			modal,
			string.format("Quota: %s", if summary.quotaPassed then "Met" else "Missed"),
			UDim2.new(0, 10, 0, 40),
			UDim2.new(1, -20, 0, 24)
		).ZIndex =
			10
		makeLabel(
			modal,
			string.format("Scams Blocked: %d", summary.caught),
			UDim2.new(0, 10, 0, 70),
			UDim2.new(1, -20, 0, 24)
		).ZIndex =
			10
		makeLabel(
			modal,
			string.format("Scams Slipped Through: %d (-$%d)", summary.missed, summary.scamLosses),
			UDim2.new(0, 10, 0, 100),
			UDim2.new(1, -20, 0, 24)
		).ZIndex =
			10
		makeLabel(
			modal,
			string.format(
				"Legit Tickets Rejected: %d (-$%d)",
				summary.falseRejections,
				summary.falseRejectPenalties
			),
			UDim2.new(0, 10, 0, 130),
			UDim2.new(1, -20, 0, 24)
		).ZIndex =
			10
		makeLabel(
			modal,
			string.format("Budget Remaining: $%d", summary.budgetLeft),
			UDim2.new(0, 10, 0, 160),
			UDim2.new(1, -20, 0, 24)
		).ZIndex =
			10
		local nextDayButton = makeChunkyButton(
			modal,
			"[Next Day]",
			Color3.fromRGB(70, 160, 70),
			UDim2.new(0, 10, 0, 210),
			UDim2.new(0, 160, 0, 36),
			function()
				nextDay:FireServer()
			end
		)
		nextDayButton.ZIndex = 10
	elseif state.phase == "GameOver" then
		modal.Visible = true
		makeLabel(modal, "Everyone is fired", UDim2.new(0, 10, 0, 10), UDim2.new(1, -20, 0, 24)).ZIndex =
			10
	else
		modal.Visible = false
	end
end

local function sortedTickets(tickets: { ClientTicket }): { ClientTicket }
	local copy = table.clone(tickets)
	table.sort(copy, function(a, b)
		return a.id < b.id
	end)
	return copy
end

local function ticketSignature(tickets: { ClientTicket }): string
	local ids = {}
	for _, ticket in tickets do
		table.insert(ids, ticket.id)
	end
	return table.concat(ids, ",")
end

local function render(state: GameState): ()
	local tickets = sortedTickets(state.tickets)
	local signature = ticketSignature(tickets)

	if signature ~= lastTicketSignature then
		lastTicketSignature = signature
		latestTickets = tickets

		if activeMailFolder == "Inbox" then
			renderMailList(mailListPane, tickets, false)

			local stillValid = false
			for _, ticket in tickets do
				if ticket.id == selectedTicketId then
					stillValid = true
					break
				end
			end
			if not stillValid then
				selectedTicketId = if #tickets > 0 then tickets[1].id else nil
			end

			local selected: ClientTicket? = nil
			for _, ticket in tickets do
				if ticket.id == selectedTicketId then
					selected = ticket
					break
				end
			end
			renderReadingPane(mailReadingPane, selected, false)
		end
	end

	if state.phase == "Lobby" then
		hasAutoOpenedThisShift = false
		rejectedTickets = {}
		if activeMailFolder == "Trash" then
			setMailFolder("Inbox")
		end
	end
	if state.phase == "InShift" and not hasAutoOpenedThisShift then
		hasAutoOpenedThisShift = true
		setMailOpen(true)
	end

	taskbarClockLabel.Text = formatClock(state.shiftMinutes)

	local lines = {}
	for _, guideline in state.guidelines do
		table.insert(lines, "- " .. guideline)
	end
	roNotesText.Text = table.concat(lines, "\n")

	renderModal(summaryModal, state)
end

local function connectComputerPrompt(): ()
	local bakeryLevel = Workspace:WaitForChild("BakeryLevel", 5)
	if not bakeryLevel then
		return
	end
	local workstation = bakeryLevel:WaitForChild("ITWorkstation", 5)
	if not workstation then
		return
	end
	local screen = workstation:WaitForChild("ITScreen", 5)
	if not screen then
		return
	end
	local prompt = screen:WaitForChild("ComputerPrompt", 5)
	if not prompt then
		return
	end

	(prompt :: ProximityPrompt).Triggered:Connect(function(triggeringPlayer: Player)
		if triggeringPlayer == player then
			screenGui.Enabled = true
		end
	end)
end

function DesktopUI.init(): ()
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	gameStateSync = remotesFolder:WaitForChild("GameStateSync") :: RemoteEvent
	submitDecision = remotesFolder:WaitForChild("SubmitDecision") :: RemoteEvent
	startShift = remotesFolder:WaitForChild("StartShift") :: RemoteEvent
	nextDay = remotesFolder:WaitForChild("NextDay") :: RemoteEvent

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DesktopUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false

	local wallpaper = buildWallpaper()
	wallpaper.Parent = screenGui

	local icons = buildDesktopIcons()
	icons.Parent = screenGui

	local taskbar: Frame
	taskbar, taskbarClockLabel = buildTaskbar()
	taskbar.Parent = screenGui

	roNotesWidget, roNotesText = buildRoNotes()
	roNotesWidget.Parent = screenGui

	mailWindow, mailListPane, mailReadingPane = buildMailWindow()
	mailWindow.Parent = screenGui

	directoryWindow = buildDirectoryWindow()
	directoryWindow.Parent = screenGui

	summaryModal = buildModal()
	summaryModal.Parent = screenGui

	screenGui.Parent = player:WaitForChild("PlayerGui")

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if gameProcessedEvent then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape and screenGui.Enabled then
			screenGui.Enabled = false
		end
	end)

	task.spawn(connectComputerPrompt)
end

function DesktopUI.start(): ()
	gameStateSync.OnClientEvent:Connect(render)
end

return DesktopUI
