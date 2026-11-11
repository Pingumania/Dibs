local _, ns = ...

ns.ROLL_TYPES = { pass = 0, need = 1, greed = 2, de = 3 }
ns.ROLL_ORDER = { 'need', 'greed', 'de', 'pass' }
ns.ROLL_LABELS = { need = 'Need', greed = 'Greed', de = 'Disenchant', pass = 'Pass' }

local rolled = {}

local function OnStartLootRoll(_, rollId)
	local link = GetLootRollItemLink(rollId)
	local action = link and DibsDB.items[C_Item.GetItemInfoInstant(link)]
	if not action then
		return
	end

	local _, _, _, _, _, canNeed, canGreed, canDisenchant = GetLootRollItemInfo(rollId)
	local allowed = action == 'pass'
		or action == 'need' and canNeed
		or action == 'greed' and canGreed
		or action == 'de' and canDisenchant
	if not allowed then
		if not canGreed then
			return
		end
		action = 'greed'
	end

	rolled[rollId] = true
	RollOnLoot(rollId, ns.ROLL_TYPES[action])
end

local function OnConfirmRoll(_, rollId, rollType)
	if rolled[rollId] then
		rolled[rollId] = nil
		ConfirmLootRoll(rollId, rollType)
		StaticPopup_Hide('CONFIRM_LOOT_ROLL')
	end
end

function ns:SetEnabled(enabled)
	DibsDB.enabled = enabled
	local registered = ns:IsEventRegistered('START_LOOT_ROLL', OnStartLootRoll)
	if enabled and not registered then
		ns:RegisterEvent('START_LOOT_ROLL', OnStartLootRoll)
		ns:RegisterEvent('CONFIRM_LOOT_ROLL', OnConfirmRoll)
		ns:RegisterEvent('CONFIRM_DISENCHANT_ROLL', OnConfirmRoll)
	elseif not enabled and registered then
		ns:UnregisterEvent('START_LOOT_ROLL', OnStartLootRoll)
		ns:UnregisterEvent('CONFIRM_LOOT_ROLL', OnConfirmRoll)
		ns:UnregisterEvent('CONFIRM_DISENCHANT_ROLL', OnConfirmRoll)
	end
	ns:RefreshConfig()
end

function ns:ParseItem(text)
	local itemId = tonumber(text) or tonumber(text:match('item:(%d+)'))
	return itemId and (C_Item.GetItemInfoInstant(itemId))
end

function ns:AddItem(itemId, action)
	DibsDB.items[itemId] = action or 'greed'
	ns:RefreshConfig()
end

function ns:RemoveItem(itemId)
	DibsDB.items[itemId] = nil
	ns:RefreshConfig()
end

function ns:OnLoad()
	_G.DibsDB = DibsDB or { enabled = true, items = {} }
	if DibsDB.enabled then
		ns:SetEnabled(true)
	end
end

ns:RegisterSlash('/dibs', function(input)
	local command, rest = input:match('^(%S*)%s*(.-)%s*$')
	command = command:lower()

	if command == '' then
		ns:ToggleConfig()
	elseif command == 'toggle' then
		ns:SetEnabled(not DibsDB.enabled)
		ns:Print(DibsDB.enabled and 'Enabled' or 'Disabled')
	elseif command == 'add' or command == 'remove' then
		local item, action = rest:match('^(.-)%s+(%a+)$')
		action = action and action:lower()
		if not ns.ROLL_TYPES[action] then
			item, action = rest, nil
		end

		local itemId = ns:ParseItem(item)
		if not itemId then
			ns:Print('Unknown item: ' .. item)
		elseif command == 'add' then
			ns:AddItem(itemId, action)
		else
			ns:RemoveItem(itemId)
		end
	else
		ns:Print('Usage: /dibs [toggle | add <link|id> [need|greed|de|pass] | remove <link|id>]')
	end
end)

function Dibs_OnAddonCompartmentClick()
	ns:ToggleConfig()
end

function Dibs_OnAddonCompartmentEnter(_, button)
	GameTooltip:SetOwner(button, 'ANCHOR_LEFT')
	GameTooltip:SetText('Dibs')
	GameTooltip:AddLine('Click to configure', 1, 1, 1)
	GameTooltip:Show()
end

function Dibs_OnAddonCompartmentLeave()
	GameTooltip:Hide()
end
