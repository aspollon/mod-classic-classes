-- mod-classic-classes: the classic classes in the game's interface (FrameXML).
--
-- 1. Talents. The server keeps the talents of the classic classes as the Reborn entries of Character Advancement (as on
--    Ascension's Warcraft Reborn realms). The client maps a classic class to those entries only while the player
--    himself plays a classic class; a player of a Conquest of Azeroth class would see the original entries instead,
--    and a classic character he inspects would show an empty build. On this realm the classic classes always use the
--    Reborn entries.
-- 2. Mystic Enchants. The realm has no Mystic Enchants, so the side tab of the character frame and of the inspect
--    frame that shows their slots is left out.

-- The table of class names (ClassConversions) is local to Util\CharacterAdvancementUtil.lua, so the functions that read it
-- are wrapped instead.
if CharacterAdvancementUtil then
    local REBORN, FILE = {}, {}
    for _, name in ipairs({ "Hunter", "Warlock", "Priest", "Paladin", "Mage", "Rogue", "Druid", "Shaman", "Warrior", "DeathKnight" }) do
        REBORN[string.upper(name)] = "Reborn" .. name
        FILE["Reborn" .. name] = string.upper(name)
    end

    local classDBCByFile = CharacterAdvancementUtil.GetClassDBCByFile
    function CharacterAdvancementUtil.GetClassDBCByFile(classFile)
        return REBORN[classFile] or classDBCByFile(classFile)
    end

    local classFileByDBC = CharacterAdvancementUtil.GetClassFileByDBC
    function CharacterAdvancementUtil.GetClassFileByDBC(classDBC)
        return FILE[classDBC] or classFileByDBC(classDBC)
    end

    local classFileForEntry = CharacterAdvancementUtil.GetClassFileForEntry
    function CharacterAdvancementUtil.GetClassFileForEntry(entry)
        local class, spec = classFileForEntry(entry)
        if entry and FILE[entry.Class] then
            class = FILE[entry.Class]
        end
        return class, spec
    end
end

local function HideTab(tab)
    if tab then
        tab:SetTabEnabled(false)
        tab:Hide()
    end
end

local function LeaveOutCharacterTab()
    local frame = AscensionCharacterFrame
    local tab = frame and frame.EnchantSideTab
    if not tab then
        return
    end
    frame.EnchantSideTab = nil
    -- Hidden only, the tab came back whenever the frame showed its side tabs again (ShowTabs shows every tab it has),
    -- so it is taken out of the frame's tabs altogether.
    local tabs = frame.RightInset
    if tabs and tabs.RemoveTab and tab.GetTabID then
        local current = tabs.currentTab == tab
        tabs:RemoveTab(tab:GetTabID())
        if current and tabs.SelectFirstEnabledTab then
            tabs:SelectFirstEnabledTab()
        end
    else
        HideTab(tab)
    end
end

local function NoMysticEnchantTab(self)
    HideTab(self.MysticEnchantTab)
    if self.RightInset and self.StatsTab and self.RightInset:GetCurrentTabID() ~= self.StatsTab:GetTabID() then
        self.RightInset:SelectTabID(self.StatsTab:GetTabID())
    end
end

local function LeaveOutInspectTab()
    if InspectFrameMixin then
        InspectFrameMixin.UpdateMysticEnchantTab = NoMysticEnchantTab
    end
    local frame = AscensionInspectFrame
    if frame and frame.UpdateMysticEnchantTab ~= NoMysticEnchantTab then
        frame.UpdateMysticEnchantTab = NoMysticEnchantTab
        HideTab(frame.MysticEnchantTab)
        -- The class line of the inspect frame selects the tab when it is there; it no longer is.
        hooksecurefunc(frame, "UpdateCharacterInfo", NoMysticEnchantTab)
    end
end

LeaveOutCharacterTab()
LeaveOutInspectTab()

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("ADDON_LOADED")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:SetScript("OnEvent", function()
    LeaveOutCharacterTab()
    LeaveOutInspectTab()
end)
