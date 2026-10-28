local _, ns = ...
local L = ns.L

local frame

local function MakeLabelClickable(button, label)
	button:SetHitRectInsets(0, -(label:GetStringWidth() + 8), 0, 0)
end

local function CreateOptionsFrame()
	local f = CreateFrame("Frame", "AfkPackOptionsFrame", UIParent, "BasicFrameTemplateWithInset")
	f:SetPoint("CENTER")
	f:SetFrameStrata("DIALOG")
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f.TitleText:SetText(L.TITLE)
	f:Hide()
	-- Close with Escape
	tinsert(UISpecialFrames, f:GetName())

	local y = -34
	local width = 0

	local function AddHeader(text)
		local header = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		header:SetPoint("TOPLEFT", 16, y)
		header:SetText(text)
		y = y - 22
	end

	f.radios = {}
	AddHeader(L.LOOT_HEADER)
	for _, mode in ipairs(ns.LOOT_MODES) do
		local radio = CreateFrame("CheckButton", nil, f, "UIRadioButtonTemplate")
		radio:SetPoint("TOPLEFT", 22, y)
		radio.text:SetFontObject("GameFontHighlight")
		radio.text:SetText(ns.LOOT_MODE_LABELS[mode])
		MakeLabelClickable(radio, radio.text)
		radio.mode = mode
		radio:SetScript("OnClick", function()
			ns.SetLootMode(mode)
		end)
		width = math.max(width, 22 + 16 + 5 + radio.text:GetStringWidth())
		f.radios[#f.radios + 1] = radio
		y = y - 22
	end

	y = y - 10
	f.checks = {}
	AddHeader(L.ACCEPT_HEADER)
	for _, option in ipairs({ { "autoSummon", L.AUTO_SUMMON }, { "autoResurrect", L.AUTO_RESURRECT } }) do
		local key, label = option[1], option[2]
		local check = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
		check:SetSize(26, 26)
		check:SetPoint("TOPLEFT", 16, y + 5)
		check.Text:SetFontObject("GameFontHighlight")
		check.Text:SetText(label)
		MakeLabelClickable(check, check.Text)
		check.key = key
		check:SetScript("OnClick", function(self)
			ns.SetOption(key, self:GetChecked())
		end)
		width = math.max(width, 16 + 26 + check.Text:GetStringWidth())
		f.checks[#f.checks + 1] = check
		y = y - 26
	end

	f:SetSize(math.max(300, width + 30), -y + 14)
	f:SetScript("OnShow", ns.UpdateOptions)
	return f
end

function ns.UpdateOptions()
	if not frame or not frame:IsShown() then
		return
	end
	local lootMode = ns.GetSetting("lootMode")
	for _, radio in ipairs(frame.radios) do
		radio:SetChecked(radio.mode == lootMode)
	end
	for _, check in ipairs(frame.checks) do
		check:SetChecked(ns.GetSetting(check.key))
	end
end

function ns.ToggleOptions()
	frame = frame or CreateOptionsFrame()
	frame:SetShown(not frame:IsShown())
end
