extends Node
## 新手引导与章节任务链；章节任务定义在 data/chapter_tasks.json。
## 纯轮询：每帧检查当前目标是否达成，达成即推进并发 objectives_changed。
## 各系统只提供计数器（fishing.cast_count / docking.menu_open_count / inventory.sold_total），不碰流程。
## 教程/建筑允许已有成果；出海和交易步骤记录起始计数，避免连跳。

signal objectives_changed

const MOVE_DISTANCE := 150.0  # 目标1：开船位移超过 150px 算学会移动
const SPOT_DISTANCE := 900.0  # 新手钓点：码头沿远离岛屿方向 900px，开船过去要一小段航程
const SPOT_ARRIVE_RADIUS := 130.0  # 进这个范围算到达钓点

const LEGACY_ORDER := ["move", "spot", "cast", "catch", "dock", "sell", "upgrade", "m_coins", "m_lighthouse", "m_market", "m_searchlight", "m_whalefall", "m_choice"]
var _ORDER: Array = LEGACY_ORDER.slice(0, 7)
var _chapter_steps: Dictionary = {}
var _step_state: Dictionary = {}
const TUTORIAL_END := 9  # 基础引导 7 步 + 新钓具试钓/返港，之后是第一章
const _TEXTS := {
	"move": "开船（W 前进，A/D 转向）",
	"spot": "开船到小地图金色标记处",
	"cast": "按 E 抛竿",
	"catch": "钓到 3 条鱼",
	"dock": "靠近码头，按 E 进入菜单",
	"sell": "在码头卖掉鱼",
	"upgrade": "用卖鱼收入升级鱼竿、卷线器或鱼饵，再出海试钓",

}
const _DONE_TEXT := "★ 雾海传说落幕，自由垂钓吧！"

var _index := 0
var _spawn_pos := Vector2.ZERO
var _spawn_recorded := false
var _spot := Vector2.ZERO  # 新手钓点世界坐标
var _spot_ready := false  # 钓点是否已算出（码头/岛进树后）
var _boat: Node2D
var _fishing: Node
var _docking: Node
var _night_deep_seen := false  # 是否体验过"夜晚的深海"（睡觉解锁用）
var _deep_unlocked := false  # 修好探照灯（主线 m_searchlight 提交 2 鲈鱼）后解锁深海
var _whalefall_recovered := false  # 是否已打捞鲸落之光
var _whalefall_target := Vector2.ZERO  # 鲸落打捞点（main.gd 计算深海最深处）
var _whalefall_target_set := false
var _ending := ""  # 终局选择：""=未选，"light"/"entrust"/"gentle"


func _ready() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_tasks.json"))
	for step: Dictionary in data["steps"]:
		_ORDER.append(str(step["id"]))
		_chapter_steps[str(step["id"])] = step


func chapter_index() -> int:
	if is_complete():
		return 5
	return int(_chapter_steps.get(current_id(), {}).get("chapter", 0))


func current_dialog() -> String:
	if current_id() == "m_searchlight":
		return str(_chapter_steps[current_id()].get("dialog", "")) + "\n" + sea_bass_hint()
	var step: Dictionary = _chapter_steps.get(current_id(), {})
	var dialog := str(step.get("dialog", ""))
	if step.has("location_hint"):
		dialog += "\n" + str(step["location_hint"])
	return dialog


func sea_bass_hint() -> String:
	var spot := FishingZones.recommended_reef_spot(get_tree().get_nodes_in_group("islands"))
	return "鲈鱼出没于白天的岛礁水域。推荐钓点：%s，金色标记附近朝岸边抛竿；这里也会钓到其他鱼。" % FishingZones.coordinates(spot)


func _begin_step() -> void:
	if str(_step_state.get("id", "")) == current_id():
		return
	_step_state = {"id": current_id(), "catches": Codex.save_catch_counts(),
		"sales": Inventory.sold_total(), "visited": false}
	Save.mark_dirty()


func _at_port() -> bool:
	for dock: Node2D in get_tree().get_nodes_in_group("docks"):
		if _boat.global_position.distance_to(dock.global_position) < 160.0:
			return true
	return false


func _chapter_check(id: String) -> bool:
	var step: Dictionary = _chapter_steps[id]
	var baseline: Dictionary = _step_state.get("catches", {})
	var caught := 0
	var varieties := 0
	var deep_caught := 0
	var entries: Array = Codex.get_entries() if str(step["type"]) in ["catch", "deep_catch", "variety", "trial_catch"] else []
	for entry: Dictionary in entries:
		var delta := maxi(int(entry["count"]) - int(baseline.get(entry["id"], 0)), 0)
		caught += delta
		if delta > 0:
			varieties += 1
		if str(entry.get("habitat", "")) == FishingZones.DEEP:
			deep_caught += delta
	match str(step["type"]):
		"trial_catch":
			if not _at_port() and not bool(_step_state.get("visited", false)):
				_step_state["visited"] = true
				_step_state["catches"] = Codex.save_catch_counts()
				Save.mark_dirty()
				return false
			_step_state["progress"] = mini(caught, int(step["target"]))
			return bool(_step_state.get("visited", false)) and caught >= int(step["target"])
		"trial_return":
			return _at_port() and (_fishing == null or not _fishing.is_fishing_active())
		"catch", "deep_catch", "variety":
			var count := caught if str(step["type"]) == "catch" else deep_caught if str(step["type"]) == "deep_catch" else varieties
			_step_state["progress"] = mini(count, int(step["target"]))
			return count >= int(step["target"])
		"sale": return Inventory.sold_total() > int(_step_state.get("sales", Inventory.sold_total()))
		"coins": return Inventory.coins() >= int(step["target"])
		"building": return Buildings.is_built("lighthouse_1" if id == "m_lighthouse" else "market_1")
		"unlock": return _deep_unlocked
		"clue": return Fragments.collected_count() >= int(step["target"])
		"recover": return _whalefall_recovered
		"ending": return _ending != ""
		"return": return _at_port()
		"survey", "voyage":
			var target := navigation_position()
			if target != Vector2.ZERO and _boat.global_position.distance_to(target) <= SPOT_ARRIVE_RADIUS:
				if not bool(_step_state.get("visited", false)):
					_step_state["visited"] = true
					Save.mark_dirty()
			return bool(_step_state.get("visited", false)) and (str(step["type"]) == "survey" or _at_port())
	return false


func navigation_active() -> bool:
	return spot_active() or current_id() in ["m_route_survey", "m_lighthouse_trial", "m_whalefall_return", "t_gear_return", "m_searchlight"]


func navigation_position() -> Vector2:
	if current_id() == "m_searchlight":
		return FishingZones.recommended_reef_spot(get_tree().get_nodes_in_group("islands"))
	if current_id() in ["m_whalefall_return", "t_gear_return"] or (current_id() == "m_lighthouse_trial" and bool(_step_state.get("visited", false))):
		var docks := get_tree().get_nodes_in_group("docks")
		return (docks[0] as Node2D).global_position if not docks.is_empty() else Vector2.ZERO
	var spot := spot_position()
	if current_id() in ["m_route_survey", "m_lighthouse_trial"]:
		var docks := get_tree().get_nodes_in_group("docks")
		if not docks.is_empty() and _spot_ready:
			var port := (docks[0] as Node2D).global_position
			var distance_from_port := float(_chapter_steps[current_id()].get("distance_from_port", SPOT_DISTANCE))
			return port + (spot - port).normalized() * distance_from_port
	return spot


func _process(_delta: float) -> void:
	_resolve_boat()
	if _boat == null:
		return
	_begin_step()
	# 整杆连钓及逐条渔获展示结束后，才交接下一项任务。
	if _fishing != null and _fishing.is_fishing_active():
		return
	if _docking != null and _docking.is_interaction_open():
		return
	var previous_id := current_id()
	var previous_text := current_text()
	while _index < _ORDER.size() and _check(_ORDER[_index]):
		_index += 1
		_begin_step()
		Save.mark_dirty()
		objectives_changed.emit()
	if previous_id == current_id() and previous_text != current_text():
		objectives_changed.emit()


func current_id() -> String:
	if _index >= _ORDER.size():
		return ""
	return _ORDER[_index]


## 当前目标文案；全完成显示毕业文案
func current_text() -> String:
	if _index >= _ORDER.size():
		return _DONE_TEXT
	var id: String = _ORDER[_index]
	if _chapter_steps.has(id):
		var step: Dictionary = _chapter_steps[id]
		var text := str(step["text"])
		if id == "m_searchlight":
			text += "\n白天 · 岛礁\n" + FishingZones.coordinates(navigation_position())
		if str(step["type"]) in ["catch", "deep_catch", "variety", "trial_catch"]:
			text += "（%d/%d）" % [int(_step_state.get("progress", 0)), int(step["target"])]
		if step.has("location_hint"):
			text += "\n" + str(step["location_hint"])
		if id == "m_lighthouse_trial" and bool(_step_state.get("visited", false)):
			text = "第二章 · 灯塔：航线已验证，返回金色标记处的码头"
		return text
	return _TEXTS[id]


func is_complete() -> bool:
	return _index >= _ORDER.size()


## 新手引导（含试钓和返港）是否完成；委托/码头引导用它，不用 is_complete()
func is_tutorial_complete() -> bool:
	return _index >= TUTORIAL_END


## 当前任务下标；存档使用 task_id 保持扩展后的兼容性
## 注：不能叫 get_index，会和 Node 父类的 get_index(bool) 冲突
func get_objective_index() -> int:
	return _index


## 睡觉解锁标记：是否体验过"夜晚的深海"（main.gd 在首次夜间进深海时标记）。
## 睡觉不再是早期教程目标，而是亲历深夜深海危险后才解锁的中期功能。


## 睡觉是否已解锁
func is_sleep_unlocked() -> bool:
	return _night_deep_seen


## 标记已体验深海之夜：解锁睡觉，发信号刷新 UI，标脏存档
func mark_night_deep_seen() -> void:
	if _night_deep_seen:
		return
	_night_deep_seen = true
	objectives_changed.emit()
	Save.mark_dirty()


func save_night_deep() -> bool:
	return _night_deep_seen


func load_night_deep(v: bool) -> void:
	_night_deep_seen = v


func _check(id: String) -> bool:
	if _chapter_steps.has(id):
		return _chapter_check(id)
	match id:
		"move":
			if not _spawn_recorded:
				_spawn_pos = _boat.global_position
				_spawn_recorded = true
			return _boat.global_position.distance_to(_spawn_pos) > MOVE_DISTANCE
		"spot":
			_ensure_spot()
			return _spot_ready and _boat.global_position.distance_to(_spot) <= SPOT_ARRIVE_RADIUS
		"cast":
			var c = _fishing.get("cast_count") if _fishing != null else null
			return c != null and int(c) > 0
		"catch":
			return Inventory.fish_total() >= 3
		"dock":
			var m = _docking.get("menu_open_count") if _docking != null else null
			return m != null and int(m) > 0
		"sell":
			return Inventory.sold_total() > 0
		"upgrade":
			return _any_fishing_upgrade_bought()

	return false


func _any_fishing_upgrade_bought() -> bool:
	for entry: Dictionary in Upgrades.get_entries():
		if bool(entry.get("purchased", false)) and str(entry.get("line", "")) in ["rod", "reel", "bait"]:
			return true
	return false


## 新手钓点是否还在引导中（小地图/世界标记/钓鱼提示条用）
func spot_active() -> bool:
	return _index <= _ORDER.find("spot")


## 新手钓点世界坐标；码头/岛没进树时返回 ZERO，调用方跳过绘制
func spot_position() -> Vector2:
	_ensure_spot()
	return _spot


## 钓点：码头沿"远离岛屿"方向 SPOT_DISTANCE；只算一次，码头/岛没进树就等下帧
func _ensure_spot() -> void:
	if _spot_ready:
		return
	var docks := get_tree().get_nodes_in_group("docks")
	var islands := get_tree().get_nodes_in_group("islands")
	if docks.is_empty() or islands.is_empty():
		return
	var dock_pos := (docks[0] as Node2D).global_position
	var island_pos := (islands[0] as Node2D).global_position
	var away := (dock_pos - island_pos).normalized()
	if away.length() < 0.5:
		away = Vector2.RIGHT
	_spot = dock_pos + away * SPOT_DISTANCE
	_spot_ready = true


## 找船（抄 Upgrades._find_fishing 的写法）；测试环境没船就等着，不报错
func _resolve_boat() -> void:
	if _boat != null:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	_boat = scene.get_node_or_null("Boat") as Node2D
	if _boat == null:
		return
	_fishing = _boat.get_node_or_null("Fishing")
	_docking = _boat.get_node_or_null("docking")


## 存档：当前目标下标；读档后 _process 会把已达成的连跳过去
func save_index() -> int:
	return _index


func load_index(i: int) -> void:
	_index = clampi(i, 0, _ORDER.size())
	objectives_changed.emit()


## 新游戏：回到初始值
func reset_save() -> void:
	_index = 0
	_step_state = {}
	_boat = null
	_night_deep_seen = false
	_spawn_recorded = false
	_spot_ready = false
	_deep_unlocked = false
	_whalefall_recovered = false
	_whalefall_target = Vector2.ZERO
	_whalefall_target_set = false
	_ending = ""
	objectives_changed.emit()


## ---- 主线状态：深海准入 / 鲸落之光 / 终局选择 ----


## 深海叙事门槛：修好探照灯才敢进深海（fishing.gd / main.gd 问这里）
func is_deep_unlocked() -> bool:
	return _deep_unlocked


## 码头"修复探照灯"按钮调用：解锁深海，主线推进
func unlock_deep() -> void:
	if _deep_unlocked:
		return
	_deep_unlocked = true
	objectives_changed.emit()
	Save.mark_dirty()


## 是否正在"打捞鲸落之光"阶段（小地图紫标/海怪狂暴用）
func is_whalefall_active() -> bool:
	return current_id() == "m_whalefall" and not _whalefall_recovered


## 是否已打捞鲸落之光
func is_whalefall_recovered() -> bool:
	return _whalefall_recovered


## 鲸落打捞点（main.gd 计算深海最深处后设置）
func whalefall_target() -> Vector2:
	return _whalefall_target


func has_whalefall_target() -> bool:
	return _whalefall_target_set


func set_whalefall_target(pos: Vector2) -> void:
	_whalefall_target = pos
	_whalefall_target_set = true
	Save.mark_dirty()


## 打捞物 E 键调用：标记已打捞，主线推进到"终章·抉择"
func recover_whalefall() -> void:
	if _whalefall_recovered:
		return
	_whalefall_recovered = true
	objectives_changed.emit()
	Save.mark_dirty()


## 终局选择：ending_panel 调用；选完主线全部完成
func set_ending(eid: String) -> void:
	if _ending != "":
		return
	_ending = eid
	objectives_changed.emit()
	Save.mark_dirty()


func get_ending() -> String:
	return _ending


func is_story_done() -> bool:
	return _ending != ""


## 主线状态存档（深海准入/鲸落/结局/打捞点）
func save_main_quest() -> Dictionary:
	return {
		"task_id": current_id(),
		"task_state": _step_state.duplicate(true),
		"deep_unlocked": _deep_unlocked,
		"whalefall_recovered": _whalefall_recovered,
		"whalefall_target": [_whalefall_target.x, _whalefall_target.y] if _whalefall_target_set else [],
		"ending": _ending,
	}


func load_main_quest(data: Dictionary) -> void:
	if data.has("task_id"):
		var task_id := str(data["task_id"])
		_index = _ORDER.size() if task_id == "" else maxi(_ORDER.find(task_id), 0)
		_step_state = (data.get("task_state", {}) as Dictionary).duplicate(true)
	else:
		# Numeric indices in older saves refer to the original 13-task chain.
		var old_index := clampi(_index, 0, LEGACY_ORDER.size())
		_index = _ORDER.size() if old_index == LEGACY_ORDER.size() else _ORDER.find(LEGACY_ORDER[old_index])
		_step_state = {}
	_deep_unlocked = bool(data.get("deep_unlocked", false))
	# 老存档迁移：旧版"建成灯塔即解锁深海"，已建灯塔的直接给准入（不用重做修探照灯）
	if not data.has("deep_unlocked") and Buildings.is_built("lighthouse_1"):
		_deep_unlocked = true
	_whalefall_recovered = bool(data.get("whalefall_recovered", false))
	var wt: Array = data.get("whalefall_target", [])
	if wt.size() == 2:
		_whalefall_target = Vector2(float(wt[0]), float(wt[1]))
		_whalefall_target_set = true
	_ending = str(data.get("ending", ""))
	# 选过结局的一定打捞过鲸落（老存档只有 ending 字段时补上）
	if _ending != "" and not _whalefall_recovered:
		_whalefall_recovered = true
	objectives_changed.emit()
