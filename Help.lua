WCED_HELP_TEXT = [=[|cffffd100Wow Classic Enemy Detector（WCED）|r

适用于《魔兽世界》经典怀旧服永久60级的好友情报、玩家查询、附近监控、战网中继与团队辅助插件。

|cffffd100入口说明|r

• 配：运行角色、战网对端、通信协议与配置权限。
• 团：本阵营玩家查询、手动职业筛选、自动邀请和团队管理。
• 侦：侦测方同步的好友在线状态、地区情报与上下线团队播报。
• WCED：按住鼠标拖动入口；单击打开本帮助。

|cffffd100首次配置|r

两个客户端必须使用不同战网账号、互为战网好友，并同时在线。一个角色设为侦测方，另一个设为监听方。监听方可保存多个侦测方，但同一时间只启用一个；通信兼容性按 Protocol version 判断。

侦测方同步角色好友快照，监听方通过“侦”查看好友在线状态与地区；对获得权限的好友还可执行远程删除。“敌”查询与追踪功能已移除。

|cffffd100友方查询与50人上限|r

地区查询固定为60级。首次返回不足50人时直接完成；达到50人时，请从查询按钮旁的职业菜单选择职业并再次点击查询。插件不会自动轮询职业，每次只查询和展示当前职业。查询按钮会显示冷却倒计时。暴雪要求每次 /who 请求来自真实鼠标或键盘操作。

|cffffd100友方查询与团队管理|r

友方页面提供保存团队、解散通知、解散团队、重组团队、批量邀请、团队调整和停止操作。团队调整会把离线、AFK 或不同区域的成员移动到 5-8 小队。自动邀请默认关闭，默认私聊口令为999。批量邀请会跳过自己、现有成员、重复玩家、30分钟内拒绝者、最近私聊者与临时黑名单玩家，并分批执行。

连续多次邀请后仍未入组的玩家进入邀请黑名单；默认1小时，可在友方页面查看原因、修改时长或清除全部。团队名单共享默认关闭，仅在当前小队或团队中与同样开启共享的 WCED 玩家交换，并按发送者保存。团队解散通知发送：“团队即将解散，稍后马上重组!!!”。

|cffffd100常用命令|r

/wd role detector|listener
/wd peer 昵称#数字
/wd query
/wd show
/wd hide
/wd status

|cffffd100重要限制|r

• 插件不能绕过暴雪的硬件点击与查询频率限制。
• /who 只能查询执行查询角色的同阵营在线玩家。
• 好友地区可能是服务器缓存快照，并非实时坐标。
• 插件无法查询任意敌方玩家所在位面。
• 战斗、邀请、转团等受保护操作仍受暴雪客户端规则约束。

项目 README 会随功能版本继续更新，本页作为游戏内快速说明。]=]

if WCED and not WCED.IS_CHINESE then
WCED_HELP_TEXT = [=[|cffffd100Wow Classic Enemy Detector (WCED)|r

Friend intel, player queries, nearby monitoring, Battle.net relay, and team tools for World of Warcraft Classic Era.

|cffffd100Launcher|r

• Use +/− to expand or collapse the tool menu (four tools per row).
• Set: role, Battle.net peers, protocol, and permissions.
• Friend: same-faction query, class filters, invites, and team tools.
• Intel: friend status and zone information synced by the detector, with per-friend online/offline group alerts.
• Watch: a compact faction/class summary from players recently exposed by target, mouseover, nameplates, or combat log. Records expire after 90 seconds.
• Drag WCED to move it; click WCED to open this help page.

|cffffd100Setup|r

The two clients must use different Battle.net accounts, be Battle.net friends, and be online together. Set one client to Detector and the other to Listener. Compatibility is based on Protocol version rather than the addon version.

|cffffd100Queries and the 50-player limit|r

Queries are fixed to level 60. If a result reaches 50 players, select a class and click Query again. WCED does not automate protected /who requests; each request still requires a real mouse or keyboard action.

|cffffd100Nearby enemy limitations|r

Watch is not a map scanner. It only lists enemy players the WoW client has recently exposed through visible units or combat events, and removes stale entries automatically.

|cffffd100Commands|r

/wd role detector|listener
/wd peer Name#1234
/wd query
/wd show | /wd hide | /wd status

Friend zones may be cached by the server. WCED cannot determine an arbitrary enemy player's layer or bypass Blizzard protected actions.]=]
end

function OpenAuthorWhisper()
    if ChatFrame_SendTell then ChatFrame_SendTell("璀璨小沐可")
    elseif ChatFrame_OpenChat then ChatFrame_OpenChat("/w 璀璨小沐可 ") end
end

function BuildHelpUI()
    local ui=CreateFrame("Frame","WCEDHelpWindow",UIParent,"BackdropTemplate")
    ui:SetSize(570,610); ui:SetPoint("CENTER"); ui:SetFrameStrata("DIALOG"); ui:SetClampedToScreen(true); ui:SetMovable(true); ui:EnableMouse(true)
    ui:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background",edgeFile="Interface/DialogFrame/UI-DialogBox-Border",edgeSize=24,insets={left=7,right=7,top=7,bottom=7}})
    ui:SetBackdropColor(0.025,0.025,0.025,0.97)
    local title=ui:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); title:SetPoint("TOP",0,-15); title:SetText("WCED 帮助  v"..VERSION)
    local author=CreateFrame("Button",nil,ui); author:SetSize(250,19); author:SetPoint("TOP",title,"BOTTOM",0,-6); author:SetText("Author: 璀璨小沐可 (哈霍兰)"); author:SetNormalFontObject("GameFontHighlightSmall"); author:GetFontString():SetTextColor(0.3,1,0.5); author:SetScript("OnClick",OpenAuthorWhisper)
    local divider=ui:CreateTexture(nil,"ARTWORK"); divider:SetPoint("TOPLEFT",20,-61); divider:SetPoint("TOPRIGHT",-20,-61); divider:SetHeight(1); divider:SetColorTexture(0.85,0.55,0.08,0.5)
    local close=CreateFrame("Button",nil,ui,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-5,-5)
    local drag=CreateFrame("Frame",nil,ui); drag:SetPoint("TOPLEFT",10,-8); drag:SetPoint("TOPRIGHT",-38,-8); drag:SetHeight(24); drag:EnableMouse(true); drag:RegisterForDrag("LeftButton"); drag:SetScript("OnDragStart",function() ui:StartMoving() end); drag:SetScript("OnDragStop",function() ui:StopMovingOrSizing() end)
    local scroll=CreateFrame("ScrollFrame","WCEDHelpScrollFrame",ui,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",22,-72); scroll:SetPoint("BOTTOMRIGHT",-34,18)
    local child=CreateFrame("Frame",nil,scroll); child:SetSize(500,1); scroll:SetScrollChild(child)
    local body=child:CreateFontString(nil,"OVERLAY","GameFontHighlight"); body:SetPoint("TOPLEFT",2,-2); body:SetWidth(492); body:SetJustifyH("LEFT"); body:SetJustifyV("TOP"); body:SetWordWrap(true); body:SetText(WCED_HELP_TEXT)
    child:SetHeight(math.max(500,body:GetStringHeight()+20))
    ui:EnableMouseWheel(true); ui:SetScript("OnMouseWheel",function(_,delta) scroll:SetVerticalScroll(math.max(0,scroll:GetVerticalScroll()-delta*40)) end)
    ui:Hide(); state.helpUI=ui
end
