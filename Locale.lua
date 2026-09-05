local _, addon = ...

local locale = GetLocale and GetLocale() or "enUS"
addon.IS_CHINESE = locale == "zhCN" or locale == "zhTW"

local en = {
    ["未知"]="Unknown", ["配置"]="Settings", ["查询"]="Query", ["添加"]="Add", ["删除"]="Delete", ["复制名称"]="Copy name",
    ["复制玩家名称"]="Copy player name", ["按 Ctrl+C 或 Command+C 复制玩家名称"]="Press Ctrl+C or Command+C to copy the player name",
    ["删除好友"]="Delete friend", ["添加好友"]="Add friend", ["确定从侦测方好友中删除 %s？"]="Remove %s from the detector's friends?",
    ["已发送好友删除请求：%s"]="Friend removal request sent: %s", ["已确认删除侦测方好友：%s"]="Detector friend removed: %s",
    ["侦测方好友删除失败：%s"]="Failed to remove detector friend: %s",
    ["输入要添加到侦测方的好友姓名"]="Enter the character name to add to the detector", ["确定添加"]="Add",
    ["请输入好友姓名"]="Enter a friend name", ["输入姓名并添加到侦测方角色好友列表。"]="Enter a name and add it to the detector's character friends.",
    ["已发送好友添加请求：%s"]="Friend add request sent: %s", ["已添加侦测方好友：%s"]="Detector friend added: %s",
    ["侦测方好友已存在：%s"]="Detector friend already exists: %s", ["侦测方好友添加失败：%s"]="Failed to add detector friend: %s",
    ["侦测方好友列表已满，无法添加"]="The detector's friend list is full", ["当前侦测方不可用，未发送添加请求"]="The detector is unavailable; the add request was not sent",
    ["正在添加侦测方好友：%s"]="Adding detector friend: %s", ["正在请求侦测方添加好友：%s"]="Requesting the detector to add friend: %s",
    ["好友添加请求正在处理中：%s"]="A friend add request is already in progress: %s", ["添加中…"]="Adding…",
    ["好友添加请求发送失败"]="Failed to send the friend add request", ["好友添加请求发送失败：%s"]="Failed to send the friend add request: %s", ["添加好友请求超时：%s，请确认侦测方已更新并在线"]="Friend add request timed out for %s; make sure the detector is updated and online",
    ["侦测方版本过低，暂不支持远程添加好友"]="The detector version is too old to support remote friend adding",
    ["对端当前不是侦测方，无法添加好友"]="The peer is not currently a detector and cannot add the friend",
    ["[好友添加] 已提交：%s"]="[Friend add] Submitted: %s", ["空姓名"]="empty name", ["未知发送者"]="unknown sender",
    ["[好友添加] 姓名为空，已拒绝"]="[Friend add] Empty name rejected", ["[好友添加] 好友已存在：%s"]="[Friend add] Friend already exists: %s",
    ["[好友添加] 好友列表已满"]="[Friend add] Friend list is full", ["[好友添加] 请求正在处理中：%s"]="[Friend add] Request already in progress: %s",
    ["[好友添加] 正在调用好友接口：%s"]="[Friend add] Calling friend API: %s", ["[好友添加] 好友接口调用失败：%s（%s）"]="[Friend add] Friend API failed: %s (%s)",
    ["[好友添加] 正在验证好友列表：%s（%d/3）"]="[Friend add] Verifying friend list: %s (%d/3)", ["[好友添加] 已在好友列表中确认：%s"]="[Friend add] Confirmed in friend list: %s",
    ["[好友添加] 三次验证均未找到：%s"]="[Friend add] Not found after three checks: %s", ["[好友添加] 收到请求但当前不是侦测方：%s"]="[Friend add] Request received, but this client is not a detector: %s",
    ["[好友添加] 收到监听方请求：%s（%s）"]="[Friend add] Listener request received: %s (%s)", ["[好友添加] 权限或来源校验失败：%s"]="[Friend add] Permission or sender validation failed: %s",
    ["[好友添加] 已回传结果：%s（%s）"]="[Friend add] Result sent: %s (%s)", ["[好友添加] 回传结果失败：%s"]="[Friend add] Failed to send result: %s",
    ["[好友添加] 请求已发送至：%s"]="[Friend add] Request sent to: %s", ["成功"]="success", ["失败"]="failure",
    ["侦测"]="Detector", ["监听"]="Listener", ["在线"]="Online", ["离线"]="Offline", ["上线"]="came online", ["下线"]="went offline", ["地区改变"]="changed zone",
    ["通信与角色配置"]="Connection and role settings", ["敌对玩家追踪"]="Enemy tracking",
    ["友方查询与团队管理"]="Friendly query and team tools", ["侦测方好友情报"]="Detector friend intel",
    ["附近敌人"]="Nearby enemies", ["展开功能菜单"]="Expand menu", ["折叠功能菜单"]="Collapse menu",
    ["联盟"]="Alliance", ["部落"]="Horde", ["阵营"]="Faction", ["职业"]="Class",
    ["等级"]="Level", ["最近发现"]="Last seen", ["附近没有发现敌方玩家"]="No nearby enemies detected",
    ["仅显示客户端近期实际发现的敌方玩家"]="Only enemies recently observed by the client are shown",
    ["记"]="K", ["击杀列表"]="Kill history", ["击杀记录"]="Kill History", ["记录：%d"]="Records: %d",
    ["搜索"]="Search", ["显示：%d / %d"]="Showing: %d / %d",
    ["胜利"]="Wins", ["辅助击杀"]="Assists", ["失败"]="Losses", ["最后战斗"]="Last combat",
    ["清除所有击杀记录"]="Clear all kill history", ["击杀记录已全部清除"]="Kill history cleared",
    ["永久清除列表中的所有胜利、辅助击杀和失败数据。"]="Permanently remove all wins, assists, and losses from the list.",
    ["原生好友姓名使用职业颜色"]="Color native friend names by class", ["好友职业染色"]="Friend class colors",
    ["原生好友与公会姓名使用职业颜色"]="Color native friend and guild names by class", ["好友与公会职业染色"]="Friend and guild class colors",
    ["原生名单姓名使用职业颜色"]="Color native list names by class", ["原生名单职业染色"]="Native list class colors",
    ["仅改变原生好友、公会和查询名单的字体颜色，不修改姓名文本。"]="Only changes the font color in native friend, guild, and Who lists; player-name text is left untouched.",
    ["在暴雪原生好友窗口中，按照玩家职业显示好友姓名颜色。"]="Color character names in Blizzard's Friends window according to class.",
    ["隐藏原生等级文本，在职业色姓名前显示绿色的 Lv.等级。"]="Hide the native level text and show the level in green before the class-colored name.",
    ["隐藏好友和公会名单的原生等级文本，在职业色姓名前显示绿色的 Lv.等级。"]="Hide native levels in the Friends and Guild lists, then show a green Lv.level before each class-colored name.",
    ["好友姓名前显示绿色的 Lv.等级；公会名单仅将姓名显示为职业颜色。"]="Show a green Lv.level before friend names; only color names by class in the Guild list.",
    ["好友姓名前显示绿色的 Lv.等级；公会和查询名单仅将姓名显示为职业颜色。"]="Show a green Lv.level before friend names; only color names by class in the Guild and Who lists.",
    ["清除"]="Clear", ["清除附近敌人记录"]="Clear nearby enemy records",
    ["附近监控"]="Nearby Monitor", ["团队"]="Group", ["当前没有加入公会"]="You are not in a guild",
    ["公"]="G", ["团"]="P", ["清"]="C", ["公会通报"]="Guild report", ["团队通报"]="Group report", ["清除监控"]="Clear monitor",
    ["监控统计已发送至公会频道"]="Monitor statistics sent to guild chat", ["监控统计已发送至团队频道"]="Monitor statistics sent to group chat",
    ["监控通报发送失败："]="Monitor report failed: ",
    ["清除全部监控记录；未再次发现的记录会在90秒后自动过期。"]="Clear all records. Players not seen again expire after 90 seconds.",
    ["将当前阵营与职业统计发送到团队或小队频道。"]="Send current faction and class statistics to raid or party chat.",
    ["将当前阵营与职业统计发送到公会频道。"]="Send current faction and class statistics to guild chat.",
    ["配"]="S", ["敌"]="E", ["友"]="F", ["侦"]="I", ["监"]="W", ["系"]="N",
    ["包"]="B", ["角"]="C", ["书"]="S", ["天"]="T", ["社"]="F", ["图"]="M", ["设"]="O", ["助"]="H",
    ["原生功能入口"]="Native shortcuts", ["打开背包"]="Open bags", ["角色信息"]="Character",
    ["法术书"]="Spellbook", ["天赋"]="Talents", ["天赋（右键任务）"]="Talents (right-click quests)", ["社交"]="Social",
    ["世界地图"]="World map", ["游戏菜单"]="Game menu", ["暴雪帮助"]="Blizzard help",
    ["原生入口接管"]="Native shortcuts", ["隐藏原生背包栏"]="Hide native bag bar", ["隐藏原生微型菜单"]="Hide native micro menu",
    ["使用 WCED 的“系 > 包”打开背包；取消勾选可恢复暴雪原生背包按钮。"]="Use WCED N > B to open bags; uncheck to restore Blizzard's bag buttons.",
    ["角色、法术书、天赋、任务等入口由 WCED“系”菜单接管；取消勾选可恢复原生菜单。"]="WCED's native menu replaces character, spellbook, talents, quests, and related shortcuts; uncheck to restore Blizzard's menu.",
    ["好友情报"]="Friend Intel", ["敌对玩家信息"]="Enemy Information", ["查询配置"]="Query Settings",
    ["请选择地区"]="Select zone", ["全部职业"]="All classes", ["按地区"]="By zone", ["按职业"]="By class",
    ["公会"]="Guild", ["玩家姓名"]="Player", ["地区"]="Zone", ["状态"]="Status", ["种族"]="Race", ["播报"]="Alert",
    ["一键播报"]="Alert all", ["一次选中或取消全部好友的上下线播报"]="Enable or disable online/offline alerts for all friends",
    ["一次选中或取消全部好友的上下线及地区改变播报"]="Enable or disable online, offline, and zone-change alerts for all friends",
    ["一次开启或关闭全部好友的上下线及地区改变播报"]="Enable or disable online, offline, and zone-change alerts for all friends",
    ["邀请状态"]="Invite status", ["最后地区"]="Last zone", ["自动播报"]="Auto alert",
    ["保存"]="Save", ["解散通知"]="Dismiss notice", ["解散"]="Dismiss", ["重组"]="Regroup",
    ["批量邀请"]="Batch invite", ["团队操作"]="Team tools", ["团队助理"]="Raid assistants",
    ["转团"]="Raid", ["将当前小队转换为团队；需要由队长点击。"]="Convert the current party to a raid; the party leader must click.",
    ["当前已经是团队"]="You are already in a raid", ["请先建立小队再转为团队"]="Form a party before converting to a raid",
    ["只有队长可以将小队转为团队"]="Only the party leader can convert the party to a raid",
    ["当前客户端不支持转团接口"]="This client does not support party-to-raid conversion", ["已请求将小队转为团队"]="Party-to-raid conversion requested",
    ["自由拾取"]="Free-for-all loot", ["自动邀请"]="Auto invite", ["开启"]="Enabled", ["口令"]="Code",
    ["共享团队信息"]="Share team info", ["黑名单"]="Blacklist", ["列表"]="List",
    ["过期时间"]="Expiry", ["小时"]="hours", ["私聊"]="Whisper", ["群发"]="Bulk", ["发送"]="Send",
    ["友方查询概览"]="Friendly query", ["敌情查询概览"]="Enemy query", ["敌方玩家追踪状态"]="Enemy tracking",
    ["查询时间"]="Query time", ["最后更新"]="Last update", ["总计"]="Total",
    ["可邀请"]="Available", ["等待加入"]="Pending", ["已加入团队"]="In your group",
    ["已加入其他团队"]="In another group", ["拒绝"]="Declined", ["未加入"]="Not joined",
    ["当前没有可用的侦测方"]="No detector is currently available",
    ["由侦测方查询并同步"]="Queried and synced by the detector",
    ["敌对玩家查询配置"]="Enemy query settings", ["公会过滤"]="Guild filter", ["玩家追踪"]="Player tracking",
    ["由侦测方执行并同步"]="Executed and synced by the detector",
    ["折叠"]="Collapse", ["展开"]="Expand", ["关闭"]="Close",
    ["当前"]="Current", ["人"]="players", ["尚未通信"]="Never", ["等待操作"]="Idle",
}

local classes = {
    ["战士"]="Warrior", ["圣骑士"]="Paladin", ["猎人"]="Hunter", ["潜行者"]="Rogue",
    ["牧师"]="Priest", ["萨满祭司"]="Shaman", ["法师"]="Mage", ["术士"]="Warlock", ["德鲁伊"]="Druid",
}
for key, value in pairs(classes) do en[key] = value end

local more = {
 ["侦测方"]="Detector",["敌方配置"]="Enemy Settings",["运行角色"]="Role",["对端战网ID"]="Peer BattleTag",
 ["允许配置"]="Allow settings",["关闭配置"]="Disable settings",["已启用"]="Active",["协议未响应"]="No protocol response",
 ["检测中…"]="Checking…",["完全兼容"]="Fully compatible",["兼容模式"]="Compatible mode",["协议不同"]="Protocol mismatch",
 ["团队播报"]="Team alert",["敌情统计"]="Enemy statistics",["无公会 / 未知"]="No guild / Unknown",
 ["关闭播报"]="Disable alert",["开启播报"]="Enable alert",["只读"]="Read only",
 ["一键私聊"]="Bulk whisper",["邀请黑名单"]="Invite blacklist",["邀请黑名单过期时间"]="Invite blacklist expiry",
 ["黑名单列表"]="Blacklist",["清除全部"]="Clear all",["进入原因"]="Reason",
 ["鼠标停留在玩家行可查看进入原因"]="Hover a player to view the reason",
 ["查看当前暂缓邀请的玩家、剩余时间和进入原因。"]="View blocked players, remaining time, and reason.",
 ["清除所有邀请黑名单和累计未加入次数。"]="Clear the invite blacklist and accumulated no-join counts.",
 ["以小时为单位，过期的玩家将被自动踢出邀请黑名单"]="In hours. Expired players are removed from the invite blacklist automatically.",
 ["向当前友方查询结果中的玩家分批发送下方文本。"]="Send the text below to the current friendly results in batches.",
 ["密语所有查询玩家，不包含本团队成员"]="Whisper all queried players except members of your current group.",
 ["记录当前队伍或团队成员，供稍后重组使用。"]="Save current group members for later regrouping.",
 ["向团队通知频道发送即将解散并重组的提示。"]="Send a warning that the group will be dismissed and regrouped.",
 ["通知后移除其他成员；仅团长可用。"]="Remove other members after warning; leader only.",
 ["重新邀请最近一次保存的团队成员。"]="Reinvite the most recently saved team.",
 ["分批邀请当前友方查询结果，并显示每人的处理状态。"]="Invite the current friendly results in batches and show each status.",
 ["把离线、AFK 或不同区域成员调整到5-8小队。"]="Move offline, AFK, or different-zone members to groups 5–8.",
 ["勾选后，转为团队时将所有成员提升为团队助理，后续进组成员也会自动提升。"]="Promote all members and future joiners to raid assistant.",
 ["勾选后，在队伍或团队建立时自动将拾取方式设为自由拾取。"]="Set loot to Free-for-All when a group is formed.",
 ["开启后，收到完全匹配右侧口令的私聊时自动邀请发送者。"]="Invite senders whose whisper exactly matches the code.",
 ["与其他WCED共享团队信息"]="Share team information with other WCED users",
 ["当前没有可用的侦测方"]="No detector is currently available",
 ["当前侦测方离线或无法通信，相关功能暂时无法使用"]="The detector is offline or unreachable; related features are unavailable.",
 ["当前没有启用的侦测方，敌情与好友情报暂时无法使用"]="No active detector; enemy and friend intel are unavailable.",
 ["请输入战网ID，例如：昵称#1234"]="Enter a BattleTag, for example Name#1234",
 ["该战网ID已经存在"]="This BattleTag already exists",["查询中..."]="Querying...",
 ["请选择地区"]="Select zone",["留空时显示全部查询结果；添加后仅显示指定公会"]="Leave empty for all results; add guilds to filter.",
 ["追踪指定敌方玩家的在线状态与最后地区"]="Track enemy online status and last known zone",
 ["侦测方运行状态"]="Detector status",["好友动态：每10秒检查"]="Friend status: checked every 10 seconds",
 ["当前查询：等待手动触发"]="Current query: waiting for manual input",["协议检测中"]="Checking protocol",
 ["尚未添加对端战网ID"]="No peer BattleTag added",["发送失败"]="Send failed",
 ["无法取得对端的在线WoW游戏账号"]="Unable to find the peer's online WoW account",
 ["当前客户端没有可用的战网插件消息接口"]="No Battle.net addon-message API is available on this client",
 ["查询配置过多，无法通过战网同步"]="Too many query settings to sync over Battle.net",
 ["已从对端同步最新查询配置"]="Latest query settings synced from peer",
 ["已拒绝未授权监听端写入配置"]="Rejected an unauthorized listener settings update",
 ["上次查询达到50人上限，请先从职业菜单选择一个职业"]="The last query reached 50 players; select a class first",
 ["上一项地区查询仍在等待服务器返回"]="The previous zone query is still waiting for the server",
 ["当前页面不能发起查询"]="Queries cannot be started from this page",
 ["请先从地区下拉菜单选择查询地图"]="Select a zone from the zone menu first",
 ["查询达到50人上限，请从职业菜单选择职业后再次查询"]="The result reached 50 players; select a class and query again",
 ["未收到新的查询事件，已按当前可读取名单结束本次查询"]="No new query event arrived; completed using the currently readable list",
 ["当前不在团队或小队中"]="You are not in a party or raid",["只有监听方可以播报统计"]="Only the listener can broadcast statistics",
 ["该条件已经存在"]="That condition already exists",["没有找到该条件"]="Condition not found",
 ["地区已经内置，请在主窗口查询时选择"]="Zones are built in; select one in the main window",
 ["临时邀请黑名单已清除"]="Temporary invite blacklist cleared",["共享团队信息需要先加入小队或团队"]="Join a party or raid before sharing team information",
 ["只有团长或助理可以调整小队"]="Only the raid leader or an assistant can adjust groups",
 ["只有队长可以解散团队"]="Only the leader can dismiss the group",["团队解散操作已执行"]="Group dismissal completed",
 ["团队调整仅可在团队中使用"]="Group adjustment is available only in a raid",["战斗中不能调整小队"]="Groups cannot be adjusted in combat",
 ["当前客户端不支持团队小队调整接口"]="This client does not support raid subgroup adjustment",
 ["没有可邀请的玩家"]="No players are available to invite",["邀请任务正在进行，请等待当前任务完成"]="An invite task is already running",
 ["正在转换为团队…"]="Converting to raid…",["等待首批玩家进入队伍…"]="Waiting for the first invited players…",
 ["首批邀请等待超时"]="Initial invite wait timed out",["请先输入私聊内容"]="Enter a whisper message first",
 ["当前查询结果中没有可私聊的玩家"]="No players in the current results can be whispered",
 ["一键私聊正在发送，请等待完成"]="Bulk whisper is already running",["角色好友已达到100人上限，已暂停自动添加追踪目标；插件不会自动删除任何好友"]="The 100-friend limit was reached; tracked friends are paused and no friends will be removed automatically",
 }
for key,value in pairs(more) do en[key]=value end

local patterns = {
 {"^查询记录：(%d+)$","Query records: %1"}, {"^追踪目标：(%d+)$","Tracked: %1"},
 {"^WCED 帮助%s+v(.+)$","WCED Help  v%1"}, {"^好友情报%s+(.+)$","Friend Intel  %1"},
 {"^总计%s+(%d+)$","Total  %1"}, {"^当前%s+(%d+)%s+人$","Current: %1 players"},
 {"^剩余%s+(%d+)%s+分钟$","%1 min remaining"}, {"^查询冷却中，请等待(%d+)秒$","Query cooldown: %1s"},
 {"^冷却%s+(%d+)s$","Cooldown %1s"}, {"^角色已设为%s+(.+)$","Role set to %1"},
 {"^正在自动添加追踪好友：(.+)$","Adding tracked friend: %1"},
 {"^已保存团队成员：(%d+)人$","Saved team members: %1"}, {"^处理中：(%d+)/(%d+)$","Processing: %1/%2"},
 {"^完成：邀请(%d+)，跳过(%d+)$","Done: %1 invited, %2 skipped"},
}

addon.ZONE_EN = {
 ["东部王国"]="Eastern Kingdoms",["卡利姆多"]="Kalimdor",["主城"]="Capital Cities",["地下城与团队"]="Dungeons and Raids",["战场"]="Battlegrounds",
 ["艾尔文森林"]="Elwynn Forest",["西部荒野"]="Westfall",["赤脊山"]="Redridge Mountains",["暮色森林"]="Duskwood",["荆棘谷"]="Stranglethorn Vale",
 ["逆风小径"]="Deadwind Pass",["悲伤沼泽"]="Swamp of Sorrows",["诅咒之地"]="Blasted Lands",["燃烧平原"]="Burning Steppes",["灼热峡谷"]="Searing Gorge",
 ["荒芜之地"]="Badlands",["洛克莫丹"]="Loch Modan",["丹莫罗"]="Dun Morogh",["湿地"]="Wetlands",["阿拉希高地"]="Arathi Highlands",
 ["希尔斯布莱德丘陵"]="Hillsbrad Foothills",["奥特兰克山脉"]="Alterac Mountains",["辛特兰"]="The Hinterlands",["银松森林"]="Silverpine Forest",
 ["提瑞斯法林地"]="Tirisfal Glades",["西瘟疫之地"]="Western Plaguelands",["东瘟疫之地"]="Eastern Plaguelands",
 ["杜隆塔尔"]="Durotar",["莫高雷"]="Mulgore",["泰达希尔"]="Teldrassil",["黑海岸"]="Darkshore",["灰谷"]="Ashenvale",["石爪山脉"]="Stonetalon Mountains",
 ["贫瘠之地"]="The Barrens",["千针石林"]="Thousand Needles",["凄凉之地"]="Desolace",["菲拉斯"]="Feralas",["尘泥沼泽"]="Dustwallow Marsh",
 ["塔纳利斯"]="Tanaris",["安戈洛环形山"]="Un'Goro Crater",["希利苏斯"]="Silithus",["费伍德森林"]="Felwood",["冬泉谷"]="Winterspring",["艾萨拉"]="Azshara",["月光林地"]="Moonglade",
 ["暴风城"]="Stormwind City",["铁炉堡"]="Ironforge",["达纳苏斯"]="Darnassus",["奥格瑞玛"]="Orgrimmar",["雷霆崖"]="Thunder Bluff",["幽暗城"]="Undercity",
 ["怒焰裂谷"]="Ragefire Chasm",["哀嚎洞穴"]="Wailing Caverns",["死亡矿井"]="The Deadmines",["影牙城堡"]="Shadowfang Keep",["黑暗深渊"]="Blackfathom Deeps",
 ["暴风城监狱"]="The Stockade",["诺莫瑞根"]="Gnomeregan",["剃刀沼泽"]="Razorfen Kraul",["血色修道院"]="Scarlet Monastery",["剃刀高地"]="Razorfen Downs",
 ["奥达曼"]="Uldaman",["祖尔法拉克"]="Zul'Farrak",["玛拉顿"]="Maraudon",["阿塔哈卡神庙"]="The Temple of Atal'Hakkar",["黑石深渊"]="Blackrock Depths",
 ["黑石塔"]="Blackrock Spire",["厄运之槌"]="Dire Maul",["通灵学院"]="Scholomance",["斯坦索姆"]="Stratholme",["熔火之心"]="Molten Core",
 ["黑翼之巢"]="Blackwing Lair",["奥妮克希亚的巢穴"]="Onyxia's Lair",["祖尔格拉布"]="Zul'Gurub",["安其拉废墟"]="Ruins of Ahn'Qiraj",
 ["安其拉神殿"]="Temple of Ahn'Qiraj",["纳克萨玛斯"]="Naxxramas",["战歌峡谷"]="Warsong Gulch",["阿拉希盆地"]="Arathi Basin",["奥特兰克山谷"]="Alterac Valley",
}
for key,value in pairs(addon.ZONE_EN) do en[key]=value end

function addon.L(text, ...)
    local value = tostring(text or "")
    if not addon.IS_CHINESE then
        value = en[value] or value
        if not en[tostring(text or "")] then
            for _,rule in ipairs(patterns) do local translated,count=value:gsub(rule[1],rule[2]); if count>0 then value=translated; break end end
        end
    end
    if select("#", ...) > 0 then return string.format(value, ...) end
    return value
end

L = addon.L
UNKNOWN = L("未知")

function addon.LocalizeFrame(frame)
    if addon.IS_CHINESE or not frame then return end
    local seen = {}
    local function Visit(object)
        if not object or seen[object] then return end
        seen[object] = true
        if object.GetText and object.SetText then
            local ok, text = pcall(object.GetText, object)
            if ok and text then
                local translated = addon.L(text)
                if translated ~= text then pcall(object.SetText, object, translated) end
            end
        end
        if object.GetRegions then
            local regions = { object:GetRegions() }
            for _, region in ipairs(regions) do Visit(region) end
        end
        if object.GetChildren then
            local children = { object:GetChildren() }
            for _, child in ipairs(children) do Visit(child) end
        end
    end
    Visit(frame)
end
