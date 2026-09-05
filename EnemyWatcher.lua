local _, addon = ...

local DEFAULT_TTL = 90
state.nearbyEnemies = state.nearbyEnemies or {}

local function WatchTTL()
    local value = WowDetectorDB and WowDetectorDB.enemyWatcher and tonumber(WowDetectorDB.enemyWatcher.expireSeconds)
    return math.max(15, math.min(600, value or DEFAULT_TTL))
end

local function PlayerFaction() return UnitFactionGroup("player") or "Alliance" end
local function EnemyFaction() return PlayerFaction() == "Alliance" and "Horde" or "Alliance" end
local function FactionLabel(faction) return L(faction == "Alliance" and "联盟" or "部落") end
local function FactionClasses(faction)
    return faction=="Alliance" and {"MAGE","HUNTER","PRIEST","PALADIN","WARRIOR","WARLOCK","ROGUE","DRUID"}
        or {"MAGE","HUNTER","PRIEST","SHAMAN","WARRIOR","WARLOCK","ROGUE","DRUID"}
end

local function ClassShort(classFile)
    local zh={MAGE="法",HUNTER="猎",PRIEST="牧",PALADIN="骑",SHAMAN="萨",WARRIOR="战",WARLOCK="术",ROGUE="贼",DRUID="德"}
    local en={MAGE="M",HUNTER="H",PRIEST="P",PALADIN="Pa",SHAMAN="S",WARRIOR="W",WARLOCK="Wl",ROGUE="R",DRUID="D"}
    return (addon.IS_CHINESE and zh or en)[classFile]
end

local function AddPlayer(name,guid,className,classFile,level,faction)
    if not name or name=="" or guid==UnitGUID("player") then return end
    local key=guid or NormalizeTrackedName(name); local old=state.nearbyEnemies[key] or {}
    state.nearbyEnemies[key]={key=key,name=name,class=className or old.class or UNKNOWN,classFile=classFile or old.classFile,
        level=(level and level>0) and level or old.level,faction=faction or old.faction,lastSeen=GetTime()}
    if RefreshEnemyWatcherUI then RefreshEnemyWatcherUI() end
end

local function ObserveUnit(unit)
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) or UnitIsUnit(unit,"player") then return end
    local faction=UnitFactionGroup(unit); if faction~="Alliance" and faction~="Horde" then return end
    local name=GetUnitName and GetUnitName(unit,true) or UnitName(unit); local className,classFile=UnitClass(unit)
    AddPlayer(name,UnitGUID(unit),className,classFile,UnitLevel(unit),faction)
end

local function ObserveCombatLog()
    local _,_,_,sourceGUID,sourceName,sourceFlags,_,destGUID,destName,destFlags=CombatLogGetCurrentEventInfo()
    local hostile,friendly,player=COMBATLOG_OBJECT_REACTION_HOSTILE or 0,COMBATLOG_OBJECT_REACTION_FRIENDLY or 0,COMBATLOG_OBJECT_TYPE_PLAYER or 0
    local band=bit and bit.band or bit32 and bit32.band; if not band then return end
    local function Capture(guid,name,flags)
        if not guid or not name or guid==UnitGUID("player") or band(flags or 0,player)==0 then return end
        local faction
        if band(flags or 0,hostile)~=0 then faction=EnemyFaction() elseif band(flags or 0,friendly)~=0 then faction=PlayerFaction() else return end
        local localizedClass,classFile,_,_,_,localizedName=GetPlayerInfoByGUID(guid)
        AddPlayer(localizedName or name,guid,localizedClass,classFile,nil,faction)
    end
    Capture(sourceGUID,sourceName,sourceFlags); Capture(destGUID,destName,destFlags)
end

local function CurrentStats()
    local now=GetTime(); local stats={Alliance={total=0,classes={}},Horde={total=0,classes={}}}
    for key,record in pairs(state.nearbyEnemies) do
        if now-(record.lastSeen or 0)>WatchTTL() then state.nearbyEnemies[key]=nil
        elseif stats[record.faction] then local bucket=stats[record.faction]; bucket.total=bucket.total+1
            if record.classFile then bucket.classes[record.classFile]=(bucket.classes[record.classFile] or 0)+1 end end
    end
    return stats
end

local function FactionSummary(faction,bucket)
    local headingColor=faction==EnemyFaction() and "|cffff5555" or "|cffffffff"
    local heading=string.format("%s>%s<|r |cff55ff77[%d]|r",headingColor,FactionLabel(faction),bucket.total)
    local pieces={}
    for _,classFile in ipairs(FactionClasses(faction)) do
        local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
        local prefix=color and string.format("|cff%02x%02x%02x",math.floor(color.r*255+0.5),math.floor(color.g*255+0.5),math.floor(color.b*255+0.5)) or "|cffffffff"
        pieces[#pieces+1]=string.format("%s%s:%d|r",prefix,ClassShort(classFile),(bucket.classes[classFile] or 0))
    end
    return heading,table.concat(pieces," ")
end

local function BroadcastMessages()
    local stats=CurrentStats(); local result={}
    for _,faction in ipairs({"Alliance","Horde"}) do local bucket=stats[faction]; local pieces={}
        for _,classFile in ipairs(FactionClasses(faction)) do pieces[#pieces+1]=ClassShort(classFile)..":"..(bucket.classes[classFile] or 0) end
        result[#result+1]=string.format(">%s< [%d] %s",FactionLabel(faction),bucket.total,table.concat(pieces," ")) end
    return result
end

local function SendWatcherReport(channel)
    if channel=="GUILD" and not IsInGuild() then Print(L("当前没有加入公会")); return end
    if channel=="GROUP" then
        if LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then channel="INSTANCE_CHAT"
        elseif IsInRaid() then channel="RAID"
        elseif IsInGroup() then channel="PARTY"
        else Print(L("当前不在团队或小队中")); return end
    end
    for _,message in ipairs(BroadcastMessages()) do
        local ok,reason=pcall(SendChatMessage,message,channel)
        if not ok then Print(L("监控通报发送失败：")..tostring(reason or UNKNOWN)); return end
    end
    Print(channel=="GUILD" and L("监控统计已发送至公会频道") or L("监控统计已发送至团队频道"))
end

function RefreshEnemyWatcherUI()
    local ui=state.enemyWatcherUI; if not ui or not ui:IsShown() then return end
    local stats=CurrentStats(); local eh,ec=FactionSummary(EnemyFaction(),stats[EnemyFaction()]); local oh,oc=FactionSummary(PlayerFaction(),stats[PlayerFaction()])
    ui.summary:SetText(string.format("|cff4aa3ff%s|r[%d]  |cff888888｜|r  |cffff5555%s|r[%d]",
        FactionLabel("Alliance"),stats.Alliance.total,FactionLabel("Horde"),stats.Horde.total))
    ui.enemyHeading:SetText(eh); ui.enemyClasses:SetText(ec); ui.ownHeading:SetText(oh); ui.ownClasses:SetText(oc); addon.LocalizeFrame(ui)
end

local function WatchButton(parent,text,width,x,tooltip,click)
    local button=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate"); button:SetSize(width,18); button:SetPoint("TOPRIGHT",parent,"TOPRIGHT",x,-7); button:SetText(L(text)); button:SetNormalFontObject("GameFontNormalSmall")
    local titles={ ["公"]="公会通报",["团"]="团队通报",["清"]="清除监控" }
    button:SetScript("OnClick",click); button:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText(L(titles[text] or text)); GameTooltip:AddLine(L(tooltip),1,1,1,true); GameTooltip:Show() end); button:SetScript("OnLeave",function() GameTooltip:Hide() end)
    return button
end

function BuildEnemyWatcherUI()
    if state.enemyWatcherUI then return state.enemyWatcherUI end
    local saved=WowDetectorDB.enemyWatcher or defaults.enemyWatcher
    local ui=CreateFrame("Frame","WCEDEnemyWatcher",UIParent,"BackdropTemplate"); ui:SetSize(336,128); ui:SetPoint(saved.point,UIParent,saved.point,saved.x,saved.y)
    ui:SetMovable(true); ui:EnableMouse(true); ui:SetClampedToScreen(true); ui:RegisterForDrag("LeftButton"); ui:SetScript("OnDragStart",ui.StartMoving)
    ui:SetScript("OnDragStop",function(self) self:StopMovingOrSizing(); local p,_,_,x,y=self:GetPoint(); saved.point,saved.x,saved.y=p,x,y end)
    ui:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background",edgeFile="Interface/Tooltips/UI-Tooltip-Border",edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
    ui:SetBackdropColor(0.025,0.02,0.035,0.94); ui:SetBackdropBorderColor(0.58,0.25,0.82,1)
    local title=ui:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); title:SetPoint("TOPLEFT",12,-10); title:SetTextColor(0.78,0.45,1); title:SetText(L("附近监控"))
    local close=CreateFrame("Button",nil,ui,"UIPanelCloseButton"); close:SetSize(20,20); close:SetPoint("TOPRIGHT",-4,-5)
    local collapse=CreateFrame("Button",nil,ui,"UIPanelButtonTemplate"); collapse:SetSize(20,20); collapse:SetPoint("TOPRIGHT",-27,-5); collapse:SetNormalFontObject("GameFontNormalLarge")
    local clear=WatchButton(ui,"清",28,-50,"清除全部监控记录；未再次发现的记录会在90秒后自动过期。",function() wipe(state.nearbyEnemies); RefreshEnemyWatcherUI() end)
    local team=WatchButton(ui,"团",28,-80,"将当前阵营与职业统计发送到团队或小队频道。",function() SendWatcherReport("GROUP") end)
    local guild=WatchButton(ui,"公",28,-110,"将当前阵营与职业统计发送到公会频道。",function() SendWatcherReport("GUILD") end)
    local line=ui:CreateTexture(nil,"ARTWORK"); line:SetPoint("TOPLEFT",10,-34); line:SetPoint("TOPRIGHT",-10,-34); line:SetHeight(1); line:SetColorTexture(0.58,0.25,0.82,0.5)
    ui.enemyHeading=ui:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); ui.enemyHeading:SetPoint("TOPLEFT",12,-42)
    ui.enemyClasses=ui:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); ui.enemyClasses:SetPoint("TOPLEFT",12,-60); ui.enemyClasses:SetWidth(312); ui.enemyClasses:SetJustifyH("LEFT"); ui.enemyClasses:SetWordWrap(false)
    ui.ownHeading=ui:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); ui.ownHeading:SetPoint("TOPLEFT",12,-82)
    ui.ownClasses=ui:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); ui.ownClasses:SetPoint("TOPLEFT",12,-100); ui.ownClasses:SetWidth(312); ui.ownClasses:SetJustifyH("LEFT"); ui.ownClasses:SetWordWrap(false)
    ui.summary=ui:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); ui.summary:SetPoint("LEFT",10,0); ui.summary:SetPoint("RIGHT",collapse,"LEFT",-6,0); ui.summary:SetJustifyH("CENTER")
    local function SetCollapsed(value)
        saved.collapsed=value and true or false; ui:SetSize(value and 250 or 336,value and 32 or 128); collapse:SetText(value and "+" or "−")
        collapse:ClearAllPoints(); collapse:SetPoint("TOPRIGHT",value and -4 or -27,-5)
        title:SetShown(not value); close:SetShown(not value); clear:SetShown(not value); team:SetShown(not value); guild:SetShown(not value); line:SetShown(not value)
        ui.enemyHeading:SetShown(not value); ui.enemyClasses:SetShown(not value); ui.ownHeading:SetShown(not value); ui.ownClasses:SetShown(not value); ui.summary:SetShown(value)
        collapse.tooltip=value and L("展开") or L("折叠")
    end
    collapse:SetScript("OnClick",function() SetCollapsed(not saved.collapsed); RefreshEnemyWatcherUI() end)
    collapse:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText(self.tooltip); GameTooltip:Show() end); collapse:SetScript("OnLeave",function() GameTooltip:Hide() end)
    ui.SetCollapsed=SetCollapsed; SetCollapsed(saved.collapsed==true)
    state.enemyWatcherUI=ui; ui:Hide(); return ui
end

function ToggleEnemyWatcher()
    local ui=BuildEnemyWatcherUI(); ui:SetShown(not ui:IsShown()); if ui:IsShown() then ObserveUnit("target"); ObserveUnit("mouseover"); RefreshEnemyWatcherUI() end
end

local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_TARGET_CHANGED","UPDATE_MOUSEOVER_UNIT","NAME_PLATE_UNIT_ADDED","COMBAT_LOG_EVENT_UNFILTERED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function(_,event,...)
    if event=="PLAYER_TARGET_CHANGED" then ObserveUnit("target") elseif event=="UPDATE_MOUSEOVER_UNIT" then ObserveUnit("mouseover")
    elseif event=="NAME_PLATE_UNIT_ADDED" then ObserveUnit(...) elseif event=="COMBAT_LOG_EVENT_UNFILTERED" then ObserveCombatLog() end
end)
C_Timer.NewTicker(1,function() if state.enemyWatcherUI and state.enemyWatcherUI:IsShown() then RefreshEnemyWatcherUI() end end)
