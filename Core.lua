PREFIX = "WowDetector"
UNKNOWN = L("未知")
VERSION = "0.28.14"
PROJECT_URL = "https://github.com/danielsss/wced"
PROTOCOL_VERSION = 2
FRIEND_SOURCE_TIMEOUT = 35

CLASSIC_ZONE_GROUPS = {
    { name = "东部王国", zones = {
        "艾尔文森林", "西部荒野", "赤脊山", "暮色森林", "荆棘谷", "逆风小径", "悲伤沼泽", "诅咒之地",
        "燃烧平原", "灼热峡谷", "荒芜之地", "洛克莫丹", "丹莫罗", "湿地", "阿拉希高地", "希尔斯布莱德丘陵",
        "奥特兰克山脉", "辛特兰", "银松森林", "提瑞斯法林地", "西瘟疫之地", "东瘟疫之地",
    } },
    { name = "卡利姆多", zones = {
        "杜隆塔尔", "莫高雷", "泰达希尔", "黑海岸", "灰谷", "石爪山脉", "贫瘠之地", "千针石林", "凄凉之地",
        "菲拉斯", "尘泥沼泽", "塔纳利斯", "安戈洛环形山", "希利苏斯", "费伍德森林", "冬泉谷", "艾萨拉", "月光林地",
    } },
    { name = "主城", zones = { "暴风城", "铁炉堡", "达纳苏斯", "奥格瑞玛", "雷霆崖", "幽暗城" } },
    { name = "地下城与团队", zones = {
        "怒焰裂谷", "哀嚎洞穴", "死亡矿井", "影牙城堡", "黑暗深渊", "暴风城监狱", "诺莫瑞根", "剃刀沼泽",
        "血色修道院", "剃刀高地", "奥达曼", "祖尔法拉克", "玛拉顿", "阿塔哈卡神庙", "黑石深渊", "黑石塔",
        "厄运之槌", "通灵学院", "斯坦索姆", "熔火之心", "黑翼之巢", "奥妮克希亚的巢穴", "祖尔格拉布",
        "安其拉废墟", "安其拉神殿", "纳克萨玛斯",
    } },
    { name = "战场", zones = { "战歌峡谷", "阿拉希盆地", "奥特兰克山谷" } },
}

if WCED and not WCED.IS_CHINESE then
    for _, group in ipairs(CLASSIC_ZONE_GROUPS) do
        group.name = WCED.ZONE_EN[group.name] or group.name
        for index, zone in ipairs(group.zones) do group.zones[index] = WCED.ZONE_EN[zone] or zone end
    end
end

function ForEachClassicZone(callback)
    for _, group in ipairs(CLASSIC_ZONE_GROUPS) do
        for _, zone in ipairs(group.zones) do callback(zone, group.name) end
    end
end

defaults = {
    role = "detector",
    peer = "",
    peers = {},
    peerPermissions = {},
    peerConfigRevisions = {},
    activeConfigPeer = "",
    remoteConfigAllowed = false,
    interval = 30,
    channel = "AUTO",
    passive = false,
    queries = { zones = {}, guilds = {}, names = {} },
    friendlyQueries = { zones = {}, guilds = {} },
    queryRevision = 0,
    lastCommunicationAt = 0,
    trackingBroadcast = {},
    friendBroadcast = {},
    listenerFriendCaches = {},
    enemySort = "zone",
    friendSort = "zone",
    friendSortAscending = true,
    trackingSort = "zone",
    trackingSortAscending = true,
    colorNativeFriendNames = false,
    hideNativeBags = false,
    hideNativeMicroMenu = false,
    queryLevel = 60,
    autoInvite = { enabled = false, code = "999" },
    team = { savedMembers = {}, declinedUntil = {}, recentWhispers = {}, inviteHistory = {}, noJoinUntil = {},
        noJoinReasons = {}, noJoinDuration = 3600, shareEnabled = true, sharedLists = {},
        promoteAllAssistants = false, freeForAllLoot = false },
    queryButton = { point = "CENTER", x = -380, y = -220, hidden = false, menuExpanded = true, systemExpanded = false },
    enemyWatcher = { point = "CENTER", x = 0, y = 190, expireSeconds = 90, collapsed = false },
    spy = { point = "CENTER", x = 0, y = 20, recordsByCharacter = {}, recordsMigrationVersion = 0 },
    window = { point = "CENTER", x = 0, y = 0, width = 760, height = 310, collapsed = false },
    friendWindow = { point = "CENTER", x = 260, y = 0, width = 460, height = 390,
        collapsed = false, expandedWidth = 460, expandedHeight = 390 },
}

state = { seen = {}, records = {}, rows = {}, peerGameAccountID = nil, lastPeerSearch = 0,
    peerGameAccountIDs = {}, peerDiagnostics = {}, peerLastSearch = {}, peerOffset = 0,
    peerVersions = {}, peerProtocols = {}, peerRoles = {}, peerVersionRequestedAt = {},
    queryQueue = {}, queryIndex = 0, pendingQuery = nil, configKind = "guild", configSide = "enemy",
    scrollOffset = 0, refreshing = false,
    configOffsets = { zone = 0, guild = 0, name = 0 }, refreshingConfig = false,
    selectedZone = nil, selectedEnemyClass = nil, selectedFriendlyClass = nil, queryClassRequired = false,
    friendlyClassRequired = false, lastQueryAt = 0, statistics = nil, receivingQuery = false, mainTab = "friendlyQuery",
    trackedLast = {}, friendAddAttempts = {}, friendRefreshSerial = 0, friendEventPending = false,
    queryGeneration = 0, friendlyRecords = {}, friendlyStatistics = nil,
    selectedFriendlyZone = nil, closeFriendsAfterWho = false,
    friendRecords = {}, incomingFriendSnapshot = nil, friendSnapshotSerial = 0, friendOffset = 0,
    friendSourceUnavailable = false, friendSourceLastAt = nil,
    friendOutboundQueue = {}, friendSnapshotSignature = nil, friendSnapshotIndex = nil, friendFullSnapshotAt = 0, friendAddLastAt = 0,
    friendCount = 0, friendListFull = false, friendLimitWarned = false,
    teamInvite = { running=false, queue={}, index=1, invited=0, skipped=0, status="等待操作" }, inviteStatuses = {},
    teamShareOutboundQueue = {}, incomingTeamShares = {}, friendlyDisplayClass = nil,
    friendlyWhisper = { running=false, queue={}, index=1, message="" }, assistantPromotionPending = {} }
frame = CreateFrame("Frame")
RefreshConfigUI, RefreshUI, RefreshFriendUI = nil, nil, nil
ReconcileTrackedFriends, PollTrackedFriends = nil, nil
ResetPagination, UpdateQueryButton = nil, nil

function MarkCommunication()
    if not WowDetectorDB then return end
    WowDetectorDB.lastCommunicationAt = time()
    if RefreshConfigUI then RefreshConfigUI() end
end

function ClearListenerFriendData()
    if not WowDetectorDB or WowDetectorDB.role ~= "listener" then return end
    wipe(state.friendRecords)
    state.incomingFriendSnapshot = nil
    state.friendDetectorZone = nil
    state.friendSnapshotAt = nil
    state.friendOffset = 0
    if RefreshFriendUI then RefreshFriendUI() end
end

function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99WCED|r " .. L(tostring(message)))
end

function CopyDefaults(source, target)
    for key, value in pairs(source) do
        if type(value) == "table" then
            target[key] = type(target[key]) == "table" and target[key] or {}
            CopyDefaults(value, target[key])
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

function Trim(value)
    return (tostring(value or ""):match("^%s*(.-)%s*$"))
end

function ShortName(value)
    return (Trim(value):match("^([^-]+)") or ""):lower()
end

function NormalizeTrackedName(value)
    return Trim(value):gsub("－", "-"):gsub("—", "-"):gsub("%s+", ""):lower()
end

function SplitTrackedName(value)
    local normalized = NormalizeTrackedName(value)
    local name, realm = normalized:match("^([^-]+)%-(.+)$")
    return name or normalized, realm
end

function TrackedNameMatches(actual, configured)
    local actualName, actualRealm = SplitTrackedName(actual)
    local configuredName, configuredRealm = SplitTrackedName(configured)
    if actualName ~= configuredName then return false end
    if actualRealm and configuredRealm then return actualRealm == configuredRealm end
    return true
end

function NormalizeBattleTag(value)
    return Trim(value):gsub("＃", "#"):gsub("%s+", ""):lower()
end

function Escape(value)
    return tostring(value or ""):gsub("%%", "%%25"):gsub("|", "%%7C"):gsub("~", "%%7E"):gsub("\n", "%%0A")
end

function Unescape(value)
    return tostring(value or ""):gsub("%%0A", "\n"):gsub("%%7E", "~"):gsub("%%7C", "|"):gsub("%%25", "%%")
end

function Serialize(record)
    return table.concat({ "1", Escape(record.zone), Escape(record.name), Escape(record.guild),
        Escape(record.level), Escape(record.class), Escape(record.race), tostring(record.time or time()) }, "|")
end

function Deserialize(message)
    local fields = {}
    for field in (message .. "|"):gmatch("(.-)|") do fields[#fields + 1] = Unescape(field) end
    if fields[1] ~= "1" or fields[3] == "" then return nil end
    return { zone = fields[2], name = fields[3], guild = fields[4], level = fields[5],
        class = fields[6], race = fields[7], time = tonumber(fields[8]) or time() }
end

function GetGameAccount(gameAccountID)
    if C_BattleNet and C_BattleNet.GetGameAccountInfoByID then
        local info = C_BattleNet.GetGameAccountInfoByID(gameAccountID)
        if info then return info.characterName, info.clientProgram, info.gameAccountID end
    end
    if BNGetGameAccountInfo then
        local _, characterName, client = BNGetGameAccountInfo(gameAccountID)
        return characterName, client, gameAccountID
    end
end

function PeerTags()
    return WowDetectorDB and WowDetectorDB.peers or {}
end

function ActivePeerTag()
    if not WowDetectorDB then return nil end
    if WowDetectorDB.role ~= "listener" then return PeerTags()[1] end
    local active = NormalizeBattleTag(WowDetectorDB.activeConfigPeer)
    if active == "" then return nil end
    for _, tag in ipairs(PeerTags()) do
        if NormalizeBattleTag(tag) == active then return tag end
    end
    return nil
end

function FindPeer(force, requestedTag)
    local tag = requestedTag or PeerTags()[1] or WowDetectorDB.peer
    local wanted = NormalizeBattleTag(tag)
    if wanted == "" then return nil end
    if state.peerGameAccountIDs[wanted] and not force then return state.peerGameAccountIDs[wanted] end
    state.peerGameAccountIDs[wanted] = nil
    state.peerLastSearch[wanted] = GetTime()
    local friendCount = BNGetNumFriends and BNGetNumFriends() or 0
    state.peerDiagnostics[wanted] = friendCount == 0 and "当前游戏好友接口返回0个战网好友" or "好友列表中没有匹配该完整战网ID"

    local function IsWoW(info, client)
        local program = info and info.clientProgram or client
        return (info and info.wowProjectID ~= nil) or (BNET_CLIENT_WOW and program == BNET_CLIENT_WOW) or program == "WoW" or program == "WoWC"
    end

    for friendIndex = 1, friendCount do
        local bnetAccountID, _, legacyTag, _, _, focusedGameID, focusedClient
        if BNGetFriendInfo then
            bnetAccountID, _, legacyTag, _, _, focusedGameID, focusedClient = BNGetFriendInfo(friendIndex)
        end
        local accountInfo = C_BattleNet and C_BattleNet.GetFriendAccountInfo and C_BattleNet.GetFriendAccountInfo(friendIndex)
        local battleTag = accountInfo and accountInfo.battleTag or legacyTag
        if battleTag and NormalizeBattleTag(battleTag) == wanted then
            state.peerDiagnostics[wanted] = "已匹配战网好友，但没有找到其在线的WoW游戏账号"

            if C_BattleNet and C_BattleNet.GetFriendNumGameAccounts and C_BattleNet.GetFriendGameAccountInfo then
                local gameCount = C_BattleNet.GetFriendNumGameAccounts(friendIndex) or 0
                for accountIndex = 1, gameCount do
                    local info = C_BattleNet.GetFriendGameAccountInfo(friendIndex, accountIndex)
                    if info and info.gameAccountID and info.isOnline ~= false and IsWoW(info) then
                        state.peerGameAccountIDs[wanted] = info.gameAccountID
                        state.peerDiagnostics[wanted] = "已匹配战网好友和在线WoW游戏账号"
                        return info.gameAccountID
                    end
                end
            end

            if focusedGameID and IsWoW(nil, focusedClient) then
                state.peerGameAccountIDs[wanted] = focusedGameID
                state.peerDiagnostics[wanted] = "已通过好友主游戏账号匹配"
                return focusedGameID
            end

            local embedded = accountInfo and accountInfo.gameAccountInfo
            if embedded and embedded.gameAccountID and embedded.isOnline ~= false and IsWoW(embedded) then
                state.peerGameAccountIDs[wanted] = embedded.gameAccountID
                state.peerDiagnostics[wanted] = "已通过好友账号信息匹配"
                return embedded.gameAccountID
            end
            return nil
        end
    end
    return nil
end

function CheckListenerFriendSource()
    if not WowDetectorDB or WowDetectorDB.role ~= "listener" then return end
    local activeTag = ActivePeerTag()
    if not activeTag then
        if #state.friendRecords > 0 or state.incomingFriendSnapshot then ClearListenerFriendData() end
        state.friendSourceUnavailable = true
        return
    end

    local online = FindPeer(true, activeTag) ~= nil
    local lastCommunication = tonumber(state.friendSourceLastAt) or 0
    local communicationAlive = lastCommunication > 0 and (time() - lastCommunication) <= FRIEND_SOURCE_TIMEOUT
    local unavailable = not online or not communicationAlive
    if unavailable and not state.friendSourceUnavailable then ClearListenerFriendData() end
    state.friendSourceUnavailable = unavailable
end

function SendRawToID(id, message)
    if not id then return false, "无法取得对端的在线WoW游戏账号" end
    if C_BattleNet and C_BattleNet.SendGameData then
        local result = C_BattleNet.SendGameData(id, PREFIX, message)
        local success = Enum and Enum.SendAddonMessageResult and Enum.SendAddonMessageResult.Success or 0
        if result ~= nil and result ~= success then
            local reasons = {
                [1]="插件消息前缀无效", [2]="消息内容无效", [3]="发送频率受限", [4]="通信类型无效",
                [5]="目标不在队伍", [6]="缺少目标", [7]="频道无效", [8]="频道频率受限",
                [9]="战网通信错误", [10]="目标不在公会", [11]="插件通信被锁定", [12]="对端被判定为离线",
            }
            return false, reasons[result] or ("发送接口返回错误代码 " .. tostring(result))
        end
    elseif BNSendGameData then BNSendGameData(id, PREFIX, message)
    else return false, "当前客户端没有可用的战网插件消息接口" end
    return true
end

function SendRaw(message)
    local sent, failures = 0, {}
    for _, tag in ipairs(PeerTags()) do
        local key = NormalizeBattleTag(tag)
        local id = FindPeer(false, tag)
        if not id and GetTime() - (state.peerLastSearch[key] or 0) > 5 then id = FindPeer(true, tag) end
        local ok, reason = SendRawToID(id, message)
        if ok then sent = sent + 1 else failures[#failures + 1] = tag .. "：" .. (reason or state.peerDiagnostics[key] or "发送失败") end
    end
    if sent > 0 then return true end
    return false, #failures > 0 and table.concat(failures, "；") or "尚未添加对端战网ID"
end

-- 好友列表可能包含数十人，不能在同一帧把整份快照全部塞进战网通道。
-- 新快照会替换尚未发完的旧快照，避免状态连续变化时积压过期消息。
function ReplaceFriendOutboundQueue(messages)
    wipe(state.friendOutboundQueue)
    for _, message in ipairs(messages or {}) do
        for _, tag in ipairs(PeerTags()) do
            state.friendOutboundQueue[#state.friendOutboundQueue + 1] = { tag=tag, message=message }
        end
    end
end

function QueueFriendMessage(message)
    for _, tag in ipairs(PeerTags()) do
        state.friendOutboundQueue[#state.friendOutboundQueue + 1] = { tag=tag, message=message }
    end
end

function ProcessFriendOutboundQueue()
    if not WowDetectorDB or WowDetectorDB.role ~= "detector" then
        wipe(state.friendOutboundQueue)
        return
    end
    if #state.friendOutboundQueue == 0 then return end
    local item = table.remove(state.friendOutboundQueue, 1)
    local key = NormalizeBattleTag(item.tag)
    local id = FindPeer(false, item.tag)
    if not id and GetTime() - (state.peerLastSearch[key] or 0) > 5 then id = FindPeer(true, item.tag) end
    SendRawToID(id, item.message)
end

function SendToPeer(record)
    SendRaw(Serialize(record))
end

function ClassColor(classFile)
    local color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    return color and color.colorStr or "ffffffff"
end

CLASS_FILE_BY_NAME = {
    ["战士"] = "WARRIOR", ["warrior"] = "WARRIOR",
    ["圣骑士"] = "PALADIN", ["paladin"] = "PALADIN",
    ["猎人"] = "HUNTER", ["hunter"] = "HUNTER",
    ["潜行者"] = "ROGUE", ["盗贼"] = "ROGUE", ["rogue"] = "ROGUE",
    ["牧师"] = "PRIEST", ["priest"] = "PRIEST",
    ["萨满祭司"] = "SHAMAN", ["萨满"] = "SHAMAN", ["shaman"] = "SHAMAN",
    ["法师"] = "MAGE", ["mage"] = "MAGE",
    ["术士"] = "WARLOCK", ["warlock"] = "WARLOCK",
    ["德鲁伊"] = "DRUID", ["druid"] = "DRUID",
}

function ResolveClassFile(className, classFile)
    if classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile] then return classFile end
    local normalized = Trim(className):lower()
    if CLASS_FILE_BY_NAME[normalized] then return CLASS_FILE_BY_NAME[normalized] end
    for token, localized in pairs(LOCALIZED_CLASS_NAMES_MALE or {}) do
        if Trim(localized):lower() == normalized then return token end
    end
    for token, localized in pairs(LOCALIZED_CLASS_NAMES_FEMALE or {}) do
        if Trim(localized):lower() == normalized then return token end
    end
end

function ColoredPlayerName(name, className, classFile)
    return "|c" .. ClassColor(ResolveClassFile(className, classFile)) .. tostring(name or "") .. "|r"
end

function TrackedClassForName(name)
    for _, record in pairs(state.records) do
        if record.isTracked and TrackedNameMatches(record.name, name) then return record.class, record.classFile, record.online == true end
    end
    for _, record in ipairs(state.friendRecords or {}) do
        if TrackedNameMatches(record.name, name) then return record.class, record.classFile, record.online == true end
    end
end

function RecordFromUnit(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) or not UnitIsEnemy("player", unit) then return end
    local guid = UnitGUID(unit)
    local name, realm = UnitName(unit)
    if not name then return end
    if realm and realm ~= "" then name = name .. "-" .. realm end
    local _, classFile = UnitClass(unit)
    local race = UnitRace(unit)
    local guild = GetGuildInfo(unit)
    return {
        key = guid or name,
        zone = GetRealZoneText() or GetZoneText() or UNKNOWN,
        name = name,
        guild = guild or UNKNOWN,
        level = UnitLevel(unit) and UnitLevel(unit) > 0 and tostring(UnitLevel(unit)) or UNKNOWN,
        class = UnitClass(unit) or UNKNOWN,
        classFile = classFile,
        race = race or UNKNOWN,
        time = time(),
    }
end

function Detect(record)
    if WowDetectorDB.role ~= "detector" or not record or not record.name then return end
    SendToPeer(record)
end

function QuoteWho(value)
    return tostring(value or ""):gsub('"', ""):gsub("[\r\n]", "")
end

function GuildNameMatches(actual, configured)
    actual, configured = Trim(actual):lower(), Trim(configured):lower()
    if actual == "" or configured == "" or actual == UNKNOWN:lower() then return false end
    return actual == configured or actual:sub(1, #configured + 1) == configured .. "-"
end

function ZoneNameMatches(actual, configured)
    actual, configured = Trim(actual):lower(), Trim(configured):lower()
    if actual == "" or configured == "" then return false end
    return actual == configured or actual:find(configured, 1, true) ~= nil or configured:find(actual, 1, true) ~= nil
end

function ConfiguredGuildFor(actual)
    for _, configured in ipairs(WowDetectorDB.queries.guilds) do
        if GuildNameMatches(actual, configured) then return configured end
    end
end

function RemoveUnconfiguredTrackingRecords()
    local configured = {}
    for _, name in ipairs(WowDetectorDB.queries.names) do configured[NormalizeTrackedName(name)] = true end
    for key, record in pairs(state.records) do
        if record.isTracked and not configured[NormalizeTrackedName(record.name)] then
            state.records[key] = nil
            WowDetectorDB.trackingBroadcast[NormalizeTrackedName(record.name)] = nil
        end
    end
end

function RebuildQueryQueue()
    wipe(state.queryQueue)
    local selectedExists = false
    ForEachClassicZone(function(value)
        local level = math.max(1, math.min(60, tonumber(WowDetectorDB.queryLevel) or 60))
        state.queryQueue[#state.queryQueue + 1] = { kind = "地区", value = value, zone = value,
            level = level, filter = 'z-"' .. QuoteWho(value) .. '" ' .. level .. '-' .. level }
        if value == state.selectedZone then selectedExists = true end
    end)
    if not selectedExists then state.selectedZone = nil end
    if state.zoneDropdown then
        if state.zoneDropdown.SetSelectionText then state.zoneDropdown:SetSelectionText(state.selectedZone or "请选择地区")
        else UIDropDownMenu_SetText(state.zoneDropdown, state.selectedZone or "请选择地区") end
    end
    if state.queryIndex > #state.queryQueue then state.queryIndex = 0 end
    if state.configUI and state.configUI.status then
        local savedCount = #WowDetectorDB.queries.guilds + #WowDetectorDB.queries.names
        state.configUI.status:SetText(string.format("已保存 %d 个配置条件%s", savedCount,
            FriendCapacitySuffix and FriendCapacitySuffix() or ""))
    end
end

UpdateQueryButton = function()
    if not state.queryActionButton then return end
    state.queryActionButton:SetWidth(92)
    if state.pendingQuery then
        state.queryActionButton:SetText(state.pendingQuery.className and ("查询中："..state.pendingQuery.className) or "查询中...")
        state.queryActionButton:SetEnabled(false)
        return
    end
    local remaining=math.max(0,5-(GetTime()-(state.lastQueryAt or 0)))
    if remaining>0 then
        state.queryActionButton:SetText(string.format("冷却 %ds",math.ceil(remaining)))
        state.queryActionButton:SetEnabled(false)
    else
        state.queryActionButton:SetText("查询")
        local friendly=state.mainTab=="friendlyQuery"
        state.queryActionButton:SetEnabled((WowDetectorDB.role=="detector" or friendly) and true or false)
    end
end

function ResetFriendlyPagination(clearResults)
    state.friendlyDisplayClass = nil
    if clearResults then wipe(state.friendlyRecords); state.friendlyStatistics = nil; state.scrollOffset = 0 end
    UpdateQueryButton()
end

ResetPagination = function()
    state.queryGeneration = (state.queryGeneration or 0) + 1
    UpdateQueryButton()
end

function JoinQueryValues(values)
    local encoded = {}
    for index, value in ipairs(values) do encoded[index] = Escape(value) end
    return table.concat(encoded, "~")
end

function SplitQueryValues(value)
    local result = {}
    if not value or value == "" then return result end
    for item in (value .. "~"):gmatch("(.-)~") do result[#result + 1] = Unescape(item) end
    return result
end

function SenderPeerTag(senderID)
    local wantedSender = tonumber(senderID)
    if not wantedSender then return nil end
    for _, tag in ipairs(PeerTags()) do
        if tonumber(FindPeer(false, tag)) == wantedSender then return tag end

        -- 一个 BattleTag 可能同时登录多个 WoW 游戏账号。发送插件消息的
        -- gameAccountID 不一定是 FindPeer 选中的第一个在线账号，因此必须
        -- 在该 BattleTag 的全部 WoW 游戏账号中确认发送者身份。
        local wantedTag = NormalizeBattleTag(tag)
        local friendCount = BNGetNumFriends and BNGetNumFriends() or 0
        for friendIndex = 1, friendCount do
            local legacyTag, focusedGameID
            if BNGetFriendInfo then
                local _, _, foundTag, _, _, foundGameID = BNGetFriendInfo(friendIndex)
                legacyTag, focusedGameID = foundTag, foundGameID
            end
            local accountInfo = C_BattleNet and C_BattleNet.GetFriendAccountInfo
                and C_BattleNet.GetFriendAccountInfo(friendIndex)
            local foundTag = accountInfo and accountInfo.battleTag or legacyTag
            if foundTag and NormalizeBattleTag(foundTag) == wantedTag then
                if tonumber(focusedGameID) == wantedSender then return tag end
                local embedded = accountInfo and accountInfo.gameAccountInfo
                if embedded and tonumber(embedded.gameAccountID) == wantedSender then return tag end
                if C_BattleNet and C_BattleNet.GetFriendNumGameAccounts and C_BattleNet.GetFriendGameAccountInfo then
                    local gameCount = C_BattleNet.GetFriendNumGameAccounts(friendIndex) or 0
                    for accountIndex = 1, gameCount do
                        local gameInfo = C_BattleNet.GetFriendGameAccountInfo(friendIndex, accountIndex)
                        if gameInfo and tonumber(gameInfo.gameAccountID) == wantedSender then return tag end
                    end
                end
                break
            end
        end
    end
end

function PeerCompatibility(tag)
    local key = NormalizeBattleTag(tag)
    local version = state.peerVersions[key]
    local protocol = tonumber(state.peerProtocols[key])
    local role = state.peerRoles[key]
    if not version then
        local requested = state.peerVersionRequestedAt[key]
        return false, requested and GetTime() - requested >= 3 and "协议未响应" or "协议检测中"
    end
    local expectedRole = WowDetectorDB and WowDetectorDB.role == "detector" and "listener" or "detector"
    if role and role ~= expectedRole then return false, "角色错误" end
    if not protocol then return false, "协议未响应" end
    if protocol ~= PROTOCOL_VERSION then return false, "协议不同" end
    return true, version == VERSION and "完全兼容" or "兼容模式"
end

function VersionAtLeast(actual, required)
    if type(actual)~="string" or type(required)~="string" then return false end
    local actualParts, requiredParts = {}, {}
    for value in actual:gmatch("%d+") do actualParts[#actualParts+1]=tonumber(value) or 0 end
    for value in required:gmatch("%d+") do requiredParts[#requiredParts+1]=tonumber(value) or 0 end
    local count=math.max(#actualParts,#requiredParts)
    for index=1,count do
        local left,right=actualParts[index] or 0,requiredParts[index] or 0
        if left~=right then return left>right end
    end
    return true
end

function HasAvailableDetector()
    if not WowDetectorDB or WowDetectorDB.role=="detector" then return true end
    local tag=ActivePeerTag()
    if not tag then return false,"当前没有启用的侦测方，敌情与好友情报暂时无法使用" end
    if not FindPeer(false,tag) then return false,"当前侦测方离线或无法通信，相关功能暂时无法使用" end
    local compatible,reason=PeerCompatibility(tag)
    if not compatible then return false,"当前侦测方不可用（"..tostring(reason).."），相关功能暂时无法使用" end
    return true
end

function RequestPeerVersion(tag)
    local key = NormalizeBattleTag(tag)
    if key == "" then return false end
    local id = FindPeer(false, tag)
    if not id then return false end
    state.peerVersionRequestedAt[key] = GetTime()
    local sent = SendRawToID(id, "VREQ")
    C_Timer.After(3.1, function() if RefreshConfigUI then RefreshConfigUI() end end)
    return sent
end

function CanEditConfig()
    return WowDetectorDB.role == "detector" or WowDetectorDB.remoteConfigAllowed == true
end

function SendPeerPolicy(tag)
    if WowDetectorDB.role ~= "detector" then return end
    local id = FindPeer(false, tag)
    if id then SendRawToID(id, "POLICY|" .. (WowDetectorDB.peerPermissions[NormalizeBattleTag(tag)] and "1" or "0")) end
end

function SendAllPeerPolicies()
    if WowDetectorDB.role ~= "detector" then return end
    for _, tag in ipairs(PeerTags()) do SendPeerPolicy(tag) end
end

function BuildQueryConfigMessage()
    local db = WowDetectorDB
    local message = table.concat({ "C", tostring(db.queryRevision or 0), JoinQueryValues(db.queries.zones),
        JoinQueryValues(db.queries.guilds), JoinQueryValues(db.queries.names), tostring(db.queryLevel or 60) }, "|")
    if #message > 3900 then Print("查询配置过多，无法通过战网同步") return false end
    return message
end

function SendQueryConfig(targetID)
    local message = BuildQueryConfigMessage()
    if not message then return false end
    if targetID then return SendRawToID(targetID, message) end
    return SendRaw(message)
end

function TouchQueryConfig()
    if not CanEditConfig() then Print("侦测方未允许本监听端修改配置") return false end
    WowDetectorDB.queryRevision = math.max(time(), (WowDetectorDB.queryRevision or 0) + 1)
    SendQueryConfig()
    return true
end

function ReceiveQueryConfig(message, senderID)
    if WowDetectorDB.role == "detector" then
        local senderTag = SenderPeerTag(senderID)
        if not senderTag or not WowDetectorDB.peerPermissions[NormalizeBattleTag(senderTag)] then
            if senderTag then SendPeerPolicy(senderTag) end
            Print("已拒绝未授权监听端写入配置")
            return
        end
    end
    local fields = {}
    for field in (message .. "|"):gmatch("(.-)|") do fields[#fields + 1] = field end
    local revision = tonumber(fields[2]) or 0
    local senderTag = SenderPeerTag(senderID)
    local senderKey = senderTag and NormalizeBattleTag(senderTag) or ""
    if WowDetectorDB.role == "listener" then
        local activeTag = ActivePeerTag()
        if not activeTag or senderKey ~= NormalizeBattleTag(activeTag) then return end
        local knownRevision = tonumber(WowDetectorDB.peerConfigRevisions[senderKey])
        if knownRevision and revision <= knownRevision then return end
        WowDetectorDB.peerConfigRevisions[senderKey] = revision
        WowDetectorDB.activeConfigPeer = senderKey
    elseif revision <= (WowDetectorDB.queryRevision or 0) then return end
    -- v0.19.0 起地区由双方相同的内置地图库提供，不再接受远端自定义地区。
    WowDetectorDB.queries.zones = {}
    WowDetectorDB.queries.guilds = SplitQueryValues(fields[4])
    WowDetectorDB.queries.names = SplitQueryValues(fields[5])
    WowDetectorDB.queryLevel = 60
    WowDetectorDB.queryRevision = revision
    ResetPagination()
    RemoveUnconfiguredTrackingRecords()
    RebuildQueryQueue()
    if WowDetectorDB.role == "detector" and ReconcileTrackedFriends then ReconcileTrackedFriends() end
    if RefreshConfigUI then RefreshConfigUI() end
    Print("已从对端同步最新查询配置")
end

function ClearRemoteSourceData(peerKey)
    if WowDetectorDB.role ~= "listener" then return end
    if peerKey and peerKey ~= "" then WowDetectorDB.peerConfigRevisions[peerKey] = nil end
    if not peerKey or WowDetectorDB.activeConfigPeer == peerKey then
        wipe(WowDetectorDB.peerConfigRevisions)
        WowDetectorDB.activeConfigPeer = ""
        WowDetectorDB.remoteConfigAllowed = false
        WowDetectorDB.queryRevision = 0
        WowDetectorDB.queries.zones = {}; WowDetectorDB.queries.guilds = {}; WowDetectorDB.queries.names = {}
        wipe(state.records); wipe(state.friendRecords); state.incomingFriendSnapshot = nil
        state.friendDetectorZone = nil; state.friendSnapshotAt = nil; state.friendOffset = 0
        state.friendSourceLastAt = nil; state.friendSourceUnavailable = false
        state.statistics = nil; state.scrollOffset = 0; state.statsOffset = 0
        state.selectedZone = nil; ResetPagination(); RebuildQueryQueue()
        if RefreshConfigUI then RefreshConfigUI() end
        if RefreshUI then RefreshUI() end
        if RefreshFriendUI then RefreshFriendUI() end
    end
end

function RequestPeerSnapshot(tag)
    if WowDetectorDB.role ~= "listener" then return end
    if not PeerCompatibility(tag) then return end
    local id = FindPeer(true, tag)
    if id then SendRawToID(id, "CREQ") end
end

function EnforceListenerPeerLimit()
    return false
end
