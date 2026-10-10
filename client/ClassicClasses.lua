-- mod-classic-classes: the classic classes on the class choice of the character creation, under the classes of
-- Conquest of Azeroth, in a row of their own. The client shows either the one or the other; the server plays both.
-- Loaded after CharacterCreate.xml (GlueXML.toc). AFK Realm builds the client patch and writes the list of classes
-- the realm offers into CLASSIC_CLASSES below.

local CLASSIC_CLASSES = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [7] = true, [8] = true, [9] = true, [11] = true } -- @CLASSES@
local ORDER = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }

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

if CharCreateSwapClassesButton then
	CharCreateSwapClassesButton:Hide()
end
