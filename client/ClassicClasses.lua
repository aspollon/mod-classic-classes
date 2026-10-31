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

local function ClassicRow()
	local container = CharCreateClassContainer
	if not container.Row3 then
		local row = CreateFrame("Frame", "CharCreateClassContainerRow3", container, "HorizontalLayoutFrame")
		row:SetSize(800, 52)
		row.layoutIndex = 3
		row.spacing = 36
		row.align = "center"
		container.Row3 = row
	end
	return container.Row3
end

local showCoAClasses = CharacterCreate_ShowCoAClasses
function CharacterCreate_ShowCoAClasses(self)
	showCoAClasses(self)

	local container = CharCreateClassContainer
	local row = ClassicRow()
	if CharacterCreate.classGuideActive or not container:IsShown() then
		row:Hide()
		return
	end

	local layoutIndex = 0
	for _, token in ipairs(ORDER) do
		local classID = Enum.Class[token]
		if classID and CLASSIC_CLASSES[classID] then
			local className, classFile = GetClassInfo(classID)
			if className and classFile then
				layoutIndex = layoutIndex + 1
				local button = self.classButtonPool:Acquire()
				button:SetID(classID)
				button.layoutIndex = layoutIndex
				button:SetParent(row)
				button:Show()
				button:SetClass(className, classFile, true)
			end
		end
	end

	row:SetShown(layoutIndex > 0)
	container.spacing = layoutIndex > 0 and 20 or 42
	row:MarkDirty()
	container:MarkDirty()
end


-- CoA's character creation shows this button again on every class refresh.
-- The AFK realm puts the classic classes in their own row, so the switch is not needed.
local function HideCoAClassSwitch()
	if CharCreateSwapClassesButton then
		CharCreateSwapClassesButton:Hide()
	end
end
HideCoAClassSwitch()
if type(CharacterCreate_RefreshClassButtons) == "function" then
	local refresh = CharacterCreate_RefreshClassButtons
	CharacterCreate_RefreshClassButtons = function(self)
		refresh(self)
		HideCoAClassSwitch()
	end
end

