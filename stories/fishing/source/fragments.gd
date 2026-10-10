extends Node
## 漂流瓶碎片收集（autoload）：深海区 5 个碎片，捡到即点亮，拼出"灯塔熄灭之谜"。
## 文本走 data/fragments.json；收集进度走 fragments_changed 信号；Save 自动存档。
## 集齐 5 个 → "守塔人的遗产"：300 金 + 5 饵 + 庇护增益（5 分钟，海怪索敌×0.8）；
## 增益到期 → 碎片重置重生，可重复收集（深海循环）。

signal fragments_changed
signal buff_started   # 集齐奖励发放时
signal buff_expired   # 增益到期、碎片重置时

const FRAGMENTS_DATA_PATH := "res://data/fragments.json"
const BUFF_DURATION := 300.0       # 庇护增益持续 5 分钟
const BUFF_DETECT_MULT := 0.8      # 增益期间海怪索敌半径倍率
const REWARD_COINS := 300
const REWARD_BAIT := 5

var _fragments: Array = []       # fragments.json 里的顺序 [{id, title, text}]
var _collected: Dictionary = {}  # fragment_id -> true
var _buff_left := 0.0            # 增益剩余秒数；>0 表示增益生效中


func _ready() -> void:
	var file := FileAccess.open(FRAGMENTS_DATA_PATH, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	_fragments = data["fragments"]


func _process(delta: float) -> void:
	if _buff_left > 0.0:
		_buff_left -= delta
		if _buff_left <= 0.0:
			_buff_left = 0.0
			# 增益到期：碎片重置，main.gd 收到 buff_expired 后重生瓶子
			_collected.clear()
			fragments_changed.emit()
			buff_expired.emit()


## 碎片总数
func total_count() -> int:
	return _fragments.size()


## 已收集数
func collected_count() -> int:
	return _collected.size()


## 是否已收集
func is_collected(fragment_id: String) -> bool:
	return _collected.has(fragment_id)


## 收集：非法 id 直接忽略；重复收集不重复触发；集齐 5 个发放"守塔人的遗产"
func collect(fragment_id: String) -> bool:
	for f: Dictionary in _fragments:
		if f["id"] == fragment_id:
			if _collected.has(fragment_id):
				return false
			_collected[fragment_id] = true
			fragments_changed.emit()
			if _collected.size() >= _fragments.size() and _buff_left <= 0.0:
				_grant_set_reward()
			return true
	return false


## 集齐奖励：金币 + 鱼饵 + 5 分钟庇护增益
func _grant_set_reward() -> void:
	Inventory.add_coins(REWARD_COINS)
	Buildings.add_bait(REWARD_BAIT)
	_buff_left = BUFF_DURATION
	buff_started.emit()


## 增益是否生效中
func buff_active() -> bool:
	return _buff_left > 0.0


## 增益剩余秒数
func buff_left() -> float:
	return _buff_left


## 增益期间的海怪索敌倍率（未生效返回 1.0）
func buff_detect_mult() -> float:
	return BUFF_DETECT_MULT if buff_active() else 1.0


## 取碎片文本（按 id）
func get_fragment(fragment_id: String) -> Dictionary:
	for f: Dictionary in _fragments:
		if f["id"] == fragment_id:
			return f
	return {}


## 全部碎片（按 json 顺序），带 collected 标记
func get_all() -> Array:
	var out: Array = []
	for f: Dictionary in _fragments:
		out.append({
			"id": f["id"],
			"title": f["title"],
			"text": f["text"],
			"collected": _collected.has(f["id"]),
		})
	return out


## 存档：已收集 id 列表
func save_collected() -> Array:
	return _collected.keys()


## 读档
func load_save(data: Dictionary) -> void:
	_collected.clear()
	var ids: Variant = data.get("fragments_collected", [])
	if ids is Array:
		for id: Variant in ids:
			_collected[str(id)] = true
	_buff_left = float(data.get("fragments_buff_left", 0.0))
	fragments_changed.emit()


## 新游戏
func reset_save() -> void:
	_collected.clear()
	_buff_left = 0.0
	fragments_changed.emit()
