extends Node
## 故事系统（autoload "Story"）：章节、里程碑、赏金鱼。
## 章节跟着主线（objectives.gd）走，推进时发 chapter_advanced（大屏标题用）；
## 里程碑是每章可选目标，条件满足后自动发放奖励；赏金鱼每 3 天轮换一种，卖出双倍价。

signal story_changed
signal chapter_advanced(chapter_id: String)  # 章节推进，大屏标题用
signal milestone_achieved(milestone_id: String)  # 里程碑达成（已自动发奖），toast 用

const CHAPTERS := [
	{"id": "prologue", "title": "序章 · 雾海", "quote": "三年前那个晚上，灯塔的灯突然灭了。"},
	{"id": "ch1", "title": "第一章 · 谋生", "quote": "先活下去，再谈真相。"},
	{"id": "ch2", "title": "第二章 · 灯塔", "quote": "先找到路，再让塔亮起来。"},
	{"id": "ch3", "title": "第三章 · 烟火气", "quote": "把一船渔获，变成一港烟火。"},
	{"id": "ch4", "title": "第四章 · 雾鲸", "quote": "雾是它的梦，别吵醒它。"},
	{"id": "finale", "title": "终章 · 抉择", "quote": "光，还是梦，选一个。"},
]

# 里程碑：按章节，每章 2 个可选目标；type 决定检查方式
const MILESTONES := [
	{"id": "m_coins_300", "chapter": "ch1", "desc": "拥有 300 金币", "type": "coins", "target": 300, "reward_coins": 50, "reward_bait": 0},
	{"id": "m_build_1", "chapter": "ch1", "desc": "建造 1 栋建筑", "type": "buildings", "target": 1, "reward_coins": 0, "reward_bait": 3},
	{"id": "m_codex_5", "chapter": "ch2", "desc": "图鉴收集 5 种鱼", "type": "codex", "target": 5, "reward_coins": 80, "reward_bait": 0},
	{"id": "m_coins_1000", "chapter": "ch2", "desc": "拥有 1000 金币", "type": "coins", "target": 1000, "reward_coins": 100, "reward_bait": 0},
	{"id": "m_build_3", "chapter": "ch3", "desc": "建造 3 栋建筑", "type": "buildings", "target": 3, "reward_coins": 0, "reward_bait": 5},
	{"id": "m_codex_8", "chapter": "ch3", "desc": "图鉴收集 8 种鱼", "type": "codex", "target": 8, "reward_coins": 150, "reward_bait": 0},
	{"id": "m_frag_3", "chapter": "ch4", "desc": "集齐 3 个漂流瓶碎片", "type": "fragments", "target": 3, "reward_coins": 200, "reward_bait": 0},
	{"id": "m_codex_10", "chapter": "ch4", "desc": "图鉴收集 10 种鱼", "type": "codex", "target": 10, "reward_coins": 0, "reward_bait": 8},
]

const BOUNTY_NAMES := {
	"hairtail": "带鱼", "sea_bass": "鲈鱼", "squid": "鱿鱼",
	"lanternfish": "灯笼鱼", "tuna": "金枪鱼",
	"ghost_jellyfish": "幽灵水母", "abyss_angler": "深渊鮟鱇",
}

const BOUNTY_ROTATE_DAYS := 3  # 赏金鱼每 3 天轮换

var _chapter := 0
var _milestones_done := {}  # id -> true（已达成并发奖）
var _bounty_fish := ""  # 当前赏金鱼 id
var _bounty_day := -1  # 上次轮换的天数


func _ready() -> void:
	# 监听各系统变化，推进章节/里程碑/赏金轮换
	if Objectives.has_signal("objectives_changed"):
		Objectives.objectives_changed.connect(_poll)
	if Inventory.has_signal("inventory_changed"):
		Inventory.inventory_changed.connect(_poll)
	if Buildings.has_signal("buildings_changed"):
		Buildings.buildings_changed.connect(_poll)
	if Codex.has_signal("codex_changed"):
		Codex.codex_changed.connect(_poll)
	if Fragments.has_signal("fragments_changed"):
		Fragments.fragments_changed.connect(_poll)


## 章节信息
func chapter_info() -> Dictionary:
	if _chapter < 0 or _chapter >= CHAPTERS.size():
		return {}
	return CHAPTERS[_chapter]


func chapter_id() -> String:
	return str(chapter_info().get("id", ""))


## 根据主线进度计算应处章节；推进时发 chapter_advanced
func _poll() -> void:
	if Save.is_restoring():
		return
	var want := _calc_chapter()
	if want != _chapter:
		_chapter = want
		chapter_advanced.emit(chapter_id())
		story_changed.emit()
		Save.mark_dirty()
	_check_milestones()
	_check_bounty()


func _calc_chapter() -> int:
	return Objectives.chapter_index()


## 里程碑：已探明章节的，条件满足时自动发放奖励并 toast 提示
func _check_milestones() -> void:
	for m in MILESTONES:
		var mid := str(m["id"])
		if _milestones_done.get(mid, false):
			continue
		# 只检查已探明章节的里程碑
		var m_ch := _chapter_index_of(str(m["chapter"]))
		if m_ch > _chapter:
			continue
		if _milestone_met(m):
			_milestones_done[mid] = true
			var rc := int(m.get("reward_coins", 0))
			var rb := int(m.get("reward_bait", 0))
			if rc > 0:
				Inventory.add_coins(rc)
			if rb > 0:
				Buildings.add_bait(rb)
			milestone_achieved.emit(mid)
			story_changed.emit()
			Save.mark_dirty()


## 按 id 取里程碑配置（toast 文案用）
func get_milestone(mid: String) -> Dictionary:
	for m in MILESTONES:
		if str(m["id"]) == mid:
			return m
	return {}


func _chapter_index_of(cid: String) -> int:
	for i in CHAPTERS.size():
		if str(CHAPTERS[i]["id"]) == cid:
			return i
	return 99


func _milestone_met(m: Dictionary) -> bool:
	var t := int(m["target"])
	match str(m["type"]):
		"coins":
			return Inventory.coins() >= t
		"buildings":
			return _built_count() >= t
		"codex":
			return Codex.discovered_count() >= t
		"fragments":
			return Fragments.collected_count() >= t
	return false


func _built_count() -> int:
	var n := 0
	for line in ["workshop", "warehouse", "lighthouse", "market"]:
		if Buildings.get_level(line) >= 1:
			n += 1
	return n


## 赏金鱼：每 3 天轮换一种，卖出双倍价
func _check_bounty() -> void:
	var day := _current_day()
	if _bounty_day < 0 or day - _bounty_day >= BOUNTY_ROTATE_DAYS:
		_rotate_bounty(day)


func _current_day() -> int:
	var scene := get_tree().current_scene
	if scene == null:
		return 0
	var dn := scene.get_node_or_null("DayNight")
	if dn != null and dn.has_method("get_day"):
		return int(dn.call("get_day"))
	return 0


func _rotate_bounty(day: int) -> void:
	var pool := ["hairtail", "sea_bass", "squid", "lanternfish", "tuna", "ghost_jellyfish", "abyss_angler"]
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 1000 + 7
	var pick: String = pool[rng.randi() % pool.size()]
	# 别连续两次相同
	if pick == _bounty_fish:
		pick = pool[(pool.find(pick) + 1) % pool.size()]
	_bounty_fish = pick
	_bounty_day = day
	story_changed.emit()
	Save.mark_dirty()


func bounty_fish() -> String:
	return _bounty_fish


func bounty_fish_name() -> String:
	if _bounty_fish == "":
		return ""
	return str(BOUNTY_NAMES.get(_bounty_fish, _bounty_fish))


## 赏金倍率：是赏金鱼返回 2.0，否则 1.0（卖鱼面板用）
func bounty_mult(fid: String) -> float:
	if fid != "" and fid == _bounty_fish:
		return 2.0
	return 1.0


## 存档
func save_data() -> Dictionary:
	return {
		"chapter": _chapter,
		"milestones_done": _milestones_done.duplicate(),
		"bounty_fish": _bounty_fish,
		"bounty_day": _bounty_day,
	}


func load_data(data: Dictionary) -> void:
	_chapter = _calc_chapter()
	_milestones_done = (data.get("milestones_done", {}) as Dictionary).duplicate()
	_bounty_fish = str(data.get("bounty_fish", ""))
	_bounty_day = int(data.get("bounty_day", -1))
	story_changed.emit()


func reset_save() -> void:
	_chapter = 0
	_milestones_done = {}
	_bounty_fish = ""
	_bounty_day = -1
	story_changed.emit()
