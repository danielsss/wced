function ReadCharacterFriends()
    local friends = {}
    local count = 0
    if C_FriendList and C_FriendList.GetNumFriends then count = C_FriendList.GetNumFriends() or 0
    elseif GetNumFriends then count = GetNumFriends() or 0 end
    for index = 1, count do
        local info = C_FriendList and C_FriendList.GetFriendInfoByIndex and C_FriendList.GetFriendInfoByIndex(index)
        if type(info) == "table" and info.name then
            friends[#friends + 1] = { name = info.name, connected = info.connected and true or false,
                area = info.area, level = info.level, class = info.className or info.class }
        elseif GetFriendInfo then
            local name, level, class, area, connected = GetFriendInfo(index)
            if name then friends[#friends + 1] = { name=name, connected=connected and true or false, area=area, level=level, class=class } end
        end
    end
    return friends
end

local nativeFriendHooks = {}
local nativeWhisperEditHooks = setmetatable({}, { __mode="k" })
local nativeFriendColorPending = false
local nativeFriendColorCache

local function NormalizeNativeWhisperCommand(editBox)
    if not editBox or nativeWhisperEditHooks[editBox] == "editing" or not editBox.GetText then return end
    local text = editBox:GetText() or ""
    local normalized, replacements = text:gsub("^/[cC][wW]%s+", "/w ", 1)
    if replacements == 0 or normalized == text then return end
    nativeWhisperEditHooks[editBox] = "editing"
    local cursor = editBox.GetCursorPosition and editBox:GetCursorPosition() or #normalized
    editBox:SetText(normalized)
    if editBox.SetCursorPosition then editBox:SetCursorPosition(math.max(0, cursor - 1)) end
    nativeWhisperEditHooks[editBox] = true
end

function InstallNativeWhisperCompatibility()
    local count = tonumber(NUM_CHAT_WINDOWS) or 10
    for index = 1, count do
        local editBox = _G["ChatFrame" .. index .. "EditBox"]
        if editBox and not nativeWhisperEditHooks[editBox] then
            nativeWhisperEditHooks[editBox] = true
            editBox:HookScript("OnTextChanged", NormalizeNativeWhisperCommand)
            editBox:HookScript("OnShow", NormalizeNativeWhisperCommand)
        end
    end
end

local function NativeFriendInfo(index)
    local info = C_FriendList and C_FriendList.GetFriendInfoByIndex and C_FriendList.GetFriendInfoByIndex(index)
    if type(info) == "table" then return info.name, info.className or info.class, info.level end
    if GetFriendInfo then local name, level, class = GetFriendInfo(index); return name, class, level end
end

local function NativeFriendColorEntries()
    if nativeFriendColorCache then return nativeFriendColorCache end
    local lookup = {}
    local count = C_FriendList and C_FriendList.GetNumFriends and C_FriendList.GetNumFriends() or (GetNumFriends and GetNumFriends() or 0)
    for index = 1, count do
        local name, className = NativeFriendInfo(index)
        local classFile = ResolveClassFile(className)
        if name then
            lookup[NormalizeTrackedName(name)] = classFile
            lookup[NormalizeTrackedName(ShortName(name))] = classFile
        end
    end
    nativeFriendColorCache = lookup
    return lookup
end

function ApplyNativeFriendClassColors()
    if not WowDetectorDB or not WowDetectorDB.colorNativeFriendNames then return end
    local friendColors = NativeFriendColorEntries()
    state.nativeFriendOriginal = state.nativeFriendOriginal or setmetatable({}, { __mode="k" })
    local function SetClassTextColor(font, classFile)
        local color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
        if color and font and font.SetTextColor then font:SetTextColor(color.r, color.g, color.b, 1) end
    end
    local seen = {}
    local function Visit(object)
        if not object or seen[object] then return end
        seen[object] = true
        if object.GetObjectType and object:GetObjectType()=="FontString" and object.GetText then
            local displayed=object:GetText()
            if displayed and displayed~="" then
                -- 角色好友行以姓名开头，直接查缓存，避免每个 FontString 再遍历全部好友。
                local displayedName = Trim(displayed:match("^%s*([^，,]+)") or displayed)
                local classFile = friendColors[NormalizeTrackedName(displayedName)]
                if classFile then
                    if not state.nativeFriendOriginal[object] then
                        local r,g,b,a=object:GetTextColor()
                        state.nativeFriendOriginal[object]={text=displayed,r=r,g=g,b=b,a=a}
                    end
                    SetClassTextColor(object, classFile)
                end
            end
        end
        if object.GetRegions then for _,region in ipairs({object:GetRegions()}) do Visit(region) end end
        if object.GetChildren then for _,child in ipairs({object:GetChildren()}) do Visit(child) end end
    end
    if FriendsFrame then Visit(FriendsFrame) end

    -- 公会名单使用固定的行控件，不能依赖 FriendsFrame 的递归文本匹配。
    -- 直接按每一行保存的 guildIndex 取资料，避免误改地区、职业等相邻列。
    local guildRows = tonumber(GUILDMEMBERS_TO_DISPLAY) or 20
    for index = 1, guildRows do
        local button = _G["GuildFrameButton" .. index]
        local nameText = _G["GuildFrameButton" .. index .. "Name"]
        if button and button:IsShown() and button.guildIndex and nameText and GetGuildRosterInfo then
            local name, _, _, _, className = GetGuildRosterInfo(button.guildIndex)
            if name and name ~= "" then
                local classFile = ResolveClassFile(className)
                local displayedName = nameText:GetText() or ShortName(name)
                if not state.nativeFriendOriginal[nameText] then
                    local r,g,b,a = nameText:GetTextColor()
                    state.nativeFriendOriginal[nameText] = { text=displayedName, r=r, g=g, b=b, a=a }
                end
                SetClassTextColor(nameText, classFile)
            end
        end
    end

    -- 暴雪原生 /who 查询页使用滚动偏移映射可见行。
    local whoRows = tonumber(WHOS_TO_DISPLAY) or 17
    local whoOffset = WhoListScrollFrame and FauxScrollFrame_GetOffset and FauxScrollFrame_GetOffset(WhoListScrollFrame) or 0
    for index = 1, whoRows do
        local button = _G["WhoFrameButton" .. index]
        local nameText = _G["WhoFrameButton" .. index .. "Name"]
        local info = C_FriendList and C_FriendList.GetWhoInfo and C_FriendList.GetWhoInfo(whoOffset + index)
        local whoName = info and (info.fullName or info.name)
        if button and button:IsShown() and nameText and whoName then
            local displayedName = nameText:GetText() or whoName
            if not state.nativeFriendOriginal[nameText] then
                local r,g,b,a = nameText:GetTextColor()
                state.nativeFriendOriginal[nameText] = { text=displayedName, r=r, g=g, b=b, a=a }
            end
            local classFile = ResolveClassFile(info.classStr or info.className, info.filename or info.classFilename or info.classFileName)
            SetClassTextColor(nameText, classFile)
        end
    end
end


local function QueueNativeFriendClassColors()
    if not WowDetectorDB or not WowDetectorDB.colorNativeFriendNames or nativeFriendColorPending then return end
    nativeFriendColorPending = true
    local function ApplyQueuedColors()
        nativeFriendColorPending = false
        ApplyNativeFriendClassColors()
    end
    if C_Timer and C_Timer.After then C_Timer.After(0, ApplyQueuedColors) else ApplyQueuedColors() end
end

local function RestoreNativeFriendNameColors()
    for font,original in pairs(state.nativeFriendOriginal or {}) do
        if font and font.SetText then font:SetText(original.text or ""); if font.SetTextColor and original.r then font:SetTextColor(original.r,original.g,original.b,original.a or 1) end end
    end
    if state.nativeFriendOriginal then wipe(state.nativeFriendOriginal) end
end

function RefreshNativeFriendNameColors()
    if WowDetectorDB and WowDetectorDB.colorNativeFriendNames then
        ApplyNativeFriendClassColors()
        return
    end
    RestoreNativeFriendNameColors()
    if FriendsFrame_UpdateFriends then pcall(FriendsFrame_UpdateFriends)
    elseif FriendsFrame_Update then pcall(FriendsFrame_Update) end
    if GuildRoster_Update then pcall(GuildRoster_Update)
    elseif GuildFrame_Update then pcall(GuildFrame_Update) end
end

function InstallNativeFriendColorHooks()
    if not hooksecurefunc then return end
    for _, functionName in ipairs({ "FriendsFrame_UpdateFriends", "FriendsFrame_UpdateFriendButton", "FriendsFrame_Update", "FriendsList_Update",
        "GuildRoster_Update", "GuildFrame_Update", "GuildStatus_Update", "WhoList_Update" }) do
        if type(_G[functionName]) == "function" and not nativeFriendHooks[functionName] then
            nativeFriendHooks[functionName] = true
            -- 一次滚动会嵌套触发多个列表与单行刷新；合并为每帧最多一次染色，避免重复全窗扫描。
            hooksecurefunc(functionName, QueueNativeFriendClassColors)
        end
    end
    QueueNativeFriendClassColors()
end

local nativeFriendEvents = CreateFrame("Frame")
nativeFriendEvents:RegisterEvent("ADDON_LOADED")
nativeFriendEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
nativeFriendEvents:RegisterEvent("FRIENDLIST_UPDATE")
nativeFriendEvents:RegisterEvent("GUILD_ROSTER_UPDATE")
nativeFriendEvents:RegisterEvent("WHO_LIST_UPDATE")
nativeFriendEvents:SetScript("OnEvent", function(_, event)
    if event == "FRIENDLIST_UPDATE" or event == "PLAYER_ENTERING_WORLD" then nativeFriendColorCache = nil end
    if event ~= "FRIENDLIST_UPDATE" and event ~= "GUILD_ROSTER_UPDATE" and event ~= "WHO_LIST_UPDATE" then
        InstallNativeFriendColorHooks(); InstallNativeWhisperCompatibility()
    end
    if WowDetectorDB and WowDetectorDB.colorNativeFriendNames then QueueNativeFriendClassColors() end
end)

function SendFriendSnapshot(friends, forceFull)
    if not WowDetectorDB or WowDetectorDB.role ~= "detector" then return end
    local detectorZone = GetRealZoneText and GetRealZoneText() or UNKNOWN
    local stamp = time()

    local current = {}
    for _, info in ipairs(friends or {}) do
        local key=NormalizeTrackedName(info.name)
        if key~="" then
            local record={name=info.name,online=info.connected and true or false,area=info.area or UNKNOWN,
                level=info.level or UNKNOWN,class=info.class or UNKNOWN}
            record.signature=table.concat({record.name,record.online and "1" or "0",record.area,record.level,record.class},"~")
            current[key]=record
        end
    end
    local previous=state.friendSnapshotIndex
    local fullRequired=forceFull or not previous or stamp-(state.friendFullSnapshotAt or 0)>=180
    local changed=false
    if fullRequired then
        state.friendSnapshotSerial = (state.friendSnapshotSerial or 0) + 1
        local serial = state.friendSnapshotSerial
        local messages = { table.concat({ "FSB", serial, Escape(detectorZone), stamp }, "|") }
        for _, info in ipairs(friends or {}) do
            messages[#messages + 1] = table.concat({ "FSI", serial, Escape(info.name), info.connected and "1" or "0",
                Escape(info.area or UNKNOWN), Escape(info.level or UNKNOWN), Escape(info.class or UNKNOWN) }, "|")
        end
        messages[#messages + 1] = table.concat({ "FSE", serial, #(friends or {}) }, "|")
        ReplaceFriendOutboundQueue(messages)
        state.friendFullSnapshotAt=stamp
        changed=true
    else
        for key,record in pairs(current) do
            if not previous[key] or previous[key].signature~=record.signature then
                QueueFriendMessage(table.concat({"FSU",Escape(record.name),record.online and "1" or "0",Escape(record.area),
                    Escape(record.level),Escape(record.class),Escape(detectorZone),stamp},"|"))
                changed=true
            end
        end
        for key,record in pairs(previous) do
            if not current[key] then
                QueueFriendMessage(table.concat({"FSR",Escape(record.name),Escape(detectorZone),stamp},"|"))
                changed=true
            end
        end
    end
    if previous and BroadcastFriendPresence then
        for key,record in pairs(current) do BroadcastFriendPresence(previous[key],record) end
    end
    state.friendSnapshotIndex=current

    if not changed and #state.friendOutboundQueue == 0 then
        -- 内容未变化时只发一条轻量心跳，让监听方知道侦测端仍可通信。
        QueueFriendMessage("FHB|" .. tostring(stamp))
    end

    state.friendRecords = {}
    for _, info in ipairs(friends or {}) do
        state.friendRecords[#state.friendRecords + 1] = {
            name=info.name, online=info.connected and true or false, zone=info.area or UNKNOWN,
            level=info.level or UNKNOWN, class=info.class or UNKNOWN,
        }
    end
    state.friendDetectorZone = detectorZone
    state.friendSnapshotAt = stamp
    if RefreshFriendUI then RefreshFriendUI() end
    return changed
end

function FindCharacterFriendName(name)
    local prepared=Trim(name)
    if prepared=="" then return nil end
    local wanted=NormalizeTrackedName(prepared)
    local fallback
    for _,info in ipairs(ReadCharacterFriends()) do
        if NormalizeTrackedName(info.name)==wanted then return info.name end
        if not fallback and TrackedNameMatches(info.name,prepared) then fallback=info.name end
    end
    return fallback
end

function RemoveCharacterFriend(name)
    local prepared=Trim(name)
    if prepared=="" then return false,"invalid" end
    local actualName=FindCharacterFriendName(prepared)
    if not actualName then return false,"not_found" end
    local ok,result
    if C_FriendList and C_FriendList.RemoveFriend then ok,result=pcall(C_FriendList.RemoveFriend,actualName)
    elseif RemoveFriend then ok,result=pcall(RemoveFriend,actualName)
    else return false,"unsupported" end
    if not ok or result==false then return false,"api_failed",actualName end
    RequestFriendList()
    return true,nil,actualName
end

function FindTrackedFriend(friends, target)
    local fallback
    for _, info in ipairs(friends) do
        if NormalizeTrackedName(info.name) == NormalizeTrackedName(target) then return info end
        if not fallback and TrackedNameMatches(info.name, target) then fallback = info end
    end
    return fallback
end

function RequestFriendList()
    if C_FriendList and C_FriendList.ShowFriends then C_FriendList.ShowFriends()
    elseif ShowFriends then ShowFriends() end
end

function AddCharacterFriend(name)
    local prepared = Trim(name):gsub("－", "-"):gsub("—", "-"):gsub("%s+", "")
    if prepared=="" then return false,"invalid" end
    local ok,result
    if C_FriendList and C_FriendList.AddFriend then ok,result=pcall(C_FriendList.AddFriend,prepared)
    elseif AddFriend then ok,result=pcall(AddFriend,prepared)
    else return false,"unsupported" end
    if not ok or result==false then return false,"api_failed" end
    RequestFriendList()
    return true
end

function FriendCapacitySuffix()
    if not WowDetectorDB or WowDetectorDB.role ~= "detector" then return "" end
    if state.friendListFull then
        return string.format("  |cffff6666好友 %d/100（已满，暂停添加）|r", state.friendCount or 100)
    end
    return string.format("  |cff66ff99好友 %d/100|r", state.friendCount or 0)
end

function UpdateFriendCapacity(friends, forcedFull)
    if friends then
        state.friendCount = #friends
    elseif forcedFull then
        state.friendCount = math.max(100, state.friendCount or 0)
    end
    local full = forcedFull == true or state.friendCount >= 100
    state.friendListFull = full
    if full and not state.friendLimitWarned then
        state.friendLimitWarned = true
        Print("角色好友已达到100人上限，已暂停自动添加追踪目标；插件不会自动删除任何好友")
    elseif not full then
        state.friendLimitWarned = false
    end
    if RefreshConfigUI then RefreshConfigUI() end
end

ReconcileTrackedFriends = function(freshData)
    if not WowDetectorDB or WowDetectorDB.role ~= "detector" then return end
    if not freshData then
        state.friendRefreshSerial = (state.friendRefreshSerial or 0) + 1
        local serial = state.friendRefreshSerial
        RequestFriendList()
        C_Timer.After(1, function()
            if WowDetectorDB and WowDetectorDB.role == "detector" and serial == state.friendRefreshSerial then ReconcileTrackedFriends(true) end
        end)
        return
    end
    local friends = ReadCharacterFriends()
    UpdateFriendCapacity(friends)
    if state.friendListFull then return end
    if GetTime() - (state.friendAddLastAt or 0) < 10 then return end
    for _, target in ipairs(WowDetectorDB.queries.names) do
        local key = NormalizeTrackedName(target)
        if key ~= "" and not FindTrackedFriend(friends, target) and GetTime() - (state.friendAddAttempts[key] or -60) >= 60 then
            state.friendAddLastAt = GetTime()
            state.friendAddAttempts[key] = GetTime()
            local called = AddCharacterFriend(target)
            Print(called and ("正在自动添加追踪好友：" .. target) or ("无法调用好友添加接口：" .. target))
            break
        end
    end
end

PollTrackedFriends = function(freshData, forceFull)
    if not WowDetectorDB or WowDetectorDB.role ~= "detector" then return end
    if not freshData then
        state.friendRefreshSerial = (state.friendRefreshSerial or 0) + 1
        local serial = state.friendRefreshSerial
        RequestFriendList()
        C_Timer.After(1, function()
                if WowDetectorDB and WowDetectorDB.role == "detector" and serial == state.friendRefreshSerial then PollTrackedFriends(true, forceFull) end
        end)
        return
    end
    local friends = ReadCharacterFriends()
    UpdateFriendCapacity(friends)
    SendFriendSnapshot(friends, forceFull)
    for _, target in ipairs(WowDetectorDB.queries.names) do
        local key = NormalizeTrackedName(target)
        local info = FindTrackedFriend(friends, target)
        if info then
            local previous = state.trackedLast[key]
            local area = info.area and info.area ~= "" and info.area or (previous and previous.area) or UNKNOWN
            local status = info.connected and "1" or "0"
            local level = info.level and tostring(info.level) or UNKNOWN
            local class = info.class or UNKNOWN
            local signature = table.concat({ status, area, level, class }, "|")
            state.trackedLast[key] = { signature=signature, area=area, sentAt=GetTime() }
            if forceFull or not previous or previous.signature ~= signature then
                QueueFriendMessage(table.concat({ "TRACK", Escape(target), status, Escape(area), Escape(level), Escape(class), tostring(time()) }, "|"))
            end
        end
    end
end
