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
