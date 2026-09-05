local _, addon = ...

state.spyMetadata = state.spyMetadata or {}
state.spyDamageToEnemies = state.spyDamageToEnemies or {}
state.spyAttackers = state.spyAttackers or {}
state.spyOutcomeAt = state.spyOutcomeAt or {}
state.spySortKey = state.spySortKey or "lastTime"
if state.spySortAscending == nil then state.spySortAscending = false end

local band = bit and bit.band or bit32 and bit32.band
local PLAYER_FLAG = COMBATLOG_OBJECT_TYPE_PLAYER or 0
local HOSTILE_FLAG = COMBATLOG_OBJECT_REACTION_HOSTILE or 0
local MINE_FLAG = COMBATLOG_OBJECT_AFFILIATION_MINE or 0
local PARTY_FLAG = COMBATLOG_OBJECT_AFFILIATION_PARTY or 0
local RAID_FLAG = COMBATLOG_OBJECT_AFFILIATION_RAID or 0
local function HasFlag(flags, flag) return band and band(flags or 0, flag) ~= 0 end
local function IsPlayer(flags) return HasFlag(flags, PLAYER_FLAG) end
local function IsHostilePlayer(flags) return IsPlayer(flags) and HasFlag(flags, HOSTILE_FLAG) end
local function IsMine(flags) return HasFlag(flags, MINE_FLAG) end
local function IsGroup(flags) return HasFlag(flags, PARTY_FLAG) or HasFlag(flags, RAID_FLAG) end

local function NormalizeSpyCount(value)
    local number = tonumber(value) or 0
    if number <= 0 then return 0 end
    return math.floor(number)
end

local function CurrentSpyCharacterKey()
    local name,realm
    if UnitFullName then name,realm=UnitFullName("player") end
    if not name or name=="" then name=UnitName and UnitName("player") end
    if not realm or realm=="" then realm=GetRealmName and GetRealmName() end
    if not name or name=="" then return nil end
    return NormalizeTrackedName(name.."-"..(realm or ""))
end

local function SpyRecords()
    if not WowDetectorDB then return {} end
    WowDetectorDB.spy = WowDetectorDB.spy or { recordsByCharacter = {}, recordsMigrationVersion = 0, point = "CENTER", x = 0, y = 20 }
    local saved=WowDetectorDB.spy
    saved.recordsByCharacter=type(saved.recordsByCharacter)=="table" and saved.recordsByCharacter or {}
    local characterKey=CurrentSpyCharacterKey()
    if not characterKey then
        state.pendingSpyRecords=state.pendingSpyRecords or {}
        return state.pendingSpyRecords
    end
    if tonumber(saved.recordsMigrationVersion or 0)<1 then
        local legacy=type(saved.records)=="table" and saved.records or nil
        local characterRecords=saved.recordsByCharacter[characterKey]
        if type(characterRecords)~="table" then characterRecords={}; saved.recordsByCharacter[characterKey]=characterRecords end
        if legacy then
            for key,record in pairs(legacy) do if characterRecords[key]==nil then characterRecords[key]=record end end
        end
        saved.records=nil
        saved.recordsMigrationVersion=1
    end
    saved.recordsByCharacter[characterKey]=type(saved.recordsByCharacter[characterKey])=="table" and saved.recordsByCharacter[characterKey] or {}
    local records=saved.recordsByCharacter[characterKey]
    -- 旧存档可能含有 IEEE 负零；统一迁移为非负整数，避免界面显示为 “-0”。
    for _, record in pairs(records) do
        if type(record) == "table" then
            record.wins = NormalizeSpyCount(record.wins)
            record.assists = NormalizeSpyCount(record.assists)
            record.losses = NormalizeSpyCount(record.losses)
        end
    end
    return records
end

local function Metadata(guid, name)
    local cached = state.spyMetadata[guid] or {}
    local localizedClass, classFile, _, _, _, apiName, realm = GetPlayerInfoByGUID and GetPlayerInfoByGUID(guid)
    local fullName = apiName or name or cached.name
    if fullName and realm and realm ~= "" and not fullName:find("-", 1, true) then fullName = fullName .. "-" .. realm end
    return { name=fullName or UNKNOWN, class=localizedClass or cached.class or UNKNOWN,
        classFile=classFile or cached.classFile, level=cached.level }
end

local function FindRecord(guid, name)
    local records=SpyRecords()
    if guid and records[guid] then return records[guid],guid end
    local wanted=NormalizeTrackedName(name)
    for key,record in pairs(records) do if wanted~="" and NormalizeTrackedName(record.name)==wanted then return record,key end end
end

local function TouchExistingRecord(guid,name)
    local record=FindRecord(guid,name); if record then record.lastTime=time() end
end

local function RecordOutcome(guid,name,outcome,dedupeKey)
    if not guid or not name or not outcome then return end
    local now=GetTime(); dedupeKey=dedupeKey or guid
    local previous=state.spyOutcomeAt[dedupeKey]
    local previousAt=type(previous)=="table" and previous.at or tonumber(previous)
    if previousAt and now-previousAt<5 then return false end
    state.spyOutcomeAt[dedupeKey]={at=now,outcome=outcome}
    local records=SpyRecords(); local record,oldKey=FindRecord(guid,name); local info=Metadata(guid,name)
    if not record then record={wins=0,assists=0,losses=0}; records[guid]=record
    elseif oldKey~=guid then records[oldKey]=nil; records[guid]=record end
    record.name=info.name; record.class=info.class; record.classFile=info.classFile
    record.level=info.level or record.level or 0
    record.wins=NormalizeSpyCount(record.wins); record.assists=NormalizeSpyCount(record.assists); record.losses=NormalizeSpyCount(record.losses)
    record[outcome]=record[outcome]+1; record.lastTime=time()
    if RefreshSpyUI then RefreshSpyUI() end
    return true
end

local function ObserveSpyUnit(unit)
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) or not UnitCanAttack("player",unit) then return end
    local guid=UnitGUID(unit); if not guid then return end
    local class,classFile=UnitClass(unit)
    state.spyMetadata[guid]={name=GetUnitName and GetUnitName(unit,true) or UnitName(unit),class=class,classFile=classFile,level=UnitLevel(unit)}
    local record=FindRecord(guid,state.spyMetadata[guid].name)
    if record then
        record.name=state.spyMetadata[guid].name or record.name
        record.class=class or record.class; record.classFile=classFile or record.classFile
        if UnitLevel(unit) and UnitLevel(unit)>0 then record.level=UnitLevel(unit) end
    end
end

local damageEvents={SWING_DAMAGE=true,RANGE_DAMAGE=true,SPELL_DAMAGE=true,SPELL_PERIODIC_DAMAGE=true,DAMAGE_SHIELD=true,DAMAGE_SPLIT=true}

local function DamageOverkill(subevent,...)
    local payload={...}
    if subevent=="SWING_DAMAGE" then return tonumber(payload[2]) end
    return tonumber(payload[5])
end

local function HandleSpyCombatLog()
    if not band then return end
    local eventInfo={CombatLogGetCurrentEventInfo()}
    local subevent=eventInfo[2]; local sourceGUID,sourceName,sourceFlags=eventInfo[4],eventInfo[5],eventInfo[6]
    local destGUID,destName,destFlags=eventInfo[8],eventInfo[9],eventInfo[10]
    local playerGUID=UnitGUID("player"); local now=GetTime()
    if damageEvents[subevent] then
        local overkill=DamageOverkill(subevent,unpack(eventInfo,12))
        if IsMine(sourceFlags) and IsHostilePlayer(destFlags) then
            state.spyDamageToEnemies[destGUID]={at=now,name=destName}; TouchExistingRecord(destGUID,destName)
            if overkill and overkill>=0 then RecordOutcome(destGUID,destName,"wins",destGUID); state.spyDamageToEnemies[destGUID]=nil end
        elseif IsGroup(sourceFlags) and IsHostilePlayer(destFlags) then
            local participation=state.spyDamageToEnemies[destGUID]
            if overkill and overkill>=0 and participation and now-participation.at<=30 then RecordOutcome(destGUID,destName,"assists",destGUID); state.spyDamageToEnemies[destGUID]=nil end
        elseif destGUID==playerGUID and IsHostilePlayer(sourceFlags) then
            state.spyAttackers[sourceGUID]={at=now,name=sourceName}; TouchExistingRecord(sourceGUID,sourceName)
            if overkill and overkill>=0 then RecordOutcome(sourceGUID,sourceName,"losses",playerGUID); wipe(state.spyAttackers) end
        end
        return
    end
    if subevent=="PARTY_KILL" and IsHostilePlayer(destFlags) then
        local participation=state.spyDamageToEnemies[destGUID]
        if IsMine(sourceFlags) then RecordOutcome(destGUID,destName,"wins",destGUID)
        elseif IsGroup(sourceFlags) and participation and now-participation.at<=30 then RecordOutcome(destGUID,destName,"assists",destGUID) end
        state.spyDamageToEnemies[destGUID]=nil; return
    end
    if subevent=="PARTY_KILL" and destGUID==playerGUID and IsHostilePlayer(sourceFlags) then
        RecordOutcome(sourceGUID,sourceName,"losses",playerGUID); state.spyLastDeathAt=now; wipe(state.spyAttackers); return
    end
    if subevent=="UNIT_DIED" and destGUID==playerGUID then wipe(state.spyAttackers) end
end

local function SortedSpyRecords()
    local result={}; local search=Trim(state.spySearch or ""):lower()
    for _,record in pairs(SpyRecords()) do
        local haystack=(tostring(record.name or "").." "..tostring(record.class or "")):lower()
        if search=="" or haystack:find(search,1,true) then result[#result+1]=record end
    end
    local sortKey=state.spySortKey or "lastTime"
    local ascending=state.spySortAscending==true
    local textKeys={name=true,class=true}
    local countKeys={wins=true,assists=true,losses=true}
    table.sort(result,function(a,b)
        local valueA,valueB=a[sortKey],b[sortKey]
        if textKeys[sortKey] then
            valueA=tostring(valueA or ""):lower(); valueB=tostring(valueB or ""):lower()
        elseif countKeys[sortKey] then
            valueA=NormalizeSpyCount(valueA); valueB=NormalizeSpyCount(valueB)
        else
            valueA=tonumber(valueA) or 0; valueB=tonumber(valueB) or 0
        end
        if valueA~=valueB then
            if ascending then return valueA<valueB end
            return valueA>valueB
        end
        if (a.lastTime or 0)~=(b.lastTime or 0) then return (a.lastTime or 0)>(b.lastTime or 0) end
        return tostring(a.name or "")<tostring(b.name or "")
    end)
    return result
end

function RefreshSpyUI()
    local ui=state.spyUI; if not ui or not ui:IsShown() then return end
    local records=SortedSpyRecords(); local total=0; for _ in pairs(SpyRecords()) do total=total+1 end; local maxOffset=math.max(0,#records-#ui.rows)
    state.spyOffset=math.max(0,math.min(state.spyOffset or 0,maxOffset)); ui.scroll:SetMinMaxValues(0,maxOffset); ui.scroll:SetValue(state.spyOffset); ui.scroll:SetShown(maxOffset>0)
    ui.count:SetText(string.format(L("显示：%d / %d"),#records,total))
    for _,header in ipairs(ui.sortHeaders or {}) do
        local arrow=header.key==state.spySortKey and (state.spySortAscending and " ↑" or " ↓") or ""
        header.text:SetText(L(header.label)..arrow)
    end
    for index,row in ipairs(ui.rows) do
        local record=records[(state.spyOffset or 0)+index]
        if record then
            row.name:SetText(record.name or UNKNOWN); local color=record.classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[record.classFile]
            row.name:SetTextColor(color and color.r or 1,color and color.g or 1,color and color.b or 1); row.class:SetText(record.class or UNKNOWN)
            row.level:SetText((record.level and record.level>0) and tostring(record.level) or "-"); row.wins:SetText(tostring(NormalizeSpyCount(record.wins))); row.assists:SetText(tostring(NormalizeSpyCount(record.assists))); row.losses:SetText(tostring(NormalizeSpyCount(record.losses))); row.time:SetText(record.lastTime and date("%m-%d %H:%M",record.lastTime) or "-"); row:Show()
        else row:Hide() end
    end
    addon.LocalizeFrame(ui)
end

function BuildSpyUI()
    if state.spyUI then return state.spyUI end
    local saved=WowDetectorDB.spy or defaults.spy
    local ui=CreateFrame("Frame","WCEDSpyWindow",UIParent,"BackdropTemplate"); ui:SetSize(720,390); ui:SetPoint(saved.point,UIParent,saved.point,saved.x,saved.y)
    ui:SetMovable(true); ui:EnableMouse(true); ui:SetClampedToScreen(true); ui:RegisterForDrag("LeftButton"); ui:SetScript("OnDragStart",ui.StartMoving)
    ui:SetScript("OnDragStop",function(self) self:StopMovingOrSizing(); local p,_,_,x,y=self:GetPoint(); saved.point,saved.x,saved.y=p,x,y end)
    ui:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background",edgeFile="Interface/Tooltips/UI-Tooltip-Border",edgeSize=13,insets={left=3,right=3,top=3,bottom=3}}); ui:SetBackdropColor(0.025,0.02,0.035,0.96); ui:SetBackdropBorderColor(0.58,0.25,0.82,1)
    local title=ui:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); title:SetPoint("TOPLEFT",16,-14); title:SetText(L("击杀记录")); title:SetTextColor(0.78,0.45,1)
    ui.count=ui:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); ui.count:SetPoint("TOPRIGHT",-48,-19)
    local close=CreateFrame("Button",nil,ui,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-4,-4)
    local searchLabel=ui:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); searchLabel:SetPoint("TOPLEFT",16,-52); searchLabel:SetText(L("搜索"))
    ui.search=CreateFrame("EditBox",nil,ui,"InputBoxTemplate"); ui.search:SetSize(250,22); ui.search:SetPoint("LEFT",searchLabel,"RIGHT",10,0); ui.search:SetAutoFocus(false); ui.search:SetMaxLetters(48)
    ui.search:SetScript("OnTextChanged",function(self) state.spySearch=Trim(self:GetText() or ""); state.spyOffset=0; RefreshSpyUI() end)
    ui.search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    local clear=CreateFrame("Button",nil,ui,"UIPanelButtonTemplate"); clear:SetSize(78,22); clear:SetPoint("TOPRIGHT",-16,-49); clear:SetText(L("清除全部"))
    clear:SetScript("OnClick",function()
        wipe(SpyRecords()); wipe(state.spyDamageToEnemies); wipe(state.spyAttackers); wipe(state.spyOutcomeAt)
        state.spyOffset=0; RefreshSpyUI(); Print(L("击杀记录已全部清除"))
    end)
    clear:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText(L("清除所有击杀记录")); GameTooltip:AddLine(L("永久清除列表中的所有胜利、辅助击杀和失败数据。"),1,1,1,true); GameTooltip:Show() end)
    clear:SetScript("OnLeave",function() GameTooltip:Hide() end)
    local line=ui:CreateTexture(nil,"ARTWORK"); line:SetPoint("TOPLEFT",12,-81); line:SetPoint("TOPRIGHT",-12,-81); line:SetHeight(1); line:SetColorTexture(0.58,0.25,0.82,0.55)
    local columns={{"玩家姓名",16,190,"LEFT","name",true},{"职业",206,100,"LEFT","class",true},{"等级",306,55,"CENTER","level",false},{"胜利",361,55,"CENTER","wins",false},{"辅助击杀",416,80,"CENTER","assists",false},{"失败",496,55,"CENTER","losses",false},{"最后战斗",551,145,"CENTER","lastTime",false}}
    ui.sortHeaders={}
    for _,column in ipairs(columns) do
        local button=CreateFrame("Button",nil,ui); button:SetPoint("TOPLEFT",column[2],-90); button:SetSize(column[3],18)
        local text=button:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); text:SetAllPoints(); text:SetJustifyH(column[4]); text:SetJustifyV("MIDDLE"); text:SetWordWrap(false)
        button:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight","ADD")
        button.label=column[1]; button.key=column[5]; button.text=text; button.defaultAscending=column[6]
        button:SetScript("OnClick",function(self)
            if state.spySortKey==self.key then state.spySortAscending=not state.spySortAscending
            else state.spySortKey=self.key; state.spySortAscending=self.defaultAscending end
            state.spyOffset=0; RefreshSpyUI()
        end)
        ui.sortHeaders[#ui.sortHeaders+1]=button
    end
    ui.rows={}
    for index=1,11 do
        local row=CreateFrame("Frame",nil,ui); row:SetPoint("TOPLEFT",12,-113-(index-1)*23); row:SetPoint("TOPRIGHT",-30,-113-(index-1)*23); row:SetHeight(22)
        local bg=row:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(1,1,1,index%2==0 and 0.055 or 0.022)
        local function Cell(x,width,justify) local text=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); text:SetPoint("LEFT",x,0); text:SetSize(width,20); text:SetJustifyH(justify or "LEFT"); text:SetJustifyV("MIDDLE"); text:SetWordWrap(false); return text end
        row.name=Cell(3,190); row.class=Cell(193,100); row.level=Cell(293,55,"CENTER"); row.wins=Cell(348,55,"CENTER"); row.assists=Cell(403,80,"CENTER"); row.losses=Cell(483,55,"CENTER"); row.time=Cell(538,135,"CENTER"); ui.rows[index]=row
    end
    ui.scroll=CreateFrame("Slider","WCEDSpyScrollBar",ui,"UIPanelScrollBarTemplate"); ui.scroll:SetPoint("TOPRIGHT",-8,-114); ui.scroll:SetPoint("BOTTOMRIGHT",-8,20); ui.scroll:SetValueStep(1); ui.scroll:SetObeyStepOnDrag(true)
    ui.scroll:SetScript("OnValueChanged",function(_,value) state.spyOffset=math.floor(value+0.5); RefreshSpyUI() end); ui.scroll:Hide()
    ui:EnableMouseWheel(true); ui:SetScript("OnMouseWheel",function(_,delta) state.spyOffset=(state.spyOffset or 0)+(delta<0 and 1 or -1); RefreshSpyUI() end)
    state.spyUI=ui; ui:Hide(); return ui
end

function ToggleSpyWindow()
    local ui=BuildSpyUI(); ui:SetShown(not ui:IsShown()); if ui:IsShown() then ObserveSpyUnit("target"); ObserveSpyUnit("mouseover"); RefreshSpyUI() end
end

local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_TARGET_CHANGED","UPDATE_MOUSEOVER_UNIT","NAME_PLATE_UNIT_ADDED","COMBAT_LOG_EVENT_UNFILTERED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function(_,event,...)
    if event=="PLAYER_TARGET_CHANGED" then ObserveSpyUnit("target") elseif event=="UPDATE_MOUSEOVER_UNIT" then ObserveSpyUnit("mouseover")
    elseif event=="NAME_PLATE_UNIT_ADDED" then ObserveSpyUnit(...) elseif event=="COMBAT_LOG_EVENT_UNFILTERED" then HandleSpyCombatLog() end
end)
