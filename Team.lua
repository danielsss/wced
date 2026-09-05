local function InvitePlayer(name)
    if C_PartyInfo and C_PartyInfo.InviteUnit then C_PartyInfo.InviteUnit(name)
    elseif InviteUnit then InviteUnit(name) end
end

local function NameFromFormattedMessage(message,formatText)
    if not message or not formatText or not tostring(formatText):find("%%s") then return nil end
    local pattern=tostring(formatText):gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])","%%%1"):gsub("%%%%s","(.+)")
    return message:match("^"..pattern.."$")
end

function HandleInviteErrorMessage(message)
    if not message then return false end
    local name=NameFromFormattedMessage(message,ERR_ALREADY_IN_GROUP_S)
    local lower=tostring(message):lower()
    local already=name~=nil or lower:find("already in a group",1,true) or lower:find("already in group",1,true)
        or tostring(message):find("已经加入了一个队伍",1,true) or tostring(message):find("已经在一个队伍",1,true)
        or tostring(message):find("已经加入其他队伍",1,true)
    if not already then return false end
    local matchedKey
    if name then matchedKey=NormalizeTrackedName(name) end
    if not matchedKey or state.inviteStatuses[matchedKey]~="waiting" then
        for key,status in pairs(state.inviteStatuses) do
            if status=="waiting" and lower:find(ShortName(key):lower(),1,true) then matchedKey=key; break end
        end
    end
    if not matchedKey then return false end
    state.inviteStatuses[matchedKey]="othergroup"
    WowDetectorDB.team.inviteHistory[matchedKey]=nil
    if RefreshUI then RefreshUI() end
    if RefreshTeamUI then RefreshTeamUI() end
    return true
end

local function ConvertGroupToRaid()
    if IsInGroup() and not IsInRaid() then
        if C_PartyInfo and C_PartyInfo.ConvertToRaid then C_PartyInfo.ConvertToRaid()
        elseif ConvertToRaid then ConvertToRaid() end
        C_Timer.After(0.8,function() if ApplyTeamPreferences then ApplyTeamPreferences() end end)
    end
end

function ConvertCurrentGroupToRaid()
    if IsInRaid() then Print(L("当前已经是团队")); return end
    if not IsInGroup() then Print(L("请先建立小队再转为团队")); return end
    if not UnitIsGroupLeader("player") then Print(L("只有队长可以将小队转为团队")); return end
    if not ((C_PartyInfo and C_PartyInfo.ConvertToRaid) or ConvertToRaid) then Print(L("当前客户端不支持转团接口")); return end
    ConvertGroupToRaid()
    Print(L("已请求将小队转为团队"))
end

function ApplyTeamPreferences()
    if not WowDetectorDB or not WowDetectorDB.team or not IsInGroup() then return end
    if not UnitIsGroupLeader("player") then return end
    if WowDetectorDB.team.freeForAllLoot then
        local method=GetLootMethod and GetLootMethod() or nil
        if method~="freeforall" then
            if C_PartyInfo and C_PartyInfo.SetLootMethod then C_PartyInfo.SetLootMethod(0)
            elseif SetLootMethod then SetLootMethod("freeforall") end
        end
    end
    if not WowDetectorDB.team.promoteAllAssistants or not IsInRaid() then return end
    state.assistantPromotionPending=state.assistantPromotionPending or {}
    local delayIndex=0
    for index=1,GetNumGroupMembers() do
        local name,rank=GetRaidRosterInfo(index)
        if name and tonumber(rank)==0 and not TrackedNameMatches(name,UnitName("player") or "") then
            local key=NormalizeTrackedName(name)
            if not state.assistantPromotionPending[key] then
                state.assistantPromotionPending[key]=true; delayIndex=delayIndex+1
                C_Timer.After(0.1*delayIndex,function()
                    state.assistantPromotionPending[key]=nil
                    if not IsInRaid() or not UnitIsGroupLeader("player") or not WowDetectorDB.team.promoteAllAssistants then return end
                    for current=1,GetNumGroupMembers() do
                        local currentName,currentRank=GetRaidRosterInfo(current)
                        if currentName and TrackedNameMatches(currentName,name) and tonumber(currentRank)==0 then
                            if C_PartyInfo and C_PartyInfo.PromoteToAssistant then C_PartyInfo.PromoteToAssistant(currentName)
                            elseif PromoteToAssistant then PromoteToAssistant(currentName) end
                            break
                        end
                    end
                end)
            end
        end
    end
end

function CurrentGroupMembers()
    local members = { [NormalizeTrackedName(UnitName("player") or "")] = true }
    if IsInRaid() then
        for index=1,GetNumGroupMembers() do local name=GetRaidRosterInfo(index); if name then members[NormalizeTrackedName(name)]=true end end
    elseif IsInGroup() then
        for index=1,GetNumSubgroupMembers() do local name=UnitName("party"..index); if name then members[NormalizeTrackedName(name)]=true end end
    end
    return members
end

function IsCurrentGroupMember(name)
    if not name or Trim(name)=="" then return false end
    for member in pairs(CurrentGroupMembers()) do
        if TrackedNameMatches(member,name) then return true end
    end
    return false
end

function PurgeExpiredInviteBlacklist()
    local now=time()
    for key,untilTime in pairs(WowDetectorDB.team.noJoinUntil or {}) do
        if tonumber(untilTime) and untilTime<=now then
            WowDetectorDB.team.noJoinUntil[key]=nil
            WowDetectorDB.team.noJoinReasons[key]=nil
            WowDetectorDB.team.inviteHistory[key]=nil
        end
    end
end

function SaveCurrentTeam()
    local saved, seen = {}, {}
    if IsInRaid() then
        for index=1,GetNumGroupMembers() do
            local name=GetRaidRosterInfo(index); local key=NormalizeTrackedName(name)
            if name and key~="" and key~=NormalizeTrackedName(UnitName("player")) and not seen[key] then saved[#saved+1]=name; seen[key]=true end
        end
    elseif IsInGroup() then
        for index=1,GetNumSubgroupMembers() do
            local name=UnitName("party"..index); local key=NormalizeTrackedName(name)
            if name and key~="" and not seen[key] then saved[#saved+1]=name; seen[key]=true end
        end
    end
    WowDetectorDB.team.savedMembers=saved
    Print(string.format("已保存团队成员：%d人",#saved))
    if WowDetectorDB.team.shareEnabled then ShareSavedTeam() end
    if RefreshTeamUI then RefreshTeamUI() end
end

function SendTeamDismissNotice()
    local channel=IsInRaid() and "RAID_WARNING" or (IsInGroup() and "PARTY" or nil)
    if not channel then Print("当前不在队伍中") return end
    SendChatMessage("团队即将解散，稍后马上重组!!!",channel)
end

function DismissCurrentTeam()
    if not IsInGroup() then Print("当前不在队伍中") return end
    if not UnitIsGroupLeader("player") then Print("只有队长可以解散团队") return end
    SendTeamDismissNotice()
    local names={}
    if IsInRaid() then for i=1,GetNumGroupMembers() do local n=GetRaidRosterInfo(i); if n and ShortName(n)~=ShortName(UnitName("player")) then names[#names+1]=n end end
    else for i=1,GetNumSubgroupMembers() do local n=UnitName("party"..i); if n then names[#names+1]=n end end end
    for _,name in ipairs(names) do if UninviteUnit then UninviteUnit(name) elseif C_PartyInfo and C_PartyInfo.UninviteUnit then C_PartyInfo.UninviteUnit(name) end end
    Print("团队解散操作已执行")
end

local function EligibleInviteNames(source)
    PurgeExpiredInviteBlacklist()
    local now=time(); local group=CurrentGroupMembers(); local seen={}; local result={}; local skipped=0
    for _,name in ipairs(source or {}) do
        name=Trim(name); local key=NormalizeTrackedName(name)
        if group[key] then state.inviteStatuses[key]="joined" end
        if name=="" or key==NormalizeTrackedName(UnitName("player")) or seen[key] or group[key]
            or (WowDetectorDB.team.declinedUntil[key] or 0)>now
            or (WowDetectorDB.team.recentWhispers[key] or 0)>now-600
            or (WowDetectorDB.team.noJoinUntil[key] or 0)>now then skipped=skipped+1
        else seen[key]=true; result[#result+1]=name end
    end
    return result,skipped
end

local function CheckInviteOutcome(name,sentAt)
    C_Timer.After(300,function()
        if not WowDetectorDB then return end
        local key=NormalizeTrackedName(name); if CurrentGroupMembers()[key] then WowDetectorDB.team.inviteHistory[key]=nil; state.inviteStatuses[key]="joined"; if RefreshUI then RefreshUI() end; return end
        local history=WowDetectorDB.team.inviteHistory[key] or { misses=0 }
        if history.sentAt~=sentAt then return end
        history.misses=(history.misses or 0)+1; WowDetectorDB.team.inviteHistory[key]=history
        if history.misses>=3 then
            WowDetectorDB.team.noJoinUntil[key]=time()+math.max(900,tonumber(WowDetectorDB.team.noJoinDuration) or 3600)
            WowDetectorDB.team.noJoinReasons[key]="连续3次邀请后，5分钟内仍未加入队伍"
        end
        state.inviteStatuses[key]="failed"; if RefreshUI then RefreshUI() end
    end)
end

function ProcessTeamInviteBatch()
    local invite=state.teamInvite
    if not invite.running then return end
    if invite.index>#invite.queue then invite.running=false; invite.status=string.format("完成：邀请%d，跳过%d",invite.invited,invite.skipped); if RefreshTeamUI then RefreshTeamUI() end; return end
    if #invite.queue>4 and invite.index>1 and not IsInGroup() then
        invite.waitingSince=invite.waitingSince or GetTime()
        if GetTime()-invite.waitingSince>=30 then
            invite.running=false; invite.status="首批邀请等待超时"
            if RefreshTeamUI then RefreshTeamUI() end
            return
        end
        invite.status="等待首批玩家进入队伍…"; if RefreshTeamUI then RefreshTeamUI() end; C_Timer.After(2,ProcessTeamInviteBatch); return
    end
    if #invite.queue>4 and IsInGroup() and not IsInRaid() then
        ConvertGroupToRaid(); invite.status="正在转换为团队…"; if RefreshTeamUI then RefreshTeamUI() end; C_Timer.After(1,ProcessTeamInviteBatch); return
    end
    local finish=math.min(#invite.queue,invite.index+2)
    for index=invite.index,finish do
        local name=invite.queue[index]; InvitePlayer(name); invite.invited=invite.invited+1
        local key=NormalizeTrackedName(name); local sentAt=time(); WowDetectorDB.team.inviteHistory[key]={sentAt=sentAt,misses=(WowDetectorDB.team.inviteHistory[key] and WowDetectorDB.team.inviteHistory[key].misses) or 0}
        state.inviteStatuses[key]="waiting"
        CheckInviteOutcome(name,sentAt)
    end
    invite.index=finish+1; invite.status=string.format("处理中：%d/%d",finish,#invite.queue)
    if RefreshTeamUI then RefreshTeamUI() end
    C_Timer.After(2,ProcessTeamInviteBatch)
end

function StartTeamInvite(source,label)
    if state.teamInvite.running then Print("邀请任务正在进行，请等待当前任务完成") return end
    local names,skipped=EligibleInviteNames(source)
    if #names==0 then Print("没有可邀请的玩家") return end
    state.teamInvite={running=true,queue=names,index=1,invited=0,skipped=skipped,status=(label or "批量邀请").."：准备中",waitingSince=nil}
    ProcessTeamInviteBatch()
end

function StartFriendlyBatchInvite()
    wipe(state.inviteStatuses)
    local names={}; for _,record in pairs(state.friendlyRecords) do
        local visible=not state.friendlyDisplayClass or ResolveClassFile(record.class,record.classFile)==ResolveClassFile(state.friendlyDisplayClass)
        if visible and not TrackedNameMatches(record.name,UnitName("player") or "") then names[#names+1]=record.name; state.inviteStatuses[NormalizeTrackedName(record.name)]="ready" end
    end
    for key in pairs(CurrentGroupMembers()) do state.inviteStatuses[key]="joined" end
    StartTeamInvite(names,"查询结果")
    if RefreshUI then RefreshUI() end
end

function RegroupSavedTeam() StartTeamInvite(WowDetectorDB.team.savedMembers,"重组团队") end

function ClearTemporaryInviteBlacklist()
    wipe(WowDetectorDB.team.noJoinUntil); wipe(WowDetectorDB.team.noJoinReasons); wipe(WowDetectorDB.team.inviteHistory)
    Print("临时邀请黑名单已清除")
    if RefreshTeamUI then RefreshTeamUI() end
end

function ProcessFriendlyWhisperBatch()
    local batch=state.friendlyWhisper
    if not batch or not batch.running then return end
    local target=batch.queue[batch.index]
    if not target then
        batch.running=false
        Print(string.format("一键私聊完成：已发送%d人，跳过队伍成员%d人",batch.sent or 0,batch.skipped or 0))
        if RefreshTeamUI then RefreshTeamUI() end
        return
    end
    if IsCurrentGroupMember(target) then
        batch.skipped=(batch.skipped or 0)+1
        batch.index=batch.index+1
        if RefreshTeamUI then RefreshTeamUI() end
        C_Timer.After(0.05,ProcessFriendlyWhisperBatch)
        return
    end
    SendChatMessage(batch.message,"WHISPER",nil,target)
    WowDetectorDB.team.recentWhispers[NormalizeTrackedName(target)]=time()
    batch.sent=(batch.sent or 0)+1
    batch.index=batch.index+1
    if RefreshTeamUI then RefreshTeamUI() end
    C_Timer.After(0.8,ProcessFriendlyWhisperBatch)
end

function StartFriendlyWhisperBatch(message)
    message=Trim(message)
    if message=="" then Print("请先输入私聊内容") return end
    if state.friendlyWhisper and state.friendlyWhisper.running then Print("一键私聊正在发送，请等待完成") return end
    local names,seen={},{}
    local group=CurrentGroupMembers()
    local skipped=0
    for _,record in pairs(state.friendlyRecords or {}) do
        local visible=not state.friendlyDisplayClass or ResolveClassFile(record.class,record.classFile)==ResolveClassFile(state.friendlyDisplayClass)
        local key=NormalizeTrackedName(record.name)
        if visible and key~="" and not seen[key] and not TrackedNameMatches(record.name,UnitName("player") or "") then
            seen[key]=true
            local inGroup=group[key] or IsCurrentGroupMember(record.name)
            if inGroup then skipped=skipped+1
            else names[#names+1]=record.name end
        end
    end
    table.sort(names,function(a,b) return tostring(a)<tostring(b) end)
    if #names==0 then
        if skipped>0 then Print(string.format("当前查询结果均为队伍成员，已跳过%d人",skipped))
        else Print("当前查询结果中没有可私聊的玩家") end
        return
    end
    state.friendlyWhisper={running=true,queue=names,index=1,message=message,sent=0,skipped=skipped}
    Print(string.format("一键私聊开始：待发送%d人，已跳过队伍成员%d人",#names,skipped))
    ProcessFriendlyWhisperBatch()
end

local function TeamShareChannel()
    if IsInRaid() then return "RAID" end
    if IsInGroup() then return "PARTY" end
end

local function QueueTeamShareMessage(message, channel)
    state.teamShareOutboundQueue[#state.teamShareOutboundQueue+1]={message=message,channel=channel}
end

function ProcessTeamShareQueue()
    if #state.teamShareOutboundQueue==0 then return end
    local item=table.remove(state.teamShareOutboundQueue,1)
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then C_ChatInfo.SendAddonMessage(PREFIX,item.message,item.channel) end
end

function ShareSavedTeam()
    if not WowDetectorDB.team.shareEnabled then return end
    local channel=TeamShareChannel()
    if not channel then Print("共享团队信息需要先加入小队或团队") return end
    local members=WowDetectorDB.team.savedMembers or {}
    local serial=tostring(time()).."-"..tostring(math.random(1000,9999))
    QueueTeamShareMessage(table.concat({"TLB",serial,tostring(time()),tostring(#members)},"|"),channel)
    for index,name in ipairs(members) do
        QueueTeamShareMessage(table.concat({"TLI",serial,tostring(index),Escape(name)},"|"),channel)
    end
    QueueTeamShareMessage("TLE|"..serial,channel)
    Print(string.format("已排队共享团队信息：%d人",#members))
end

function ReceiveSharedTeamMessage(message,sender)
    if not WowDetectorDB.team.shareEnabled or not sender or NormalizeTrackedName(sender)==NormalizeTrackedName(UnitName("player")) then return end
    local serial,stamp,count=message:match("^TLB|([^|]+)|(%d+)|(%d+)$")
    if serial then
        state.incomingTeamShares[NormalizeTrackedName(sender)]={serial=serial,time=tonumber(stamp) or time(),expected=tonumber(count) or 0,members={}}
        return
    end
    local itemSerial,index,name=message:match("^TLI|([^|]+)|(%d+)|(.+)$")
    if itemSerial then
        local incoming=state.incomingTeamShares[NormalizeTrackedName(sender)]
        if incoming and incoming.serial==itemSerial then incoming.members[tonumber(index) or (#incoming.members+1)]=Unescape(name) end
        return
    end
    local endSerial=message:match("^TLE|([^|]+)$")
    if endSerial then
        local key=NormalizeTrackedName(sender); local incoming=state.incomingTeamShares[key]
        if not incoming or incoming.serial~=endSerial then return end
        local members={}
        for index=1,incoming.expected do if incoming.members[index] then members[#members+1]=incoming.members[index] end end
        WowDetectorDB.team.sharedLists[key]={sender=sender,members=members,updatedAt=incoming.time,complete=#members==incoming.expected}
        state.incomingTeamShares[key]=nil
    end
end

function AdjustRaidGroups()
    if not IsInRaid() then Print("团队调整仅可在团队中使用") return end
    if not UnitIsGroupLeader("player") and not (UnitIsGroupAssistant and UnitIsGroupAssistant("player")) then Print("只有团长或助理可以调整小队") return end
    if InCombatLockdown and InCombatLockdown() then Print("战斗中不能调整小队") return end
    if not SetRaidSubgroup then Print("当前客户端不支持团队小队调整接口") return end
    local localZone=GetRealZoneText and GetRealZoneText() or ""
    local occupancy={[5]=0,[6]=0,[7]=0,[8]=0}; local candidates={}
    for index=1,GetNumGroupMembers() do
        local name,_,subgroup,_,_,_,zone,online=GetRaidRosterInfo(index)
        if subgroup and occupancy[subgroup]~=nil then occupancy[subgroup]=occupancy[subgroup]+1 end
        local unit="raid"..index; local afk=UnitIsAFK and UnitIsAFK(unit)
        local away=zone and zone~="" and localZone~="" and zone~=localZone
        if name and subgroup and subgroup<5 and (online==false or afk or away) then
            candidates[#candidates+1]={index=index,name=name,offline=online==false,afk=afk,away=away}
        end
    end
    table.sort(candidates,function(a,b)
        local ap=(a.offline and 4 or 0)+(a.afk and 2 or 0)+(a.away and 1 or 0)
        local bp=(b.offline and 4 or 0)+(b.afk and 2 or 0)+(b.away and 1 or 0)
        return ap>bp
    end)
    local moved=0
    for _,entry in ipairs(candidates) do
        local destination
        for group=5,8 do if occupancy[group]<5 then destination=group; break end end
        if not destination then break end
        SetRaidSubgroup(entry.index,destination); occupancy[destination]=occupancy[destination]+1; moved=moved+1
    end
    Print(string.format("团队调整完成：已将%d名离线、AFK或不同区域成员移至5-8组",moved))
end

function HandleAutoInviteWhisper(message,sender)
    if not WowDetectorDB.autoInvite.enabled or Trim(message)~=Trim(WowDetectorDB.autoInvite.code) then return end
    local key=NormalizeTrackedName(sender)
    state.autoInviteLast=state.autoInviteLast or {}
    if CurrentGroupMembers()[key] or (WowDetectorDB.team.declinedUntil[key] or 0)>time() or GetTime()-(state.autoInviteLast[key] or -30)<10 then return end
    state.autoInviteLast[key]=GetTime()
    InvitePlayer(sender)
end

function HandleInviteSystemMessage(message)
    local name=message and (message:match("^(.+)拒绝了你邀请其加入队伍的请求") or message:match("^(.+) declines your group invitation"))
    if name then local key=NormalizeTrackedName(name); WowDetectorDB.team.declinedUntil[key]=time()+1800; state.inviteStatuses[key]="declined"; if RefreshTeamUI then RefreshTeamUI() end; if RefreshUI then RefreshUI() end end
end
