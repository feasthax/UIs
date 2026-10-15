--// FlowUI — Custom UI Library for Flow
--// Loadstring-compatible, no external dependencies
--// Supports: Tabs, Toggles, Dropdowns (single + multi), Labels, Buttons, Inputs, ViewportFrames

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local FlowUI = {}
FlowUI.__index = FlowUI

local COLORS = {
	bg = Color3.fromRGB(12, 12, 18),
	sidebar = Color3.fromRGB(16, 16, 24),
	content = Color3.fromRGB(18, 18, 26),
	card = Color3.fromRGB(22, 22, 32),
	cardHover = Color3.fromRGB(28, 28, 40),
	accent = Color3.fromRGB(140, 90, 255),
	accentDim = Color3.fromRGB(100, 65, 180),
	text = Color3.fromRGB(230, 230, 240),
	textDim = Color3.fromRGB(140, 140, 155),
	textMuted = Color3.fromRGB(90, 90, 105),
	border = Color3.fromRGB(35, 30, 50),
	toggleOn = Color3.fromRGB(140, 90, 255),
	toggleOff = Color3.fromRGB(50, 50, 65),
	toggleKnob = Color3.fromRGB(255, 255, 255),
	dropdownBg = Color3.fromRGB(15, 15, 22),
	scrollBar = Color3.fromRGB(80, 70, 110),
	gold = Color3.fromRGB(255, 215, 0),
	red = Color3.fromRGB(255, 70, 70),
	green = Color3.fromRGB(80, 220, 120),
	headerBg = Color3.fromRGB(20, 18, 30),
}

local FONT = {
	bold = Enum.Font.GothamBold,
	semibold = Enum.Font.GothamSemibold,
	regular = Enum.Font.Gotham,
	mono = Enum.Font.RobotoMono,
}

local RARITY_COLORS = {
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(100, 200, 100),
	Rare = Color3.fromRGB(80, 160, 255),
	Epic = Color3.fromRGB(180, 80, 255),
	Legendary = Color3.fromRGB(255, 170, 0),
	Mythical = Color3.fromRGB(255, 50, 80),
	Secret = Color3.fromRGB(255, 215, 0),
	Secret2 = Color3.fromRGB(255, 215, 0),
	Secret3 = Color3.fromRGB(255, 215, 0),
}

-- Globals for compatibility
if not getgenv().Toggles then getgenv().Toggles = {} end
if not getgenv().Options then getgenv().Options = {} end
local Toggles = getgenv().Toggles
local Options = getgenv().Options

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = parent
	return c
end

local function stroke(parent, col, thick)
	local s = Instance.new("UIStroke")
	s.Color = col or COLORS.border
	s.Thickness = thick or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function tween(obj, props, dur)
	TweenService:Create(obj, TweenInfo.new(dur or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function comma(n)
	local s = tostring(math.floor(n))
	return s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

----------------------------------------------------------------------
-- TOGGLE OBJECT (compatibility with LinoriaLib Toggles[id])
----------------------------------------------------------------------
local ToggleObj = {}
ToggleObj.__index = ToggleObj

function ToggleObj.new(id, default, callback)
	local self = setmetatable({}, ToggleObj)
	self.Value = default
	self._id = id
	self._callback = callback
	self._visual = nil
	Toggles[id] = self
	return self
end

function ToggleObj:SetValue(val)
	self.Value = val
	if self._visual then self:_updateVisual() end
	if self._callback then pcall(self._callback, val) end
end

function ToggleObj:_updateVisual()
	if not self._visual then return end
	local knob = self._visual:FindFirstChild("Knob")
	local bg = self._visual
	if self.Value then
		tween(bg, {BackgroundColor3 = COLORS.toggleOn}, 0.15)
		tween(knob, {Position = UDim2.new(1, -18, 0.5, -7)}, 0.15)
	else
		tween(bg, {BackgroundColor3 = COLORS.toggleOff}, 0.15)
		tween(knob, {Position = UDim2.new(0, 4, 0.5, -7)}, 0.15)
	end
end

----------------------------------------------------------------------
-- DROPDOWN OBJECT (compatibility with LinoriaLib Options[id])
----------------------------------------------------------------------
local DropdownObj = {}
DropdownObj.__index = DropdownObj

function DropdownObj.new(id, default, values, multi, callback)
	local self = setmetatable({}, DropdownObj)
	self.Value = default
	self._id = id
	self._values = values
	self._multi = multi
	self._callback = callback
	self._displayLabel = nil
	self._listFrame = nil
	Options[id] = self
	return self
end

function DropdownObj:SetValue(val)
	self.Value = val
	self:_updateDisplay()
	if self._callback then pcall(self._callback, val) end
end

function DropdownObj:SetValues(newValues)
	self._values = newValues
	if self._listFrame then
		self:_rebuildList()
	end
end

function DropdownObj:_getDisplayText()
	if self._multi then
		if type(self.Value) ~= "table" then return "None" end
		local selected = {}
		for k, v in self.Value do
			if v then table.insert(selected, tostring(k)) end
		end
		if #selected == 0 then return "None" end
		if #selected <= 2 then return table.concat(selected, ", ") end
		return #selected .. " selected"
	else
		return self.Value and tostring(self.Value) or "None"
	end
end

function DropdownObj:_updateDisplay()
	if self._displayLabel then
		pcall(function() self._displayLabel.Text = self:_getDisplayText() end)
	end
end

function DropdownObj:_rebuildList()
	if not self._listFrame then return end
	for _, c in self._listFrame:GetChildren() do
		if c:IsA("TextButton") then c:Destroy() end
	end
	for _, val in self._values do
		self:_addListItem(val)
	end
end

function DropdownObj:_addListItem(val)
	if not self._listFrame then return end
	local isSelected = false
	if self._multi then
		isSelected = type(self.Value) == "table" and self.Value[val] == true
	else
		isSelected = self.Value == val
	end

	local btn = Instance.new("TextButton")
	btn.Name = "Item_" .. val
	btn.Size = UDim2.new(1, -4, 0, 26)
	btn.BackgroundColor3 = isSelected and COLORS.accent or COLORS.dropdownBg
	btn.BackgroundTransparency = isSelected and 0.7 or 1
	btn.BorderSizePixel = 0
	btn.Text = "  " .. val
	btn.TextColor3 = isSelected and COLORS.text or COLORS.textDim
	btn.Font = FONT.regular
	btn.TextSize = 12
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.TextTruncate = Enum.TextTruncate.AtEnd
	btn.AutoButtonColor = false
	btn.Parent = self._listFrame
	corner(btn, 4)

	btn.MouseEnter:Connect(function()
		if not (self._multi and type(self.Value) == "table" and self.Value[val]) and self.Value ~= val then
			tween(btn, {BackgroundTransparency = 0.8, BackgroundColor3 = COLORS.cardHover}, 0.1)
		end
	end)
	btn.MouseLeave:Connect(function()
		local sel = self._multi and type(self.Value) == "table" and self.Value[val] or self.Value == val
		if not sel then
			tween(btn, {BackgroundTransparency = 1, BackgroundColor3 = COLORS.dropdownBg}, 0.1)
		end
	end)

	btn.MouseButton1Click:Connect(function()
		if self._multi then
			if type(self.Value) ~= "table" then self.Value = {} end
			self.Value[val] = not self.Value[val]
			if not self.Value[val] then self.Value[val] = nil end
			local sel = self.Value[val] == true
			tween(btn, {BackgroundColor3 = sel and COLORS.accent or COLORS.dropdownBg, BackgroundTransparency = sel and 0.7 or 1}, 0.1)
			btn.TextColor3 = sel and COLORS.text or COLORS.textDim
		else
			self.Value = val
			for _, c in self._listFrame:GetChildren() do
				if c:IsA("TextButton") then
					local s = c.Name == "Item_" .. val
					tween(c, {BackgroundColor3 = s and COLORS.accent or COLORS.dropdownBg, BackgroundTransparency = s and 0.7 or 1}, 0.1)
					c.TextColor3 = s and COLORS.text or COLORS.textDim
				end
			end
		end
		self:_updateDisplay()
		if self._callback then pcall(self._callback, self.Value) end
	end)
end

----------------------------------------------------------------------
-- GROUPBOX (container for controls within a tab column)
----------------------------------------------------------------------
local Groupbox = {}
Groupbox.__index = Groupbox

function Groupbox.new(title, parent)
	local self = setmetatable({}, Groupbox)

	self._frame = Instance.new("Frame")
	self._frame.Name = "Group_" .. title
	self._frame.Size = UDim2.new(1, -8, 0, 0)
	self._frame.AutomaticSize = Enum.AutomaticSize.Y
	self._frame.BackgroundColor3 = COLORS.card
	self._frame.BackgroundTransparency = 0.3
	self._frame.BorderSizePixel = 0
	self._frame.Parent = parent
	corner(self._frame, 8)
	stroke(self._frame, COLORS.border, 1)

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = self._frame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = self._frame

	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 18)
	header.BackgroundTransparency = 1
	header.Text = title
	header.TextColor3 = COLORS.accent
	header.Font = FONT.bold
	header.TextSize = 13
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.LayoutOrder = 0
	header.Parent = self._frame

	self._order = 0
	return self
end

function Groupbox:_nextOrder()
	self._order += 1
	return self._order
end

function Groupbox:AddToggle(id, opts)
	opts = opts or {}
	local order = self:_nextOrder()
	local default = opts.Default or false

	local row = Instance.new("Frame")
	row.Name = "Toggle_" .. id
	row.Size = UDim2.new(1, 0, 0, 24)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.Parent = self._frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -50, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = opts.Text or id
	label.TextColor3 = COLORS.text
	label.Font = FONT.regular
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	if opts.Tooltip then
		label.Text = label.Text
	end

	local toggleBg = Instance.new("Frame")
	toggleBg.Name = "ToggleBg"
	toggleBg.Size = UDim2.new(0, 36, 0, 18)
	toggleBg.Position = UDim2.new(1, -36, 0.5, -9)
	toggleBg.BackgroundColor3 = default and COLORS.toggleOn or COLORS.toggleOff
	toggleBg.BorderSizePixel = 0
	toggleBg.Parent = row
	corner(toggleBg, 9)

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.Position = default and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 4, 0.5, -7)
	knob.BackgroundColor3 = COLORS.toggleKnob
	knob.BorderSizePixel = 0
	knob.Parent = toggleBg
	corner(knob, 7)

	local toggle = ToggleObj.new(id, default, opts.Callback)
	toggle._visual = toggleBg

	local clickBtn = Instance.new("TextButton")
	clickBtn.Size = UDim2.new(1, 0, 1, 0)
	clickBtn.BackgroundTransparency = 1
	clickBtn.Text = ""
	clickBtn.Parent = row

	clickBtn.MouseButton1Click:Connect(function()
		toggle:SetValue(not toggle.Value)
	end)

	return toggle
end

function Groupbox:AddDropdown(id, opts)
	opts = opts or {}
	local order = self:_nextOrder()

	local container = Instance.new("Frame")
	container.Name = "Dropdown_" .. id
	container.Size = UDim2.new(1, 0, 0, 20)
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.BackgroundTransparency = 1
	container.LayoutOrder = order
	container.Parent = self._frame

	local innerLayout = Instance.new("UIListLayout")
	innerLayout.Padding = UDim.new(0, 3)
	innerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	innerLayout.Parent = container

	local headerRow = Instance.new("Frame")
	headerRow.Name = "Header"
	headerRow.Size = UDim2.new(1, 0, 0, 20)
	headerRow.BackgroundTransparency = 1
	headerRow.LayoutOrder = 1
	headerRow.Parent = container

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(0.4, 0, 1, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = opts.Text or id
	titleLbl.TextColor3 = COLORS.textDim
	titleLbl.Font = FONT.regular
	titleLbl.TextSize = 12
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = headerRow

	local dd = DropdownObj.new(id, opts.Default or (opts.Multi and {} or nil), opts.Values or {}, opts.Multi, opts.Callback)

	local valueLbl = Instance.new("TextLabel")
	valueLbl.Name = "Value"
	valueLbl.Size = UDim2.new(0.6, 0, 1, 0)
	valueLbl.BackgroundTransparency = 1
	valueLbl.Text = dd:_getDisplayText()
	valueLbl.TextColor3 = COLORS.text
	valueLbl.Font = FONT.semibold
	valueLbl.TextSize = 12
	valueLbl.TextXAlignment = Enum.TextXAlignment.Right
	valueLbl.TextTruncate = Enum.TextTruncate.AtEnd
	valueLbl.Parent = headerRow
	dd._displayLabel = valueLbl

	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Name = "List"
	listFrame.Size = UDim2.new(1, 0, 0, 0)
	listFrame.BackgroundColor3 = COLORS.dropdownBg
	listFrame.BackgroundTransparency = 0.1
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarThickness = 3
	listFrame.ScrollBarImageColor3 = COLORS.scrollBar
	listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.Visible = false
	listFrame.LayoutOrder = 2
	listFrame.ClipsDescendants = true
	listFrame.Parent = container
	corner(listFrame, 4)

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 2)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = listFrame

	local listPad = Instance.new("UIPadding")
	listPad.PaddingTop = UDim.new(0, 2)
	listPad.PaddingBottom = UDim.new(0, 2)
	listPad.PaddingLeft = UDim.new(0, 2)
	listPad.PaddingRight = UDim.new(0, 2)
	listPad.Parent = listFrame

	dd._listFrame = listFrame

	for _, val in opts.Values or {} do
		dd:_addListItem(val)
	end

	local expanded = false
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(1, 0, 1, 0)
	toggleBtn.BackgroundTransparency = 1
	toggleBtn.Text = ""
	toggleBtn.Parent = headerRow

	toggleBtn.MouseButton1Click:Connect(function()
		expanded = not expanded
		listFrame.Visible = expanded
		if expanded then
			local itemCount = 0
			for _, c in listFrame:GetChildren() do
				if c:IsA("TextButton") then itemCount += 1 end
			end
			local h = math.min(itemCount * 28, 160)
			listFrame.Size = UDim2.new(1, 0, 0, h)
		else
			listFrame.Size = UDim2.new(1, 0, 0, 0)
		end
	end)

	return dd
end

function Groupbox:AddLabel(text)
	local order = self:_nextOrder()

	local lbl = Instance.new("TextLabel")
	lbl.Name = "Label_" .. order
	lbl.Size = UDim2.new(1, 0, 0, 0)
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.BackgroundTransparency = 1
	lbl.Text = text or ""
	lbl.TextColor3 = COLORS.textDim
	lbl.Font = FONT.regular
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextWrapped = true
	lbl.LayoutOrder = order
	lbl.RichText = true
	lbl.Parent = self._frame

	local obj = {_label = lbl}
	function obj:SetText(t) pcall(function() lbl.Text = t end) end
	function obj:GetText() return lbl.Text end
	return obj
end

function Groupbox:AddButton(text, callback)
	local order = self:_nextOrder()

	local btn = Instance.new("TextButton")
	btn.Name = "Button_" .. text
	btn.Size = UDim2.new(1, 0, 0, 28)
	btn.BackgroundColor3 = COLORS.accent
	btn.BackgroundTransparency = 0.5
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = COLORS.text
	btn.Font = FONT.semibold
	btn.TextSize = 13
	btn.AutoButtonColor = false
	btn.LayoutOrder = order
	btn.Parent = self._frame
	corner(btn, 6)

	btn.MouseEnter:Connect(function() tween(btn, {BackgroundTransparency = 0.3}, 0.1) end)
	btn.MouseLeave:Connect(function() tween(btn, {BackgroundTransparency = 0.5}, 0.1) end)
	btn.MouseButton1Click:Connect(function()
		if callback then pcall(callback) end
	end)

	return btn
end

function Groupbox:AddInput(id, opts)
	opts = opts or {}
	local order = self:_nextOrder()

	local row = Instance.new("Frame")
	row.Name = "Input_" .. id
	row.Size = UDim2.new(1, 0, 0, 28)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.Parent = self._frame

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(0.3, 0, 1, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = opts.Text or id
	titleLbl.TextColor3 = COLORS.textDim
	titleLbl.Font = FONT.regular
	titleLbl.TextSize = 12
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = row

	local inputBox = Instance.new("TextBox")
	inputBox.Name = "Box"
	inputBox.Size = UDim2.new(0.7, -4, 0, 24)
	inputBox.Position = UDim2.new(0.3, 4, 0.5, -12)
	inputBox.BackgroundColor3 = COLORS.dropdownBg
	inputBox.BorderSizePixel = 0
	inputBox.Text = opts.Default or ""
	inputBox.PlaceholderText = opts.Placeholder or ""
	inputBox.TextColor3 = COLORS.text
	inputBox.PlaceholderColor3 = COLORS.textMuted
	inputBox.Font = FONT.regular
	inputBox.TextSize = 12
	inputBox.ClearTextOnFocus = false
	inputBox.TextTruncate = Enum.TextTruncate.AtEnd
	inputBox.Parent = row
	corner(inputBox, 4)
	stroke(inputBox, COLORS.border, 1)

	local inputPad = Instance.new("UIPadding")
	inputPad.PaddingLeft = UDim.new(0, 6)
	inputPad.PaddingRight = UDim.new(0, 6)
	inputPad.Parent = inputBox

	if opts.Finished then
		inputBox.FocusLost:Connect(function(enterPressed)
			if opts.Callback then pcall(opts.Callback, inputBox.Text) end
		end)
	else
		inputBox:GetPropertyChangedSignal("Text"):Connect(function()
			if opts.Callback then pcall(opts.Callback, inputBox.Text) end
		end)
	end

	return inputBox
end

----------------------------------------------------------------------
-- TAB
----------------------------------------------------------------------
local Tab = {}
Tab.__index = Tab

function Tab.new(name, contentParent)
	local self = setmetatable({}, Tab)
	self._name = name
	self._frame = Instance.new("Frame")
	self._frame.Name = "Tab_" .. name
	self._frame.Size = UDim2.new(1, 0, 1, 0)
	self._frame.BackgroundTransparency = 1
	self._frame.Visible = false
	self._frame.Parent = contentParent

	local columns = Instance.new("Frame")
	columns.Name = "Columns"
	columns.Size = UDim2.new(1, 0, 1, 0)
	columns.BackgroundTransparency = 1
	columns.Parent = self._frame

	self._leftCol = Instance.new("ScrollingFrame")
	self._leftCol.Name = "Left"
	self._leftCol.Size = UDim2.new(0.5, -4, 1, 0)
	self._leftCol.Position = UDim2.new(0, 0, 0, 0)
	self._leftCol.BackgroundTransparency = 1
	self._leftCol.BorderSizePixel = 0
	self._leftCol.ScrollBarThickness = 3
	self._leftCol.ScrollBarImageColor3 = COLORS.scrollBar
	self._leftCol.CanvasSize = UDim2.new(0, 0, 0, 0)
	self._leftCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
	self._leftCol.Parent = columns

	local leftLayout = Instance.new("UIListLayout")
	leftLayout.Padding = UDim.new(0, 6)
	leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
	leftLayout.Parent = self._leftCol

	local leftPad = Instance.new("UIPadding")
	leftPad.PaddingTop = UDim.new(0, 4)
	leftPad.PaddingLeft = UDim.new(0, 4)
	leftPad.PaddingRight = UDim.new(0, 2)
	leftPad.Parent = self._leftCol

	self._rightCol = Instance.new("ScrollingFrame")
	self._rightCol.Name = "Right"
	self._rightCol.Size = UDim2.new(0.5, -4, 1, 0)
	self._rightCol.Position = UDim2.new(0.5, 4, 0, 0)
	self._rightCol.BackgroundTransparency = 1
	self._rightCol.BorderSizePixel = 0
	self._rightCol.ScrollBarThickness = 3
	self._rightCol.ScrollBarImageColor3 = COLORS.scrollBar
	self._rightCol.CanvasSize = UDim2.new(0, 0, 0, 0)
	self._rightCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
	self._rightCol.Parent = columns

	local rightLayout = Instance.new("UIListLayout")
	rightLayout.Padding = UDim.new(0, 6)
	rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rightLayout.Parent = self._rightCol

	local rightPad = Instance.new("UIPadding")
	rightPad.PaddingTop = UDim.new(0, 4)
	rightPad.PaddingLeft = UDim.new(0, 2)
	rightPad.PaddingRight = UDim.new(0, 4)
	rightPad.Parent = self._rightCol

	self._leftOrder = 0
	self._rightOrder = 0
	return self
end

function Tab:AddLeftGroupbox(title)
	self._leftOrder += 1
	local g = Groupbox.new(title, self._leftCol)
	g._frame.LayoutOrder = self._leftOrder
	return g
end

function Tab:AddRightGroupbox(title)
	self._rightOrder += 1
	local g = Groupbox.new(title, self._rightCol)
	g._frame.LayoutOrder = self._rightOrder
	return g
end

----------------------------------------------------------------------
-- RECENT HATCHES (with pagination + pinned secrets)
----------------------------------------------------------------------
local HatchLog = {}
HatchLog.__index = HatchLog

function HatchLog.new(contentParent)
	local self = setmetatable({}, HatchLog)
	self._entries = {}
	self._secrets = {}
	self._page = 1
	self._perPage = 15
	self._count = 0

	self._frame = Instance.new("Frame")
	self._frame.Name = "Tab_Recent Hatches"
	self._frame.Size = UDim2.new(1, 0, 1, 0)
	self._frame.BackgroundTransparency = 1
	self._frame.Visible = false
	self._frame.Parent = contentParent

	-- Pinned secrets section
	self._secretsFrame = Instance.new("Frame")
	self._secretsFrame.Name = "Secrets"
	self._secretsFrame.Size = UDim2.new(1, -8, 0, 0)
	self._secretsFrame.Position = UDim2.new(0, 4, 0, 4)
	self._secretsFrame.AutomaticSize = Enum.AutomaticSize.Y
	self._secretsFrame.BackgroundColor3 = Color3.fromRGB(30, 25, 10)
	self._secretsFrame.BackgroundTransparency = 0.3
	self._secretsFrame.BorderSizePixel = 0
	self._secretsFrame.Visible = false
	self._secretsFrame.Parent = self._frame
	corner(self._secretsFrame, 8)
	stroke(self._secretsFrame, COLORS.gold, 1)

	local secretPad = Instance.new("UIPadding")
	secretPad.PaddingTop = UDim.new(0, 6)
	secretPad.PaddingBottom = UDim.new(0, 6)
	secretPad.PaddingLeft = UDim.new(0, 8)
	secretPad.PaddingRight = UDim.new(0, 8)
	secretPad.Parent = self._secretsFrame

	local secretLayout = Instance.new("UIListLayout")
	secretLayout.Padding = UDim.new(0, 4)
	secretLayout.SortOrder = Enum.SortOrder.LayoutOrder
	secretLayout.Parent = self._secretsFrame

	local secretTitle = Instance.new("TextLabel")
	secretTitle.Name = "Title"
	secretTitle.Size = UDim2.new(1, 0, 0, 16)
	secretTitle.BackgroundTransparency = 1
	secretTitle.Text = "SECRETS"
	secretTitle.TextColor3 = COLORS.gold
	secretTitle.Font = FONT.bold
	secretTitle.TextSize = 12
	secretTitle.TextXAlignment = Enum.TextXAlignment.Left
	secretTitle.LayoutOrder = 0
	secretTitle.Parent = self._secretsFrame

	self._secretScroll = Instance.new("Frame")
	self._secretScroll.Name = "SecretEntries"
	self._secretScroll.Size = UDim2.new(1, 0, 0, 0)
	self._secretScroll.AutomaticSize = Enum.AutomaticSize.Y
	self._secretScroll.BackgroundTransparency = 1
	self._secretScroll.LayoutOrder = 1
	self._secretScroll.Parent = self._secretsFrame

	local secretEntryLayout = Instance.new("UIListLayout")
	secretEntryLayout.Padding = UDim.new(0, 3)
	secretEntryLayout.SortOrder = Enum.SortOrder.LayoutOrder
	secretEntryLayout.Parent = self._secretScroll

	-- Main entries
	self._mainFrame = Instance.new("Frame")
	self._mainFrame.Name = "Main"
	self._mainFrame.Size = UDim2.new(1, -8, 1, -46)
	self._mainFrame.Position = UDim2.new(0, 4, 0, 4)
	self._mainFrame.BackgroundTransparency = 1
	self._mainFrame.Parent = self._frame

	self._scroll = Instance.new("ScrollingFrame")
	self._scroll.Name = "Entries"
	self._scroll.Size = UDim2.new(1, 0, 1, 0)
	self._scroll.BackgroundTransparency = 1
	self._scroll.BorderSizePixel = 0
	self._scroll.ScrollBarThickness = 3
	self._scroll.ScrollBarImageColor3 = COLORS.scrollBar
	self._scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	self._scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	self._scroll.Parent = self._mainFrame

	local entryLayout = Instance.new("UIListLayout")
	entryLayout.Padding = UDim.new(0, 3)
	entryLayout.SortOrder = Enum.SortOrder.LayoutOrder
	entryLayout.Parent = self._scroll

	local entryPad = Instance.new("UIPadding")
	entryPad.PaddingTop = UDim.new(0, 2)
	entryPad.PaddingBottom = UDim.new(0, 2)
	entryPad.Parent = self._scroll

	-- Pagination bar
	self._pageBar = Instance.new("Frame")
	self._pageBar.Name = "PageBar"
	self._pageBar.Size = UDim2.new(1, -8, 0, 32)
	self._pageBar.Position = UDim2.new(0, 4, 1, -36)
	self._pageBar.BackgroundColor3 = COLORS.card
	self._pageBar.BackgroundTransparency = 0.3
	self._pageBar.BorderSizePixel = 0
	self._pageBar.Parent = self._frame
	corner(self._pageBar, 6)

	local pageLayout = Instance.new("UIListLayout")
	pageLayout.FillDirection = Enum.FillDirection.Horizontal
	pageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	pageLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	pageLayout.Padding = UDim.new(0, 6)
	pageLayout.Parent = self._pageBar

	self._prevBtn = Instance.new("TextButton")
	self._prevBtn.Name = "Prev"
	self._prevBtn.Size = UDim2.new(0, 28, 0, 24)
	self._prevBtn.BackgroundColor3 = COLORS.accent
	self._prevBtn.BackgroundTransparency = 0.5
	self._prevBtn.Text = "<"
	self._prevBtn.TextColor3 = COLORS.text
	self._prevBtn.Font = FONT.bold
	self._prevBtn.TextSize = 14
	self._prevBtn.AutoButtonColor = false
	self._prevBtn.BorderSizePixel = 0
	self._prevBtn.Parent = self._pageBar
	corner(self._prevBtn, 4)

	self._pageLbl = Instance.new("TextLabel")
	self._pageLbl.Name = "PageLabel"
	self._pageLbl.Size = UDim2.new(0, 80, 0, 24)
	self._pageLbl.BackgroundTransparency = 1
	self._pageLbl.Text = "Page 1/1"
	self._pageLbl.TextColor3 = COLORS.text
	self._pageLbl.Font = FONT.semibold
	self._pageLbl.TextSize = 13
	self._pageLbl.Parent = self._pageBar

	self._nextBtn = Instance.new("TextButton")
	self._nextBtn.Name = "Next"
	self._nextBtn.Size = UDim2.new(0, 28, 0, 24)
	self._nextBtn.BackgroundColor3 = COLORS.accent
	self._nextBtn.BackgroundTransparency = 0.5
	self._nextBtn.Text = ">"
	self._nextBtn.TextColor3 = COLORS.text
	self._nextBtn.Font = FONT.bold
	self._nextBtn.TextSize = 14
	self._nextBtn.AutoButtonColor = false
	self._nextBtn.BorderSizePixel = 0
	self._nextBtn.Parent = self._pageBar
	corner(self._nextBtn, 4)

	self._prevBtn.MouseButton1Click:Connect(function()
		if self._page > 1 then
			self._page -= 1
			self:_render()
		end
	end)

	self._nextBtn.MouseButton1Click:Connect(function()
		local totalPages = math.max(1, math.ceil(#self._entries / self._perPage))
		if self._page < totalPages then
			self._page += 1
			self:_render()
		end
	end)

	return self
end

function HatchLog:_createEntryRow(entry, parent, layoutOrder)
	local rarCol = RARITY_COLORS[entry.rarity] or Color3.fromRGB(180, 180, 180)

	local row = Instance.new("Frame")
	row.Name = "Entry"
	row.Size = UDim2.new(1, 0, 0, 48)
	row.BackgroundColor3 = COLORS.card
	row.BackgroundTransparency = 0.2
	row.BorderSizePixel = 0
	row.LayoutOrder = layoutOrder
	row.Parent = parent
	corner(row, 6)

	-- ViewportFrame for 3D pet
	local vf = Instance.new("ViewportFrame")
	vf.Size = UDim2.new(0, 44, 0, 44)
	vf.Position = UDim2.new(0, 2, 0, 2)
	vf.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
	vf.BackgroundTransparency = 0.5
	vf.BorderSizePixel = 0
	vf.Parent = row
	corner(vf, 6)

	vf.Ambient = Color3.fromRGB(200, 200, 210)
	vf.LightColor = Color3.fromRGB(255, 255, 255)
	vf.LightDirection = Vector3.new(-1, -1, -2)

	pcall(function()
		local petModel = RS.Content.Pets:FindFirstChild(entry.name)
		if petModel then
			local clone = petModel:Clone()
			clone.Parent = vf
			local cf, size = clone:GetBoundingBox()
			local maxDim = math.max(size.X, size.Y, size.Z)
			local center = cf.Position
			local front = cf.LookVector
			local cam = Instance.new("Camera")
			cam.FieldOfView = 30
			cam.CFrame = CFrame.new(center - front * maxDim * 1.2 + Vector3.new(0, maxDim * 0.15, 0), center)
			cam.Parent = vf
			vf.CurrentCamera = cam
		end
	end)

	local title = entry.title or entry.name
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, -100, 0, 22)
	nameLbl.Position = UDim2.new(0, 50, 0, 3)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = title
	nameLbl.TextColor3 = rarCol
	nameLbl.Font = FONT.bold
	nameLbl.TextSize = 13
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
	nameLbl.Parent = row

	local infoLbl = Instance.new("TextLabel")
	infoLbl.Size = UDim2.new(1, -100, 0, 16)
	infoLbl.Position = UDim2.new(0, 50, 0, 26)
	infoLbl.BackgroundTransparency = 1
	infoLbl.Text = entry.rarity .. " | 1/" .. comma(math.max(1, entry.oneIn))
	infoLbl.TextColor3 = COLORS.textDim
	infoLbl.Font = FONT.regular
	infoLbl.TextSize = 11
	infoLbl.TextXAlignment = Enum.TextXAlignment.Left
	infoLbl.Parent = row

	-- Tier/Mutation badge on right
	local badges = {}
	if entry.tier and entry.tier ~= "Normal" then table.insert(badges, entry.tier) end
	if entry.mutation and entry.mutation ~= "" then table.insert(badges, entry.mutation) end
	if #badges > 0 then
		local badgeLbl = Instance.new("TextLabel")
		badgeLbl.Size = UDim2.new(0, 60, 0, 16)
		badgeLbl.Position = UDim2.new(1, -66, 0.5, -8)
		badgeLbl.BackgroundColor3 = COLORS.accent
		badgeLbl.BackgroundTransparency = 0.6
		badgeLbl.Text = table.concat(badges, " ")
		badgeLbl.TextColor3 = COLORS.text
		badgeLbl.Font = FONT.semibold
		badgeLbl.TextSize = 10
		badgeLbl.TextTruncate = Enum.TextTruncate.AtEnd
		badgeLbl.Parent = row
		corner(badgeLbl, 4)
	end

	return row
end

function HatchLog:_render()
	-- Clear current entries
	for _, c in self._scroll:GetChildren() do
		if c:IsA("Frame") then c:Destroy() end
	end

	local totalPages = math.max(1, math.ceil(#self._entries / self._perPage))
	self._page = math.clamp(self._page, 1, totalPages)
	self._pageLbl.Text = "Page " .. self._page .. "/" .. totalPages

	local startIdx = (self._page - 1) * self._perPage + 1
	local endIdx = math.min(startIdx + self._perPage - 1, #self._entries)

	for i = startIdx, endIdx do
		local entry = self._entries[i]
		if entry then
			self:_createEntryRow(entry, self._scroll, i - startIdx + 1)
		end
	end

	-- Update secrets offset
	local secretsH = 0
	if self._secretsFrame.Visible then
		secretsH = self._secretsFrame.AbsoluteSize.Y + 8
	end
	self._mainFrame.Position = UDim2.new(0, 4, 0, secretsH + 4)
	self._mainFrame.Size = UDim2.new(1, -8, 1, -secretsH - 46)

	self._scroll.CanvasPosition = Vector2.new(0, 0)
end

function HatchLog:AddEntry(petName, rarity, oneIn, tier, mutation)
	self._count += 1
	local title = ""
	local parts = {}
	if tier and tier ~= "Normal" then table.insert(parts, "[" .. tier .. "]") end
	if mutation and mutation ~= "" then table.insert(parts, "[" .. mutation .. "]") end
	table.insert(parts, petName)
	title = table.concat(parts, " ")

	local entry = {
		name = petName,
		rarity = rarity,
		oneIn = oneIn,
		tier = tier,
		mutation = mutation,
		title = title,
		index = self._count,
	}

	table.insert(self._entries, 1, entry)

	-- Secret? Pin it
	local isSecret = type(rarity) == "string" and rarity:find("^Secret") ~= nil
	if isSecret then
		table.insert(self._secrets, 1, entry)
		self._secretsFrame.Visible = true
		-- Add to pinned UI
		local order = #self._secrets
		self:_createEntryRow(entry, self._secretScroll, order)
	end

	-- Only re-render if on page 1
	if self._page == 1 then
		self:_render()
	else
		-- Update page count
		local totalPages = math.max(1, math.ceil(#self._entries / self._perPage))
		self._pageLbl.Text = "Page " .. self._page .. "/" .. totalPages
	end
end

----------------------------------------------------------------------
-- WINDOW (main container)
----------------------------------------------------------------------
local Window = {}
Window.__index = Window

function FlowUI:CreateWindow(opts)
	opts = opts or {}
	local win = setmetatable({}, Window)

	local pg = LocalPlayer:WaitForChild("PlayerGui")

	win._screenGui = Instance.new("ScreenGui")
	win._screenGui.Name = "FlowUI"
	win._screenGui.ResetOnSpawn = false
	win._screenGui.DisplayOrder = 999
	win._screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	win._screenGui.Parent = pg

	local size = opts.Size or UDim2.fromOffset(640, 500)

	-- Main frame
	win._main = Instance.new("Frame")
	win._main.Name = "Main"
	win._main.Size = size
	win._main.BackgroundColor3 = COLORS.bg
	win._main.BorderSizePixel = 0
	win._main.Parent = win._screenGui
	corner(win._main, 10)
	stroke(win._main, COLORS.border, 1)

	if opts.Center then
		win._main.AnchorPoint = Vector2.new(0.5, 0.5)
		win._main.Position = UDim2.new(0.5, 0, 0.5, 0)
	end

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 32)
	titleBar.BackgroundColor3 = COLORS.headerBg
	titleBar.BorderSizePixel = 0
	titleBar.Parent = win._main
	corner(titleBar, 10)

	-- Cover bottom corners of title bar
	local tbCover = Instance.new("Frame")
	tbCover.Size = UDim2.new(1, 0, 0, 12)
	tbCover.Position = UDim2.new(0, 0, 1, -12)
	tbCover.BackgroundColor3 = COLORS.headerBg
	tbCover.BorderSizePixel = 0
	tbCover.Parent = titleBar

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, -80, 1, 0)
	titleLbl.Position = UDim2.new(0, 12, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = opts.Title or "Flow"
	titleLbl.TextColor3 = COLORS.accent
	titleLbl.Font = FONT.bold
	titleLbl.TextSize = 15
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = titleBar

	-- Subtitle (welcome message)
	local subtitleLbl = Instance.new("TextLabel")
	subtitleLbl.Size = UDim2.new(0, 200, 1, 0)
	subtitleLbl.Position = UDim2.new(1, -210, 0, 0)
	subtitleLbl.BackgroundTransparency = 1
	subtitleLbl.Text = "Welcome, " .. LocalPlayer.DisplayName
	subtitleLbl.TextColor3 = COLORS.textMuted
	subtitleLbl.Font = FONT.regular
	subtitleLbl.TextSize = 12
	subtitleLbl.TextXAlignment = Enum.TextXAlignment.Right
	subtitleLbl.Parent = titleBar

	-- Minimize button
	local minimizeBtn = Instance.new("TextButton")
	minimizeBtn.Name = "Minimize"
	minimizeBtn.Size = UDim2.new(0, 24, 0, 24)
	minimizeBtn.Position = UDim2.new(1, -30, 0, 4)
	minimizeBtn.BackgroundColor3 = COLORS.card
	minimizeBtn.BackgroundTransparency = 0.5
	minimizeBtn.Text = "_"
	minimizeBtn.TextColor3 = COLORS.textDim
	minimizeBtn.Font = FONT.bold
	minimizeBtn.TextSize = 14
	minimizeBtn.AutoButtonColor = false
	minimizeBtn.BorderSizePixel = 0
	minimizeBtn.Parent = titleBar
	corner(minimizeBtn, 4)

	local minimized = false
	local bodyFrame

	minimizeBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		if bodyFrame then
			bodyFrame.Visible = not minimized
		end
		if minimized then
			tween(win._main, {Size = UDim2.fromOffset(size.X.Offset, 32)}, 0.2)
		else
			tween(win._main, {Size = size}, 0.2)
		end
	end)

	-- Dragging
	local dragging, dragInput, dragStart, startPos
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = win._main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	titleBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			win._main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	-- Body (sidebar + content)
	bodyFrame = Instance.new("Frame")
	bodyFrame.Name = "Body"
	bodyFrame.Size = UDim2.new(1, 0, 1, -32)
	bodyFrame.Position = UDim2.new(0, 0, 0, 32)
	bodyFrame.BackgroundTransparency = 1
	bodyFrame.Parent = win._main

	-- Sidebar
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 120, 1, 0)
	sidebar.BackgroundColor3 = COLORS.sidebar
	sidebar.BorderSizePixel = 0
	sidebar.Parent = bodyFrame
	local sideCorner = Instance.new("UICorner")
	sideCorner.CornerRadius = UDim.new(0, 10)
	sideCorner.Parent = sidebar
	-- Cover top-right and top-left corners
	local sideCover = Instance.new("Frame")
	sideCover.Size = UDim2.new(1, 0, 0, 12)
	sideCover.BackgroundColor3 = COLORS.sidebar
	sideCover.BorderSizePixel = 0
	sideCover.Parent = sidebar
	-- Cover right corners
	local sideCover2 = Instance.new("Frame")
	sideCover2.Size = UDim2.new(0, 12, 1, 0)
	sideCover2.Position = UDim2.new(1, -12, 0, 0)
	sideCover2.BackgroundColor3 = COLORS.sidebar
	sideCover2.BorderSizePixel = 0
	sideCover2.Parent = sidebar

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.Padding = UDim.new(0, 2)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = sidebar

	local tabPad = Instance.new("UIPadding")
	tabPad.PaddingTop = UDim.new(0, 8)
	tabPad.PaddingLeft = UDim.new(0, 6)
	tabPad.PaddingRight = UDim.new(0, 6)
	tabPad.Parent = sidebar

	-- Content area
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -124, 1, -4)
	content.Position = UDim2.new(0, 122, 0, 2)
	content.BackgroundColor3 = COLORS.content
	content.BackgroundTransparency = 0.5
	content.BorderSizePixel = 0
	content.Parent = bodyFrame
	corner(content, 8)

	win._sidebar = sidebar
	win._content = content
	win._tabs = {}
	win._tabButtons = {}
	win._activeTab = nil
	win._tabOrder = 0
	win._hatchLog = nil
	win._bodyFrame = bodyFrame

	-- Toggle keybind (RightControl)
	UIS.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.RightControl then
			win._main.Visible = not win._main.Visible
		end
	end)

	return win
end

function Window:AddTab(name)
	self._tabOrder += 1
	local tab = Tab.new(name, self._content)
	self._tabs[name] = tab

	local btn = Instance.new("TextButton")
	btn.Name = "Tab_" .. name
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.BackgroundColor3 = COLORS.accent
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.Text = name
	btn.TextColor3 = COLORS.textDim
	btn.Font = FONT.semibold
	btn.TextSize = 13
	btn.AutoButtonColor = false
	btn.LayoutOrder = self._tabOrder
	btn.Parent = self._sidebar
	corner(btn, 6)

	self._tabButtons[name] = btn

	btn.MouseEnter:Connect(function()
		if self._activeTab ~= name then
			tween(btn, {BackgroundTransparency = 0.8}, 0.1)
		end
	end)
	btn.MouseLeave:Connect(function()
		if self._activeTab ~= name then
			tween(btn, {BackgroundTransparency = 1}, 0.1)
		end
	end)

	btn.MouseButton1Click:Connect(function()
		self:_switchTab(name)
	end)

	-- Auto-select first tab
	if self._tabOrder == 1 then
		self:_switchTab(name)
	end

	return tab
end

function Window:AddHatchLog(name)
	self._tabOrder += 1
	local log = HatchLog.new(self._content)
	self._hatchLog = log
	self._tabs[name] = {_frame = log._frame}

	local btn = Instance.new("TextButton")
	btn.Name = "Tab_" .. name
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.BackgroundColor3 = COLORS.accent
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.Text = name
	btn.TextColor3 = COLORS.textDim
	btn.Font = FONT.semibold
	btn.TextSize = 13
	btn.AutoButtonColor = false
	btn.LayoutOrder = self._tabOrder
	btn.Parent = self._sidebar
	corner(btn, 6)

	self._tabButtons[name] = btn

	btn.MouseEnter:Connect(function()
		if self._activeTab ~= name then
			tween(btn, {BackgroundTransparency = 0.8}, 0.1)
		end
	end)
	btn.MouseLeave:Connect(function()
		if self._activeTab ~= name then
			tween(btn, {BackgroundTransparency = 1}, 0.1)
		end
	end)

	btn.MouseButton1Click:Connect(function()
		self:_switchTab(name)
	end)

	return log
end

function Window:_switchTab(name)
	if self._activeTab == name then return end
	-- Hide all
	for tabName, tab in self._tabs do
		tab._frame.Visible = false
		if self._tabButtons[tabName] then
			tween(self._tabButtons[tabName], {BackgroundTransparency = 1, TextColor3 = COLORS.textDim}, 0.15)
		end
	end
	-- Show selected
	local tab = self._tabs[name]
	if tab then
		tab._frame.Visible = true
		if self._tabButtons[name] then
			tween(self._tabButtons[name], {BackgroundTransparency = 0.6, TextColor3 = COLORS.text}, 0.15)
		end
	end
	self._activeTab = name
	-- Re-render hatch log when switching to it
	if self._hatchLog and self._hatchLog._frame == (tab and tab._frame) then
		self._hatchLog:_render()
	end
end

function Window:GetHatchLog()
	return self._hatchLog
end

-- Notification system
function FlowUI:Notify(text, duration)
	duration = duration or 5
	task.spawn(function()
		pcall(function()
			local pg = LocalPlayer:FindFirstChild("PlayerGui")
			if not pg then return end

			local gui = pg:FindFirstChild("FlowNotifications")
			if not gui then
				gui = Instance.new("ScreenGui")
				gui.Name = "FlowNotifications"
				gui.ResetOnSpawn = false
				gui.DisplayOrder = 1000
				gui.Parent = pg

				local layout = Instance.new("UIListLayout")
				layout.Padding = UDim.new(0, 4)
				layout.SortOrder = Enum.SortOrder.LayoutOrder
				layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
				layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
				layout.Parent = gui

				local pad = Instance.new("UIPadding")
				pad.PaddingBottom = UDim.new(0, 40)
				pad.PaddingRight = UDim.new(0, 10)
				pad.Parent = gui
			end

			local notif = Instance.new("Frame")
			notif.Size = UDim2.new(0, 280, 0, 0)
			notif.AutomaticSize = Enum.AutomaticSize.Y
			notif.BackgroundColor3 = COLORS.card
			notif.BorderSizePixel = 0
			notif.BackgroundTransparency = 0.1
			notif.LayoutOrder = -os.clock()
			notif.Parent = gui
			corner(notif, 8)
			stroke(notif, COLORS.accent, 1)

			local npad = Instance.new("UIPadding")
			npad.PaddingTop = UDim.new(0, 8)
			npad.PaddingBottom = UDim.new(0, 8)
			npad.PaddingLeft = UDim.new(0, 10)
			npad.PaddingRight = UDim.new(0, 10)
			npad.Parent = notif

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 0, 0)
			lbl.AutomaticSize = Enum.AutomaticSize.Y
			lbl.BackgroundTransparency = 1
			lbl.Text = text
			lbl.TextColor3 = COLORS.text
			lbl.Font = FONT.regular
			lbl.TextSize = 13
			lbl.TextWrapped = true
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = notif

			task.wait(duration)
			tween(notif, {BackgroundTransparency = 1}, 0.3)
			tween(lbl, {TextTransparency = 1}, 0.3)
			task.wait(0.35)
			notif:Destroy()
		end)
	end)
end

-- Expose for global access
getgenv().FlowUI = FlowUI
return FlowUI
