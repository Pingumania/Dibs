local _, ns = ...

local frame, scrollBox

local function AddFromCursor()
	local cursorType, itemId = GetCursorInfo()
	if cursorType == 'item' then
		ClearCursor()
		ns:AddItem(itemId)
	end
end

local function CreateRow(row)
	row:EnableMouse(true)
	row:SetScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		GameTooltip:SetItemByID(self.itemId)
		GameTooltip:Show()
	end)
	row:SetScript('OnLeave', GameTooltip_Hide)
	row:SetScript('OnReceiveDrag', AddFromCursor)
	row:SetScript('OnMouseUp', AddFromCursor)

	row.Icon = row:CreateTexture(nil, 'ARTWORK')
	row.Icon:SetSize(20, 20)
	row.Icon:SetPoint('LEFT')

	row.Remove = CreateFrame('Button', nil, row, 'UIPanelCloseButtonNoScripts')
	row.Remove:SetSize(20, 20)
	row.Remove:SetPoint('RIGHT')
	row.Remove:SetScript('OnClick', function()
		ns:RemoveItem(row.itemId)
	end)

	row.Dropdown = CreateFrame('DropdownButton', nil, row, 'WowStyle1DropdownTemplate')
	row.Dropdown:SetWidth(100)
	row.Dropdown:SetPoint('RIGHT', row.Remove, 'LEFT', -2, 0)
	row.Dropdown:SetupMenu(function(_, root)
		local function IsSelected(action)
			return DibsDB.items[row.itemId] == action
		end
		local function SetSelected(action)
			DibsDB.items[row.itemId] = action
		end
		for _, action in ipairs(ns.ROLL_ORDER) do
			root:CreateRadio(ns.ROLL_LABELS[action], IsSelected, SetSelected, action)
		end
	end)

	row.Name = row:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
	row.Name:SetPoint('LEFT', row.Icon, 'RIGHT', 4, 0)
	row.Name:SetPoint('RIGHT', row.Dropdown, 'LEFT', -4, 0)
	row.Name:SetJustifyH('LEFT')
	row.Name:SetWordWrap(false)
end

local function InitRow(row, itemId)
	if not row.Icon then
		CreateRow(row)
	end

	row.itemId = itemId
	row.Icon:SetTexture(C_Item.GetItemIconByID(itemId))
	row.Name:SetText(itemId)
	row.Dropdown:GenerateMenu()

	local item = Item:CreateFromItemID(itemId)
	item:ContinueOnItemLoad(function()
		if row.itemId == itemId then
			row.Name:SetText(item:GetItemLink())
		end
	end)
end

local function CreateConfig()
	frame = CreateFrame('Frame', 'DibsFrame', UIParent, 'ButtonFrameTemplate')
	frame:SetSize(380, 420)
	frame:SetFrameStrata('DIALOG')
	frame:EnableMouse(true)
	frame:Hide()
	frame:SetTitle('Dibs')
	ButtonFrameTemplate_HidePortrait(frame)
	ns:SetFrameMoveable(frame)
	table.insert(UISpecialFrames, 'DibsFrame')

	local point = DibsDB.point
	if point then
		frame:SetPoint(point[1], UIParent, point[2], point[3], point[4])
	else
		frame:SetPoint('CENTER')
	end

	frame:HookScript('OnMouseUp', function(self)
		local p, _, relativePoint, x, y = self:GetPoint()
		DibsDB.point = { p, relativePoint, x, y }
		AddFromCursor()
	end)
	frame:SetScript('OnReceiveDrag', AddFromCursor)
	frame:SetScript('OnShow', function()
		ns:RefreshConfig()
	end)

	frame.Enabled = CreateFrame('CheckButton', nil, frame, 'MinimalCheckboxTemplate')
	frame.Enabled:SetPoint('TOPLEFT', 10, -28)
	frame.Enabled:SetScript('OnClick', function(self)
		ns:SetEnabled(self:GetChecked())
	end)

	local label = frame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
	label:SetPoint('LEFT', frame.Enabled, 'RIGHT', 2, 0)
	label:SetText('Enabled')

	local input = CreateFrame('EditBox', nil, frame, 'InputBoxInstructionsTemplate')
	input:SetPoint('LEFT', label, 'RIGHT', 16, 0)
	input:SetPoint('RIGHT', -12, 0)
	input:SetPoint('TOP', frame.Enabled, 'TOP', 0, -4)
	input:SetHeight(22)
	input:SetAutoFocus(false)
	input.Instructions:SetPoint('TOPLEFT')
	input.Instructions:SetText('Item link or ID')
	input:SetScript('OnEnterPressed', function(self)
		local itemId = ns:ParseItem(self:GetText())
		if itemId then
			ns:AddItem(itemId)
			self:SetText('')
		end
		self:ClearFocus()
	end)
	hooksecurefunc(ChatFrameUtil, 'InsertLink', function(link)
		if input:HasFocus() then
			input:SetText(link)
		end
	end)

	local hint = frame:CreateFontString(nil, 'ARTWORK', 'GameFontDisableSmall2')
	hint:SetPoint('TOPLEFT', frame.Inset, 'BOTTOMLEFT', 0, 1)
	hint:SetPoint('BOTTOMRIGHT', -6, 4)
	hint:SetTextColor(0.7, 0.7, 0.7)
	hint:SetText('Drop an item onto this window to add it')

	scrollBox = CreateFrame('Frame', nil, frame.Inset, 'WowScrollBoxList')
	local scrollBar = CreateFrame('EventFrame', nil, frame.Inset, 'MinimalScrollBar')
	scrollBar:SetPoint('TOPRIGHT', -6, -4)
	scrollBar:SetPoint('BOTTOMRIGHT', -6, 4)

	local view = CreateScrollBoxListLinearView()
	view:SetElementExtent(24)
	view:SetElementInitializer('Frame', InitRow)
	ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

	local topLeft = CreateAnchor('TOPLEFT', frame.Inset, 'TOPLEFT', 6, -4)
	ScrollUtil.AddManagedScrollBarVisibilityBehavior(scrollBox, scrollBar, {
		topLeft,
		CreateAnchor('BOTTOMRIGHT', frame.Inset, 'BOTTOMRIGHT', -22, 4),
	}, {
		topLeft,
		CreateAnchor('BOTTOMRIGHT', frame.Inset, 'BOTTOMRIGHT', -6, 4),
	})
end

function ns:RefreshConfig()
	if not (frame and frame:IsShown()) then
		return
	end

	frame.Enabled:SetChecked(DibsDB.enabled)

	local itemIds = {}
	for itemId in next, DibsDB.items do
		table.insert(itemIds, itemId)
	end
	table.sort(itemIds)
	scrollBox:SetDataProvider(CreateDataProvider(itemIds), ScrollBoxConstants.RetainScrollPosition)
end

function ns:ToggleConfig()
	if not frame then
		CreateConfig()
	end
	frame:SetShown(not frame:IsShown())
end
