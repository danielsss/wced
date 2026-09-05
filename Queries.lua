function RestoreFriendsWindowState()
    if not state.closeFriendsAfterWho then return end
    if FriendsFrame and FriendsFrame:IsShown() then
        if HideUIPanel then HideUIPanel(FriendsFrame) else FriendsFrame:Hide() end
    end
end

function RunNextQuery()
    local friendly = state.mainTab == "friendlyQuery"
    if WowDetectorDB.role ~= "detector" and not friendly then Print("当前页面不能发起查询") return end
    if state.pendingQuery then Print("上一项地区查询仍在等待服务器返回") return end
    local remaining = 5 - (GetTime() - (state.lastQueryAt or 0))
    if remaining > 0 then Print(string.format("查询冷却中，请等待%d秒", math.ceil(remaining))) return end
    local query
    local configuredLevel = math.max(1, math.min(60, tonumber(WowDetectorDB.queryLevel) or 60))
    if friendly then
        local zone = state.selectedFriendlyZone
        if not zone then Print("请先从地区下拉菜单选择查询地图") return end
        local className=state.selectedFriendlyClass
        if state.friendlyClassRequired and not className then Print("上次查询达到50人上限，请先从职业菜单选择一个职业") return end
        state.friendlyDisplayClass=className
        if className then
            for key,record in pairs(state.friendlyRecords) do
                if ResolveClassFile(record.class,record.classFile)==ResolveClassFile(className) then state.friendlyRecords[key]=nil end
            end
        else wipe(state.friendlyRecords) end
        local filters={'z-"'..QuoteWho(zone)..'"','60-60'}
        if className then filters[#filters+1]='c-"'..QuoteWho(className)..'"' end
        query={kind=className and "友方职业" or "友方地区",value=zone,zone=zone,level=60,
            filter=table.concat(filters," "),friendly=true,className=className}
    else
        if state.queryClassRequired and not state.selectedEnemyClass then Print("上次查询达到50人上限，请先从职业菜单选择一个职业") return end
        ResetPagination()
        RebuildQueryQueue()
        if #state.queryQueue == 0 then Print("请先配置查询地区") return end
        for index, item in ipairs(state.queryQueue) do
            if item.zone == state.selectedZone then
                local className=state.selectedEnemyClass
                query={kind=className and "职业" or item.kind,value=item.value,zone=item.zone,level=item.level,
                    filter=item.filter..(className and (' c-"'..QuoteWho(className)..'"') or ""),className=className}
                state.queryIndex=index; break
            end
        end
    end
    if not query then Print("请先在地区选项中选择要查询的地区") return end
    query.generation = state.queryGeneration
    state.pendingQuery = query
    state.lastQueryAt = GetTime()
    if not query.friendly then SendRaw(table.concat({ "QSTART", Escape(query.zone or query.value), tostring(time()) }, "|")) end
    if state.queryActionButton then state.queryActionButton:SetEnabled(false); UpdateQueryButton() end
    state.closeFriendsAfterWho = not (FriendsFrame and FriendsFrame:IsShown())
    -- 后台接收 WHO_LIST_UPDATE，不把结果导向暴雪好友/查询窗口。
    C_FriendList.SetWhoToUi(false)
    C_FriendList.SendWho(query.filter)
    C_Timer.After(0, RestoreFriendsWindowState)
    C_Timer.After(0.1, RestoreFriendsWindowState)
    C_Timer.After(0.5, RestoreFriendsWindowState)
    Print(string.format("正在查询：%s，等级%d%s",query.zone,query.level,query.className and ("，职业："..query.className) or "，全部职业"))
    local pending = query
    C_Timer.After(8, function()
        if state.pendingQuery == pending then
            pending.completedFromCurrentResults=true
            Print("未收到新的查询事件，已按当前可读取名单结束本次查询")
            ProcessWhoResults()
        end
    end)
end

function ProcessWhoResults()
    if not state.pendingQuery then return end
    local friendly = state.pendingQuery.friendly == true
    if not friendly and WowDetectorDB.role ~= "detector" then return end
    local count = C_FriendList.GetNumWhoResults() or 0
    local matchedCount = 0
    for index = 1, count do
        local info = C_FriendList.GetWhoInfo(index)
        local matchesZone = not state.pendingQuery.zone or (info and ZoneNameMatches(info.area, state.pendingQuery.zone))
        local matchesLevel = info and (not state.pendingQuery.level or tonumber(info.level) == tonumber(state.pendingQuery.level))
        local matchesClass = info and (not state.pendingQuery.className
            or ResolveClassFile(info.classStr,info.filename)==ResolveClassFile(state.pendingQuery.className))
        local guildFilters = friendly and {} or WowDetectorDB.queries.guilds
        local matchesGuild = info and (#guildFilters == 0)
        if info and #guildFilters > 0 then
            local normalized = Trim(info.fullGuildName):lower()
            for _, guild in ipairs(guildFilters) do
                local wanted = Trim(guild):lower()
                if normalized == wanted or normalized:match("^" .. wanted:gsub("([^%w])", "%%%1") .. "%-") then matchesGuild = true; break end
            end
        end
        local isSelf=info and info.fullName and TrackedNameMatches(info.fullName,UnitName("player") or "")
        if info and info.fullName and not isSelf and matchesZone and matchesLevel and matchesClass and matchesGuild then
            matchedCount = matchedCount + 1
            local record = { key = info.fullName, zone = info.area or UNKNOWN, name = info.fullName,
                guild = info.fullGuildName ~= "" and info.fullGuildName or UNKNOWN,
                level = info.level and tostring(info.level) or UNKNOWN, class = info.classStr or UNKNOWN,
                classFile = info.filename, race = info.raceStr or UNKNOWN, time = time(), received = GetTime(), friendly=friendly }
            if friendly then state.friendlyRecords[record.name] = record else Detect(record) end
        end
    end
    local completedQuery = state.pendingQuery
    local effectiveCount=completedQuery.completedFromCurrentResults and matchedCount or count
    Print(string.format("%s查询完成：%s，服务器返回%d人，精确匹配%d人", completedQuery.kind, completedQuery.value, count, matchedCount))
    if friendly then
        state.friendlyStatistics = { zone=completedQuery.zone, time=time() }
        if completedQuery.className and effectiveCount >= 50 then
            Print("注意：" .. tostring(completedQuery.className or "该职业") .. "仍返回50人，此职业结果可能继续受到服务器上限截断")
        elseif not completedQuery.className and effectiveCount>=50 then
            state.friendlyClassRequired=true
            Print("查询达到50人上限，请从职业菜单选择职业后再次查询")
        end
    else
        SendRaw(table.concat({ "QDONE", Escape(completedQuery.zone or completedQuery.value), tostring(time()) }, "|"))
    end
    state.pendingQuery = nil
    RestoreFriendsWindowState(); state.closeFriendsAfterWho = false
    if not friendly and not completedQuery.className and effectiveCount>=50 then
        state.queryClassRequired=true
        Print("查询达到50人上限，请从职业菜单选择职业后再次查询")
    end
    UpdateQueryButton()
    RefreshUI()
    local delay = math.max(0, 5 - (GetTime() - state.lastQueryAt))
    C_Timer.After(delay, function()
        if state.queryActionButton and not state.pendingQuery then
            state.queryActionButton:SetEnabled(true); UpdateQueryButton()
        end
    end)
end

function AddQuery(kind, value)
    if kind == "zone" then Print("地区已经内置，请在主窗口查询时选择") return false end
    local friendly = state.configSide == "friendly"
    if not friendly and not CanEditConfig() then Print("侦测方未允许本监听端增加配置") return false end
    local map = { zone = "zones", guild = "guilds", name = "names" }
    local labels = { zone = "地区", guild = "公会", name = "玩家" }
    local bucket = map[kind]
    value = Trim(value)
    if not bucket or value == "" then return false end
    local querySet = friendly and WowDetectorDB.friendlyQueries or WowDetectorDB.queries
    if friendly and kind == "name" then return false end
    for _, existing in ipairs(querySet[bucket]) do
        if existing:lower() == value:lower() then Print("该条件已经存在") return true end
    end
    table.insert(querySet[bucket], value)
    if friendly and kind == "zone" and not state.selectedFriendlyZone then state.selectedFriendlyZone = value end
    if kind == "zone" then ResetPagination() end
    RebuildQueryQueue(); if not friendly then TouchQueryConfig() end; Print("已添加" .. labels[kind] .. "：" .. value)
    if kind == "name" and WowDetectorDB.role == "detector" and ReconcileTrackedFriends then ReconcileTrackedFriends() end
    return true
end

function RemoveQuery(kind, value)
    if kind == "zone" then Print("内置地区不能删除") return false end
    local friendly = state.configSide == "friendly"
    if not friendly and not CanEditConfig() then Print("侦测方未允许本监听端删除配置") return false end
    local map = { zone = "zones", guild = "guilds", name = "names" }
    local bucket = map[kind]
    value = Trim(value)
    if not bucket or value == "" then return false end
    local querySet = friendly and WowDetectorDB.friendlyQueries or WowDetectorDB.queries
    for index, existing in ipairs(querySet[bucket]) do
        if existing:lower() == value:lower() then
            table.remove(querySet[bucket], index)
            if kind == "name" then
                WowDetectorDB.trackingBroadcast[NormalizeTrackedName(existing)] = nil
                RemoveUnconfiguredTrackingRecords()
            end
            if kind == "zone" then ResetPagination() end
            if friendly and kind == "zone" and state.selectedFriendlyZone == existing then
                state.selectedFriendlyZone = querySet.zones[1]; ResetFriendlyPagination(true)
            end
            RebuildQueryQueue(); if not friendly then TouchQueryConfig() end; Print("已删除：" .. existing); return true
        end
    end
    Print("没有找到该条件"); return true
end

function ListQueries()
    Print("地区：已内置经典旧世全部地图，请在查询下拉菜单选择")
    local labels = { guilds = "公会", names = "玩家" }
    for _, bucket in ipairs({ "guilds", "names" }) do
        Print(labels[bucket] .. "：" .. (#WowDetectorDB.queries[bucket] > 0 and table.concat(WowDetectorDB.queries[bucket], "，") or "未设置"))
    end
end

function BuildGuildStatistics()
    local configuredGuilds = WowDetectorDB.queries.guilds
    local counts, total, guilds = {}, 0, {}
    for _, guild in ipairs(configuredGuilds) do
        counts[guild] = 0
        guilds[#guilds + 1] = guild
    end
    for _, record in pairs(state.records) do
        local configuredGuild = not record.isTracked and ConfiguredGuildFor(record.guild)
        if not record.isTracked and (#configuredGuilds == 0 or configuredGuild) then
            total = total + 1
            if #configuredGuilds == 0 then
                local guild = Trim(record.guild)
                if guild == "" or guild == UNKNOWN then guild = "无公会 / 未知" end
                if counts[guild] == nil then guilds[#guilds + 1] = guild; counts[guild] = 0 end
                counts[guild] = counts[guild] + 1
            elseif configuredGuild then
                counts[configuredGuild] = counts[configuredGuild] + 1
            end
        end
    end
    if #configuredGuilds == 0 then
        table.sort(guilds, function(a, b)
            local countA, countB = counts[a] or 0, counts[b] or 0
            if countA ~= countB then return countA > countB end
            return a < b
        end)
    end
    return counts, total, guilds
end

function SaveStatisticsSnapshot(queryZone, queryTime)
    local counts, total, guilds = BuildGuildStatistics()
    state.statistics = { counts = counts, total = total, guilds = guilds, zone = queryZone, time = queryTime or time() }
end

function BroadcastStatistics()
    if WowDetectorDB.role ~= "listener" then Print("只有监听方可以播报统计") return end
    local channel
    if IsInRaid() then channel = "RAID" elseif IsInGroup() then channel = "PARTY" else Print("当前不在团队或小队中") return end
    local _, total
    if state.statistics then total = state.statistics.total
    else _, total = BuildGuildStatistics() end
    local zone = state.statistics and state.statistics.zone or state.selectedZone or UNKNOWN
    SendChatMessage("[敌情查询·" .. zone .. "] 总计：" .. tostring(total or 0), channel)
end

function BroadcastTrackingChange(previous, current)
    if not previous or not current or not WowDetectorDB.trackingBroadcast[NormalizeTrackedName(current.name)] then return end
    local message
    if previous.online ~= current.online then
        if current.online then message = current.name .. " 已上线，地区：" .. (current.zone or UNKNOWN)
        else message = current.name .. " 已下线，最后地区：" .. (current.zone or previous.zone or UNKNOWN) end
    elseif current.online and previous.zone ~= current.zone then
        message = current.name .. " 地区变化：" .. (previous.zone or UNKNOWN) .. " → " .. (current.zone or UNKNOWN)
    end
    if not message then return end
    local channel = IsInRaid() and "RAID" or (IsInGroup() and "PARTY" or nil)
    if channel then SendChatMessage("[敌方玩家追踪] " .. message, channel) end
end
