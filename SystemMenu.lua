local _, addon = ...

local BAG_FRAMES = {
    "BagsBar", "MainMenuBarBackpackButton", "CharacterBag0Slot", "CharacterBag1Slot",
    "CharacterBag2Slot", "CharacterBag3Slot", "KeyRingButton",
}

local MICRO_FRAMES = {
    "MicroMenu", "MicroMenuContainer", "CharacterMicroButton", "SpellbookMicroButton",
    "PlayerSpellsMicroButton", "TalentMicroButton", "QuestLogMicroButton", "SocialsMicroButton",
    "GuildMicroButton", "WorldMapMicroButton", "LFDMicroButton", "CollectionsMicroButton",
    "EJMicroButton", "AchievementMicroButton", "StoreMicroButton", "MainMenuMicroButton", "HelpMicroButton",
}

state.nativeEntryShown = state.nativeEntryShown or setmetatable({}, { __mode = "k" })
state.nativeEntryHooks = state.nativeEntryHooks or setmetatable({}, { __mode = "k" })

local function SetNativeFrames(names, hidden, category)
    for _, name in ipairs(names) do
        local native = _G[name]
        if native and native.Hide and native.Show then
            if hidden then
                if state.nativeEntryShown[native] == nil then
                    state.nativeEntryShown[native] = native:IsShown() and true or false
                end
                pcall(native.Hide, native)
            else
                if state.nativeEntryShown[native] then pcall(native.Show, native) end
                state.nativeEntryShown[native] = nil
            end
            if hooksecurefunc and not state.nativeEntryHooks[native] then
                state.nativeEntryHooks[native] = true
                hooksecurefunc(native, "Show", function(self)
                    if WowDetectorDB and ((category == "bags" and WowDetectorDB.hideNativeBags)
                        or (category == "micro" and WowDetectorDB.hideNativeMicroMenu)) then
                        C_Timer.After(0, function() if self and self.Hide then pcall(self.Hide, self) end end)
                    end
                end)
            end
        end
    end
end

function ApplyNativeEntryVisibility()
    if not WowDetectorDB then return end
    SetNativeFrames(BAG_FRAMES, WowDetectorDB.hideNativeBags == true, "bags")
    SetNativeFrames(MICRO_FRAMES, WowDetectorDB.hideNativeMicroMenu == true, "micro")
end

local function ClickFirstNative(...)
    for index = 1, select("#", ...) do
        local native = _G[select(index, ...)]
        if native and native.Click then native:Click(); return true end
    end
    return false
end

function OpenNativeSystemEntry(entry)
    if entry == "bags" then
        if ToggleAllBags then ToggleAllBags() else ClickFirstNative("MainMenuBarBackpackButton") end
    elseif entry == "character" then
        if ToggleCharacter then
            ToggleCharacter("PaperDollFrame")
        elseif CharacterFrame then
            if ToggleFrame then ToggleFrame(CharacterFrame)
            elseif CharacterFrame:IsShown() then CharacterFrame:Hide() else CharacterFrame:Show() end
        else
            ClickFirstNative("CharacterMicroButton")
        end
    elseif entry == "spellbook" then
        if not ClickFirstNative("SpellbookMicroButton", "PlayerSpellsMicroButton") and ToggleSpellBook then ToggleSpellBook(BOOKTYPE_SPELL) end
    elseif entry == "talents" then
        if not ClickFirstNative("TalentMicroButton", "PlayerSpellsMicroButton") and ToggleTalentFrame then ToggleTalentFrame() end
    elseif entry == "quests" then
        if not ClickFirstNative("QuestLogMicroButton") and ToggleQuestLog then ToggleQuestLog() end
    elseif entry == "social" then
        if not ClickFirstNative("SocialsMicroButton") and ToggleFriendsFrame then ToggleFriendsFrame() end
    elseif entry == "map" then
        if not ClickFirstNative("WorldMapMicroButton") and ToggleWorldMap then ToggleWorldMap() end
    elseif entry == "settings" then
        -- ToggleGameMenu() 会先调用受保护的 SpellStopCasting()；插件按钮即使由
        -- 玩家点击触发也可能被污染检查拒绝。直接切换菜单框体可避开该调用。
        if GameMenuFrame then
            if GameMenuFrame:IsShown() then
                if HideUIPanel then HideUIPanel(GameMenuFrame) else GameMenuFrame:Hide() end
            else
                if ShowUIPanel then ShowUIPanel(GameMenuFrame) else GameMenuFrame:Show() end
            end
        end
    elseif entry == "help" then
        if not ClickFirstNative("HelpMicroButton") and ToggleHelpFrame then ToggleHelpFrame() end
    end
end

local nativeEvents = CreateFrame("Frame")
nativeEvents:RegisterEvent("ADDON_LOADED")
nativeEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
nativeEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
nativeEvents:SetScript("OnEvent", function() C_Timer.After(0, ApplyNativeEntryVisibility) end)
