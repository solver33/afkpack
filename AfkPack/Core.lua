local ADDON_NAME, ns = ...
local L = ns.L

-- Roll types, same ids as the buttons of the Blizzard group loot frame
local ROLL_PASS, ROLL_NEED, ROLL_GREED, ROLL_TRANSMOG = 0, 1, 2, 4

local ROLL_NAMES = {
	[ROLL_PASS] = L.ROLL_PASS,
	[ROLL_NEED] = L.ROLL_NEED,
	[ROLL_GREED] = L.ROLL_GREED,
	[ROLL_TRANSMOG] = L.ROLL_TRANSMOG,
}

ns.LOOT_MODES = { "off", "pass", "need", "greed" }
ns.LOOT_MODE_LABELS = {
	off = L.MODE_OFF,
	pass = L.MODE_PASS,
	need = L.MODE_NEED,
	greed = L.MODE_GREED,
}

local DEFAULTS = {
	lootMode = "off",
	autoSummon = false,
	autoResurrect = false,
}

local db
-- rollID -> roll type this addon sent, so only our own rolls get auto-confirmed
local rolled = {}

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99" .. L.TITLE .. "|r: " .. msg)
end

local function IsSecret(value)
	return issecretvalue ~= nil and issecretvalue(value)
end

-- Midnight can hand out secret values in restricted contexts; never build strings from them
local function Plain(value)
	if IsSecret(value) or value == nil or value == "" then
		return L.UNKNOWN
	end
	return value
end

local function HidePopups(...)
	for i = 1, select("#", ...) do
		StaticPopup_Hide((select(i, ...)))
	end
end

--[[ Loot rolls ]]

local function GetItemClass(link)
	local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(link)
	return classID, subClassID
end

local function IsPet(link)
	if not link then
		return false
	end
	-- Caged battle pets have their own hyperlink type
	if link:find("|Hbattlepet:", 1, true) then
		return true
	end
	local classID, subClassID = GetItemClass(link)
	return classID == Enum.ItemClass.Battlepet
		or (classID == Enum.ItemClass.Miscellaneous and subClassID == Enum.ItemMiscellaneousSubclass.CompanionPet)
end

local function IsRecipe(link)
	return link ~= nil and GetItemClass(link) == Enum.ItemClass.Recipe
end

local function ChooseRollType(rollID)
	local _, name, _, _, _, canNeed, canGreed, _, _, _, _, _, canTransmog = GetLootRollItemInfo(rollID)
	if not name then
		return nil
	end
	-- Read the link now: rolling may end the roll and invalidate the id
	local link = GetLootRollItemLink(rollID)

	-- Pets are always passed, in every mode including "off"
	if IsPet(link) then
		return ROLL_PASS, link or name
	end

	local mode = db.lootMode
	if mode == "off" then
		return nil
	end
	if mode == "pass" then
		return ROLL_PASS, link or name
	end
	-- Recipes never get an automatic Need, they fall back to the next best roll
	if mode == "need" and canNeed and not IsRecipe(link) then
		return ROLL_NEED, link or name
	end
	-- Transmog wins over Greed, and the Blizzard frame hides Greed when Transmog is offered
	if canTransmog then
		return ROLL_TRANSMOG, link or name
	end
	if canGreed then
		return ROLL_GREED, link or name
	end
	return ROLL_PASS, link or name
end

local function HandleRoll(rollID)
	if rolled[rollID] then
		return
	end

	local rollType, link = ChooseRollType(rollID)
	if not rollType then
		return
	end

	rolled[rollID] = rollType
	RollOnLoot(rollID, rollType)
	Print(L.ROLLED:format(ROLL_NAMES[rollType], link))
end

local function ProcessActiveRolls()
	for _, rollID in ipairs(GetActiveLootRollIDs()) do
		HandleRoll(rollID)
	end
end

--[[ Summons ]]

local summonTicker, summonNotified

local function StopSummonWatch()
	if summonTicker then
		summonTicker:Cancel()
		summonTicker = nil
	end
	summonNotified = nil
end

local function IsSummonPending()
	return C_SummonInfo.GetSummonConfirmTimeLeft() > 0
end

local function TryAcceptSummon()
	if not db.autoSummon or not IsSummonPending() then
		StopSummonWatch()
		return
	end

	-- Same conditions under which the Blizzard dialog enables its Accept button
	if UnitAffectingCombat("player") or not PlayerCanTeleport() then
		if not summonNotified then
			summonNotified = true
			Print(L.SUMMON_WAITING)
		end
		return
	end

	local summoner = Plain(C_SummonInfo.GetSummonConfirmSummoner())
	local area = Plain(C_SummonInfo.GetSummonConfirmAreaName())
	StopSummonWatch()
	C_SummonInfo.ConfirmSummon()
	HidePopups("CONFIRM_SUMMON", "CONFIRM_SUMMON_SCENARIO", "CONFIRM_SUMMON_STARTING_AREA")
	Print(L.SUMMON_ACCEPTED:format(summoner, area))
end

local function WatchSummon()
	if not db.autoSummon or summonTicker or not IsSummonPending() then
		return
	end
	-- Accepting this one would throw a new character out of the starting zone for good
	if C_SummonInfo.IsSummonSkippingStartExperience() then
		Print(L.SUMMON_START_AREA)
		return
	end
	summonTicker = C_Timer.NewTicker(1, TryAcceptSummon)
end

--[[ Resurrections ]]

local resTicker, resNotified

local function StopResurrectWatch()
	if resTicker then
		resTicker:Cancel()
		resTicker = nil
	end
	resNotified = nil
end

local function IsResurrectPending()
	if not UnitIsDeadOrGhost("player") then
		return false
	end
	local offerer = ResurrectGetOfferer()
	return IsSecret(offerer) or offerer ~= nil
end

local function TryAcceptResurrect()
	if not db.autoResurrect or not IsResurrectPending() then
		StopResurrectWatch()
		return
	end

	-- The Blizzard dialog keeps Accept disabled until this delay runs out
	local delay = GetCorpseRecoveryDelay()
	if delay > 0 then
		if not resNotified then
			resNotified = true
			Print(L.RES_WAITING:format(math.ceil(delay)))
		end
		return
	end

	local offerer = Plain(ResurrectGetOfferer())
	StopResurrectWatch()
	AcceptResurrect()
	HidePopups("RESURRECT", "RESURRECT_NO_SICKNESS", "RESURRECT_NO_TIMER")
	Print(L.RES_ACCEPTED:format(offerer))
end

local function WatchResurrect()
	if not db.autoResurrect or resTicker or not IsResurrectPending() then
		return
	end
	resTicker = C_Timer.NewTicker(0.5, TryAcceptResurrect)
end

--[[ Settings ]]

-- Picks up rolls, summons and resurrections that were already waiting
local function Refresh()
	ProcessActiveRolls()
	WatchSummon()
	WatchResurrect()
	if ns.UpdateOptions then
		ns.UpdateOptions()
	end
end

function ns.GetSetting(key)
	return db[key]
end

function ns.SetLootMode(mode)
	if not ns.LOOT_MODE_LABELS[mode] then
		return
	end
	db.lootMode = mode
	Refresh()
end

function ns.SetOption(key, value)
	db[key] = not not value
	Refresh()
end

local function OnOff(value)
	return value and L.ON or L.OFF
end

local function PrintStatus()
	Print(L.STATUS_LOOT:format(ns.LOOT_MODE_LABELS[db.lootMode]))
	Print(L.STATUS_SUMMON:format(OnOff(db.autoSummon)))
	Print(L.STATUS_RESURRECT:format(OnOff(db.autoResurrect)))
end

--[[ Events ]]

local events = {}

function events.ADDON_LOADED(name)
	if name ~= ADDON_NAME then
		return
	end
	AfkPackDB = AfkPackDB or {}
	db = AfkPackDB
	for key, value in pairs(DEFAULTS) do
		if db[key] == nil then
			db[key] = value
		end
	end
	if not ns.LOOT_MODE_LABELS[db.lootMode] then
		db.lootMode = DEFAULTS.lootMode
	end
end

function events.PLAYER_ENTERING_WORLD()
	Refresh()
end

function events.START_LOOT_ROLL(rollID)
	HandleRoll(rollID)
end

-- Need on a bind-on-pickup item asks for confirmation; confirm only the rolls we made
function events.CONFIRM_LOOT_ROLL(rollID, rollType)
	if rolled[rollID] ~= rollType then
		return
	end
	ConfirmLootRoll(rollID, rollType)
	StaticPopup_Hide("CONFIRM_LOOT_ROLL", rollID)
	-- In case the Blizzard handler shows the dialog after us
	C_Timer.After(0, function()
		StaticPopup_Hide("CONFIRM_LOOT_ROLL", rollID)
	end)
end

function events.CANCEL_LOOT_ROLL(rollID)
	rolled[rollID] = nil
end

function events.CANCEL_ALL_LOOT_ROLLS()
	wipe(rolled)
end

function events.CONFIRM_SUMMON()
	WatchSummon()
end

function events.CANCEL_SUMMON()
	StopSummonWatch()
end

function events.RESURRECT_REQUEST()
	WatchResurrect()
end

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(_, event, ...)
	events[event](...)
end)
for event in pairs(events) do
	eventFrame:RegisterEvent(event)
end

--[[ Slash command ]]

SLASH_AFKPACK1 = "/afkpack"
SlashCmdList.AFKPACK = function(input)
	local cmd = strtrim(input or ""):lower()
	if cmd == "" then
		ns.ToggleOptions()
	elseif ns.LOOT_MODE_LABELS[cmd] then
		ns.SetLootMode(cmd)
		Print(L.STATUS_LOOT:format(ns.LOOT_MODE_LABELS[cmd]))
	elseif cmd == "summon" then
		ns.SetOption("autoSummon", not db.autoSummon)
		Print(L.STATUS_SUMMON:format(OnOff(db.autoSummon)))
	elseif cmd == "res" or cmd == "resurrect" then
		ns.SetOption("autoResurrect", not db.autoResurrect)
		Print(L.STATUS_RESURRECT:format(OnOff(db.autoResurrect)))
	elseif cmd == "status" then
		PrintStatus()
	elseif cmd == "help" then
		for _, line in ipairs(L.HELP) do
			Print(line)
		end
	else
		Print(L.UNKNOWN_COMMAND:format(cmd))
	end
end

-- Entry in the addon compartment (the addons button next to the minimap)
function AfkPack_OnAddonCompartmentClick()
	ns.ToggleOptions()
end
