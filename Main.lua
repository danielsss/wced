function BuildQueryButton()
    -- 主窗口标题按钮同时承担折叠/展开入口。
end

function Status()
    local online = 0
    for _, tag in ipairs(PeerTags()) do if FindPeer(true, tag) then online = online + 1 end end
    Print(string.format("角色=%s，对端=%d，已找到=%d", WowDetectorDB.role, #PeerTags(), online))
end

SLASH_WOWDETECTOR1 = "/wowdetector"
SLASH_WOWDETECTOR2 = "/wd"
SlashCmdList.WOWDETECTOR = function(input)
    local command, rest = Trim(input):match("^(%S*)%s*(.-)$")
    command = command:lower()
    if command == "role" and (rest == "detector" or rest == "listener") then
        WowDetectorDB.role = rest; state.mainTab="friendlyQuery"; local trimmed = EnforceListenerPeerLimit(); if state.launcher then state.launcher:SetShown(not WowDetectorDB.queryButton.hidden) end; Print("角色已设为 " .. rest)
        RefreshUI(); RefreshConfigUI(); if trimmed and WowDetectorDB.peer ~= "" then RequestPeerSnapshot(WowDetectorDB.peer) end
    elseif command == "peer" and rest ~= "" then
        local key, exists = NormalizeBattleTag(rest), false
        for _, tag in ipairs(PeerTags()) do if NormalizeBattleTag(tag) == key then exists = true end end
        if not exists then
            local wasEmpty = #WowDetectorDB.peers == 0
            table.insert(WowDetectorDB.peers, rest); WowDetectorDB.peerPermissions[key] = nil
            if WowDetectorDB.role == "listener" then
                WowDetectorDB.remoteConfigAllowed = false
                if wasEmpty then WowDetectorDB.activeConfigPeer = "" end
            end
        end
        WowDetectorDB.peer = WowDetectorDB.peers[1] or ""; Print(exists and "该对端已经存在" or ("已添加对端战网ID：" .. rest)); FindPeer(true, rest); RequestPeerVersion(rest)
    elseif command == "query" then RunNextQuery()
    elseif command == "queryui" and (rest == "on" or rest == "off") then
        WowDetectorDB.queryButton.hidden = rest == "off"
        if state.launcher then state.launcher:SetShown(not WowDetectorDB.queryButton.hidden) end
        if WowDetectorDB.queryButton.hidden and state.ui then state.ui:Hide() end
    elseif command == "show" then state.ui:Show()
    elseif command == "hide" then state.ui:Hide()
    elseif command == "status" then Status()
    else
        Print("命令：/wd role detector|listener")
        Print("/wd peer 昵称#数字  |  /wd query")
        Print("/wd queryui on|off")
        Print("/wd show  |  /wd hide  |  /wd status")
    end
end

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...; if name ~= ADDON_NAME then return end
        WowDetectorDB = type(WowDetectorDB) == "table" and WowDetectorDB or {}
        local hadShareSetting = type(WowDetectorDB.team)=="table" and WowDetectorDB.team.shareEnabled~=nil
        CopyDefaults(defaults, WowDetectorDB)
        if not hadShareSetting then WowDetectorDB.team.shareEnabled=true end
        if WowDetectorDB.autoInvite.code == "1" then WowDetectorDB.autoInvite.code = "999" end
        WowDetectorDB.queryLevel = 60
        WowDetectorDB.queries = {zones={},guilds={},names={}}
        WowDetectorDB.trackingBroadcast = {}
        state.mainTab="friendlyQuery"; wipe(state.records); state.statistics=nil
        WowDetectorDB.friendlyQueries.zones = {}
        WowDetectorDB.friendlyQueries.guilds = {}
        if #WowDetectorDB.peers == 0 and Trim(WowDetectorDB.peer) ~= "" then table.insert(WowDetectorDB.peers, WowDetectorDB.peer) end
        local migrated, seen = {}, {}
        for _, tag in ipairs(WowDetectorDB.peers) do
            local key = NormalizeBattleTag(tag)
            if key ~= "" and not seen[key] then migrated[#migrated + 1] = Trim(tag); seen[key] = true end
        end
        WowDetectorDB.peers = migrated; WowDetectorDB.peer = migrated[1] or ""
        EnforceListenerPeerLimit()
        if WowDetectorDB.role=="listener" then RestoreListenerFriendCache(ActivePeerTag()) end
        if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then C_ChatInfo.RegisterAddonMessagePrefix(PREFIX) end
        BuildUI(); BuildConfigUI(); BuildQueryButton(); InstallNativeWhisperCompatibility(); RebuildQueryQueue(); C_Timer.After(2, function()
            for _, tag in ipairs(PeerTags()) do FindPeer(true, tag); RequestPeerVersion(tag) end
            if WowDetectorDB.role == "detector" then SendAllPeerPolicies() end
            Status()
        end)
    elseif event == "WHO_LIST_UPDATE" then ProcessWhoResults()
    elseif event == "FRIENDLIST_UPDATE" and WowDetectorDB.role == "detector" then
        state.friendRefreshSerial = (state.friendRefreshSerial or 0) + 1
        -- 好友事件本身表示缓存已经更新，立即计算并发送单条变化；延迟任务仅负责追踪名单补加。
        PollTrackedFriends(true)
    elseif event == "BN_CHAT_MSG_ADDON" then
        local prefix, message, _, senderID = ...; if prefix == PREFIX then Receive(message, senderID) end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix,message,_,sender=...; if prefix==PREFIX then ReceiveSharedTeamMessage(message,sender) end
    elseif event == "UI_ERROR_MESSAGE" then
        local _, message = ...
        if WowDetectorDB.role == "detector" and ERR_FRIEND_LIST_FULL and message == ERR_FRIEND_LIST_FULL then
            state.friendCount = math.max(100, state.friendCount or 0)
            UpdateFriendCapacity(nil, true)
        end
        if HandleInviteErrorMessage then HandleInviteErrorMessage(message) end
    elseif event == "CHAT_MSG_WHISPER" then
        local message,sender=...; if sender then WowDetectorDB.team.recentWhispers[NormalizeTrackedName(sender)]=time() end; HandleAutoInviteWhisper(message,sender)
    elseif event == "CHAT_MSG_WHISPER_INFORM" then
        local _,target=...; if target then WowDetectorDB.team.recentWhispers[NormalizeTrackedName(target)]=time() end
    elseif event == "CHAT_MSG_SYSTEM" then
        HandleInviteSystemMessage(...)
    elseif event == "GROUP_ROSTER_UPDATE" then
        local members=CurrentGroupMembers()
        for key in pairs(WowDetectorDB.team.inviteHistory) do if members[key] then WowDetectorDB.team.inviteHistory[key]=nil; state.inviteStatuses[key]="joined" end end
        if state.teamInvite.running and IsInGroup() and not IsInRaid() then
            local total=(GetNumSubgroupMembers and GetNumSubgroupMembers() or 0)+1
            if total>=2 then
                if C_PartyInfo and C_PartyInfo.ConvertToRaid then C_PartyInfo.ConvertToRaid() elseif ConvertToRaid then ConvertToRaid() end
            end
        end
        if ApplyTeamPreferences then C_Timer.After(0.5,ApplyTeamPreferences) end
        if RefreshTeamUI then RefreshTeamUI() end
        if RefreshUI then RefreshUI() end
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" then
        state.friendOffset = 0
        if RefreshFriendUI then RefreshFriendUI() end
    elseif event == "BN_FRIEND_INFO_CHANGED" or event == "BN_FRIEND_ACCOUNT_ONLINE" or event == "BN_FRIEND_ACCOUNT_OFFLINE" or event == "BN_CONNECTED" then
        wipe(state.peerGameAccountIDs)
        for _, tag in ipairs(PeerTags()) do FindPeer(true, tag); RequestPeerVersion(tag) end
        -- 普通好友资料变化只用于刷新在线状态，不再反复请求配置和权限。
        -- 战网刚连接或对端刚上线时才执行一次必要的重新同步。
        if event == "BN_CONNECTED" or event == "BN_FRIEND_ACCOUNT_ONLINE" then
            if WowDetectorDB.role == "detector" then
                SendAllPeerPolicies()
            elseif WowDetectorDB.activeConfigPeer == "" then
                local tag = ActivePeerTag()
                if tag then RequestPeerSnapshot(tag) end
            end
        end
        if WowDetectorDB.role == "listener" then CheckListenerFriendSource() end
        RefreshConfigUI()
    end
end)

for _, event in ipairs({ "ADDON_LOADED", "WHO_LIST_UPDATE", "FRIENDLIST_UPDATE", "UI_ERROR_MESSAGE", "BN_CHAT_MSG_ADDON", "CHAT_MSG_ADDON", "BN_FRIEND_INFO_CHANGED",
    "BN_FRIEND_ACCOUNT_ONLINE", "BN_FRIEND_ACCOUNT_OFFLINE", "BN_CONNECTED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED",
    "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_SYSTEM", "GROUP_ROSTER_UPDATE" }) do frame:RegisterEvent(event) end

C_Timer.NewTicker(1, function() if WowDetectorDB then RefreshUI() end end)
C_Timer.NewTicker(1, function()
    local localeAddon = _G.WCED
    if not localeAddon or localeAddon.IS_CHINESE then return end
    for _, ui in ipairs({ state.ui, state.configUI, state.friendUI, state.helpUI, state.blacklistUI, state.enemyWatcherUI, state.spyUI }) do
        if ui and ui:IsShown() then localeAddon.LocalizeFrame(ui) end
    end
end)
C_Timer.NewTicker(0.1, ProcessFriendOutboundQueue)
C_Timer.NewTicker(0.1, ProcessTeamShareQueue)
C_Timer.NewTicker(10, function() if WowDetectorDB and WowDetectorDB.role == "detector" then PollTrackedFriends(true) end end)
C_Timer.NewTicker(10, function() if WowDetectorDB and WowDetectorDB.role == "listener" then CheckListenerFriendSource() end end)
