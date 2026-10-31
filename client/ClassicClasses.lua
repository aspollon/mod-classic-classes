-- mod-classic-classes: the classic classes on the class choice of the character creation, under the classes of
-- Conquest of Azeroth, in a row of their own. The client shows either the one or the other; the server plays both.
-- Loaded after CharacterCreate.xml (GlueXML.toc). AFK Realm builds the client patch and writes the list of classes
-- the realm offers into CLASSIC_CLASSES below.

local CLASSIC_CLASSES = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [7] = true, [8] = true, [9] = true, [11] = true } -- @CLASSES@
local ORDER = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }

-- The AFK Realm badge belongs to the login wallpaper, not to the whole glue UI.
-- Parented to AccountLogin it disappears with the login screen and never sits over
-- the character creation or character selection.
do
	local function AttachBadge()
		local parent = _G.AccountLogin
		if not parent or _G.AFKRealmBadge then
			return
		end
		local badge = CreateFrame("Frame", "AFKRealmBadge", parent)
		badge:SetSize(220, 24)
		badge:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 24, 20)
		badge:SetFrameStrata(parent:GetFrameStrata())
		badge:SetFrameLevel(parent:GetFrameLevel() + 1)
		local text = badge:CreateFontString(nil, "OVERLAY")
		text:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
		text:SetAllPoints()
		text:SetJustifyH("LEFT")
		text:SetText("powered by AFK Realm")
		text:SetTextColor(1.0, 0.82, 0.0, 0.9)
		parent:HookScript("OnShow", function() badge:Show() end)
		parent:HookScript("OnHide", function() badge:Hide() end)
		_G.AFKRealmBadge = badge
	end
	AttachBadge()
	if type(AccountLogin_OnShow) == "function" then
		hooksecurefunc("AccountLogin_OnShow", AttachBadge)
	end
end

if not C_CharacterCreate or not CharacterCreate_ShowCoAClasses or not CharCreateClassContainer then
	return
end

local canCreateClass = C_CharacterCreate.CanCreateClass
C_CharacterCreate.CanCreateClass = function(classID, ...)
	if CLASSIC_CLASSES[classID] then
		return true
	end
	return canCreateClass(classID, ...)
end

-- The CoA client still applies the old race/class masks in the creation preview.
-- On this realm every playable race may choose every class the realm offers; the
-- server validates the real creation request.
if type(IsRaceClassValid) == "function" then
	IsRaceClassValid = function(race, classID, ...)
		return true
	end
end

-- The stock class button only lights the ten race buttons of the original client.
-- AFK's client can have many more race buttons; light every one of them.
if CharCreateClassButtonMixin then
	function CharCreateClassButtonMixin:HighlightValidRaces()
		for i = 1, 127 do
			local button = _G["CharCreateRaceButton" .. i]
			if button and button:IsEnabled() and button.Glow and button.Glow.Anim then
				if IsRaceClassValid(button:GetID(), self:GetID()) then
					button.Glow.Anim:Play()
				else
					button.Glow.Anim:Stop()
				end
			end
		end
	end

	function CharCreateClassButtonMixin:StopHighlightingRaces()
		for i = 1, 127 do
			local button = _G["CharCreateRaceButton" .. i]
			if button and button.Glow and button.Glow.Anim then
				button.Glow.Anim:Stop()
			end
		end
	end
end

-- Keep the CoA class switch. It shows the CoA classes first and the classic classes
-- after one click. The classic class IDs are the same IDs the server module and
-- ClassicClassesFrame.lua use, so their Reborn spells and talents stay active.
-- The switch itself is provided by the CoA client and must not be hidden; the old
-- extra classic row is intentionally not created.

