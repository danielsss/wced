RefreshUI = function()
    if not state.ui or state.refreshing then return end
    state.refreshing = true
    local detectorView = WowDetectorDB.role == "detector"
    local expanded = not WowDetectorDB.window.collapsed
    local friendlyView = state.mainTab == "friendlyQuery"
    local enemyConfigView = state.mainTab == "enemyConfig"
    local detectorAvailable,detectorWarning=HasAvailableDetector()
    local warningShown=not detectorView and not friendlyView and not detectorAvailable
    if state.detectorWarning then
        state.detectorWarning:SetShown(expanded and warningShown)
        state.detectorWarning.text:SetText(detectorWarning or "当前没有可用的侦测方")
    end
    if state.detectorPanel then state.detectorPanel:SetShown(detectorView and expanded and not enemyConfigView and not friendlyView) end
    if state.queryTabButton then state.queryTabButton:SetShown(not detectorView and expanded and not friendlyView) end
    if state.trackingTabButton then state.trackingTabButton:SetShown(not detectorView and expanded and not friendlyView) end
    if state.friendlyTabButton then state.friendlyTabButton:SetShown(expanded and not friendlyView) end
    if state.enemyQueryHint then state.enemyQueryHint:SetShown(not detectorView and expanded and state.mainTab == "enemyQuery") end
    if state.enemySortDropdown then state.enemySortDropdown:SetShown(not detectorView and expanded and state.mainTab == "enemyQuery") end
    if state.statsPanel then state.statsPanel:SetShown((not detectorView or friendlyView) and expanded and not enemyConfigView) end
    if state.header then state.header:SetShown((not detectorView or friendlyView) and expanded and not enemyConfigView) end
    if state.enemyConfigPanel then state.enemyConfigPanel:SetShown(expanded and enemyConfigView) end
    if state.enemyConfigPanel then
        state.enemyConfigPanel:ClearAllPoints()
        state.enemyConfigPanel:SetPoint("TOPLEFT",10,-65-(warningShown and 34 or 0))
        state.enemyConfigPanel:SetPoint("BOTTOMRIGHT",-10,12)
    end
    if state.teamPanel then state.teamPanel:SetShown(expanded and friendlyView) end
    if state.trackingSortHeaders then
        for _,button in pairs(state.trackingSortHeaders) do button:SetShown(expanded and not detectorView and state.mainTab=="enemyTracking") end
    end
    if state.broadcastActionButton then state.broadcastActionButton:SetShown(expanded and not detectorView and state.mainTab=="enemyQuery") end
    if state.queryTabButton then state.queryTabButton:SetEnabled(true); state.queryTabButton:GetFontString():SetTextColor(state.mainTab=="enemyQuery" and 1 or 0.9,state.mainTab=="enemyQuery" and 0.82 or 0.9,state.mainTab=="enemyQuery" and 0.05 or 0.9) end
    if state.trackingTabButton then state.trackingTabButton:SetEnabled(true); state.trackingTabButton:GetFontString():SetTextColor(state.mainTab=="enemyTracking" and 1 or 0.9,state.mainTab=="enemyTracking" and 0.28 or 0.9,state.mainTab=="enemyTracking" and 0.2 or 0.9) end
    if state.friendlyTabButton then state.friendlyTabButton:SetEnabled(true); state.friendlyTabButton:GetFontString():SetTextColor(state.mainTab=="enemyConfig" and 1 or 0.9,state.mainTab=="enemyConfig" and 0.82 or 0.9,state.mainTab=="enemyConfig" and 0.05 or 0.9) end
    if state.mainTabMarks then
        state.mainTabMarks.enemyQuery:SetShown(state.mainTab=="enemyQuery")
        state.mainTabMarks.enemyTracking:SetShown(state.mainTab=="enemyTracking")
        state.mainTabMarks.enemyConfig:SetShown(state.mainTab=="enemyConfig")
    end
    if state.statsPanel then
        state.statsPanel:ClearAllPoints()
        local statsY=friendlyView and -265 or (-65-(warningShown and 34 or 0))
        state.statsPanel:SetPoint("TOPLEFT",10,statsY)
        state.statsPanel:SetPoint("TOPRIGHT",-10,statsY)
        state.statsPanel:SetHeight(friendlyView and 68 or 55)
    end
    local headerY=friendlyView and -340 or (-127-(warningShown and 34 or 0))
    if state.header then state.header:ClearAllPoints(); state.header:SetPoint("TOPLEFT",12,headerY); state.header:SetPoint("TOPRIGHT",-32,headerY) end
    if state.scrollBar then
        state.scrollBar:ClearAllPoints()
        state.scrollBar:SetPoint("TOPRIGHT",-7,headerY-16)
        state.scrollBar:SetPoint("BOTTOMRIGHT",-7,25)
    end
    for index,row in ipairs(state.rows) do
        row:ClearAllPoints(); row:SetPoint("TOPLEFT",12,headerY-19-(index-1)*20); row:SetPoint("TOPRIGHT",-32,headerY-19-(index-1)*20)
    end
    if friendlyView and RefreshTeamUI then RefreshTeamUI() end
    if enemyConfigView then
        if state.scrollBar then state.scrollBar:Hide() end
        for _,row in ipairs(state.rows) do row:Hide() end
        if RefreshEnemyConfigUI then RefreshEnemyConfigUI() end
        state.ui.count:SetText("敌方配置")
        state.refreshing=false
        return
    end
    if state.queryActionButton then state.queryActionButton:SetShown(expanded and (detectorView or friendlyView)); UpdateQueryButton() end
    if state.classDropdown then
        state.classDropdown:SetShown(expanded and (detectorView or friendlyView))
        local selected=friendlyView and state.selectedFriendlyClass or state.selectedEnemyClass
        local required=friendlyView and state.friendlyClassRequired or state.queryClassRequired
        UIDropDownMenu_SetText(state.classDropdown,selected or "全部职业")
    end
    if detectorView and not friendlyView then
        if state.scrollBar then state.scrollBar:Hide() end
        for _, row in ipairs(state.rows) do row:Hide() end
        state.ui.count:SetText("侦测方")
        local last = tonumber(WowDetectorDB.lastCommunicationAt) or 0
        state.detectorCommunication:SetText(last > 0 and ("最后通信：" .. date("%m-%d %H:%M:%S", last)) or "最后通信：尚未通信")
        state.detectorConfig:SetText(string.format("内置地图：%d    公会过滤：%d    追踪目标：%d",
            #state.queryQueue, #WowDetectorDB.queries.guilds, #WowDetectorDB.queries.names))
        state.detectorPolling:SetText("好友动态：每10秒检查")
        state.detectorQuery:SetText(state.pendingQuery and ("当前查询：" .. (state.pendingQuery.zone or state.pendingQuery.value or UNKNOWN))
            or "当前查询：等待手动触发")
        state.refreshing = false
        return
    end
    if state.zoneDropdown then
        state.zoneDropdown:SetShown(expanded and friendlyView)
        if friendlyView then UIDropDownMenu_SetText(state.zoneDropdown, state.selectedFriendlyZone or "请选择地区") end
    end
    local active = {}
    local configuredGuilds = friendlyView and {} or WowDetectorDB.queries.guilds
    local guildCounts, totalCount, statisticsGuilds
    if friendlyView then
        guildCounts, totalCount, statisticsGuilds = {}, 0, {}
        local known = {}
        for _, record in pairs(state.friendlyRecords) do
            local matchesClass = not state.friendlyDisplayClass
                or ResolveClassFile(record.class,record.classFile)==ResolveClassFile(state.friendlyDisplayClass)
            local isSelf=TrackedNameMatches(record.name,UnitName("player") or "")
            if matchesClass and not isSelf then
                local guild = Trim(record.guild) ~= "" and record.guild or UNKNOWN
                guildCounts[guild] = (guildCounts[guild] or 0) + 1; totalCount = totalCount + 1
                if not known[guild] then known[guild] = true; statisticsGuilds[#statisticsGuilds + 1] = guild end
            end
        end
        table.sort(statisticsGuilds, function(a, b)
            local countA, countB = guildCounts[a] or 0, guildCounts[b] or 0
            if countA ~= countB then return countA > countB end
            return tostring(a) < tostring(b)
        end)
    elseif state.statistics then
        guildCounts, totalCount, statisticsGuilds = state.statistics.counts, state.statistics.total, state.statistics.guilds
    else guildCounts, totalCount, statisticsGuilds = BuildGuildStatistics() end
    local displayedGuilds = #configuredGuilds > 0 and configuredGuilds or (statisticsGuilds or {})
    local queryTab = state.mainTab ~= "enemyTracking"
    if state.broadcastActionButton then state.broadcastActionButton:SetShown(state.mainTab=="enemyQuery" and not friendlyView and expanded) end
    local trackingOnline, trackingOffline, latestTrackingTime = 0, 0, nil
    local sourceRecords = friendlyView and state.friendlyRecords or state.records
    for _, record in pairs(sourceRecords) do
        local configuredGuild = ConfiguredGuildFor(record.guild)
        local matchesDisplayedClass = not friendlyView or not state.friendlyDisplayClass
            or ResolveClassFile(record.class,record.classFile)==ResolveClassFile(state.friendlyDisplayClass)
        local isSelf=friendlyView and TrackedNameMatches(record.name,UnitName("player") or "")
        if not isSelf and ((queryTab and not record.isTracked and matchesDisplayedClass and (friendlyView or #configuredGuilds == 0 or configuredGuild)) or (not queryTab and record.isTracked)) then
            active[#active + 1] = record
        end
        if record.isTracked then
            if record.online then trackingOnline = trackingOnline + 1 else trackingOffline = trackingOffline + 1 end
            if not latestTrackingTime or (record.time or 0) > latestTrackingTime then latestTrackingTime = record.time end
        end
    end
    table.sort(active, function(a, b)
        if a.isTracked ~= b.isTracked then return a.isTracked and true or false end
        if queryTab then
            if not friendlyView then
                local mode = WowDetectorDB.enemySort == "class" and "class" or "zone"
                local secondary = mode == "class" and "zone" or "class"
                local primaryA, primaryB = tostring(a[mode] or UNKNOWN), tostring(b[mode] or UNKNOWN)
                if primaryA ~= primaryB then return primaryA < primaryB end
                local secondaryA, secondaryB = tostring(a[secondary] or UNKNOWN), tostring(b[secondary] or UNKNOWN)
                if secondaryA ~= secondaryB then return secondaryA < secondaryB end
            end
            local guildA = (Trim(a.guild) ~= "" and a.guild ~= UNKNOWN) and a.guild or "无公会 / 未知"
            local guildB = (Trim(b.guild) ~= "" and b.guild ~= UNKNOWN) and b.guild or "无公会 / 未知"
            if friendlyView then
                local noGuildA=Trim(a.guild)=="" or a.guild==UNKNOWN
                local noGuildB=Trim(b.guild)=="" or b.guild==UNKNOWN
                if noGuildA~=noGuildB then return not noGuildA end
                local countA, countB = guildCounts[a.guild] or 0, guildCounts[b.guild] or 0
                if countA ~= countB then return countA > countB end
            end
            if guildA ~= guildB then return guildA < guildB end
            return tostring(a.name or "") < tostring(b.name or "")
        end
        if (a.online and true or false) ~= (b.online and true or false) then return a.online and true or false end
        local trackingSort=WowDetectorDB.trackingSort=="class" and "class" or "zone"
        local valueA=tostring(a[trackingSort] or UNKNOWN):lower()
        local valueB=tostring(b[trackingSort] or UNKNOWN):lower()
        if valueA~=valueB then
            if WowDetectorDB.trackingSortAscending==false then return valueA>valueB end
            return valueA<valueB
        end
        if (a.received or 0) ~= (b.received or 0) then return (a.received or 0) > (b.received or 0) end
        return tostring(a.name or "") < tostring(b.name or "")
    end)
    state.ui.count:SetText(string.format(queryTab and "查询记录：%d" or "追踪目标：%d", #active))
    local stats = {}
    if queryTab then
        local queryTime = state.statistics and state.statistics.time
        local queryZone = state.statistics and state.statistics.zone
        if friendlyView then queryZone = state.friendlyStatistics and state.friendlyStatistics.zone; queryTime = state.friendlyStatistics and state.friendlyStatistics.time end
        local statsName = friendlyView and "友方查询概览" or "敌情查询概览"
        if friendlyView and state.friendlyDisplayClass then statsName=statsName.."  ·  "..state.friendlyDisplayClass end
        state.ui.statsTitle:SetText(queryZone and (statsName .. "  ·  " .. queryZone) or statsName)
        state.ui.statsTime:SetText(queryTime and ("查询时间  " .. date("%m-%d %H:%M:%S", queryTime)) or "查询时间  --")
        state.ui.statsTime:SetTextColor(0.35, 1, 0.55)
        state.ui.statsTotal:SetText("总计  " .. tostring(totalCount))
        state.ui.statsTitle:SetWordWrap(false)
        state.ui.statsTotal:ClearAllPoints(); state.ui.statsTime:ClearAllPoints()
        if friendlyView then
            state.ui.statsTitle:SetWidth(math.max(180,state.statsPanel:GetWidth()-390))
            state.ui.statsTotal:SetPoint("TOPRIGHT",state.statsPanel,"TOPRIGHT",-258,-8); state.ui.statsTotal:SetWidth(82); state.ui.statsTotal:SetJustifyH("RIGHT")
            state.ui.statsTime:SetPoint("TOPRIGHT",state.statsPanel,"TOPRIGHT",-18,-8); state.ui.statsTime:SetWidth(225); state.ui.statsTime:SetJustifyH("RIGHT")
        else
            state.ui.statsTitle:SetWidth(200)
            state.ui.statsTotal:SetPoint("LEFT",state.broadcastActionButton,"RIGHT",12,0); state.ui.statsTotal:SetWidth(90); state.ui.statsTotal:SetJustifyH("LEFT")
            state.ui.statsTime:SetPoint("TOPRIGHT",state.statsPanel,"TOPRIGHT",-24,-8); state.ui.statsTime:SetWidth(225); state.ui.statsTime:SetJustifyH("RIGHT")
        end
        if friendlyView then
            local saved=#(WowDetectorDB.team.savedMembers or {})
            local blocked=0; for _,untilTime in pairs(WowDetectorDB.team.noJoinUntil or {}) do if untilTime>time() then blocked=blocked+1 end end
            state.ui.stats:SetText(string.format("保存 %d ｜ 黑名单 %d ｜ %s",saved,blocked,state.teamInvite.status or "等待操作")); state.ui.stats:Show()
        else state.ui.stats:Hide() end
        state.statsScrollBar:Hide()
        for _,row in ipairs(state.statsRows) do row.guild=nil; if row.invite then row.invite:Hide() end; row:Hide() end
    else
        stats = { "|cff66ff99在线  " .. trackingOnline .. "|r", "|cffff7777离线  " .. trackingOffline .. "|r",
            "|cffffd100总计  " .. (trackingOnline + trackingOffline) .. "|r" }
        state.ui.statsTitle:SetText("敌方玩家追踪状态")
        state.ui.statsTime:SetText(latestTrackingTime and ("最后更新  " .. date("%m-%d %H:%M:%S", latestTrackingTime)) or "最后更新  --")
        state.ui.statsTime:SetTextColor(0.35, 1, 0.55)
        state.ui.statsTotal:SetText("")
        state.ui.stats:SetText(table.concat(stats, "   |cff777777·|r   "))
        state.ui.stats:Show()
        state.statsScrollBar:Hide()
        for _, row in ipairs(state.statsRows) do row.guild = nil; if row.invite then row.invite:Hide() end; row:Hide() end
    end
    if state.queryTabButton then state.queryTabButton:SetEnabled(true); state.queryTabButton:GetFontString():SetTextColor(state.mainTab=="enemyQuery" and 1 or 0.9,state.mainTab=="enemyQuery" and 0.82 or 0.9,state.mainTab=="enemyQuery" and 0.05 or 0.9) end
    if state.trackingTabButton then state.trackingTabButton:SetEnabled(true); state.trackingTabButton:GetFontString():SetTextColor(state.mainTab=="enemyTracking" and 1 or 0.9,state.mainTab=="enemyTracking" and 0.28 or 0.9,state.mainTab=="enemyTracking" and 0.2 or 0.9) end
    if state.friendlyTabButton then state.friendlyTabButton:SetEnabled(true); state.friendlyTabButton:GetFontString():SetTextColor(state.mainTab=="enemyConfig" and 1 or 0.9,state.mainTab=="enemyConfig" and 0.82 or 0.9,state.mainTab=="enemyConfig" and 0.05 or 0.9) end
    if state.mainTabMarks then
        state.mainTabMarks.enemyQuery:SetShown(state.mainTab=="enemyQuery")
        state.mainTabMarks.enemyTracking:SetShown(state.mainTab=="enemyTracking")
        state.mainTabMarks.enemyConfig:SetShown(state.mainTab=="enemyConfig")
    end
    local labels
    if friendlyView then labels = { "地区", "玩家姓名", "公会", "等级", "职业", "邀请状态" }
    elseif queryTab then labels = { "地区", "玩家姓名", "公会", "等级", "职业", "种族" }
    else labels = { "最后地区", "玩家姓名", "状态", "等级", "职业", "自动播报" } end
    if not queryTab then
        local sortIndex=WowDetectorDB.trackingSort=="class" and 5 or 1
        labels[sortIndex]=labels[sortIndex]..(WowDetectorDB.trackingSortAscending==false and " ↓" or " ↑")
    end
    if state.headerLabels then for index, label in ipairs(labels) do state.headerLabels[index]:SetText(label) end end
    if state.trackingSortHeaders then
        for _,button in pairs(state.trackingSortHeaders) do button:SetShown(expanded and not queryTab and not enemyConfigView) end
    end
    if state.layoutColumns then state.layoutColumns(state.ui:GetWidth()) end
    local contentTop=friendlyView and 360 or (147+(warningShown and 34 or 0))
    local visibleCount = math.max(0, math.min(#state.rows, math.floor((state.ui:GetHeight() - contentTop) / 20)))
    local maxOffset = math.max(0, #active - visibleCount)
    state.scrollOffset = math.max(0, math.min(state.scrollOffset or 0, maxOffset))
    if state.scrollBar then
        state.scrollBar:SetMinMaxValues(0, maxOffset)
        state.scrollBar:SetValue(state.scrollOffset)
        state.scrollBar:SetShown(not WowDetectorDB.window.collapsed and maxOffset > 0)
    end
    for index, row in ipairs(state.rows) do
        local record = index <= visibleCount and active[state.scrollOffset + index] or nil
        if record and not WowDetectorDB.window.collapsed then
            row.zone:SetText(record.zone)
            row.name:SetText(ColoredPlayerName(record.name, record.class, record.classFile))
            local guildText=Trim(record.guild)
            row.guild:SetText((guildText=="" or guildText==UNKNOWN) and "-" or guildText)
            row.level:SetText(record.level)
            row.class:SetText(record.class)
            if friendlyView then
                local inviteState=IsCurrentGroupMember and IsCurrentGroupMember(record.name) and "joined"
                    or state.inviteStatuses[NormalizeTrackedName(record.name)] or "ready"
                local labels={ready="|cffffffff可邀请|r",waiting="|cffffd34e等待加入|r",joined="|cff55ff88已加入团队|r",othergroup="|cff66ccff已加入其他团队|r",declined="|cffff5555拒绝|r",failed="|cffff5555未加入|r"}
                row.race:SetText(labels[inviteState] or labels.ready); row.race:SetShown(true)
            else
                row.race:SetText(record.isTracked and "" or record.race); row.race:SetShown(not record.isTracked)
            end
            row.trackingName = record.isTracked and record.name or nil
            row.inviteName = nil
            if row.broadcast then
                row.broadcast:SetShown(record.isTracked)
                if record.isTracked then
                    local enabled = WowDetectorDB.trackingBroadcast[NormalizeTrackedName(record.name)] and true or false
                    row.broadcast:SetText(enabled and "关闭播报" or "开启播报")
                end
            end
            row:Show()
        else
            row.trackingName = nil
            row.inviteName = nil
            if row.broadcast then row.broadcast:Hide() end
            row:Hide()
        end
    end
    state.refreshing = false
end

function BroadcastFriendPresence(previous,current)
    if not previous or not current then return end
    if not WowDetectorDB.friendBroadcast[NormalizeTrackedName(current.name)] then return end
    local onlineChanged=previous.online~=current.online
    local previousZone=previous.zone or previous.area
    local currentZone=current.zone or current.area
    local zoneChanged=previous.online and current.online
        and currentZone and currentZone~="" and currentZone~=UNKNOWN
        and previousZone and previousZone~="" and previousZone~=UNKNOWN
        and not ZoneNameMatches(previousZone,currentZone)
    if not onlineChanged and not zoneChanged then return end
    local channel=IsInRaid() and "RAID" or (IsInGroup() and "PARTY" or nil)
    if not channel then return end
    local zone=currentZone
    if not current.online and (not zone or zone=="" or zone==UNKNOWN) then zone=previous.zone end
    if not current.online and (not zone or zone=="" or zone==UNKNOWN) then zone=previous.area end
    -- 服务器聊天频道会拒绝插件拼入的 |cff...|r 客户端颜色控制码；
    -- 姓名职业色只用于本地列表，团队通知必须发送纯文本姓名。
    local action=onlineChanged and L(current.online and "上线" or "下线") or L("地区改变")
    SendChatMessage(string.format("[%s] %s -> %s",current.name or UNKNOWN,action,zone or UNKNOWN),channel)
end

local function IsKnownFriendValue(value)
    local normalized=Trim(value):lower()
    return normalized~="" and normalized~="未知" and normalized~="unknown"
end

local function ListenerFriendCache(senderTag,create)
    if not WowDetectorDB or WowDetectorDB.role~="listener" then return nil end
    local key=NormalizeBattleTag(senderTag or ActivePeerTag())
    if key=="" then return nil end
    WowDetectorDB.listenerFriendCaches=type(WowDetectorDB.listenerFriendCaches)=="table" and WowDetectorDB.listenerFriendCaches or {}
    local cache=WowDetectorDB.listenerFriendCaches[key]
    if not cache and create then
        cache={records={},updatedAt=0,detectorZone=nil}
        WowDetectorDB.listenerFriendCaches[key]=cache
    end
    if cache then cache.records=type(cache.records)=="table" and cache.records or {} end
    return cache,key
end

local function MergeFriendWithCache(record,cached)
    if not record then return nil end
    local merged={name=record.name,online=record.online and true or false,zone=record.zone,
        level=record.level,class=record.class,classFile=record.classFile}
    if cached then
        if not IsKnownFriendValue(merged.zone) and IsKnownFriendValue(cached.zone) then merged.zone=cached.zone end
        if not IsKnownFriendValue(merged.level) and IsKnownFriendValue(cached.level) then merged.level=cached.level end
        if not IsKnownFriendValue(merged.class) and IsKnownFriendValue(cached.class) then merged.class=cached.class end
        if not merged.classFile then merged.classFile=cached.classFile end
    end
    if not IsKnownFriendValue(merged.zone) then merged.zone=UNKNOWN end
    if not IsKnownFriendValue(merged.level) then merged.level=UNKNOWN end
    if not IsKnownFriendValue(merged.class) then merged.class=UNKNOWN end
    return merged
end

local function SaveFriendToCache(cache,record)
    if not cache or not record then return end
    local key=NormalizeTrackedName(record.name)
    if key=="" then return end
    cache.records[key]=MergeFriendWithCache(record,cache.records[key])
    cache.updatedAt=time()
end

function RestoreListenerFriendCache(senderTag)
    local cache=ListenerFriendCache(senderTag,false)
    if not cache then return false end
    wipe(state.friendRecords)
    for _,record in pairs(cache.records) do state.friendRecords[#state.friendRecords+1]=MergeFriendWithCache(record,nil) end
    state.friendDetectorZone=cache.detectorZone
    state.friendSnapshotAt=tonumber(cache.updatedAt) or nil
    state.friendCacheRestored=true
    state.friendOffset=0
    if RefreshFriendUI then RefreshFriendUI() end
    return #state.friendRecords>0
end

local function BeginCharacterFriendAdd(name,callback)
    local prepared=Trim(name):gsub("－","-"):gsub("—","-"):gsub("%s+","")
    if prepared=="" then Print(L("[好友添加] 姓名为空，已拒绝")); callback(false,"invalid",prepared); return end
    if FindCharacterFriendName(prepared) then Print(string.format(L("[好友添加] 好友已存在：%s"),prepared)); callback(true,"exists",prepared); return end
    local friends=ReadCharacterFriends(); UpdateFriendCapacity(friends)
    if #friends>=100 or state.friendListFull then Print(L("[好友添加] 好友列表已满")); callback(false,"full",prepared); return end
    state.manualFriendAddPending=state.manualFriendAddPending or {}
    local key=NormalizeTrackedName(prepared)
    if state.manualFriendAddPending[key] then Print(string.format(L("[好友添加] 请求正在处理中：%s"),prepared)); callback(false,"pending",prepared); return end
    Print(string.format(L("[好友添加] 正在调用好友接口：%s"),prepared))
    local called,reason=AddCharacterFriend(prepared)
    if not called then Print(string.format(L("[好友添加] 好友接口调用失败：%s（%s）"),prepared,tostring(reason or "failed"))); callback(false,reason or "failed",prepared); return end
    Print(string.format(L("正在添加侦测方好友：%s"),prepared))
    state.manualFriendAddPending[key]=true
    local attempts=0
    local function VerifyAdd()
        attempts=attempts+1
        Print(string.format(L("[好友添加] 正在验证好友列表：%s（%d/3）"),prepared,attempts))
        RequestFriendList()
        C_Timer.After(1,function()
            local actualName=FindCharacterFriendName(prepared)
            if actualName then
                state.manualFriendAddPending[key]=nil
                Print(string.format(L("[好友添加] 已在好友列表中确认：%s"),actualName))
                PollTrackedFriends(true,true)
                callback(true,"added",actualName)
            elseif attempts<3 then
                VerifyAdd()
            else
                state.manualFriendAddPending[key]=nil
                Print(string.format(L("[好友添加] 三次验证均未找到：%s"),prepared))
                PollTrackedFriends(true,true)
                callback(false,"failed",prepared)
            end
        end)
    end
    VerifyAdd()
end

function Receive(message, senderID)
    if message == "VREQ" then
        SendRawToID(senderID, "VINFO|" .. VERSION .. "|" .. PROTOCOL_VERSION .. "|" .. tostring(WowDetectorDB.role or "unknown"))
        return
    end
    local peerVersion, peerProtocol, peerRole = message:match("^VINFO|([^|]+)|([^|]+)|([^|]+)$")
    if peerVersion then
        local versionSender = SenderPeerTag(senderID)
        if not versionSender then return end
        local key = NormalizeBattleTag(versionSender)
        state.peerVersions[key] = peerVersion
        state.peerProtocols[key] = tonumber(peerProtocol)
        state.peerRoles[key] = peerRole
        state.peerVersionRequestedAt[key] = nil
        MarkCommunication()
        if WowDetectorDB.role == "listener" and key == NormalizeBattleTag(WowDetectorDB.activeConfigPeer) then
            state.friendSourceLastAt = time()
            state.friendSourceUnavailable = false
            local compatible = PeerCompatibility(versionSender)
            if compatible then RequestPeerSnapshot(versionSender)
            else
                ClearRemoteSourceData(nil)
                Print("当前侦测方通信协议不兼容，已停止接收其数据")
            end
        end
        if RefreshConfigUI then RefreshConfigUI() end
        return
    end
    local pingNonce = message:match("^PING|(.+)$")
    if pingNonce then
        SendRawToID(senderID, "PONG|" .. pingNonce)
        local senderTag = SenderPeerTag(senderID)
        if senderTag and WowDetectorDB.role == "detector" then SendPeerPolicy(senderTag) end
        MarkCommunication()
        Print("收到对端通信测试，已自动回应")
        return
    end
    local pongNonce = message:match("^PONG|(.+)$")
    if pongNonce then
        return
    end
    if message == "CREQ" then
        local senderTag = SenderPeerTag(senderID)
        if senderTag and WowDetectorDB.role == "detector" then
            SendPeerPolicy(senderTag); MarkCommunication()
            PollTrackedFriends(true, true)
        end
        return
    end
    if message:sub(1,5)=="FDEL|" and WowDetectorDB.role=="detector" then
        local senderTag=SenderPeerTag(senderID)
        if not senderTag or not PeerCompatibility(senderTag) or not WowDetectorDB.peerPermissions[NormalizeBattleTag(senderTag)] then
            if senderTag then SendPeerPolicy(senderTag) end
            return
        end
        local name=Unescape(message:sub(6))
        if name~="" then
            state.friendDeletePending=state.friendDeletePending or {}
            local pendingKey=NormalizeTrackedName(name)
            if not state.friendDeletePending[pendingKey] then
                local actualName=FindCharacterFriendName(name)
                if not actualName then
                    SendRawToID(senderID,"FDELRESULT|1|"..Escape(name))
                    PollTrackedFriends(false,true)
                else
                    local called,reason=RemoveCharacterFriend(actualName)
                    if not called then
                        SendRawToID(senderID,"FDELRESULT|0|"..Escape(name))
                        Print(string.format(L("侦测方好友删除失败：%s"),name))
                    else
                        state.friendDeletePending[pendingKey]=true
                        local attempts=0
                        local function VerifyRemoval()
                            attempts=attempts+1
                            RequestFriendList()
                            C_Timer.After(1,function()
                                if not FindCharacterFriendName(actualName) then
                                    state.friendDeletePending[pendingKey]=nil
                                    SendRawToID(senderID,"FDELRESULT|1|"..Escape(name))
                                    Print(string.format(L("已确认删除侦测方好友：%s"),actualName))
                                    PollTrackedFriends(true,true)
                                elseif attempts<3 then
                                    if attempts==2 then RemoveCharacterFriend(actualName) end
                                    VerifyRemoval()
                                else
                                    state.friendDeletePending[pendingKey]=nil
                                    SendRawToID(senderID,"FDELRESULT|0|"..Escape(name))
                                    Print(string.format(L("侦测方好友删除失败：%s"),actualName))
                                    PollTrackedFriends(true,true)
                                end
                            end)
                        end
                        VerifyRemoval()
                    end
                end
            end
        end
        return
    end
    if message:sub(1,11)=="FDELRESULT|" and WowDetectorDB.role=="listener" then
        local senderTag=SenderPeerTag(senderID)
        if not senderTag or NormalizeBattleTag(senderTag)~=NormalizeBattleTag(ActivePeerTag()) or not PeerCompatibility(senderTag) then return end
        local fields={}
        for field in (message.."|"):gmatch("(.-)|") do fields[#fields+1]=Unescape(field) end
        local success=fields[2]=="1"; local name=fields[3] or ""
        if success then
            local wanted=NormalizeTrackedName(name)
            for index=#state.friendRecords,1,-1 do
                if NormalizeTrackedName(state.friendRecords[index].name)==wanted or TrackedNameMatches(state.friendRecords[index].name,name) then table.remove(state.friendRecords,index) end
            end
            WowDetectorDB.friendBroadcast[wanted]=nil
            Print(string.format(L("已确认删除侦测方好友：%s"),name))
            if RefreshFriendUI then RefreshFriendUI() end
        else
            Print(string.format(L("侦测方好友删除失败：%s"),name))
        end
        return
    end
    if message:sub(1,5)=="FADD|" then
        local senderTag=SenderPeerTag(senderID)
        local name=Unescape(message:sub(6))
        if WowDetectorDB.role~="detector" then
            Print(string.format(L("[好友添加] 收到请求但当前不是侦测方：%s"),name))
            SendRawToID(senderID,table.concat({"FADDRESULT","0",Escape(name),"role"},"|"))
            return
        end
        Print(string.format(L("[好友添加] 收到监听方请求：%s（%s）"),name,senderTag or L("未知发送者")))
        if not senderTag or not PeerCompatibility(senderTag) or not WowDetectorDB.peerPermissions[NormalizeBattleTag(senderTag)] then
            Print(string.format(L("[好友添加] 权限或来源校验失败：%s"),senderTag or L("未知发送者")))
            if senderTag then SendPeerPolicy(senderTag) end
            if senderTag then SendRawToID(senderID,table.concat({"FADDRESULT","0",Escape(name),"permission"},"|")) end
            return
        end
        BeginCharacterFriendAdd(name,function(success,reason,actualName)
            local sent,sendReason=SendRawToID(senderID,table.concat({"FADDRESULT",success and "1" or "0",Escape(actualName or name),Escape(reason or "")},"|"))
            if sent then Print(string.format(L("[好友添加] 已回传结果：%s（%s）"),actualName or name,success and L("成功") or L("失败")))
            else Print(string.format(L("[好友添加] 回传结果失败：%s"),tostring(sendReason or UNKNOWN))) end
            if success then Print(string.format(L("已添加侦测方好友：%s"),actualName or name))
            else Print(string.format(L("侦测方好友添加失败：%s"),actualName or name)) end
        end)
        return
    end
    if message:sub(1,11)=="FADDRESULT|" and WowDetectorDB.role=="listener" then
        local senderTag=SenderPeerTag(senderID)
        if not senderTag or NormalizeBattleTag(senderTag)~=NormalizeBattleTag(ActivePeerTag()) or not PeerCompatibility(senderTag) then return end
        local fields={}
        for field in (message.."|"):gmatch("(.-)|") do fields[#fields+1]=Unescape(field) end
        local success=fields[2]=="1"; local name=fields[3] or ""; local reason=fields[4] or ""
        state.friendAddRequestToken=(state.friendAddRequestToken or 0)+1
        state.friendAddBusyName=nil
        if RefreshFriendUI then RefreshFriendUI() end
        if success then Print(string.format(L(reason=="exists" and "侦测方好友已存在：%s" or "已添加侦测方好友：%s"),name))
        elseif reason=="full" then Print(L("侦测方好友列表已满，无法添加"))
        elseif reason=="permission" then Print(L("侦测方未允许本监听端修改配置"))
        elseif reason=="role" then Print(L("对端当前不是侦测方，无法添加好友"))
        else Print(string.format(L("侦测方好友添加失败：%s"),name)) end
        return
    end
    local policy = message:match("^POLICY|([01])$")
    if policy then
        local policySender = SenderPeerTag(senderID)
        if not policySender then return end
        if WowDetectorDB.role == "listener" and (NormalizeBattleTag(policySender) ~= NormalizeBattleTag(ActivePeerTag()) or not PeerCompatibility(policySender)) then return end
        -- 权限状态属于后台同步信息，只更新界面，不向聊天框输出，避免好友状态事件刷屏。
        WowDetectorDB.remoteConfigAllowed = policy == "1"
        MarkCommunication()
        return
    end
    if message:sub(1, 2) == "C|" then
        return
    end
    if WowDetectorDB.role ~= "listener" then return end
    local senderTag = SenderPeerTag(senderID)
    if not senderTag then
        Print("收到一条敌情消息，但发送者与已保存的对端战网ID不匹配，已忽略")
        return
    end
    if NormalizeBattleTag(senderTag) ~= NormalizeBattleTag(ActivePeerTag()) then return end
    if not PeerCompatibility(senderTag) then return end
    state.friendSourceLastAt = time()
    state.friendSourceUnavailable = false
    MarkCommunication()
    local heartbeatTime = message:match("^FHB|(%d+)$")
    if heartbeatTime then
        state.friendSnapshotAt = tonumber(heartbeatTime) or time()
        if RefreshFriendUI then RefreshFriendUI() end
        return
    end
    if message:sub(1,4)=="FSU|" then
        local fields={}
        for field in (message.."|"):gmatch("(.-)|") do fields[#fields+1]=Unescape(field) end
        local name=fields[2]
        if name and name~="" then
            local cache=ListenerFriendCache(senderTag,true)
            local wanted=NormalizeTrackedName(name)
            local cached=cache and cache.records[wanted]
            local updated=MergeFriendWithCache({name=name,online=fields[3]=="1",zone=fields[4]~="" and fields[4] or UNKNOWN,
                level=fields[5]~="" and fields[5] or UNKNOWN,class=fields[6]~="" and fields[6] or UNKNOWN}
                ,cached)
            local replaced=false; local previous
            for index,record in ipairs(state.friendRecords) do
                if NormalizeTrackedName(record.name)==wanted then previous=record; state.friendRecords[index]=updated; replaced=true; break end
            end
            previous=previous or cached
            if not replaced then state.friendRecords[#state.friendRecords+1]=updated end
            BroadcastFriendPresence(previous,updated)
            state.friendDetectorZone=fields[7]~="" and fields[7] or state.friendDetectorZone
            state.friendSnapshotAt=tonumber(fields[8]) or time(); state.friendOffset=0
            SaveFriendToCache(cache,updated)
            if cache then cache.detectorZone=state.friendDetectorZone; cache.updatedAt=state.friendSnapshotAt end
            if RefreshFriendUI then RefreshFriendUI() end
        end
        return
    end
    if message:sub(1,4)=="FSR|" then
        local fields={}
        for field in (message.."|"):gmatch("(.-)|") do fields[#fields+1]=Unescape(field) end
        local wanted=NormalizeTrackedName(fields[2])
        if wanted~="" then
            local cache=ListenerFriendCache(senderTag,true)
            for index=#state.friendRecords,1,-1 do if NormalizeTrackedName(state.friendRecords[index].name)==wanted then table.remove(state.friendRecords,index) end end
            if cache then cache.records[wanted]=nil; cache.updatedAt=tonumber(fields[4]) or time(); cache.detectorZone=fields[3]~="" and fields[3] or cache.detectorZone end
            WowDetectorDB.friendBroadcast[wanted]=nil
            state.friendDetectorZone=fields[3]~="" and fields[3] or state.friendDetectorZone
            state.friendSnapshotAt=tonumber(fields[4]) or time(); state.friendOffset=0
            if RefreshFriendUI then RefreshFriendUI() end
        end
        return
    end
    local snapshotSerial, detectorZone, snapshotTime = message:match("^FSB|(%d+)|([^|]*)|(%d+)$")
    if snapshotSerial then
        state.incomingFriendSnapshot = { serial=tonumber(snapshotSerial), zone=Unescape(detectorZone), senderTag=senderTag,
            time=tonumber(snapshotTime) or time(), records={} }
        return
    end
    if message:sub(1, 4) == "FSI|" then
        local fields = {}
        for field in (message .. "|"):gmatch("(.-)|") do fields[#fields + 1] = Unescape(field) end
        local incoming = state.incomingFriendSnapshot
        if incoming and tonumber(fields[2]) == incoming.serial and fields[3] and fields[3] ~= "" then
            local cache=ListenerFriendCache(incoming.senderTag,false)
            local cached=cache and cache.records[NormalizeTrackedName(fields[3])]
            incoming.records[#incoming.records + 1] = MergeFriendWithCache({ name=fields[3], online=fields[4] == "1",
                zone=fields[5] ~= "" and fields[5] or UNKNOWN,
                level=fields[6] ~= "" and fields[6] or UNKNOWN,
                class=fields[7] ~= "" and fields[7] or UNKNOWN },cached)
        end
        return
    end
    local finishedSerial = message:match("^FSE|(%d+)|%d+$")
    if finishedSerial then
        local incoming = state.incomingFriendSnapshot
        if incoming and tonumber(finishedSerial) == incoming.serial then
            local previousByName={}
            for _,record in ipairs(state.friendRecords or {}) do previousByName[NormalizeTrackedName(record.name)]=record end
            local hadPrevious=state.friendSnapshotAt~=nil and not state.friendCacheRestored
            state.friendRecords = incoming.records
            state.friendDetectorZone = incoming.zone
            state.friendSnapshotAt = incoming.time
            state.friendOffset = 0
            state.incomingFriendSnapshot = nil
            state.friendCacheRestored=nil
            local cache=ListenerFriendCache(senderTag,true)
            if cache then
                cache.records={}
                for _,record in ipairs(state.friendRecords) do SaveFriendToCache(cache,record) end
                cache.detectorZone=state.friendDetectorZone; cache.updatedAt=state.friendSnapshotAt
            end
            if hadPrevious then
                for _,record in ipairs(state.friendRecords) do BroadcastFriendPresence(previousByName[NormalizeTrackedName(record.name)],record) end
            end
            if RefreshFriendUI then RefreshFriendUI() end
        end
        return
    end
    -- “敌”功能已移除；旧版本发送的 TRACK、QSTART、QDONE 和敌情记录不再接收。
    return
end

function MakeText(parent, width, anchor, text)
    local font = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    font:SetWidth(width)
    if font.SetWordWrap then font:SetWordWrap(false) end
    font:SetJustifyH("LEFT")
    font:SetPoint("LEFT", anchor, "LEFT", 0, 0)
    font:SetText(text or "")
    return font
end

function CreateSortDropdown(parent, name, getMode, setMode, refresh)
    local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dropdown, 72)
    local function UpdateText()
        UIDropDownMenu_SetText(dropdown, getMode() == "class" and "按职业" or "按地区")
    end
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        for _, option in ipairs({ { text="按地区", value="zone" }, { text="按职业", value="class" } }) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text; info.value = option.value; info.checked = getMode() == option.value
            info.func = function()
                setMode(option.value); UpdateText(); CloseDropDownMenus(); refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UpdateText()
    return dropdown
end

local friendDeleteName

local function InsertFriendNameIntoChat(name)
    if not name or name=="" then return end
    if ChatEdit_InsertLink and ACTIVE_CHAT_EDIT_BOX then
        ChatEdit_InsertLink(name)
        return
    end
    if ChatFrame_OpenChat then
        ChatFrame_OpenChat(name,DEFAULT_CHAT_FRAME)
        return
    end
    local editBox=ChatEdit_ChooseBoxForSend and ChatEdit_ChooseBoxForSend(DEFAULT_CHAT_FRAME)
    editBox=editBox or (DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox)
    if not editBox then return end
    if ChatEdit_ActivateChat then ChatEdit_ActivateChat(editBox) else editBox:Show(); editBox:SetFocus() end
    editBox:Insert(name)
end
StaticPopupDialogs.WCED_DELETE_DETECTOR_FRIEND={
    text=L("确定从侦测方好友中删除 %s？"),button1=DELETE,button2=CANCEL,timeout=0,whileDead=true,hideOnEscape=true,showAlert=true,preferredIndex=3,
    OnAccept=function()
        local tag=ActivePeerTag(); local id=tag and FindPeer(true,tag)
        if friendDeleteName and id and PeerCompatibility(tag) then
            SendRawToID(id,"FDEL|"..Escape(friendDeleteName)); Print(string.format(L("已发送好友删除请求：%s"),friendDeleteName))
        else Print("当前侦测方不可用，未发送删除请求") end
    end,
}

local function SubmitDetectorFriendAdd(name)
        name=Trim(name or "")
        Print(string.format(L("[好友添加] 已提交：%s"),name~="" and name or L("空姓名")))
        if name=="" then Print(L("请输入好友姓名")); return end
        if state.friendAddBusyName then Print(string.format(L("好友添加请求正在处理中：%s"),state.friendAddBusyName)); return end
        if WowDetectorDB.role=="detector" then
            state.friendAddBusyName=name
            if RefreshFriendUI then RefreshFriendUI() end
            BeginCharacterFriendAdd(name,function(success,reason,actualName)
                state.friendAddBusyName=nil
                if RefreshFriendUI then RefreshFriendUI() end
                if success then Print(string.format(L(reason=="exists" and "侦测方好友已存在：%s" or "已添加侦测方好友：%s"),actualName or name))
                elseif reason=="full" then Print(L("侦测方好友列表已满，无法添加"))
                else Print(string.format(L("侦测方好友添加失败：%s"),actualName or name)) end
            end)
            return
        end
        local tag=ActivePeerTag(); local id=tag and FindPeer(true,tag)
        if WowDetectorDB.remoteConfigAllowed~=true then Print(L("侦测方未允许本监听端修改配置")); return end
        if id and PeerCompatibility(tag) then
            local peerVersion=state.peerVersions[NormalizeBattleTag(tag)]
            if not VersionAtLeast(peerVersion,"0.28.6") then Print(L("侦测方版本过低，暂不支持远程添加好友")); return end
            state.friendAddBusyName=name
            state.friendAddRequestToken=(state.friendAddRequestToken or 0)+1
            local requestToken=state.friendAddRequestToken
            if RefreshFriendUI then RefreshFriendUI() end
            local sent,sendReason=SendRawToID(id,"FADD|"..Escape(name))
            if not sent then
                state.friendAddBusyName=nil
                if RefreshFriendUI then RefreshFriendUI() end
                Print(string.format(L("好友添加请求发送失败：%s"),tostring(sendReason or UNKNOWN)))
                return
            end
            Print(string.format(L("[好友添加] 请求已发送至：%s"),tag or UNKNOWN))
            Print(string.format(L("正在请求侦测方添加好友：%s"),name))
            C_Timer.After(8,function()
                if state.friendAddRequestToken~=requestToken or not state.friendAddBusyName then return end
                state.friendAddRequestToken=state.friendAddRequestToken+1
                state.friendAddBusyName=nil
                if RefreshFriendUI then RefreshFriendUI() end
                Print(string.format(L("添加好友请求超时：%s，请确认侦测方已更新并在线"),name))
            end)
        else Print(L("当前侦测方不可用，未发送添加请求")) end
end

local friendAddDialog=CreateFrame("Frame","WCEDFriendAddDialog",UIParent,"BackdropTemplate")
friendAddDialog:SetSize(430,150); friendAddDialog:SetPoint("CENTER"); friendAddDialog:SetFrameStrata("DIALOG")
friendAddDialog:SetClampedToScreen(true); friendAddDialog:EnableMouse(true); friendAddDialog:Hide()
friendAddDialog:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background",edgeFile="Interface/DialogFrame/UI-DialogBox-Border",edgeSize=24,insets={left=8,right=8,top=8,bottom=8}})
friendAddDialog:SetBackdropColor(0.025,0.025,0.025,0.98)
local friendAddTitle=friendAddDialog:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
friendAddTitle:SetPoint("TOP",0,-18); friendAddTitle:SetText(L("输入要添加到侦测方的好友姓名"))
friendAddDialog.editBox=CreateFrame("EditBox",nil,friendAddDialog,"InputBoxTemplate")
friendAddDialog.editBox:SetSize(280,30); friendAddDialog.editBox:SetPoint("TOP",0,-50); friendAddDialog.editBox:SetAutoFocus(false); friendAddDialog.editBox:SetMaxLetters(48)
friendAddDialog.accept=CreateFrame("Button",nil,friendAddDialog,"UIPanelButtonTemplate")
friendAddDialog.accept:SetSize(125,26); friendAddDialog.accept:SetPoint("BOTTOMLEFT",75,18); friendAddDialog.accept:SetText(L("确定添加"))
friendAddDialog.cancel=CreateFrame("Button",nil,friendAddDialog,"UIPanelButtonTemplate")
friendAddDialog.cancel:SetSize(125,26); friendAddDialog.cancel:SetPoint("BOTTOMRIGHT",-75,18); friendAddDialog.cancel:SetText(CANCEL)
friendAddDialog.accept:SetScript("OnClick",function()
    local name=friendAddDialog.editBox:GetText() or ""
    if Trim(name)=="" then Print(L("请输入好友姓名")); friendAddDialog.editBox:SetFocus(); return end
    friendAddDialog:Hide(); SubmitDetectorFriendAdd(name)
end)
friendAddDialog.cancel:SetScript("OnClick",function() friendAddDialog:Hide() end)
friendAddDialog.editBox:SetScript("OnEnterPressed",function() friendAddDialog.accept:Click() end)
friendAddDialog.editBox:SetScript("OnEscapePressed",function() friendAddDialog:Hide() end)
friendAddDialog:SetScript("OnShow",function(self) self.editBox:SetText(""); self.editBox:SetFocus() end)
friendAddDialog:SetScript("OnHide",function(self) self.editBox:ClearFocus() end)
table.insert(UISpecialFrames,"WCEDFriendAddDialog")

local function ShowDetectorFriendAddDialog()
    friendAddDialog:Show(); friendAddDialog:Raise()
end

local friendContextMenu=CreateFrame("Frame","WCEDFriendContextMenu",UIParent,"BackdropTemplate")
friendContextMenu:SetFrameStrata("TOOLTIP"); friendContextMenu:SetSize(170,96); friendContextMenu:Hide(); friendContextMenu:EnableMouse(true)
friendContextMenu:SetClampedToScreen(true)
friendContextMenu:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background",edgeFile="Interface/Tooltips/UI-Tooltip-Border",
    tile=true,tileSize=16,edgeSize=14,insets={left=4,right=4,top=4,bottom=4}})
friendContextMenu:SetBackdropColor(0.025,0.025,0.025,0.97); friendContextMenu:SetBackdropBorderColor(0.65,0.65,0.65,1)
friendContextMenu:RegisterEvent("GLOBAL_MOUSE_DOWN")
friendContextMenu:SetScript("OnEvent",function(self) if not self:IsMouseOver() then self:Hide() end end)
table.insert(UISpecialFrames,"WCEDFriendContextMenu")

local friendContextTitle=friendContextMenu:CreateFontString(nil,"OVERLAY","GameFontNormal")
friendContextTitle:SetPoint("TOPLEFT",14,-11); friendContextTitle:SetPoint("TOPRIGHT",-14,-11); friendContextTitle:SetJustifyH("LEFT")
local friendContextLine=friendContextMenu:CreateTexture(nil,"ARTWORK")
friendContextLine:SetColorTexture(0.45,0.45,0.45,0.8); friendContextLine:SetHeight(1); friendContextLine:SetPoint("TOPLEFT",10,-32); friendContextLine:SetPoint("TOPRIGHT",-10,-32)

local function CreateFriendContextButton(index)
    local button=CreateFrame("Button",nil,friendContextMenu)
    button:SetHeight(25); button:SetPoint("TOPLEFT",7,-35-(index-1)*26); button:SetPoint("TOPRIGHT",-7,-35-(index-1)*26)
    button.highlight=button:CreateTexture(nil,"HIGHLIGHT"); button.highlight:SetAllPoints(); button.highlight:SetColorTexture(0.75,0.55,0.08,0.28)
    button.text=button:CreateFontString(nil,"OVERLAY","GameFontHighlight"); button.text:SetPoint("LEFT",8,0); button.text:SetJustifyH("LEFT")
    return button
end
local friendCopyButton=CreateFriendContextButton(1)
local friendDeleteButton=CreateFriendContextButton(2)

local function ShowFriendContextMenu(record)
    if not record or not record.name or record.name=="" then return end
    local name=record.name
    friendContextTitle:SetText(ColoredPlayerName(name,record.class))
    friendCopyButton.text:SetText(L("复制名称")); friendCopyButton.text:SetTextColor(1,1,1)
    friendCopyButton:SetScript("OnClick",function()
        friendContextMenu:Hide(); InsertFriendNameIntoChat(name)
    end)
    local canDelete=WowDetectorDB.role=="listener" and WowDetectorDB.remoteConfigAllowed==true
    if canDelete then
        friendDeleteButton:Show(); friendDeleteButton.text:SetText(L("删除好友")); friendDeleteButton.text:SetTextColor(1,0.25,0.25)
        friendDeleteButton:SetScript("OnClick",function()
            friendContextMenu:Hide(); friendDeleteName=name; StaticPopup_Show("WCED_DELETE_DETECTOR_FRIEND",name)
        end)
        friendContextMenu:SetHeight(96)
    else
        friendDeleteButton:Hide(); friendContextMenu:SetHeight(70)
    end
    local scale=UIParent:GetEffectiveScale()
    local x,y=GetCursorPosition(); x,y=x/scale,y/scale
    friendContextMenu:ClearAllPoints(); friendContextMenu:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x+4,y-4)
    friendContextMenu:Show()
end

function BuildFriendUI()
    local saved = WowDetectorDB.friendWindow
    if tonumber(saved.width) == 620 or tonumber(saved.width) == 560 or tonumber(saved.width) == 490 then saved.width = 460 end
    if tonumber(saved.height) == 430 then saved.height = 390 end
    local ui = CreateFrame("Frame", "WowDetectorFriendWindow", UIParent, "BackdropTemplate")
    ui:SetSize(saved.width or 460, saved.height or 390)
    ui:SetPoint(saved.point or "CENTER", UIParent, saved.point or "CENTER", saved.x or 260, saved.y or 0)
    ui:SetMovable(true); ui:SetResizable(true); ui:SetClampedToScreen(true); ui:EnableMouse(true)
    if ui.SetResizeBounds then ui:SetResizeBounds(440, 270, 720, 600) else ui:SetMinResize(440, 270); ui:SetMaxResize(720, 600) end
    ui:SetBackdrop({ bgFile="Interface/Tooltips/UI-Tooltip-Background", edgeFile="Interface/Tooltips/UI-Tooltip-Border",
        edgeSize=14, insets={left=3,right=3,top=3,bottom=3} })
    ui:SetBackdropColor(0.03, 0.03, 0.03, 0.94); ui:SetBackdropBorderColor(0.85, 0.55, 0.08, 1)

    local title = ui:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -12); title:SetText("好友情报"); ui.title = title
    local close = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
    close:SetSize(24, 24); close:SetPoint("TOPRIGHT", -6, -6); close:SetText("×")
    close:SetScript("OnClick", function() ui:Hide() end)
    local collapse = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
    collapse:SetSize(24, 24); collapse:SetPoint("TOPRIGHT", -36, -6); collapse:SetText("−")
    local drag = CreateFrame("Frame", nil, ui); drag:SetPoint("TOPLEFT", 8, -5); drag:SetPoint("TOPRIGHT", -42, -5); drag:SetHeight(34); drag:EnableMouse(true)
    drag:SetScript("OnMouseDown", function(_, button) if button == "LeftButton" then ui:StartMoving() end end)
    drag:SetScript("OnMouseUp", function()
        ui:StopMovingOrSizing(); local point, _, _, x, y = ui:GetPoint()
        saved.point, saved.x, saved.y = point, x, y
    end)

    local alertPanel = CreateFrame("Frame", nil, ui, "BackdropTemplate")
    alertPanel:SetPoint("TOPLEFT", 12, -42); alertPanel:SetPoint("TOPRIGHT", -12, -42); alertPanel:SetHeight(72)
    alertPanel:SetBackdrop({ bgFile="Interface/Buttons/WHITE8X8", edgeFile="Interface/Tooltips/UI-Tooltip-Border",
        edgeSize=9, insets={left=2,right=2,top=2,bottom=2} })
    alertPanel:SetBackdropColor(0.055,0.055,0.055,0.92); alertPanel:SetBackdropBorderColor(0.38,0.30,0.12,0.9)
    local function AlertValue(x, label, color)
        local block=alertPanel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        block:SetPoint("BOTTOMLEFT",x,8); block:SetWidth(140); block:SetJustifyH("LEFT")
        if block.SetWordWrap then block:SetWordWrap(false) end
        block:SetTextColor(color[1],color[2],color[3]); block:SetText(label); return block
    end
    ui.alertDanger=AlertValue(12,"同区威胁: 0",{1,0.32,0.32})
    ui.alertOnline=AlertValue(170,"在线总数: 0",{0.35,1,0.55})
    ui.alerts={ui.alertDanger,ui.alertOnline}
    local alertDivider=alertPanel:CreateTexture(nil,"ARTWORK")
    alertDivider:SetPoint("TOPLEFT",alertPanel,"TOPLEFT",9,-34); alertDivider:SetPoint("TOPRIGHT",alertPanel,"TOPRIGHT",-9,-34)
    alertDivider:SetHeight(1); alertDivider:SetColorTexture(0.58,0.43,0.10,0.34)
    local broadcastAllGroup=CreateFrame("Frame",nil,alertPanel)
    broadcastAllGroup:SetSize(86,22); broadcastAllGroup:SetPoint("TOPLEFT",alertPanel,"TOPLEFT",8,-5)
    ui.broadcastAll=CreateFrame("Button",nil,broadcastAllGroup,"UIPanelButtonTemplate"); ui.broadcastAll:SetAllPoints()
    ui.broadcastAll:SetText(L("开启播报"))
    ui.broadcastAll:SetScript("OnClick",function()
        local records=state.friendRecords or {}
        local selected=0
        for _,record in ipairs(records) do if WowDetectorDB.friendBroadcast[NormalizeTrackedName(record.name)] then selected=selected+1 end end
        local enabled=not (#records>0 and selected==#records)
        for _,record in ipairs(state.friendRecords or {}) do WowDetectorDB.friendBroadcast[NormalizeTrackedName(record.name)]=enabled or nil end
        RefreshFriendUI()
    end)
    ui.broadcastAll:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText(self:GetText() or L("开启播报")); GameTooltip:AddLine(L("一次开启或关闭全部好友的上下线及地区改变播报"),1,1,1,true); GameTooltip:Show() end)
    ui.broadcastAll:SetScript("OnLeave",function() GameTooltip:Hide() end)
    ui.friendAddButton=CreateFrame("Button",nil,alertPanel,"UIPanelButtonTemplate")
    ui.friendAddButton:SetSize(86,22); ui.friendAddButton:SetPoint("LEFT",broadcastAllGroup,"RIGHT",5,0); ui.friendAddButton:SetText(L("添加好友"))
    ui.friendAddButton:SetScript("OnClick",ShowDetectorFriendAddDialog)
    ui.friendAddButton:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText(L("添加好友"))
        GameTooltip:AddLine(L("输入姓名并添加到侦测方角色好友列表。"),1,1,1,true); GameTooltip:Show()
    end)
    ui.friendAddButton:SetScript("OnLeave",function() GameTooltip:Hide() end)
    ui.broadcastAllGroup=broadcastAllGroup; ui.alertDivider=alertDivider
    local sourceWarning=CreateFrame("Frame",nil,ui,"BackdropTemplate")
    sourceWarning:SetPoint("TOPLEFT",12,-42); sourceWarning:SetPoint("TOPRIGHT",-12,-42); sourceWarning:SetHeight(28)
    sourceWarning:SetBackdrop({bgFile="Interface/Buttons/WHITE8X8",edgeFile="Interface/Tooltips/UI-Tooltip-Border",edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    sourceWarning:SetBackdropColor(0.18,0.015,0.015,0.94); sourceWarning:SetBackdropBorderColor(1,0.16,0.12,0.95)
    sourceWarning.text=sourceWarning:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); sourceWarning.text:SetPoint("CENTER"); sourceWarning.text:SetTextColor(1,0.35,0.28)
    sourceWarning:Hide(); ui.sourceWarning=sourceWarning

    local header = CreateFrame("Frame", nil, ui); header:SetPoint("TOPLEFT", 14, -122); header:SetPoint("TOPRIGHT", -30, -122); header:SetHeight(18)
    ui.header = header
    ui.broadcastHeader=MakeText(header,46,header,L("播报"))
    local columns = { {"玩家姓名","name",132}, {"地区","zone",88}, {"状态","status",70} }
    ui.headers = {}
    for index, item in ipairs(columns) do
        local button=CreateFrame("Button",nil,header); button:SetHeight(18); button:SetWidth(item[3]); button.key=item[2]; button.label=item[1]
        button.text=button:CreateFontString(nil,"OVERLAY","GameFontHighlight"); button.text:SetAllPoints(); button.text:SetJustifyH("LEFT"); button.text:SetWordWrap(false)
        button:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight","ADD")
        button:SetScript("OnClick",function(self)
            if WowDetectorDB.friendSort==self.key then WowDetectorDB.friendSortAscending=not (WowDetectorDB.friendSortAscending~=false)
            else WowDetectorDB.friendSort=self.key; WowDetectorDB.friendSortAscending=true end
            state.friendOffset=0; RefreshFriendUI()
        end)
        ui.headers[index]=button
    end
    ui.rows = {}
    for index = 1, 24 do
        local row = CreateFrame("Frame", nil, ui); row:SetPoint("TOPLEFT", 14, -141 - (index - 1) * 18); row:SetPoint("TOPRIGHT", -30, -141 - (index - 1) * 18); row:SetHeight(18)
        row.baseBackground=row:CreateTexture(nil,"BACKGROUND"); row.baseBackground:SetAllPoints()
        row.baseBackground:SetColorTexture(1,1,1,index%2==0 and 0.035 or 0)
        row.dangerBackground=row:CreateTexture(nil,"BORDER"); row.dangerBackground:SetAllPoints()
        row.dangerBackground:SetColorTexture(0.75,0.03,0.03,0.32); row.dangerBackground:Hide()
        row.broadcast=CreateFrame("CheckButton",nil,row,"UICheckButtonTemplate"); row.broadcast:SetSize(20,20); row.broadcast:SetPoint("LEFT",6,0)
        row.broadcast:SetScript("OnClick",function(self)
            local record=self:GetParent().record; if not record then return end
            local key=NormalizeTrackedName(record.name)
            WowDetectorDB.friendBroadcast[key]=self:GetChecked() and true or nil
        end)
        row.star=row:CreateTexture(nil,"ARTWORK"); row.star:SetSize(16,16); row.star:SetPoint("LEFT",32,0)
        row.star:SetTexture("Interface/TargetingFrame/UI-RaidTargetingIcon_1"); row.star:Hide()
        row.starPulse=row.star:CreateAnimationGroup(); row.starPulse:SetLooping("BOUNCE")
        local starAlpha=row.starPulse:CreateAnimation("Alpha"); starAlpha:SetFromAlpha(1); starAlpha:SetToAlpha(0.25); starAlpha:SetDuration(0.55)
        row.name = MakeText(row, 132, row); row.name:ClearAllPoints(); row.name:SetPoint("LEFT", row, "LEFT", 52, 0)
        row.zone = MakeText(row, 88, row); row.zone:ClearAllPoints(); row.zone:SetPoint("LEFT", row, "LEFT", 196, 0)
        row.status = MakeText(row, 62, row); row.status:ClearAllPoints(); row.status:SetPoint("LEFT", row, "LEFT", 292, 0)
        row:EnableMouse(true); row:SetScript("OnMouseUp",function(self,button) if button=="RightButton" then ShowFriendContextMenu(self.record) end end)
        ui.rows[index] = row
    end
    local scroll = CreateFrame("Slider", "WowDetectorFriendScrollBar", ui, "UIPanelScrollBarTemplate")
    scroll:SetPoint("TOPRIGHT", -7, -143); scroll:SetPoint("BOTTOMRIGHT", -7, 20); scroll:SetValueStep(1); scroll:SetObeyStepOnDrag(true)
    scroll:SetScript("OnValueChanged", function(_, value) state.friendOffset=math.floor(value+0.5); if RefreshFriendUI then RefreshFriendUI() end end)
    ui.scroll = scroll
    ui:EnableMouseWheel(true); ui:SetScript("OnMouseWheel", function(_, delta)
        if scroll:IsShown() then state.friendOffset=(state.friendOffset or 0)+(delta < 0 and 2 or -2); RefreshFriendUI() end
    end)
    local grip = CreateFrame("Button", nil, ui); grip:SetSize(20,20); grip:SetPoint("BOTTOMRIGHT",-3,3)
    grip:SetNormalTexture("Interface/ChatFrame/UI-ChatIM-SizeGrabber-Up")
    grip:SetScript("OnMouseDown", function(_,button) if button=="LeftButton" then ui:StartSizing("BOTTOMRIGHT") end end)
    grip:SetScript("OnMouseUp", function() ui:StopMovingOrSizing(); saved.width,saved.height=ui:GetSize(); RefreshFriendUI() end)
    ui.alertPanel, ui.close, ui.collapse, ui.grip = alertPanel, close, collapse, grip
    local function ApplyCollapsedState()
        local collapsed = saved.collapsed == true
        if collapsed then
            if ui:GetHeight() > 100 then
                saved.expandedWidth, saved.expandedHeight = ui:GetSize()
            end
            ui:SetResizable(false); ui:SetSize(205, 42)
            title:Hide(); close:Hide(); header:Hide(); grip:Hide(); scroll:Hide()
            collapse:ClearAllPoints(); collapse:SetPoint("RIGHT", ui, "RIGHT", -6, 0); collapse:SetText("+")
            alertPanel:ClearAllPoints(); alertPanel:SetPoint("TOPLEFT", 5, -5); alertPanel:SetPoint("BOTTOMRIGHT", -34, 5)
        else
            ui:SetResizable(true)
            ui:SetSize(math.max(440, tonumber(saved.expandedWidth) or tonumber(saved.width) or 460),
                math.max(270, tonumber(saved.expandedHeight) or tonumber(saved.height) or 390))
            title:Show(); close:Show(); header:Show(); grip:Show()
            collapse:ClearAllPoints(); collapse:SetPoint("TOPRIGHT", -36, -6); collapse:SetText("−")
            alertPanel:ClearAllPoints(); alertPanel:SetPoint("TOPLEFT", 12, -42); alertPanel:SetPoint("TOPRIGHT", -12, -42); alertPanel:SetHeight(72)
        end
        if RefreshFriendUI then RefreshFriendUI() end
    end
    ui.ApplyCollapsedState = ApplyCollapsedState
    collapse:SetScript("OnClick", function()
        if not saved.collapsed then saved.expandedWidth, saved.expandedHeight = ui:GetSize() end
        saved.collapsed = not saved.collapsed
        ApplyCollapsedState()
    end)
    ui:SetScript("OnShow", function() ApplyCollapsedState() end)
    state.friendUI=ui; ApplyCollapsedState(); ui:Hide()
end

RefreshFriendUI = function()
    local ui = state.friendUI
    if not ui then return end
    local localZone = GetRealZoneText and GetRealZoneText() or UNKNOWN
    local available,warningText=HasAvailableDetector()
    local warningShown=WowDetectorDB.role=="listener" and not available and not WowDetectorDB.friendWindow.collapsed
    ui.sourceWarning:SetShown(warningShown)
    ui.sourceWarning.text:SetText(warningText or "当前没有可用的侦测方")
    local shift=warningShown and 32 or 0
    if not WowDetectorDB.friendWindow.collapsed then
        ui.alertPanel:ClearAllPoints(); ui.alertPanel:SetPoint("TOPLEFT",12,-42-shift); ui.alertPanel:SetPoint("TOPRIGHT",-12,-42-shift); ui.alertPanel:SetHeight(72)
        ui.header:ClearAllPoints(); ui.header:SetPoint("TOPLEFT",14,-122-shift); ui.header:SetPoint("TOPRIGHT",-30,-122-shift)
        ui.scroll:ClearAllPoints(); ui.scroll:SetPoint("TOPRIGHT",-7,-143-shift); ui.scroll:SetPoint("BOTTOMRIGHT",-7,20)
        for index,row in ipairs(ui.rows) do row:ClearAllPoints(); row:SetPoint("TOPLEFT",14,-141-shift-(index-1)*18); row:SetPoint("TOPRIGHT",-30,-141-shift-(index-1)*18) end
    end
    local records = {}
    for _, record in ipairs(state.friendRecords or {}) do records[#records+1] = record end
    table.sort(records, function(a,b)
        local aSame = a.online and ZoneNameMatches(a.zone, localZone)
        local bSame = b.online and ZoneNameMatches(b.zone, localZone)
        if aSame ~= bSame then return aSame end
        if a.online ~= b.online then return a.online end
        local mode=WowDetectorDB.friendSort
        if mode~="name" and mode~="status" then mode="zone" end
        local av,bv
        if mode=="status" then av=a.online and 1 or 0; bv=b.online and 1 or 0
        else av=tostring(a[mode] or UNKNOWN):lower(); bv=tostring(b[mode] or UNKNOWN):lower() end
        if av~=bv then
            if WowDetectorDB.friendSortAscending==false then return av>bv end
            return av<bv
        end
        return tostring(a.name or "") < tostring(b.name or "")
    end)
    local visible = math.min(#ui.rows, math.max(1, math.floor((ui:GetHeight()-161-shift)/18)))
    local maxOffset = math.max(0, #records-visible)
    state.friendOffset = math.max(0, math.min(state.friendOffset or 0, maxOffset))
    ui.scroll:SetMinMaxValues(0,maxOffset); ui.scroll:SetValue(state.friendOffset); ui.scroll:SetShown(maxOffset>0)
    local dangerCount, onlineCount = 0, 0
    for _, record in ipairs(records) do
        if record.online then
            onlineCount=onlineCount+1
            if ZoneNameMatches(record.zone,localZone) then dangerCount=dangerCount+1 end
        end
    end
    local syncText=state.friendSnapshotAt and date("%H:%M:%S",state.friendSnapshotAt) or "--"
    ui.title:SetText("好友情报  |cff66ff99同步 "..syncText.."|r")
    ui.alertDanger:SetText("同区威胁: "..dangerCount)
    ui.alertOnline:SetText("在线总数: "..onlineCount)
    if WowDetectorDB.friendWindow.collapsed then
        ui.alertDanger:SetText("危: "..dangerCount)
        ui.alertOnline:SetText("在线: "..onlineCount)
        ui.broadcastAllGroup:Hide()
        ui.friendAddButton:Hide()
        ui.alertDivider:Hide()
        local compactContentWidth=math.max(140,ui.alertPanel:GetWidth()-8)
        local compactColumnWidth=compactContentWidth/2
        ui.alertDanger:Show(); ui.alertDanger:ClearAllPoints()
        ui.alertDanger:SetPoint("CENTER",ui.alertPanel,"LEFT",4+compactColumnWidth/2,0); ui.alertDanger:SetWidth(compactColumnWidth)
        ui.alertDanger:SetJustifyH("CENTER")
        ui.alertOnline:Show(); ui.alertOnline:ClearAllPoints()
        ui.alertOnline:SetPoint("CENTER",ui.alertPanel,"LEFT",4+compactColumnWidth*1.5,0); ui.alertOnline:SetWidth(compactColumnWidth)
        ui.alertOnline:SetJustifyH("CENTER")
        ui.header:Hide(); ui.scroll:Hide()
        for _,row in ipairs(ui.rows) do row:Hide() end
        return
    end
    ui.header:Show()
    local selectedCount=0
    for _,record in ipairs(records) do if WowDetectorDB.friendBroadcast[NormalizeTrackedName(record.name)] then selectedCount=selectedCount+1 end end
    ui.broadcastAllGroup:Show(); ui.friendAddButton:Show(); ui.alertDivider:Show(); ui.broadcastAll:SetEnabled(#records>0); ui.broadcastAllGroup:SetAlpha(#records>0 and 1 or 0.45)
    ui.broadcastAll:SetText(L(#records>0 and selectedCount==#records and "关闭播报" or "开启播报"))
    ui.broadcastAllGroup:ClearAllPoints(); ui.broadcastAllGroup:SetPoint("TOPLEFT",ui.alertPanel,"TOPLEFT",8,-5)
    ui.friendAddButton:ClearAllPoints(); ui.friendAddButton:SetPoint("LEFT",ui.broadcastAllGroup,"RIGHT",5,0)
    local canAdd=WowDetectorDB.role=="detector" or (WowDetectorDB.role=="listener" and available and WowDetectorDB.remoteConfigAllowed==true)
    local addBusy=state.friendAddBusyName~=nil
    ui.friendAddButton:SetText(L(addBusy and "添加中…" or "添加好友"))
    ui.friendAddButton:SetEnabled(canAdd and not addBusy); ui.friendAddButton:SetAlpha(canAdd and not addBusy and 1 or 0.45)
    local statsWidth=math.max(130,(ui.alertPanel:GetWidth()-32)/2)
    for index,block in ipairs(ui.alerts) do
        block:Show(); block:ClearAllPoints(); block:SetPoint("BOTTOMLEFT",ui.alertPanel,"BOTTOMLEFT",12+(index-1)*statsWidth,8); block:SetWidth(statsWidth-8); block:SetJustifyH("LEFT")
    end
    -- 使用固定内容宽度和 8px 列间距；扩大窗口时不再把空白平均摊到各列之间。
    -- 姓名行左侧预留 20px 给同区星标，姓名标头必须使用相同起点。
    ui.broadcastHeader:ClearAllPoints(); ui.broadcastHeader:SetPoint("LEFT",ui.header,"LEFT",0,0)
    local xs = {52,196,292}
    for i,h in ipairs(ui.headers) do
        h:ClearAllPoints(); h:SetPoint("LEFT",h:GetParent(),"LEFT",xs[i],0)
        local activeSort=WowDetectorDB.friendSort
        if activeSort~="name" and activeSort~="status" then activeSort="zone" end
        local arrow=activeSort==h.key and (WowDetectorDB.friendSortAscending==false and " ↓" or " ↑") or ""
        h.text:SetText(h.label..arrow)
    end
    for index,row in ipairs(ui.rows) do
        if index <= visible then
            local record=records[state.friendOffset+index]
            if record then
                row.record=record
                local same=record.online and ZoneNameMatches(record.zone,localZone)
                row.broadcast:SetChecked(WowDetectorDB.friendBroadcast[NormalizeTrackedName(record.name)] and true or false)
                row.zone:SetText(tostring(record.zone or UNKNOWN))
                row.dangerBackground:SetShown(same); row.star:SetShown(same)
                if same and not row.starPulse:IsPlaying() then row.starPulse:Play()
                elseif not same and row.starPulse:IsPlaying() then row.starPulse:Stop() end
                row.name:SetText(record.online and ColoredPlayerName(record.name,record.class) or ("|cff888888"..tostring(record.name or "").."|r"))
                row.status:SetText(record.online and "|cff66ff99在线|r" or "|cffff6666离线|r")
                for i,key in ipairs({"name","zone","status"}) do
                    row[key]:ClearAllPoints(); row[key]:SetPoint("LEFT",row,"LEFT",xs[i],0)
                end
                row:Show()
            else row.record=nil; row.dangerBackground:Hide(); row.star:Hide(); row.starPulse:Stop(); row:Hide() end
        else row.record=nil; row.dangerBackground:Hide(); row.star:Hide(); row.starPulse:Stop(); row:Hide() end
    end
end

RefreshEnemyConfigUI = function()
    local panel=state.enemyConfigPanel
    if not panel then return end
    state.configSide="enemy"
    if state.configKind~="name" then state.configKind="guild" end
    local canEdit=CanEditConfig()
    panel.guildTab:SetEnabled(true); panel.nameTab:SetEnabled(true)
    panel.guildTab:GetFontString():SetTextColor(state.configKind=="guild" and 1 or 0.82,state.configKind=="guild" and 0.82 or 0.82,state.configKind=="guild" and 0.05 or 0.82)
    panel.nameTab:GetFontString():SetTextColor(state.configKind=="name" and 1 or 0.82,state.configKind=="name" and 0.3 or 0.82,state.configKind=="name" and 0.2 or 0.82)
    panel.guildMark:SetShown(state.configKind=="guild")
    panel.nameMark:SetShown(state.configKind=="name")
    panel.input:SetEnabled(canEdit); panel.input:SetAlpha(canEdit and 1 or 0.5); panel.add:SetEnabled(canEdit)
    local sourceValues=state.configKind=="name" and WowDetectorDB.queries.names or WowDetectorDB.queries.guilds
    local values={}
    for _,value in ipairs(sourceValues) do values[#values+1]=value end
    local trackedStatus={}
    local valueStatus={}
    if state.configKind=="name" then
        local function IndexTrackedRecord(record,overwrite)
            if not record or not record.name then return end
            local full=NormalizeTrackedName(record.name)
            local short=ShortName(record.name)
            local info={class=record.class,classFile=record.classFile,online=record.online==true}
            if full~="" and (overwrite or not trackedStatus[full]) then trackedStatus[full]=info end
            if short~="" and (overwrite or not trackedStatus[short]) then trackedStatus[short]=info end
        end
        for _,record in ipairs(state.friendRecords or {}) do IndexTrackedRecord(record,false) end
        for _,record in pairs(state.records or {}) do if record.isTracked then IndexTrackedRecord(record,true) end end
        for _,value in ipairs(values) do
            valueStatus[value]=trackedStatus[NormalizeTrackedName(value)] or trackedStatus[ShortName(value)] or false
        end
        table.sort(values,function(a,b)
            local infoA,infoB=valueStatus[a],valueStatus[b]
            local onlineA,onlineB=infoA and infoA.online==true or false,infoB and infoB.online==true or false
            if onlineA~=onlineB then return onlineA end
            return tostring(a)<tostring(b)
        end)
    end
    panel.title:SetText(state.configKind=="name" and "玩家追踪" or "公会过滤")
    panel.help:SetText(state.configKind=="name" and "追踪指定敌方玩家的在线状态与最后地区" or "留空时显示全部查询结果；添加后仅显示指定公会")
    local panelHeight=panel:GetHeight() or 0
    local visibleRows=math.max(1,math.min(#panel.rows,math.floor((panelHeight-209)/25)+1))
    panel.visibleRows=visibleRows
    local maxOffset=math.max(0,#values-visibleRows); state.enemyConfigOffset=math.max(0,math.min(state.enemyConfigOffset or 0,maxOffset))
    panel.scroll:SetMinMaxValues(0,maxOffset); panel.scroll:SetValue(state.enemyConfigOffset); panel.scroll:SetShown(maxOffset>0)
    for index,row in ipairs(panel.rows) do
        local value=values[state.enemyConfigOffset+index]; row.value=value
        if value and state.configKind=="name" then
            local info=valueStatus[value]
            row.text:SetText(info and info.online and ("|cff33ff66●|r "..ColoredPlayerName(value,info.class,info.classFile)) or ("|cff999999"..tostring(value).."|r"))
        else row.text:SetText(value or "") end
        row.remove:SetEnabled(canEdit); row:SetShown(value~=nil)
        if index>visibleRows then row:Hide() end
    end
    panel.status:SetText(string.format("公会 %d   ·   追踪 %d%s",#WowDetectorDB.queries.guilds,#WowDetectorDB.queries.names,
        canEdit and "" or "   |cffffcc00只读|r"))
end

function BuildEnemyConfigPanel(ui)
    local panel=CreateFrame("Frame",nil,ui,"BackdropTemplate")
    panel:SetPoint("TOPLEFT",10,-65); panel:SetPoint("BOTTOMRIGHT",-10,12)
    panel:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background",edgeFile="Interface/Tooltips/UI-Tooltip-Border",edgeSize=10,insets={left=2,right=2,top=2,bottom=2}})
    panel:SetBackdropColor(0.055,0.035,0.035,0.94); panel:SetBackdropBorderColor(0.65,0.12,0.12,0.95)
    local heading=panel:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); heading:SetPoint("TOPLEFT",16,-14); heading:SetText("敌对玩家查询配置")
    local hint=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); hint:SetPoint("LEFT",heading,"RIGHT",14,0); hint:SetText("|cffff7777由侦测方执行并同步|r")
    panel.guildTab=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate"); panel.guildTab:SetHeight(28)
    panel.guildTab:SetPoint("TOPLEFT",16,-48); panel.guildTab:SetPoint("TOPRIGHT",panel,"TOP",-4,-48); panel.guildTab:SetText("公会过滤")
    panel.nameTab=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate"); panel.nameTab:SetHeight(28)
    panel.nameTab:SetPoint("TOPLEFT",panel,"TOP",4,-48); panel.nameTab:SetPoint("TOPRIGHT",-16,-48); panel.nameTab:SetText("玩家追踪")
    local function Mark(button,r,g,b) local mark=panel:CreateTexture(nil,"ARTWORK"); mark:SetPoint("BOTTOMLEFT",button,"BOTTOMLEFT",5,1); mark:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-5,1); mark:SetHeight(2); mark:SetColorTexture(r,g,b,1); return mark end
    panel.guildMark=Mark(panel.guildTab,1,0.72,0.08); panel.nameMark=Mark(panel.nameTab,1,0.18,0.12)
    panel.guildTab:SetScript("OnClick",function() state.configKind="guild"; state.enemyConfigOffset=0; RefreshEnemyConfigUI() end)
    panel.nameTab:SetScript("OnClick",function() state.configKind="name"; state.enemyConfigOffset=0; RefreshEnemyConfigUI() end)
    panel.title=panel:CreateFontString(nil,"OVERLAY","GameFontNormal"); panel.title:SetPoint("TOPLEFT",16,-91)
    panel.help=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); panel.help:SetPoint("TOPLEFT",120,-92); panel.help:SetTextColor(0.7,0.7,0.7)
    panel.input=CreateFrame("EditBox",nil,panel,"InputBoxTemplate"); panel.input:SetSize(330,24); panel.input:SetPoint("TOPLEFT",16,-116); panel.input:SetAutoFocus(false)
    panel.add=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate"); panel.add:SetSize(82,25); panel.add:SetPoint("LEFT",panel.input,"RIGHT",10,0); panel.add:SetText("添加")
    local function AddValue() if AddQuery(state.configKind,panel.input:GetText()) then panel.input:SetText(""); panel.input:ClearFocus(); RefreshEnemyConfigUI() end end
    panel.input:SetScript("OnEnterPressed",AddValue); panel.input:SetScript("OnEscapePressed",panel.input.ClearFocus); panel.add:SetScript("OnClick",AddValue)
    panel.rows={}
    local function ScrollConfig(delta)
        if not panel.scroll:IsShown() then return end
        state.enemyConfigOffset=(state.enemyConfigOffset or 0)+(delta<0 and 3 or -3)
        RefreshEnemyConfigUI()
    end
    for index=1,18 do
        local row=CreateFrame("Frame",nil,panel); row:SetPoint("TOPLEFT",16,-151-(index-1)*25); row:SetPoint("TOPRIGHT",-36,-151-(index-1)*25); row:SetHeight(24)
        local bg=row:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(1,1,1,index%2==0 and 0.045 or 0.018)
        row.text=row:CreateFontString(nil,"OVERLAY","GameFontHighlight"); row.text:SetPoint("LEFT",7,0); row.text:SetPoint("RIGHT",-70,0); row.text:SetJustifyH("LEFT")
        row.remove=CreateFrame("Button",nil,row,"UIPanelButtonTemplate"); row.remove:SetSize(56,21); row.remove:SetPoint("RIGHT",-2,0); row.remove:SetText("删除")
        row.remove:SetScript("OnClick",function() if row.value then RemoveQuery(state.configKind,row.value); RefreshEnemyConfigUI() end end)
        row:EnableMouseWheel(true); row:SetScript("OnMouseWheel",function(_,delta) ScrollConfig(delta) end)
        row.remove:EnableMouseWheel(true); row.remove:SetScript("OnMouseWheel",function(_,delta) ScrollConfig(delta) end)
        panel.rows[index]=row
    end
    panel.scroll=CreateFrame("Slider","WCEDEnemyConfigScrollBar",panel,"UIPanelScrollBarTemplate"); panel.scroll:SetPoint("TOPRIGHT",-8,-151); panel.scroll:SetPoint("BOTTOMRIGHT",-8,34); panel.scroll:SetValueStep(1); panel.scroll:SetObeyStepOnDrag(true)
    panel.scroll:SetScript("OnValueChanged",function(_,value) if not state.refreshing then state.enemyConfigOffset=math.floor(value+0.5); RefreshEnemyConfigUI() end end)
    panel.scroll:EnableMouseWheel(true); panel.scroll:SetScript("OnMouseWheel",function(_,delta) ScrollConfig(delta) end)
    panel:EnableMouseWheel(true); panel:SetScript("OnMouseWheel",function(_,delta) ScrollConfig(delta) end)
    panel.status=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); panel.status:SetPoint("BOTTOMLEFT",16,14)
    state.enemyConfigPanel=panel; panel:Hide()
end

local RefreshBlacklistWindow

RefreshTeamUI = function()
    local panel=state.teamPanel; if not panel then return end
    if PurgeExpiredInviteBlacklist then PurgeExpiredInviteBlacklist() end
    local saved=#(WowDetectorDB.team.savedMembers or {}); local invite=state.teamInvite
    panel.batch:SetEnabled(not invite.running); panel.regroup:SetEnabled(not invite.running and saved>0)
    panel.autoCheck:SetChecked(WowDetectorDB.autoInvite.enabled==true)
    panel.shareCheck:SetChecked(WowDetectorDB.team.shareEnabled==true)
    if panel.assistantCheck then panel.assistantCheck:SetChecked(WowDetectorDB.team.promoteAllAssistants==true) end
    if panel.lootCheck then panel.lootCheck:SetChecked(WowDetectorDB.team.freeForAllLoot==true) end
    if not panel.code:HasFocus() then panel.code:SetText(WowDetectorDB.autoInvite.code or "999") end
    if not panel.blacklistHours:HasFocus() then panel.blacklistHours:SetText(string.format("%.2g",(tonumber(WowDetectorDB.team.noJoinDuration) or 3600)/3600)) end
    if panel.whisperSend then
        local batch=state.friendlyWhisper
        panel.whisperSend:SetEnabled(not (batch and batch.running))
        panel.whisperSend:SetText(batch and batch.running and string.format("%d/%d",math.min(batch.index-1,#batch.queue),#batch.queue) or "发送")
    end
    if state.blacklistUI and state.blacklistUI:IsShown() then RefreshBlacklistWindow() end
end

RefreshBlacklistWindow = function()
    local ui=state.blacklistUI; if not ui then return end
    local entries={}
    for key,untilTime in pairs(WowDetectorDB.team.noJoinUntil or {}) do
        if untilTime>time() then entries[#entries+1]={key=key,untilTime=untilTime,reason=WowDetectorDB.team.noJoinReasons[key] or "多次邀请后未加入队伍"} end
    end
    table.sort(entries,function(a,b) return a.untilTime<b.untilTime end)
    ui.count:SetText("当前 "..#entries.." 人")
    local maxOffset=math.max(0,#entries-#ui.rows); state.blacklistOffset=math.max(0,math.min(state.blacklistOffset or 0,maxOffset))
    ui.scroll:SetMinMaxValues(0,maxOffset); ui.scroll:SetValue(state.blacklistOffset); ui.scroll:SetShown(maxOffset>0)
    for index,row in ipairs(ui.rows) do
        local entry=entries[state.blacklistOffset+index]; row.entry=entry
        if entry then row.name:SetText(entry.key); row.remaining:SetText(string.format("剩余 %d 分钟",math.max(1,math.ceil((entry.untilTime-time())/60)))); row:Show() else row:Hide() end
    end
end

local function BuildBlacklistWindow()
    local ui=CreateFrame("Frame","WCEDBlacklistWindow",UIParent,"BackdropTemplate"); ui:SetSize(410,285); ui:SetPoint("CENTER"); ui:SetFrameStrata("DIALOG"); ui:SetClampedToScreen(true); ui:SetMovable(true); ui:EnableMouse(true)
    ui:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background",edgeFile="Interface/DialogFrame/UI-DialogBox-Border",edgeSize=22,insets={left=7,right=7,top=7,bottom=7}}); ui:SetBackdropColor(0.03,0.03,0.03,0.97)
    local title=ui:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); title:SetPoint("TOPLEFT",18,-17); title:SetText("邀请黑名单")
    ui.count=ui:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); ui.count:SetPoint("TOPRIGHT",-47,-21)
    local close=CreateFrame("Button",nil,ui,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-4,-4)
    ui.rows={}
    for index=1,8 do
        local row=CreateFrame("Frame",nil,ui); row:SetPoint("TOPLEFT",18,-52-(index-1)*25); row:SetPoint("TOPRIGHT",-18,-52-(index-1)*25); row:SetHeight(24)
        local bg=row:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(1,1,1,index%2==0 and 0.05 or 0.02)
        row.name=row:CreateFontString(nil,"OVERLAY","GameFontHighlight"); row.name:SetPoint("LEFT",7,0); row.name:SetWidth(205); row.name:SetJustifyH("LEFT")
        row.remaining=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.remaining:SetPoint("RIGHT",-7,0); row.remaining:SetTextColor(1,0.72,0.2)
        row:EnableMouse(true); row:SetScript("OnEnter",function(self) if self.entry then GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText("进入原因",1,0.82,0); GameTooltip:AddLine(self.entry.reason,1,1,1,true); GameTooltip:Show() end end); row:SetScript("OnLeave",function() GameTooltip:Hide() end)
        ui.rows[index]=row
    end
    ui.scroll=CreateFrame("Slider","WCEDBlacklistScrollBar",ui,"UIPanelScrollBarTemplate"); ui.scroll:SetPoint("TOPRIGHT",-7,-52); ui.scroll:SetPoint("BOTTOMRIGHT",-7,33); ui.scroll:SetValueStep(1); ui.scroll:SetObeyStepOnDrag(true)
    ui.scroll:SetScript("OnValueChanged",function(_,value) state.blacklistOffset=math.floor(value+0.5); RefreshBlacklistWindow() end); ui.scroll:Hide()
    ui:EnableMouseWheel(true); ui:SetScript("OnMouseWheel",function(_,delta) state.blacklistOffset=(state.blacklistOffset or 0)+(delta<0 and 1 or -1); RefreshBlacklistWindow() end)
    local hint=ui:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); hint:SetPoint("BOTTOMLEFT",18,15); hint:SetText("鼠标停留在玩家行可查看进入原因")
    ui:Hide(); state.blacklistUI=ui
end

function BuildTeamPanel(ui)
    local panel=CreateFrame("Frame",nil,ui,"BackdropTemplate"); panel:SetPoint("TOPLEFT",10,-65); panel:SetPoint("TOPRIGHT",-10,-65); panel:SetHeight(195)
    panel:SetBackdrop({bgFile="Interface/Buttons/WHITE8X8",edgeFile="Interface/Tooltips/UI-Tooltip-Border",edgeSize=9,insets={left=2,right=2,top=2,bottom=2}})
    panel:SetBackdropColor(0.035,0.075,0.045,0.94); panel:SetBackdropBorderColor(0.18,0.65,0.32,0.9)
    local section=panel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); section:SetPoint("TOPLEFT",10,-10); section:SetText("团队操作")
    local actions={
        {"保存",SaveCurrentTeam,48,"记录当前队伍或团队成员，供稍后重组使用。"},
        {"解散通知",SendTeamDismissNotice,70,"向团队通知频道发送即将解散并重组的提示。"},
        {"解散",DismissCurrentTeam,48,"通知后移除其他成员；仅团长可用。"},
        {"重组",RegroupSavedTeam,48,"重新邀请最近一次保存的团队成员。"},
        {"转团",ConvertCurrentGroupToRaid,48,"将当前小队转换为团队；需要由队长点击。"},
        {"调",AdjustRaidGroups,38,"把离线、AFK 或不同区域成员调整到5-8小队。"},
    }
    local previous,firstAction
    for _,item in ipairs(actions) do local tooltipTitle,tooltipBody=item[1],item[4]; local b=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate"); b:SetSize(item[3],22); if previous then b:SetPoint("LEFT",previous,"RIGHT",5,0) else b:SetPoint("LEFT",section,"RIGHT",9,0) end; if not firstAction then firstAction=b end; b:SetText(item[1]); b:SetScript("OnClick",item[2]); b:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText(tooltipTitle); GameTooltip:AddLine(tooltipBody,1,1,1,true); GameTooltip:Show() end); b:SetScript("OnLeave",function() GameTooltip:Hide() end); previous=b; if item[1]=="重组" then panel.regroup=b end end
    panel.assistantCheck=CreateFrame("CheckButton",nil,panel,"UICheckButtonTemplate"); panel.assistantCheck:SetSize(22,22); panel.assistantCheck:SetPoint("TOPLEFT",firstAction,"BOTTOMLEFT",0,-3)
    panel.assistantCheck:SetScript("OnClick",function(self) WowDetectorDB.team.promoteAllAssistants=self:GetChecked() and true or false; if WowDetectorDB.team.promoteAllAssistants then ApplyTeamPreferences() end; RefreshTeamUI() end)
    panel.assistantCheck:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText("团队助理"); GameTooltip:AddLine("勾选后，转为团队时将所有成员提升为团队助理，后续进组成员也会自动提升。",1,1,1,true); GameTooltip:Show() end); panel.assistantCheck:SetScript("OnLeave",function() GameTooltip:Hide() end)
    local assistantLabel=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); assistantLabel:SetPoint("LEFT",panel.assistantCheck,"RIGHT",-1,0); assistantLabel:SetText("团队助理")
    panel.lootCheck=CreateFrame("CheckButton",nil,panel,"UICheckButtonTemplate"); panel.lootCheck:SetSize(22,22); panel.lootCheck:SetPoint("LEFT",assistantLabel,"RIGHT",6,0)
    panel.lootCheck:SetScript("OnClick",function(self) WowDetectorDB.team.freeForAllLoot=self:GetChecked() and true or false; if WowDetectorDB.team.freeForAllLoot then ApplyTeamPreferences() end; RefreshTeamUI() end)
    panel.lootCheck:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText("自由拾取"); GameTooltip:AddLine("勾选后，在队伍或团队建立时自动将拾取方式设为自由拾取。",1,1,1,true); GameTooltip:Show() end); panel.lootCheck:SetScript("OnLeave",function() GameTooltip:Hide() end)
    local lootLabel=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); lootLabel:SetPoint("LEFT",panel.lootCheck,"RIGHT",-1,0); lootLabel:SetText("自由拾取")
    local divider1=panel:CreateTexture(nil,"ARTWORK"); divider1:SetPoint("TOPLEFT",8,-56); divider1:SetPoint("TOPRIGHT",-8,-56); divider1:SetHeight(1); divider1:SetColorTexture(0.18,0.65,0.32,0.38)
    local inviteSection=panel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); inviteSection:SetPoint("TOPLEFT",10,-63); inviteSection:SetText("自动邀请")
    panel.autoCheck=CreateFrame("CheckButton",nil,panel,"UICheckButtonTemplate"); panel.autoCheck:SetSize(24,24); panel.autoCheck:SetPoint("LEFT",inviteSection,"RIGHT",8,0)
    panel.autoCheck:SetScript("OnClick",function(self) WowDetectorDB.autoInvite.enabled=self:GetChecked() and true or false; RefreshTeamUI() end)
    panel.autoCheck:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText("自动邀请"); GameTooltip:AddLine("开启后，收到完全匹配右侧口令的私聊时自动邀请发送者。",1,1,1,true); GameTooltip:Show() end); panel.autoCheck:SetScript("OnLeave",function() GameTooltip:Hide() end)
    local autoLabel=panel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); autoLabel:SetPoint("LEFT",panel.autoCheck,"RIGHT",0,0); autoLabel:SetText("开启")
    local label=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); label:SetPoint("LEFT",autoLabel,"RIGHT",12,0); label:SetText("口令")
    panel.code=CreateFrame("EditBox",nil,panel,"InputBoxTemplate"); panel.code:SetSize(62,20); panel.code:SetPoint("LEFT",label,"RIGHT",7,0); panel.code:SetAutoFocus(false)
    panel.code:SetJustifyH("CENTER")
    local function SaveInviteCode(self) local code=Trim(self:GetText()); WowDetectorDB.autoInvite.code=code~="" and code or "999"; self:ClearFocus(); RefreshTeamUI() end
    panel.code:SetScript("OnEnterPressed",SaveInviteCode); panel.code:SetScript("OnEditFocusLost",SaveInviteCode); panel.code:SetScript("OnEscapePressed",panel.code.ClearFocus)
    panel.shareCheck=CreateFrame("CheckButton",nil,panel,"UICheckButtonTemplate"); panel.shareCheck:SetSize(24,24); panel.shareCheck:SetPoint("LEFT",panel.code,"RIGHT",16,0)
    panel.shareCheck:SetScript("OnClick",function(self) WowDetectorDB.team.shareEnabled=self:GetChecked() and true or false; if WowDetectorDB.team.shareEnabled then ShareSavedTeam() end; RefreshTeamUI() end)
    local shareLabel=panel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); shareLabel:SetPoint("LEFT",panel.shareCheck,"RIGHT",0,0); shareLabel:SetText("共享团队信息")
    panel.shareCheck:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText("共享团队信息"); GameTooltip:AddLine("与其他WCED共享团队信息",1,1,1,true); GameTooltip:Show() end); panel.shareCheck:SetScript("OnLeave",function() GameTooltip:Hide() end)
    local divider2=panel:CreateTexture(nil,"ARTWORK"); divider2:SetPoint("TOPLEFT",8,-91); divider2:SetPoint("TOPRIGHT",-8,-91); divider2:SetHeight(1); divider2:SetColorTexture(0.18,0.65,0.32,0.38)
    local blacklistLabel=panel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); blacklistLabel:SetPoint("TOPLEFT",12,-101); blacklistLabel:SetText("黑名单")
    local showBlacklist=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate"); showBlacklist:SetSize(52,20); showBlacklist:SetPoint("LEFT",blacklistLabel,"RIGHT",8,0); showBlacklist:SetText("列表"); showBlacklist:SetScript("OnClick",function() if not state.blacklistUI then BuildBlacklistWindow() end; RefreshBlacklistWindow(); state.blacklistUI:Show() end)
    showBlacklist:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText("黑名单列表"); GameTooltip:AddLine("查看当前暂缓邀请的玩家、剩余时间和进入原因。",1,1,1,true); GameTooltip:Show() end); showBlacklist:SetScript("OnLeave",function() GameTooltip:Hide() end)
    local clearBlacklist=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate"); clearBlacklist:SetSize(52,20); clearBlacklist:SetPoint("LEFT",showBlacklist,"RIGHT",6,0); clearBlacklist:SetText("清除"); clearBlacklist:SetScript("OnClick",function() ClearTemporaryInviteBlacklist(); RefreshBlacklistWindow() end)
    clearBlacklist:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText("清除全部"); GameTooltip:AddLine("清除所有邀请黑名单和累计未加入次数。",1,1,1,true); GameTooltip:Show() end); clearBlacklist:SetScript("OnLeave",function() GameTooltip:Hide() end)
    local expiryLabel=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); expiryLabel:SetPoint("LEFT",clearBlacklist,"RIGHT",18,0); expiryLabel:SetText("过期时间")
    local expiryHover=CreateFrame("Frame",nil,panel); expiryHover:SetPoint("TOPLEFT",expiryLabel,"TOPLEFT",-2,3); expiryHover:SetPoint("BOTTOMRIGHT",expiryLabel,"BOTTOMRIGHT",2,-3); expiryHover:EnableMouse(true)
    expiryHover:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText("邀请黑名单过期时间"); GameTooltip:AddLine("以小时为单位，过期的玩家将被自动踢出邀请黑名单",1,1,1,true); GameTooltip:Show() end); expiryHover:SetScript("OnLeave",function() GameTooltip:Hide() end)
    panel.blacklistHours=CreateFrame("EditBox",nil,panel,"InputBoxTemplate"); panel.blacklistHours:SetSize(42,20); panel.blacklistHours:SetPoint("LEFT",expiryLabel,"RIGHT",7,0); panel.blacklistHours:SetAutoFocus(false); panel.blacklistHours:SetJustifyH("CENTER")
    local function SaveBlacklistHours(self) local hours=math.max(0.25,math.min(168,tonumber(self:GetText()) or 1)); WowDetectorDB.team.noJoinDuration=math.floor(hours*3600); self:ClearFocus(); RefreshTeamUI() end
    panel.blacklistHours:SetScript("OnEnterPressed",SaveBlacklistHours); panel.blacklistHours:SetScript("OnEditFocusLost",SaveBlacklistHours); panel.blacklistHours:SetScript("OnEscapePressed",panel.blacklistHours.ClearFocus)
    panel.blacklistHours:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText("邀请黑名单过期时间"); GameTooltip:AddLine("以小时为单位，过期的玩家将被自动踢出邀请黑名单",1,1,1,true); GameTooltip:Show() end); panel.blacklistHours:SetScript("OnLeave",function() GameTooltip:Hide() end)
    local hoursLabel=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); hoursLabel:SetPoint("LEFT",panel.blacklistHours,"RIGHT",5,0); hoursLabel:SetText("小时")
    panel.batch=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate"); panel.batch:SetSize(74,20); panel.batch:SetPoint("LEFT",hoursLabel,"RIGHT",14,0); panel.batch:SetText("批量邀请"); panel.batch:SetScript("OnClick",StartFriendlyBatchInvite)
    panel.batch:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText("批量邀请"); GameTooltip:AddLine("分批邀请当前友方查询结果，并显示每人的处理状态。",1,1,1,true); GameTooltip:Show() end); panel.batch:SetScript("OnLeave",function() GameTooltip:Hide() end)
    local divider3=panel:CreateTexture(nil,"ARTWORK"); divider3:SetPoint("TOPLEFT",8,-130); divider3:SetPoint("TOPRIGHT",-8,-130); divider3:SetHeight(1); divider3:SetColorTexture(0.18,0.65,0.32,0.38)
    local whisperLabel=panel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); whisperLabel:SetPoint("TOPLEFT",12,-139); whisperLabel:SetText("群发")
    local whisperHover=CreateFrame("Frame",nil,panel); whisperHover:SetPoint("TOPLEFT",whisperLabel,"TOPLEFT",-2,3); whisperHover:SetPoint("BOTTOMRIGHT",whisperLabel,"BOTTOMRIGHT",2,-3); whisperHover:EnableMouse(true)
    whisperHover:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText("群发"); GameTooltip:AddLine("密语所有查询玩家，不包含本团队成员",1,1,1,true); GameTooltip:Show() end); whisperHover:SetScript("OnLeave",function() GameTooltip:Hide() end)
    panel.whisperInput=CreateFrame("EditBox",nil,panel,"InputBoxTemplate"); panel.whisperInput:SetPoint("TOPLEFT",12,-160); panel.whisperInput:SetPoint("TOPRIGHT",-78,-160); panel.whisperInput:SetHeight(24); panel.whisperInput:SetAutoFocus(false); panel.whisperInput:SetMaxLetters(220); panel.whisperInput:SetJustifyH("LEFT")
    panel.whisperInput:SetScript("OnEscapePressed",panel.whisperInput.ClearFocus)
    panel.whisperSend=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate"); panel.whisperSend:SetSize(58,23); panel.whisperSend:SetPoint("TOPRIGHT",-12,-159); panel.whisperSend:SetText("发送")
    local function SendFriendlyWhisperText() if StartFriendlyWhisperBatch then StartFriendlyWhisperBatch(panel.whisperInput:GetText()) end end
    panel.whisperInput:SetScript("OnEnterPressed",function(self) SendFriendlyWhisperText(); self:ClearFocus() end)
    panel.whisperSend:SetScript("OnClick",SendFriendlyWhisperText)
    state.teamPanel=panel; panel:Hide(); RefreshTeamUI()
end

local function StyleCompactQueryDropdown(dropdown,name,width)
    UIDropDownMenu_SetWidth(dropdown,width-32)
    dropdown:SetSize(width,25)
    for _,suffix in ipairs({"Left","Middle","Right"}) do local texture=_G[name..suffix]; if texture then texture:Hide() end end
    local shell=CreateFrame("Frame",nil,dropdown,"BackdropTemplate")
    shell:SetPoint("TOPLEFT",15,-2); shell:SetPoint("BOTTOMRIGHT",-1,2); shell:SetFrameLevel(math.max(0,dropdown:GetFrameLevel()-1))
    shell:SetBackdrop({bgFile="Interface/Buttons/WHITE8X8",edgeFile="Interface/Tooltips/UI-Tooltip-Border",edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    shell:SetBackdropColor(0.025,0.025,0.025,0.96); shell:SetBackdropBorderColor(0.55,0.38,0.08,0.95)
    local text=_G[name.."Text"]
    if text then text:ClearAllPoints(); text:SetPoint("LEFT",dropdown,"LEFT",24,0); text:SetPoint("RIGHT",dropdown,"RIGHT",-25,0); text:SetJustifyH("CENTER"); text:SetFontObject("GameFontHighlightSmall") end
    local button=_G[name.."Button"]
    if button then button:ClearAllPoints(); button:SetPoint("RIGHT",dropdown,"RIGHT",0,0); button:SetSize(24,24) end
end

function BuildUI()
    local w = WowDetectorDB.window
    local ui = CreateFrame("Frame", "WowDetectorWindow", UIParent, "BackdropTemplate")
    -- v0.15.0 的五行统计区需要更高的最小展开高度；兼容旧版本保存的较小窗口尺寸。
    w.height = math.max(tonumber(w.height) or 440, 440)
    ui:SetSize(w.width, w.height)
    ui:SetPoint(w.point, UIParent, w.point, w.x, w.y)
    ui:SetMovable(true); ui:SetResizable(true); ui:EnableMouse(true); ui:SetClampedToScreen(true)
    ui:RegisterForDrag("LeftButton")
    ui:SetScript("OnDragStart", function() ui:StartMoving() end)
    ui:SetScript("OnDragStop", function()
        ui:StopMovingOrSizing(); local point, _, _, x, y = ui:GetPoint(); w.point, w.x, w.y = point, x, y
    end)
    if ui.SetResizeBounds then ui:SetResizeBounds(620, 440, 1100, 650) else ui:SetMinResize(620, 440); ui:SetMaxResize(1100, 650) end
    ui:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 14, insets = { left=3, right=3, top=3, bottom=3 } })
    ui:SetBackdropColor(0.03, 0.03, 0.03, 0.92)
    ui:SetBackdropBorderColor(0.85, 0.55, 0.08, 1)

    local launcher = CreateFrame("Button", "WowDetectorLauncher", UIParent, "BackdropTemplate")
    launcher:SetSize(112, 30); launcher:SetPoint(WowDetectorDB.queryButton.point, UIParent, WowDetectorDB.queryButton.point,
        WowDetectorDB.queryButton.x, WowDetectorDB.queryButton.y)
    launcher:SetBackdrop({ bgFile="Interface/Buttons/WHITE8X8", edgeFile="Interface/Tooltips/UI-Tooltip-Border",
        edgeSize=12, insets={left=3,right=3,top=3,bottom=3} })
    launcher:SetBackdropColor(0.08, 0.08, 0.08, 0.96); launcher:SetBackdropBorderColor(0.85, 0.55, 0.08, 1)
    launcher:SetText("WCED"); launcher:GetFontString():SetTextColor(1, 0.82, 0)
    launcher:GetFontString():SetFontObject("GameFontNormalLarge")
    launcher:GetFontString():ClearAllPoints(); launcher:GetFontString():SetPoint("TOPLEFT", 9, -6)
    local divider=launcher:CreateTexture(nil,"ARTWORK"); divider:SetPoint("TOPLEFT",6,-33); divider:SetPoint("TOPRIGHT",-6,-33); divider:SetHeight(1); divider:SetColorTexture(0.85,0.55,0.08,0.55)
    local menu=CreateFrame("Frame",nil,launcher); menu:SetSize(112,62); menu:SetPoint("TOP",launcher,"TOP",0,-34)
    local function LauncherTextButton(text,index,color,tooltip)
        local button=CreateFrame("Button",nil,menu,"BackdropTemplate"); button:SetSize(31,25)
        local column=(index-1)%4; local row=math.floor((index-1)/4); button:SetPoint("TOPLEFT",7+column*34,-4-row*28)
        button:SetBackdrop({bgFile="Interface/Buttons/WHITE8X8",edgeFile="Interface/Tooltips/UI-Tooltip-Border",edgeSize=7,insets={left=1,right=1,top=1,bottom=1}})
        button:SetBackdropColor(0.08,0.08,0.08,0.95); button:SetBackdropBorderColor(color[1]*0.55,color[2]*0.55,color[3]*0.55,0.95)
        button:SetText(text); button:GetFontString():SetFontObject("GameFontNormalLarge"); button:GetFontString():SetTextColor(color[1],color[2],color[3])
        button:SetScript("OnEnter",function(self) self:SetBackdropColor(0.18,0.18,0.18,1); GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText(tooltip); GameTooltip:Show() end)
        button:SetScript("OnLeave",function(self) self:SetBackdropColor(0.08,0.08,0.08,0.95); GameTooltip:Hide() end)
        return button
    end
    local launcherConfig=LauncherTextButton(L("配"),1,{1,0.78,0.08},L("通信与角色配置"))
    launcherConfig:SetScript("OnClick", function()
        if state.configUI then
            state.configUI:SetShown(not state.configUI:IsShown())
            if state.configUI:IsShown() then RebuildQueryQueue(); RefreshConfigUI() end
        end
    end)
    local launcherFriendly=LauncherTextButton(L("团"),2,{0.25,1,0.42},L("友方查询与团队管理"))
    launcherFriendly:SetScript("OnClick",function() state.mainTab="friendlyQuery"; state.scrollOffset=0; if state.setMainExpanded then state.setMainExpanded(true) end; UpdateQueryButton(); RefreshUI() end)
    local launcherDetect=LauncherTextButton(L("侦"),3,{1,0.25,0.2},L("侦测方好友情报"))
    launcherDetect:SetScript("OnUpdate",function(self,elapsed) self.pulse=(self.pulse or 0)+elapsed; local v=0.55+0.45*((math.sin(self.pulse*4)+1)*0.5); self:GetFontString():SetTextColor(1,v*0.4,v*0.35) end)
    launcherDetect:SetScript("OnClick", function()
        if not state.friendUI then return end
        state.friendUI:SetShown(not state.friendUI:IsShown())
        if state.friendUI:IsShown() then
            if WowDetectorDB.role == "detector" then PollTrackedFriends() end
            RefreshFriendUI()
        end
    end)
    local launcherSpy=LauncherTextButton(L("记"),5,{1,0.55,0.08},L("击杀列表"))
    launcherSpy:SetScript("OnClick",ToggleSpyWindow)
    local launcherWatch=LauncherTextButton(L("监"),6,{0.72,0.32,1},L("附近敌人"))
    launcherWatch:SetScript("OnClick",ToggleEnemyWatcher)
    local launcherSystem=LauncherTextButton(L("系"),7,{0.35,0.8,1},L("原生功能入口"))
    local systemDivider=launcher:CreateTexture(nil,"ARTWORK"); systemDivider:SetPoint("TOPLEFT",6,-98); systemDivider:SetPoint("TOPRIGHT",-6,-98); systemDivider:SetHeight(1); systemDivider:SetColorTexture(0.35,0.8,1,0.48)
    local systemMenu=CreateFrame("Frame",nil,launcher); systemMenu:SetSize(146,62); systemMenu:SetPoint("TOPLEFT",launcher,"TOPLEFT",0,-101)
    local function SystemTextButton(text,index,entry,tooltip)
        local button=CreateFrame("Button",nil,systemMenu,"BackdropTemplate"); button:SetSize(31,25)
        local column=(index-1)%4; local row=math.floor((index-1)/4); button:SetPoint("TOPLEFT",7+column*34,-1-row*28)
        button:SetBackdrop({bgFile="Interface/Buttons/WHITE8X8",edgeFile="Interface/Tooltips/UI-Tooltip-Border",edgeSize=7,insets={left=1,right=1,top=1,bottom=1}})
        button:SetBackdropColor(0.055,0.075,0.09,0.97); button:SetBackdropBorderColor(0.18,0.48,0.68,0.95)
        button:SetText(L(text)); button:GetFontString():SetFontObject("GameFontNormalLarge"); button:GetFontString():SetTextColor(0.55,0.88,1)
        button:SetScript("OnClick",function() OpenNativeSystemEntry(entry) end)
        button:SetScript("OnEnter",function(self) self:SetBackdropColor(0.12,0.2,0.25,1); GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText(L(tooltip)); GameTooltip:Show() end)
        button:SetScript("OnLeave",function(self) self:SetBackdropColor(0.055,0.075,0.09,0.97); GameTooltip:Hide() end)
        return button
    end
    SystemTextButton("包",1,"bags","打开背包")
    SystemTextButton("角",2,"character","角色信息")
    SystemTextButton("书",3,"spellbook","法术书")
    local talentSystemButton=SystemTextButton("天",4,"talents","天赋（右键任务）")
    talentSystemButton:RegisterForClicks("LeftButtonUp","RightButtonUp")
    talentSystemButton:SetScript("OnClick",function(_,mouseButton) OpenNativeSystemEntry(mouseButton=="RightButton" and "quests" or "talents") end)
    SystemTextButton("社",5,"social","社交")
    SystemTextButton("图",6,"map","世界地图")
    SystemTextButton("设",7,"settings","游戏菜单")
    SystemTextButton("助",8,"help","暴雪帮助")
    local menuToggle=CreateFrame("Button",nil,launcher,"UIPanelButtonTemplate"); menuToggle:SetSize(25,23); menuToggle:SetPoint("TOPRIGHT",-4,-3); menuToggle:SetNormalFontObject("GameFontNormalLarge")
    local function UpdateLauncherSize()
        local menuExpanded=WowDetectorDB.queryButton.menuExpanded~=false
        local systemExpanded=menuExpanded and WowDetectorDB.queryButton.systemExpanded==true
        menu:SetShown(menuExpanded); divider:SetShown(menuExpanded)
        systemMenu:SetShown(systemExpanded); systemDivider:SetShown(systemExpanded)
        -- 主菜单只有三列：普通展开时保持紧凑宽度；仅展开四列系统菜单时加宽。
        launcher:SetSize((systemExpanded and 146 or 112),not menuExpanded and 30 or (systemExpanded and 164 or 96))
        menu:ClearAllPoints(); menu:SetPoint("TOP",launcher,"TOP",0,-34)
        menuToggle:ClearAllPoints(); menuToggle:SetPoint("TOPRIGHT",-4,-3)
        menuToggle:SetText(menuExpanded and "−" or "+")
        menuToggle.tooltip=menuExpanded and L("折叠功能菜单") or L("展开功能菜单")
    end
    local function SetMenuExpanded(expanded)
        WowDetectorDB.queryButton.menuExpanded=expanded and true or false
        UpdateLauncherSize()
    end
    launcherSystem:SetScript("OnClick",function() WowDetectorDB.queryButton.systemExpanded=not WowDetectorDB.queryButton.systemExpanded; UpdateLauncherSize() end)
    menuToggle:SetScript("OnClick",function() SetMenuExpanded(not WowDetectorDB.queryButton.menuExpanded) end)
    menuToggle:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText(self.tooltip); GameTooltip:Show() end); menuToggle:SetScript("OnLeave",function() GameTooltip:Hide() end)
    SetMenuExpanded(WowDetectorDB.queryButton.menuExpanded~=false)
    C_Timer.After(0, ApplyNativeEntryVisibility)
    launcher:SetClampedToScreen(true); launcher:SetMovable(true); launcher:RegisterForClicks("LeftButtonUp")
    launcher:RegisterForDrag("LeftButton")
    launcher:SetScript("OnDragStart", function() launcher.isDragging=true; launcher:StartMoving() end)
    launcher:SetScript("OnDragStop", function()
        launcher:StopMovingOrSizing(); local point, _, _, x, y = launcher:GetPoint()
        WowDetectorDB.queryButton.point, WowDetectorDB.queryButton.x, WowDetectorDB.queryButton.y = point, x, y
        C_Timer.After(0,function() launcher.isDragging=false end)
    end)
    launcher:SetScript("OnClick",function()
        if launcher.isDragging or not state.helpUI then return end
        state.helpUI:SetShown(not state.helpUI:IsShown())
    end)
    state.launcherMenu=menu
    ui.count = ui:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.count:SetPoint("TOPRIGHT", -45, -10)
    local collapse = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
    collapse:SetSize(27, 23); collapse:SetPoint("TOPRIGHT", -9, -5); collapse:SetText("−")
    collapse:SetNormalFontObject("GameFontNormalLarge")
    local config = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
    config:SetSize(88, 25); config:SetPoint("TOPLEFT", ui, "TOPLEFT", 12, -6); config:SetText("配置")
    config:SetScript("OnClick", function()
        if state.configUI then
            state.configUI:SetShown(not state.configUI:IsShown())
            if state.configUI:IsShown() then RebuildQueryQueue(); RefreshConfigUI() end
        end
    end)
    local query = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
    query:SetSize(92, 25); query:SetPoint("TOPLEFT", ui, "TOPLEFT", 12, -6); query:SetText("查询")
    query:SetScript("OnClick", RunNextQuery)
    query:SetEnabled(WowDetectorDB.role == "detector"); state.queryActionButton = query
    local broadcast = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
    broadcast:SetSize(90, 22); broadcast:SetText("团队播报")
    broadcast:SetScript("OnClick", BroadcastStatistics); state.broadcastActionButton = broadcast
    local classDropdown=CreateFrame("Frame","WCEDQueryClassDropdown",ui,"UIDropDownMenuTemplate")
    classDropdown:SetPoint("LEFT",query,"RIGHT",-8,-1); UIDropDownMenu_SetText(classDropdown,"全部职业"); StyleCompactQueryDropdown(classDropdown,"WCEDQueryClassDropdown",118)
    UIDropDownMenu_Initialize(classDropdown,function()
        local faction=UnitFactionGroup("player")
        local function ClassName(token, fallback)
            return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or L(fallback)
        end
        local classes=faction=="Alliance" and {
            ClassName("WARRIOR","战士"),ClassName("PALADIN","圣骑士"),ClassName("HUNTER","猎人"),ClassName("ROGUE","潜行者"),
            ClassName("PRIEST","牧师"),ClassName("MAGE","法师"),ClassName("WARLOCK","术士"),ClassName("DRUID","德鲁伊")}
            or {ClassName("WARRIOR","战士"),ClassName("HUNTER","猎人"),ClassName("ROGUE","潜行者"),ClassName("PRIEST","牧师"),
                ClassName("SHAMAN","萨满祭司"),ClassName("MAGE","法师"),ClassName("WARLOCK","术士"),ClassName("DRUID","德鲁伊")}
        local friendly=WowDetectorDB.role=="listener" and state.mainTab=="friendlyQuery"
        local selected=friendly and state.selectedFriendlyClass or state.selectedEnemyClass
        local required=friendly and state.friendlyClassRequired or state.queryClassRequired
        local function AddClass(text,value)
            local info=UIDropDownMenu_CreateInfo(); info.text=text; info.checked=selected==value
            info.func=function()
                if friendly then state.selectedFriendlyClass=value; state.friendlyDisplayClass=value; if value==nil then state.friendlyClassRequired=false end
                else state.selectedEnemyClass=value; if value==nil then state.queryClassRequired=false end end
                state.scrollOffset=0; UIDropDownMenu_SetText(classDropdown,text); CloseDropDownMenus(); UpdateQueryButton(); RefreshUI()
            end
            UIDropDownMenu_AddButton(info)
        end
        AddClass(L("全部职业"),nil); for _,className in ipairs(classes) do AddClass(className,className) end
    end)
    state.classDropdown=classDropdown
    local zoneDropdown = CreateFrame("Frame", "WowDetectorZoneDropdown", ui, "UIDropDownMenuTemplate")
    zoneDropdown:SetPoint("LEFT", classDropdown, "RIGHT", -8, 0); StyleCompactQueryDropdown(zoneDropdown,"WowDetectorZoneDropdown",132)
    UIDropDownMenu_SetText(zoneDropdown, "请选择地区")
    UIDropDownMenu_Initialize(zoneDropdown, function(_, level, menuList)
        local function AddChoice(text, value)
            local info = UIDropDownMenu_CreateInfo(); info.text = text; info.value = value
            local friendly = WowDetectorDB.role == "listener" and state.mainTab == "friendlyQuery"
            info.checked = (friendly and state.selectedFriendlyZone or state.selectedZone) == value
            info.func = function()
                if friendly then
                    if state.selectedFriendlyZone ~= value then ResetFriendlyPagination(true) end
                    state.selectedFriendlyZone = value; state.friendlyClassRequired=false
                else if state.selectedZone ~= value then ResetPagination() end; state.selectedZone = value; state.queryClassRequired=false end
                state.scrollOffset = 0
                UIDropDownMenu_SetText(zoneDropdown, text); CloseDropDownMenus(); RefreshUI()
            end
            UIDropDownMenu_AddButton(info, level)
        end
        if level == 1 then
            for _, group in ipairs(CLASSIC_ZONE_GROUPS) do
                local info = UIDropDownMenu_CreateInfo(); info.text = group.name; info.hasArrow = true
                info.notCheckable = true; info.menuList = group.name
                UIDropDownMenu_AddButton(info, level)
            end
        elseif level == 2 then
            for _, group in ipairs(CLASSIC_ZONE_GROUPS) do
                if group.name == menuList then for _, zone in ipairs(group.zones) do AddChoice(zone, zone) end; break end
            end
        end
    end)
    state.zoneDropdown = zoneDropdown

    local drag = CreateFrame("Frame", nil, ui)
    drag:SetPoint("TOPLEFT", 470, 0); drag:SetPoint("TOPRIGHT", -120, 0); drag:SetHeight(32); drag:EnableMouse(true)
    drag:SetScript("OnMouseDown", function(_, button) if button == "LeftButton" then ui:StartMoving() end end)
    drag:SetScript("OnMouseUp", function() ui:StopMovingOrSizing(); local point, _, _, x, y = ui:GetPoint(); w.point, w.x, w.y = point, x, y end)

    local detectorPanel = CreateFrame("Frame", nil, ui, "BackdropTemplate")
    detectorPanel:SetPoint("TOPLEFT", 10, -38); detectorPanel:SetPoint("TOPRIGHT", -10, -38); detectorPanel:SetHeight(128)
    detectorPanel:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10, insets = { left=2, right=2, top=2, bottom=2 } })
    detectorPanel:SetBackdropColor(0.06, 0.06, 0.06, 0.9); detectorPanel:SetBackdropBorderColor(0.35, 0.55, 0.35, 0.9)
    local detectorTitle = detectorPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    detectorTitle:SetPoint("TOPLEFT", 12, -10); detectorTitle:SetText("侦测方运行状态")
    state.detectorCommunication = detectorPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    state.detectorCommunication:SetPoint("TOPRIGHT", -12, -11)
    state.detectorConfig = detectorPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    state.detectorConfig:SetPoint("TOPLEFT", 12, -39)
    state.detectorPolling = detectorPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    state.detectorPolling:SetPoint("TOPLEFT", 12, -67); state.detectorPolling:SetTextColor(0.4, 1, 0.6)
    state.detectorQuery = detectorPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    state.detectorQuery:SetPoint("TOPLEFT", 12, -95)
    state.detectorPanel = detectorPanel

    local queryTab = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
    queryTab:SetSize(120, 24); queryTab:SetPoint("TOPLEFT", 12, -36); queryTab:SetText("敌对玩家信息")
    queryTab:SetScript("OnClick", function() state.mainTab = "enemyQuery"; state.scrollOffset = 0; UpdateQueryButton(); RefreshUI() end)
    state.queryTabButton = queryTab
    local trackingTab = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
    trackingTab:SetSize(120, 24); trackingTab:SetPoint("LEFT", queryTab, "RIGHT", 6, 0); trackingTab:SetText("敌对玩家追踪")
    trackingTab:SetScript("OnClick", function() state.mainTab = "enemyTracking"; state.scrollOffset = 0; UpdateQueryButton(); RefreshUI() end)
    state.trackingTabButton = trackingTab
    local friendlyTab = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
    friendlyTab:SetSize(120, 24); friendlyTab:SetPoint("LEFT", trackingTab, "RIGHT", 6, 0); friendlyTab:SetText("查询配置")
    friendlyTab:SetScript("OnClick", function()
        state.mainTab = "enemyConfig"; state.configSide="enemy"; state.configKind=state.configKind=="name" and "name" or "guild"; state.scrollOffset = 0
        RefreshUI()
    end)
    state.friendlyTabButton = friendlyTab
    local function TabMark(button,r,g,b)
        local mark=button:CreateTexture(nil,"ARTWORK"); mark:SetPoint("BOTTOMLEFT",button,"BOTTOMLEFT",5,1); mark:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-5,1); mark:SetHeight(2); mark:SetColorTexture(r,g,b,1); mark:Hide(); return mark
    end
    state.mainTabMarks={enemyQuery=TabMark(queryTab,1,0.72,0.08),enemyTracking=TabMark(trackingTab,1,0.16,0.12),enemyConfig=TabMark(friendlyTab,1,0.72,0.08)}
    local detectorWarning=CreateFrame("Frame",nil,ui,"BackdropTemplate")
    detectorWarning:SetPoint("TOPLEFT",10,-64); detectorWarning:SetPoint("TOPRIGHT",-10,-64); detectorWarning:SetHeight(28)
    detectorWarning:SetBackdrop({bgFile="Interface/Buttons/WHITE8X8",edgeFile="Interface/Tooltips/UI-Tooltip-Border",edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    detectorWarning:SetBackdropColor(0.18,0.015,0.015,0.94); detectorWarning:SetBackdropBorderColor(1,0.16,0.12,0.95)
    detectorWarning.text=detectorWarning:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); detectorWarning.text:SetPoint("CENTER"); detectorWarning.text:SetTextColor(1,0.35,0.28)
    detectorWarning:Hide(); state.detectorWarning=detectorWarning
    local enemyQueryHint = ui:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    enemyQueryHint:SetPoint("TOPRIGHT", -128, -43)
    enemyQueryHint:SetText("|cff66ff99由侦测方查询并同步|r")
    enemyQueryHint:SetJustifyH("RIGHT"); enemyQueryHint:SetWordWrap(false)
    state.enemyQueryHint = enemyQueryHint
    local enemySortDropdown = CreateSortDropdown(ui, "WCEDEnemySortDropdown",
        function() return WowDetectorDB.enemySort end,
        function(mode) WowDetectorDB.enemySort = mode; state.scrollOffset = 0 end,
        function() RefreshUI() end)
    enemySortDropdown:SetPoint("TOPRIGHT", -8, -34)
    state.enemySortDropdown = enemySortDropdown

    local statsPanel = CreateFrame("Frame", nil, ui, "BackdropTemplate")
    statsPanel:SetPoint("TOPLEFT", 10, -65); statsPanel:SetPoint("TOPRIGHT", -10, -65); statsPanel:SetHeight(55)
    statsPanel:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10, insets = { left=2, right=2, top=2, bottom=2 } })
    statsPanel:SetBackdropColor(0.07, 0.07, 0.07, 0.88); statsPanel:SetBackdropBorderColor(0.45, 0.38, 0.18, 0.9)
    state.statsPanel = statsPanel
    BuildTeamPanel(ui)
    local statsTitle = statsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statsTitle:SetPoint("TOPLEFT", 10, -7); statsTitle:SetText("敌情统计")
    ui.statsTitle = statsTitle
    broadcast:ClearAllPoints(); broadcast:SetPoint("LEFT", statsTitle, "RIGHT", 10, 0)
    ui.statsTotal = statsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ui.statsTotal:SetPoint("LEFT", broadcast, "RIGHT", 12, 0); ui.statsTotal:SetTextColor(0.35, 1, 0.55)
    ui.statsTime = statsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.statsTime:SetPoint("TOPRIGHT", -24, -8); ui.statsTime:SetTextColor(0.35, 1, 0.55)
    ui.stats = statsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.stats:SetPoint("TOPLEFT", 10, -29); ui.stats:SetPoint("TOPRIGHT", -10, -29); ui.stats:SetHeight(20)
    ui.stats:SetJustifyH("LEFT"); ui.stats:SetJustifyV("TOP"); ui.stats:SetWordWrap(false)
    state.statsRows = {}
    for index = 1, 5 do
        local row = CreateFrame("Frame", nil, statsPanel)
        row:SetPoint("TOPLEFT", 10, -31 - (index - 1) * 20); row:SetPoint("TOPRIGHT", -29, -31 - (index - 1) * 20); row:SetHeight(20)
        if index % 2 == 0 then
            local bg = row:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(1, 1, 1, 0.035)
        end
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.name:SetPoint("LEFT", 6, 0); row.name:SetPoint("RIGHT", row, "RIGHT", -70, 0); row.name:SetJustifyH("LEFT")
        row.count = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.count:SetPoint("RIGHT", -8, 0); row.count:SetJustifyH("RIGHT")
        state.statsRows[index] = row
    end
    local statsScrollBar = CreateFrame("Slider", "WowDetectorStatsScrollBar", statsPanel, "UIPanelScrollBarTemplate")
    statsScrollBar:SetPoint("TOPRIGHT", -3, -30); statsScrollBar:SetPoint("BOTTOMRIGHT", -3, 8)
    statsScrollBar:SetValueStep(1); statsScrollBar:SetObeyStepOnDrag(true); statsScrollBar:SetMinMaxValues(0, 0)
    statsScrollBar:SetScript("OnValueChanged", function(_, value)
        if state.refreshing then return end
        state.statsOffset = math.floor(value + 0.5); RefreshUI()
    end)
    statsScrollBar:Hide(); state.statsScrollBar = statsScrollBar
    statsPanel:EnableMouse(true); statsPanel:EnableMouseWheel(true)
    statsPanel:SetScript("OnMouseWheel", function(_, delta)
        if not statsScrollBar:IsShown() then return end
        state.statsOffset = (state.statsOffset or 0) + (delta < 0 and 1 or -1); RefreshUI()
    end)
    local header = CreateFrame("Frame", nil, ui); header:SetPoint("TOPLEFT", 12, -213); header:SetPoint("TOPRIGHT", -32, -213); header:SetHeight(18)
    state.header = header
    local widths = { 120, 170, 170, 55, 95, 90 }
    local columnKeys = { "zone", "name", "guild", "level", "class", "race" }
    local columnRatios = { 0.17, 0.24, 0.24, 0.08, 0.13, 0.14 }
    local labels = { "地区", "玩家姓名", "公会", "等级", "职业", "种族" }
    local offset = 0
    state.headerLabels = {}
    for i = 1, #labels do
        local t = MakeText(header, widths[i], header, labels[i]); t:ClearAllPoints(); t:SetPoint("LEFT", offset, 0)
        state.headerLabels[i] = t; offset = offset + widths[i]
    end
    state.trackingSortHeaders={}
    for index,key in pairs({[1]="zone",[5]="class"}) do
        local button=CreateFrame("Button",nil,header); button:SetHeight(18); button.key=key
        button:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight","ADD")
        button:SetScript("OnClick",function(self)
            if WowDetectorDB.trackingSort==self.key then WowDetectorDB.trackingSortAscending=not (WowDetectorDB.trackingSortAscending~=false)
            else WowDetectorDB.trackingSort=self.key; WowDetectorDB.trackingSortAscending=true end
            state.scrollOffset=0; RefreshUI()
        end)
        button:Hide(); state.trackingSortHeaders[index]=button
    end

    for index = 1, 32 do
        local row = CreateFrame("Frame", nil, ui); row:SetPoint("TOPLEFT", 12, -232 - (index - 1) * 20); row:SetPoint("TOPRIGHT", -32, -232 - (index - 1) * 20); row:SetHeight(20)
        if index % 2 == 0 then local bg = row:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(1, 1, 1, 0.035) end
        local x = 0
        for i, key in ipairs(columnKeys) do
            row[key] = MakeText(row, widths[i], row); row[key]:ClearAllPoints(); row[key]:SetPoint("LEFT", x, 0); x = x + widths[i]
        end
        row.broadcast = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.broadcast:SetSize(82, 19); row.broadcast:Hide()
        row.broadcast:SetScript("OnClick", function()
            if not row.trackingName then return end
            local key = NormalizeTrackedName(row.trackingName)
            WowDetectorDB.trackingBroadcast[key] = not WowDetectorDB.trackingBroadcast[key] or nil
            RefreshUI()
        end)
        state.rows[index] = row
    end

    local function LayoutColumns(frameWidth)
        local available = math.max(570, (frameWidth or ui:GetWidth()) - 50)
        local trackingView = state.mainTab == "enemyTracking"
        local ratios = trackingView and { 0.18, 0.24, 0.20, 0.09, 0.13, 0.16 } or columnRatios
        local lastDataIndex = #columnKeys
        local x = 0
        for index, key in ipairs(columnKeys) do
            local columnWidth
            if index > lastDataIndex then columnWidth = 0
            elseif index == lastDataIndex then columnWidth = available - x
            else columnWidth = math.floor(available * ratios[index]) end
            state.headerLabels[index]:SetWidth(columnWidth)
            state.headerLabels[index]:ClearAllPoints(); state.headerLabels[index]:SetPoint("LEFT", header, "LEFT", x, 0)
            local sortButton=state.trackingSortHeaders and state.trackingSortHeaders[index]
            if sortButton then sortButton:ClearAllPoints(); sortButton:SetPoint("LEFT",header,"LEFT",x,0); sortButton:SetWidth(columnWidth) end
            for _, row in ipairs(state.rows) do
                row[key]:SetWidth(columnWidth)
                row[key]:ClearAllPoints(); row[key]:SetPoint("LEFT", row, "LEFT", x, 0)
                if index == 6 and row.broadcast then
                    row.broadcast:ClearAllPoints(); row.broadcast:SetPoint("LEFT", row, "LEFT", x + 2, 0)
                    row.broadcast:SetWidth(math.max(62, columnWidth - 4))
                end
            end
            x = x + columnWidth
        end
    end
    state.layoutColumns = LayoutColumns

    local scrollBar = CreateFrame("Slider", "WowDetectorScrollBar", ui, "UIPanelScrollBarTemplate")
    scrollBar:SetPoint("TOPRIGHT", -7, -229); scrollBar:SetPoint("BOTTOMRIGHT", -7, 25)
    scrollBar:SetValueStep(1); scrollBar:SetObeyStepOnDrag(true); scrollBar:SetMinMaxValues(0, 0); scrollBar:SetValue(0)
    scrollBar:SetScript("OnValueChanged", function(_, value)
        if state.refreshing then return end
        state.scrollOffset = math.floor(value + 0.5)
        RefreshUI()
    end)
    scrollBar:Hide(); state.scrollBar = scrollBar
    ui:EnableMouseWheel(true)
    ui:SetScript("OnMouseWheel", function(_, delta)
        if not state.scrollBar or not state.scrollBar:IsShown() then return end
        state.scrollOffset = state.scrollOffset + (delta < 0 and 3 or -3)
        RefreshUI()
    end)

    local grip = CreateFrame("Button", nil, ui); grip:SetSize(22, 22); grip:SetPoint("BOTTOMRIGHT", -2, 2); grip:EnableMouse(true)
    state.grip = grip
    local texture = grip:CreateTexture(nil, "ARTWORK"); texture:SetAllPoints(); texture:SetTexture("Interface/ChatFrame/UI-ChatIM-SizeGrabber-Up")
    grip:SetScript("OnMouseDown", function() ui:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function() ui:StopMovingOrSizing(); w.width, w.height = ui:GetWidth(), ui:GetHeight() end)
    ui:SetScript("OnSizeChanged", function(_, width, height)
        if not w.collapsed then w.width, w.height = width, height end
        LayoutColumns(width)
        local visible = math.max(0, math.min(#state.rows, math.floor((height - (state.mainTab=="friendlyQuery" and 251 or 147)) / 20)))
        for i, row in ipairs(state.rows) do if i > visible then row:Hide() end end
        RefreshUI()
    end)
    state.ui = ui
    state.queryButton = launcher
    state.launcher = launcher
    LayoutColumns(ui:GetWidth())

    local function SetExpanded(expanded)
        w.collapsed = not expanded
        ui:SetShown(expanded)
        config:Hide()
        query:SetShown(expanded and (WowDetectorDB.role == "detector" or state.mainTab == "friendlyQuery"))
        broadcast:SetShown(expanded and WowDetectorDB.role == "listener" and state.mainTab == "enemyQuery")
        zoneDropdown:SetShown(expanded and (WowDetectorDB.role == "detector" or state.mainTab == "friendlyQuery"))
        classDropdown:SetShown(expanded and (WowDetectorDB.role == "detector" or state.mainTab == "friendlyQuery"))
        local detectorView = WowDetectorDB.role == "detector"
        ui.count:SetShown(expanded); detectorPanel:SetShown(expanded and detectorView)
        local friendlyView=state.mainTab=="friendlyQuery"
        queryTab:SetShown(expanded and not detectorView and not friendlyView); trackingTab:SetShown(expanded and not detectorView and not friendlyView); friendlyTab:SetShown(expanded and not friendlyView)
        enemyQueryHint:SetShown(expanded and not detectorView and state.mainTab == "enemyQuery")
        enemySortDropdown:SetShown(expanded and not detectorView and state.mainTab == "enemyQuery")
        statsPanel:SetShown(expanded and (not detectorView or friendlyView) and state.mainTab~="enemyConfig"); header:SetShown(expanded and (not detectorView or friendlyView) and state.mainTab~="enemyConfig"); grip:SetShown(expanded)
        if not expanded then scrollBar:Hide() end
        for _, row in ipairs(state.rows) do row:SetShown(expanded) end
        if expanded then
            if ui.SetResizeBounds then ui:SetResizeBounds(620, 440, 1100, 650) else ui:SetMinResize(620, 440) end
            ui:SetSize(w.width or 760, w.height or 310)
            ui:SetBackdropColor(0.03, 0.03, 0.03, 0.92); ui:SetBackdropBorderColor(0.85, 0.55, 0.08, 1)
            RefreshUI()
        else
            ui:Hide()
        end
    end
    state.setMainExpanded=SetExpanded
    BuildFriendUI(); BuildHelpUI()
    collapse:SetScript("OnClick", function() SetExpanded(false) end)
    local initiallyCollapsed = w.collapsed
    w.collapsed = false
    SetExpanded(not initiallyCollapsed)
    launcher:SetShown(not WowDetectorDB.queryButton.hidden)
end

RefreshConfigUI = function()
    local ui = state.configUI
    if not ui or state.refreshingConfig then return end
    state.refreshingConfig = true
    ui.roleDetector:SetEnabled(WowDetectorDB.role ~= "detector")
    ui.roleListener:SetEnabled(WowDetectorDB.role ~= "listener")
    if ui.peer and not ui.peer:HasFocus() then ui.peer:SetText("") end
    local peers = PeerTags()
    local peerVisible = #ui.peerRows
    local peerMaxOffset = math.max(0, #peers - peerVisible)
    state.peerOffset = math.max(0, math.min(state.peerOffset or 0, peerMaxOffset))
    if ui.peerScrollBar then
        ui.peerScrollBar:SetMinMaxValues(0, peerMaxOffset); ui.peerScrollBar:SetValue(state.peerOffset)
        ui.peerScrollBar:SetShown(peerMaxOffset > 0)
    end
    for index, row in ipairs(ui.peerRows) do
        if index > peerVisible then row.tag = nil; row:Hide()
        else
        local tag = peers[state.peerOffset + index]
        row.tag = tag
        if tag then
            local online = FindPeer(false, tag) ~= nil
            local compatible, compatibility = PeerCompatibility(tag)
            local key = NormalizeBattleTag(tag)
            row.name:SetText(tag)
            row.status:SetText(online and "在线" or "离线")
            row.status:SetTextColor(online and 0.35 or 1, online and 1 or 0.25, online and 0.55 or 0.25)
            local requested = state.peerVersionRequestedAt[key]
            local waiting = requested and GetTime() - requested < 3
            row.version:SetText(state.peerVersions[key] and ("v" .. state.peerVersions[key] .. " / P" .. tostring(state.peerProtocols[key] or "?"))
                or (waiting and "检测中…" or "协议未响应"))
            if compatible and compatibility == "完全兼容" then row.version:SetTextColor(0.35, 1, 0.55)
            elseif compatible then row.version:SetTextColor(1, 0.82, 0)
            elseif state.peerVersions[key] then row.version:SetTextColor(1, 0.3, 0.25)
            else row.version:SetTextColor(1, 0.82, 0) end
            row.permission:SetShown(true)
            if WowDetectorDB.role == "detector" then
                row.permission:SetText(WowDetectorDB.peerPermissions[NormalizeBattleTag(tag)] and "关闭配置" or "允许配置")
            else
                row.permission:SetText(NormalizeBattleTag(tag) == NormalizeBattleTag(ActivePeerTag()) and "已启用" or "启用")
                row.permission:SetEnabled(NormalizeBattleTag(tag) == NormalizeBattleTag(ActivePeerTag()) or online)
            end
            row:Show()
        else row.version:SetText(""); row:Hide() end
        end
    end
    local friendlyConfig = state.configSide == "friendly"
    local canEdit = friendlyConfig or CanEditConfig()
    if ui.enemyConfigTab then ui.enemyConfigTab:SetEnabled(friendlyConfig) end
    if ui.friendlyConfigTab then ui.friendlyConfigTab:SetEnabled(not friendlyConfig); ui.friendlyConfigTab:SetShown(WowDetectorDB.role == "listener") end
    if ui.nameKindButton then ui.nameKindButton:SetShown(not friendlyConfig) end
    if ui.addPeer then ui.addPeer:SetEnabled(true) end
    if ui.peer then ui.peer:SetEnabled(true); ui.peer:SetAlpha(1) end
    if ui.peerHint then
        ui.peerHint:SetShown(WowDetectorDB.role == "listener")
        ui.peerHint:SetText("|cffffd100按通信协议判断兼容性|r  |cff66ff99绿色完全兼容|r  |cffffcc00黄色兼容模式|r")
    end
    if ui.queryInput then ui.queryInput:SetEnabled(canEdit); ui.queryInput:SetAlpha(canEdit and 1 or 0.55) end
    if ui.addQuery then ui.addQuery:SetEnabled(canEdit) end
    if ui.lastCommunication then
        local last = tonumber(WowDetectorDB.lastCommunicationAt) or 0
        ui.lastCommunication:SetText(last > 0 and ("最后一次通信时间：" .. date("%Y-%m-%d %H:%M:%S", last)) or "最后一次通信时间：尚未通信")
    end
    if ui.nativeFriendColorCheck then ui.nativeFriendColorCheck:SetChecked(WowDetectorDB.colorNativeFriendNames == true) end
    if ui.hideNativeBagsCheck then ui.hideNativeBagsCheck:SetChecked(WowDetectorDB.hideNativeBags == true) end
    if ui.hideNativeMicroCheck then ui.hideNativeMicroCheck:SetChecked(WowDetectorDB.hideNativeMicroMenu == true) end
    if ui.enemyConfigTab then ui.enemyConfigTab:Hide() end
    if ui.friendlyConfigTab then ui.friendlyConfigTab:Hide() end
    if ui.nameKindButton then ui.nameKindButton:Hide() end
    state.refreshingConfig = false
end

function BuildConfigUI()
    local ui = CreateFrame("Frame", "WowDetectorConfigWindow", UIParent, "BackdropTemplate")
    ui:SetSize(510, 440); ui:SetPoint("CENTER"); ui:SetFrameStrata("DIALOG")
    ui:EnableMouse(true); ui:SetMovable(true); ui:SetClampedToScreen(true)
    ui:RegisterForDrag("LeftButton")
    ui:SetScript("OnDragStart", function() ui:StartMoving() end)
    ui:SetScript("OnDragStop", function() ui:StopMovingOrSizing() end)
    ui:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/DialogFrame/UI-DialogBox-Border", edgeSize = 24,
        insets = { left=7, right=7, top=7, bottom=7 } }); ui:SetBackdropColor(0.03, 0.03, 0.03, 0.96)
    ui:Hide()

    local title = ui:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -13); title:SetText("WCED Settings  v" .. VERSION)
    local author = CreateFrame("Button", nil, ui)
    author:SetSize(250, 18); author:SetPoint("TOP", title, "BOTTOM", 0, -3)
    author:SetText("Author: 璀璨小沐可 (哈霍兰)")
    author:SetNormalFontObject("GameFontHighlightSmall")
    author:SetHighlightFontObject("GameFontNormalSmall")
    author:GetFontString():SetTextColor(0.25, 1, 0.45)
    author:SetScript("OnClick", function()
        OpenAuthorWhisper()
    end)
    author:SetScript("OnEnter", function(self)
        self:GetFontString():SetTextColor(0.65, 1, 0.72)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("点击私聊作者", 0.35, 1, 0.5)
        GameTooltip:Show()
    end)
    author:SetScript("OnLeave", function(self)
        self:GetFontString():SetTextColor(0.25, 1, 0.45)
        GameTooltip:Hide()
    end)
    local titleDivider = ui:CreateTexture(nil, "ARTWORK")
    -- 作者链接上下各留一行呼吸空间，使标题信息与配置区清晰分隔。
    titleDivider:SetPoint("TOPLEFT", 22, -57); titleDivider:SetPoint("TOPRIGHT", -22, -57); titleDivider:SetHeight(1)
    titleDivider:SetColorTexture(0.85, 0.55, 0.08, 0.48)
    local close = CreateFrame("Button", nil, ui, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", -4, -4)
    local drag = CreateFrame("Frame", nil, ui); drag:SetPoint("TOPLEFT", 10, -8); drag:SetPoint("TOPRIGHT", -35, -8); drag:SetHeight(24); drag:EnableMouse(true)
    drag:SetScript("OnMouseDown", function(_, b) if b == "LeftButton" then ui:StartMoving() end end)
    drag:SetScript("OnMouseUp", function() ui:StopMovingOrSizing() end)

    local function Label(text, x, y)
        local label = ui:CreateFontString(nil, "OVERLAY", "GameFontNormal"); label:SetPoint("TOPLEFT", x, y); label:SetText(text); return label
    end
    local function Edit(width, x, y)
        local edit = CreateFrame("EditBox", nil, ui, "InputBoxTemplate"); edit:SetSize(width, 24); edit:SetPoint("TOPLEFT", x, y)
        edit:SetAutoFocus(false); edit:SetScript("OnEscapePressed", edit.ClearFocus); edit:SetScript("OnEnterPressed", edit.ClearFocus); return edit
    end

    Label("运行角色", 22, -68)
    ui.roleDetector = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate"); ui.roleDetector:SetSize(100, 25); ui.roleDetector:SetPoint("TOPLEFT", 105, -62); ui.roleDetector:SetText("侦测")
    ui.roleListener = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate"); ui.roleListener:SetSize(100, 25); ui.roleListener:SetPoint("TOPLEFT", 211, -62); ui.roleListener:SetText("监听")
    local function SetRole(role)
        WowDetectorDB.role = role
        state.configSide = "friendly"; state.mainTab = "friendlyQuery"
        local trimmed = EnforceListenerPeerLimit()
        if state.launcher and not WowDetectorDB.queryButton.hidden then state.launcher:Show() end
        local showQueryControls = not WowDetectorDB.window.collapsed
        if state.queryActionButton then state.queryActionButton:SetShown(showQueryControls); state.queryActionButton:SetEnabled(true) end
        if state.zoneDropdown then state.zoneDropdown:SetShown(showQueryControls) end
        if state.broadcastActionButton then state.broadcastActionButton:Hide() end
        RefreshUI()
        RefreshConfigUI()
        if trimmed and WowDetectorDB.peer ~= "" then RequestPeerSnapshot(WowDetectorDB.peer) end
    end
    ui.roleDetector:SetScript("OnClick", function() SetRole("detector") end)
    ui.roleListener:SetScript("OnClick", function() SetRole("listener") end)

    local function AddPeerFromInput()
        local tag = Trim(ui.peer:GetText())
        if tag == "" then Print("请输入战网ID，例如：昵称#1234") return end
        local key = NormalizeBattleTag(tag)
        for _, existing in ipairs(PeerTags()) do if NormalizeBattleTag(existing) == key then Print("该战网ID已经存在"); return end end
        local wasEmpty = #WowDetectorDB.peers == 0
        table.insert(WowDetectorDB.peers, tag)
        WowDetectorDB.peer = WowDetectorDB.peers[1] or ""
        WowDetectorDB.peerPermissions[key] = nil
        if WowDetectorDB.role == "listener" then
            WowDetectorDB.remoteConfigAllowed = false
            if wasEmpty then WowDetectorDB.activeConfigPeer = ""; WowDetectorDB.peer = tag end
        end
        ui.peer:SetText(""); ui.peer:ClearFocus(); FindPeer(true, tag); SendPeerPolicy(tag); RequestPeerVersion(tag)
        RefreshConfigUI()
        Print("已添加对端战网ID：" .. tag .. "（默认不允许监听端修改配置）")
    end
    Label("对端战网ID", 22, -94); ui.peer = Edit(275, 125, -88)
    ui.peer:SetScript("OnEnterPressed", AddPeerFromInput)
    local addPeer = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate"); addPeer:SetSize(75, 25); addPeer:SetPoint("TOPLEFT", 405, -87); addPeer:SetText("添加")
    ui.addPeer = addPeer
    addPeer:SetScript("OnClick", AddPeerFromInput)
    local peerPanel = CreateFrame("Frame", nil, ui, "BackdropTemplate")
    peerPanel:SetPoint("TOPLEFT", 20, -128); peerPanel:SetPoint("TOPRIGHT", -20, -128); peerPanel:SetHeight(166)
    peerPanel:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background", edgeFile="Interface/Tooltips/UI-Tooltip-Border", edgeSize=10, insets={left=2,right=2,top=2,bottom=2}})
    peerPanel:SetBackdropColor(0.06,0.06,0.06,0.9); peerPanel:SetBackdropBorderColor(0.45,0.38,0.18,0.9)
    ui.peerPanel = peerPanel
    local hint = peerPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("BOTTOMLEFT", 13, 7); hint:SetPoint("BOTTOMRIGHT", -13, 7)
    hint:SetJustifyH("LEFT"); hint:SetWordWrap(false)
    hint:SetText("|cffffd100按通信协议判断兼容性|r  |cff66ff99绿色完全兼容|r  |cffffcc00黄色兼容模式|r")
    ui.peerHint = hint
    ui.peerRows = {}
    for index = 1, 5 do
        local row = CreateFrame("Frame", nil, peerPanel); row:SetPoint("TOPLEFT", 7, -5 - (index - 1) * 26); row:SetPoint("TOPRIGHT", -23, -5 - (index - 1) * 26); row:SetHeight(25)
        if index % 2 == 0 then local bg = row:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(1,1,1,0.04) end
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); row.name:SetPoint("LEFT", 6, 0); row.name:SetWidth(150); row.name:SetJustifyH("LEFT")
        row.version = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); row.version:SetPoint("LEFT", 158, 0); row.version:SetWidth(88); row.version:SetJustifyH("LEFT"); row.version:SetWordWrap(false)
        row.status = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); row.status:SetPoint("LEFT", 246, 0); row.status:SetWidth(48); row.status:SetJustifyH("LEFT"); row.status:SetWordWrap(false)
        row.permission = CreateFrame("Button", nil, row, "UIPanelButtonTemplate"); row.permission:SetSize(72, 21); row.permission:SetPoint("LEFT", 296, 0)
        row.permission:SetScript("OnClick", function()
            if not row.tag then return end
            local key = NormalizeBattleTag(row.tag)
            if WowDetectorDB.role == "detector" then
                WowDetectorDB.peerPermissions[key] = not WowDetectorDB.peerPermissions[key] or nil
                SendPeerPolicy(row.tag)
            elseif NormalizeBattleTag(ActivePeerTag()) ~= key then
                local compatible, reason = PeerCompatibility(row.tag)
                if not compatible then
                    RequestPeerVersion(row.tag)
                    Print(reason == "协议不同" and ("无法启用：对端协议 P" .. tostring(state.peerProtocols[key]) .. "，本端协议 P" .. PROTOCOL_VERSION)
                        or ("无法启用：" .. reason .. "，已重新检测对端协议"))
                    RefreshConfigUI()
                    return
                end
                ClearRemoteSourceData(nil)
                WowDetectorDB.activeConfigPeer = key; WowDetectorDB.peer = row.tag
                RestoreListenerFriendCache(row.tag)
                RequestPeerSnapshot(row.tag)
            end
            RefreshConfigUI()
        end)
        local remove = CreateFrame("Button", nil, row, "UIPanelButtonTemplate"); remove:SetSize(50, 21); remove:SetPoint("RIGHT", -2, 0); remove:SetText("删除")
        remove:SetScript("OnClick", function()
            if not row.tag then return end
            local key = NormalizeBattleTag(row.tag)
            for i = #WowDetectorDB.peers, 1, -1 do if NormalizeBattleTag(WowDetectorDB.peers[i]) == key then table.remove(WowDetectorDB.peers, i) end end
            WowDetectorDB.peerPermissions[key] = nil; state.peerGameAccountIDs[key] = nil
            if WowDetectorDB.listenerFriendCaches then WowDetectorDB.listenerFriendCaches[key]=nil end
            state.peerVersions[key] = nil; state.peerProtocols[key] = nil; state.peerRoles[key] = nil; state.peerVersionRequestedAt[key] = nil
            WowDetectorDB.peer = WowDetectorDB.peers[1] or ""
            ClearRemoteSourceData(key)
            RefreshConfigUI()
        end)
        ui.peerRows[index] = row
    end
    local peerScroll = CreateFrame("Slider", "WowDetectorPeerScrollBar", peerPanel, "UIPanelScrollBarTemplate")
    peerScroll:SetPoint("TOPRIGHT", -3, -5); peerScroll:SetPoint("BOTTOMRIGHT", -3, 5)
    peerScroll:SetValueStep(1); peerScroll:SetObeyStepOnDrag(true); peerScroll:SetMinMaxValues(0,0)
    peerScroll:SetScript("OnValueChanged", function(_, value) if not state.refreshingConfig then state.peerOffset = math.floor(value + 0.5); RefreshConfigUI() end end)
    peerScroll:Hide(); ui.peerScrollBar = peerScroll
    peerPanel:EnableMouse(true); peerPanel:EnableMouseWheel(true)
    peerPanel:SetScript("OnMouseWheel", function(_, delta)
        if not peerScroll:IsShown() then return end
        state.peerOffset = (state.peerOffset or 0) + (delta < 0 and 1 or -1); RefreshConfigUI()
    end)

    ui.lastCommunication = ui:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.lastCommunication:SetPoint("TOPLEFT", 125, -300); ui.lastCommunication:SetTextColor(0.7, 0.7, 0.7)

    ui.nativeFriendColorCheck = CreateFrame("CheckButton", nil, ui, "UICheckButtonTemplate")
    ui.nativeFriendColorCheck:SetSize(24, 24); ui.nativeFriendColorCheck:SetPoint("TOPLEFT", 20, -322)
    local nativeFriendColorLabel = ui:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nativeFriendColorLabel:SetPoint("LEFT", ui.nativeFriendColorCheck, "RIGHT", 2, 0); nativeFriendColorLabel:SetText(L("原生名单姓名使用职业颜色"))
    ui.nativeFriendColorCheck:SetScript("OnClick", function(self)
        WowDetectorDB.colorNativeFriendNames = self:GetChecked() and true or false
        if WowDetectorDB.colorNativeFriendNames then InstallNativeFriendColorHooks() end
        RefreshNativeFriendNameColors(); RefreshConfigUI()
    end)
    ui.nativeFriendColorCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(L("原生名单职业染色"))
        GameTooltip:AddLine(L("仅改变原生好友、公会和查询名单的字体颜色，不修改姓名文本。"), 1, 1, 1, true); GameTooltip:Show()
    end)
    ui.nativeFriendColorCheck:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local nativeDivider=ui:CreateTexture(nil,"ARTWORK")
    nativeDivider:SetPoint("TOPLEFT",22,-352); nativeDivider:SetPoint("TOPRIGHT",-22,-352); nativeDivider:SetHeight(1); nativeDivider:SetColorTexture(0.85,0.55,0.08,0.36)
    local nativeTitle=ui:CreateFontString(nil,"OVERLAY","GameFontNormal"); nativeTitle:SetPoint("TOPLEFT",22,-365); nativeTitle:SetText("原生入口接管")
    ui.hideNativeBagsCheck=CreateFrame("CheckButton",nil,ui,"UICheckButtonTemplate"); ui.hideNativeBagsCheck:SetSize(24,24); ui.hideNativeBagsCheck:SetPoint("TOPLEFT",20,-386)
    local hideBagsLabel=ui:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); hideBagsLabel:SetPoint("LEFT",ui.hideNativeBagsCheck,"RIGHT",2,0); hideBagsLabel:SetText("隐藏原生背包栏")
    ui.hideNativeMicroCheck=CreateFrame("CheckButton",nil,ui,"UICheckButtonTemplate"); ui.hideNativeMicroCheck:SetSize(24,24); ui.hideNativeMicroCheck:SetPoint("TOPLEFT",245,-386)
    local hideMicroLabel=ui:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); hideMicroLabel:SetPoint("LEFT",ui.hideNativeMicroCheck,"RIGHT",2,0); hideMicroLabel:SetText("隐藏原生微型菜单")
    local function NativeVisibilityChanged()
        WowDetectorDB.hideNativeBags=ui.hideNativeBagsCheck:GetChecked() and true or false
        WowDetectorDB.hideNativeMicroMenu=ui.hideNativeMicroCheck:GetChecked() and true or false
        ApplyNativeEntryVisibility(); RefreshConfigUI()
    end
    ui.hideNativeBagsCheck:SetScript("OnClick",NativeVisibilityChanged); ui.hideNativeMicroCheck:SetScript("OnClick",NativeVisibilityChanged)
    ui.hideNativeBagsCheck:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText("隐藏原生背包栏"); GameTooltip:AddLine("使用 WCED 的“系 > 包”打开背包；取消勾选可恢复暴雪原生背包按钮。",1,1,1,true); GameTooltip:Show() end)
    ui.hideNativeBagsCheck:SetScript("OnLeave",function() GameTooltip:Hide() end)
    ui.hideNativeMicroCheck:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText("隐藏原生微型菜单"); GameTooltip:AddLine("角色、法术书、天赋、任务等入口由 WCED“系”菜单接管；取消勾选可恢复原生菜单。",1,1,1,true); GameTooltip:Show() end)
    ui.hideNativeMicroCheck:SetScript("OnLeave",function() GameTooltip:Hide() end)

    state.configUI = ui
    RefreshConfigUI()
end
