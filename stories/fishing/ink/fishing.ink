// 从 fishing 原文整理。所有“模拟完成”只用于剧情审阅，不执行钓鱼与建设。
VAR fragments = 0
VAR codex_complete = false
VAR ahai_done = false
VAR market_done = false
VAR preview_reward_coins = 0
VAR ending = ""
VAR clue_log_1 = false
VAR clue_log_2 = false
VAR clue_fisher_tale = false
VAR clue_last_note = false
VAR clue_salvage = false
-> opening

=== opening ===
# source: main.gd::_show_story_intro
《雾海传说》剧情审阅版
这里保留原游戏任务与对白。按钮模拟目标达成，不代表已在游戏里完成这些动作。
三年前那个晚上，灯塔的灯突然灭了。第二天一早，深海就被雾吞了，再没散过。
守塔的老林说，灯里藏着这片海最大的秘密——探照灯修好的那天，雾就会散。可他不肯再多说一个字。
我得先活下去。钓鱼，卖钱，攒家当……然后去深海，把真相捞出来。
+ [开始序章教学] -> tutorial

=== tutorial ===
序章 · 雾海
玩法目标：开船（W 前进，A/D 转向）
+ [模拟完成此目标]
-
玩法目标：开船到小地图金色标记处
+ [模拟完成此目标]
-
玩法目标：按 E 抛竿
+ [模拟完成此目标]
-
玩法目标：钓到 3 条鱼
+ [模拟完成此目标]
-
玩法目标：靠近码头，按 E 进入菜单
+ [模拟完成此目标]
-
玩法目标：在码头卖掉鱼
+ [模拟完成此目标]
-
玩法目标：用卖鱼收入升级鱼竿、卷线器或鱼饵，再出海试钓
+ [模拟完成此目标]
-
-> t_gear_trial

=== t_gear_trial ===
# source: data/chapter_tasks.json#t_gear_trial
序章 · 雾海
三年前那个晚上，灯塔的灯突然灭了。
目标：新钓具试用：离港后新钓获 1 条鱼
新钓具装好了。先出海试钓一条鱼，感受一下它的变化，再回码头吧。
+ [模拟达成目标，继续] -> t_gear_return

=== t_gear_return ===
# source: data/chapter_tasks.json#t_gear_return
目标：试钓完成：结束本杆后返回码头
新钓具用起来顺手多了。把这一杆收好，再回码头，准备下一趟出海。
+ [模拟达成目标，继续] -> m_fishing_trip

=== m_fishing_trip ===
# source: data/chapter_tasks.json#m_fishing_trip
第一章 · 谋生
先活下去，再谈真相。
目标：第一章 · 谋生：新钓获 3 条鱼
先独立出一次海。带回三条鱼，试试自己能不能靠这片海生活。
+ {not ahai_done} [先听阿海的可选委托] -> ahai
+ [模拟达成目标，继续] -> m_trip_sale

=== m_trip_sale ===
# source: data/chapter_tasks.json#m_trip_sale
目标：第一章 · 谋生：返港售卖本次渔获
把这趟渔获带回码头卖掉。航行、钓鱼和买卖，得连起来才是一门生计。
+ [模拟达成目标，继续] -> m_coins

=== m_coins ===
# source: data/chapter_tasks.json#m_coins
目标：第一章 · 谋生：留出 300 金币修塔
有了稳定的收入，该给旧灯塔留一笔修缮的钱了。
+ [模拟达成目标，继续] -> m_route_survey

=== m_route_survey ===
# source: data/chapter_tasks.json#m_route_survey
第二章 · 灯塔
先找到路，再让塔亮起来。
目标：第二章 · 灯塔：前往金色标记勘察航线
老林让我先去标记处看看航线。记住这片海的样子，塔亮后再来走一趟。
+ [模拟达成目标，继续] -> m_lighthouse

=== m_lighthouse ===
# source: data/chapter_tasks.json#m_lighthouse
目标：第二章 · 灯塔：返港建造灯塔
航线已经摸清。回港建造灯塔，让下一趟出海有个能望见的归处。
+ [模拟达成目标，继续] -> m_lighthouse_trial

=== m_lighthouse_trial ===
# source: data/chapter_tasks.json#m_lighthouse_trial
目标：第二章 · 灯塔：抵达航线标记，再返回码头
塔亮了。沿金色标记再跑一趟，然后回到码头，试试这条航线是否好走了。
+ [模拟达成目标，继续] -> m_market_variety

=== m_market_variety ===
# source: data/chapter_tasks.json#m_market_variety
第三章 · 烟火气
把一船渔获，变成一港烟火。
目标：第三章 · 烟火气：新钓获 2 种不同的鱼
港口不能只有一种鱼。去不同水域转转，带回两种渔获，为鱼市备货。
+ [模拟达成目标，继续] -> m_market

=== m_market ===
# source: data/chapter_tasks.json#m_market
目标：第三章 · 烟火气：返港建造鱼市
有了几样渔获，才有摆摊的底气。回港建鱼市，给这里添点人气。
+ [模拟达成目标，继续] -> m_market_trade

=== m_market_trade ===
# source: data/chapter_tasks.json#m_market_trade
目标：第三章 · 烟火气：在鱼市售卖一批鱼
鱼市开张了，把船上的鱼卖一批，看看新市场带来的收益。
+ {ahai_done and not market_done} [先听鱼市老板娘的可选委托] -> market_owner
+ [模拟达成目标，继续] -> m_searchlight

=== m_searchlight ===
# source: data/chapter_tasks.json#m_searchlight
第四章 · 雾鲸
雾是它的梦，别吵醒它。
目标：第四章 · 雾鲸：提交 2 条鲈鱼，修复探照灯
老林终于愿意谈雾海了。先在码头交两条鲈鱼，修好探照灯，再去深海。
+ [模拟达成目标，继续] -> m_deep_fishing

=== m_deep_fishing ===
# source: data/chapter_tasks.json#m_deep_fishing
目标：第四章 · 雾鲸：新钓获 2 条深海鱼
别急着去找鲸落。先试钓两条深海鱼，熟悉雾里航行和避开海怪的节奏。往东南远离岛屿，在参考坐标周边找找，不用停在精确的一点。白天可以钓金枪鱼，夜晚还有鱿鱼、灯笼鱼等。
+ [模拟达成目标，继续] -> m_sea_clue

=== m_sea_clue ===
# source: data/chapter_tasks.json#m_sea_clue
目标：第四章 · 雾鲸：寻找一个漂流瓶碎片
雾里漂着旧瓶子。先找一个，看看守塔人留下了什么线索。
+ [查看漂流瓶线索与图鉴收集] -> investigation

=== m_whalefall ===
# source: data/chapter_tasks.json#m_whalefall
目标：第四章 · 雾鲸：前往深海，打捞鲸落之光
线索指向深海最深处。循着紫色标记去找鲸落之光，小心周围的海怪。
老林：雾鲸……是我害死的。当年我为了多打鱼，用强光把它从深海里逼了出来。
老林：它临死前掉了一块光——'鲸落之光'。拿回来，也许雾就能散了。
老林：去深海最深处找它。小心，海怪最近很暴躁。
+ [模拟达成目标，继续] -> m_whalefall_return

=== m_whalefall_return ===
# source: data/chapter_tasks.json#m_whalefall_return
目标：第四章 · 雾鲸：带着鲸落之光返回码头
光已经在船上了。先安全回到码头，再决定它的归处。
+ [模拟达成目标，继续] -> m_choice

=== m_choice ===
# source: data/chapter_tasks.json#m_choice
终章 · 抉择
光，还是梦，选一个。
目标：终章 · 抉择：决定鲸落之光的归处
回到港口了。这束光该照亮航路，还是留给雾鲸的梦？
鲸落之光在你手里微微发烫。老林站在灯塔下，等了你很久。
“东西拿到了……那就到了做决定的时候了。”
“点亮探照灯，雾会散，真相大白——但光会把它引醒。”
“或者把光给我，我把它沉进海里。我们继续守着这个秘密。”
-> final_choice

=== ahai ===
听说你小子会钓鱼了？我是老船工阿海。
帮我个忙——给我捎 3 条沙丁鱼下酒，浅滩上随便钓钓就有。
年轻人，出海前给我捎 3 条沙丁鱼下酒，怎么样？浅滩上随便钓钓就有。
+ [模拟交付3条沙丁鱼，获得80金币]
~ ahai_done = true
~ preview_reward_coins += 80
-> m_fishing_trip
+ [暂不完成委托] -> m_fishing_trip

=== market_owner ===
哟，听说你们这儿建了鱼市？我是鱼市的老板娘。
给我弄 1 条金枪鱼来镇场子——深海那条传说中的鱼！价钱好说！
听说深海有金枪鱼？给我弄 1 条来镇场子，价钱好说！
+ [模拟交付1条金枪鱼，获得300金币与5鱼饵]
~ market_done = true
~ preview_reward_coins += 300
-> m_market_trade
+ [暂不完成委托] -> m_market_trade

=== investigation ===
当前线索：{fragments}/5。完整图鉴：{codex_complete:已完成|未完成}。
此处可选读线索；原游戏需要出海拾取。原作集齐后300秒会重置碎片，本审阅版不模拟计时。
+ {not clue_log_1} [拾取：气象记录残页] -> read_log_1
+ {not clue_log_2} [拾取：守塔人日志残页] -> read_log_2
+ {not clue_fisher_tale} [拾取：老渔民口述] -> read_fisher_tale
+ {not clue_last_note} [拾取：最后的纸条] -> read_last_note
+ {not clue_salvage} [拾取：打捞队记录] -> read_salvage
+ {not codex_complete} [模拟补全鱼类图鉴（10种）]
~ codex_complete = true
-> investigation
+ {fragments >= 1} [带着线索继续打捞主线] -> m_whalefall

=== read_log_1 ===
# source: data/fragments.json#log_1
港务局气象记录：三年前的那个晚上，风力 2 级，能见度良好。“风暴”的说法，是后来才传开的。
~ clue_log_1 = true
~ fragments += 1
+ [继续调查] -> investigation

=== read_log_2 ===
# source: data/fragments.json#log_2
守塔人日志：它每晚都靠近一点。灯越亮，它游得越近。我把灯调暗了，它停下了。原来它要的不是船，是光。
~ clue_log_2 = true
~ fragments += 1
+ [继续调查] -> investigation

=== read_fisher_tale ===
# source: data/fragments.json#fisher_tale
老渔民口述：雾最浓的那几天，海面下有声音，像打呼噜。雾一浓，它就睡得沉。雾是它呼出来的——它在做梦呢。
~ clue_fisher_tale = true
~ fragments += 1
+ [继续调查] -> investigation

=== read_last_note ===
# source: data/fragments.json#last_note
如果有人看到这个，别点灯。灯是我吹灭的，不是我失职，是我故意的。让它以为我们已经走了。——老林
~ clue_last_note = true
~ fragments += 1
+ [继续调查] -> investigation

=== read_salvage ===
# source: data/fragments.json#salvage
沉船里找到半张图纸：灯罩内壁刻满细纹，旁边注着一行小字——“强光惊它，柔光引路。光要软得像月光，它才不会醒。”
~ clue_salvage = true
~ fragments += 1
+ [继续调查] -> investigation

=== final_choice ===
鲸落之光在你手里。你会怎么做？
+ [点亮探照灯] -> ending_light
+ [交给老林] -> ending_entrust
+ {fragments >= 5 and codex_complete} [柔光：用知识寻找第三条路] -> ending_gentle
{fragments < 5 or not codex_complete:？？？——似乎还有第三条路……（原作此选项锁定）}

=== ending_light ===
# source: scripts/ending_panel.gd#light
~ ending = "light"
点亮探照灯
你亲手把鲸落之光装进探照灯。
光柱刺破雾海，深海的雾开始散了。码头上的人们欢呼起来。
但海面下，有巨大的阴影翻了个身。
老林按住你的肩膀：“从今天起，守夜的人，多了一个。”
—— 主线完成。雾海散了，但深海里有什么，醒了。
-> END

=== ending_entrust ===
# source: scripts/ending_panel.gd#entrust
~ ending = "entrust"
交给老林
你把鲸落之光交给了老林。
他看了很久，把它沉进了海里。“有些秘密，守比说难。”
“三年了，我一个人守。现在，有你陪我了。”
他塞给你 500 金币：“拿去，别说出去。”
—— 主线完成。雾还在，但你们守住了比雾更重要的东西。
~ preview_reward_coins += 500
-> END

=== ending_gentle ===
# source: scripts/ending_panel.gd#gentle
~ ending = "gentle"
柔光
你想起碎片里的记载：雾鲸怕的不是光，是强光。
你用剩下的碎片图纸，在作坊里打出了柔光罩。
光变得温和，既照亮了航道，又没有惊醒它。
雾散了。雾鲸还在睡。老林第一次笑了：“你比我聪明。”
—— 主线完成（隐藏结局）。你找到了第三条路。
-> END
