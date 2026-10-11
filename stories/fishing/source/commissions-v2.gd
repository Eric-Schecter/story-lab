extends Node
## 支线任务（autoload "Commissions"）：码头 NPC 的可选委托，不卡主线。
## 原有交鱼委托 + 三条可独立接取的人物故事，状态按 ID 保存。
## 调查只记录观察结果；返港选择后才结算，对话由主场景在安全时机交接。
## 老林的"修探照灯"和"鲸落之光"已并入主线（objectives.gd 的 m_searchlight / m_whalefall）。

signal commissions_changed

const _QUESTS := [
	{
		"id": "sardines_for_ahai",
		"npc": "老船工阿海",
		"request": "年轻人，出海前给我捎 3 条沙丁鱼下酒，怎么样？浅滩上随便钓钓就有。",
		"fish_id": "sardine",
		"fish_name": "沙丁鱼",
		"count": 3,
		"reward_text": "80 金币",
		"reward_coins": 80,
		"reward_bait": 0,
		"requires_tutorial": true,
		"requires_building": "",
		"lock_text": "完成新手引导后，阿海会有事找你。",
		"unlock_lines": [
			"听说你小子会钓鱼了？我是老船工阿海。",
			"帮我个忙——给我捎 3 条沙丁鱼下酒，浅滩上随便钓钓就有。",
		],
	},
	{
		"id": "tuna_for_market",
		"npc": "鱼市老板娘",
		"request": "听说深海有金枪鱼？给我弄 1 条来镇场子，价钱好说！",
		"fish_id": "tuna",
		"fish_name": "金枪鱼",
		"count": 1,
		"reward_text": "300 金币，5 鱼饵",
		"reward_coins": 300,
		"reward_bait": 5,
		"requires_tutorial": false,
		"requires_building": "market_1",
		"lock_text": "需要先建造鱼市，老板娘才会来码头。",
		"unlock_lines": [
			"哟，听说你们这儿建了鱼市？我是鱼市的老板娘。",
			"给我弄 1 条金枪鱼来镇场子——深海那条传说中的鱼！价钱好说！",
		],
	},
]

var _quests: Array = []
var _index := 0  # 当前查看的委托，完成状态按稳定 ID 保存。
var _completed: Dictionary = {}
var _accepted: Dictionary = {}
var _announced: Dictionary = {}
var _pending_dialogs: Array = []
var _completing := false


func _ready() -> void:
	_quests = _QUESTS.duplicate(true)
	var file := FileAccess.open("res://data/side_stories.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	_quests.append_array(data["quests"])


func quests() -> Array:
	return _quests.duplicate(true)


func is_done(idx: int) -> bool:
	return idx >= 0 and idx < _quests.size() and _completed.has(str(_quests[idx]["id"]))


func is_quest_accepted(idx: int) -> bool:
	return idx >= 0 and idx < _quests.size() and _accepted.has(str(_quests[idx]["id"])) and not is_done(idx)


func is_available(idx: int) -> bool:
	if idx < 0 or idx >= _quests.size() or is_done(idx):
		return false
	var q: Dictionary = _quests[idx]
	if bool(q.get("requires_tutorial", false)) and not Objectives.is_tutorial_complete():
		return false
	var building := str(q.get("requires_building", ""))
	if building != "" and not Buildings.is_built(building):
		return false
	if bool(q.get("requires_deep", false)) and not Objectives.is_deep_unlocked():
		return false
	return true


func select_quest(idx: int) -> void:
	if idx >= 0 and idx < _quests.size():
		_index = idx
		Save.mark_dirty()
		commissions_changed.emit()


func selected_index() -> int:
	return _index


func current_quest() -> Dictionary:
	return _quests[_index] if is_available(_index) else {}


func next_quest() -> Dictionary:
	return _quests[_index] if _index < _quests.size() else {}


func lock_reason() -> String:
	if is_done(_index):
		return "委托已完成。"
	return str(next_quest().get("lock_text", "暂未解锁。"))


func is_all_done() -> bool:
	return _completed.size() >= _quests.size()


func is_accepted() -> bool:
	var q := current_quest()
	return not q.is_empty() and _accepted.has(str(q["id"]))


func accept_quest() -> void:
	var q := current_quest()
	if q.is_empty() or is_accepted() or not q.has("choices"):
		return
	_accepted[str(q["id"])] = {"observed": 0.0, "visited": false}
	Save.mark_dirty()
	commissions_changed.emit()


func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var boat := scene.get_node_or_null("Boat") as Node2D
	if boat == null:
		return
	var fishing := boat.get_node_or_null("Fishing")
	var docking := boat.get_node_or_null("docking")
	if (fishing != null and fishing.is_fishing_active()) or (docking != null and docking.is_interaction_open()):
		return
	for i in _quests.size():
		var q: Dictionary = _quests[i]
		var id := str(q["id"])
		if not is_available(i) or not _accepted.has(id) or str(q.get("quest_type", "")) != "visit":
			continue
		var state: Dictionary = _accepted[id]
		if bool(state.get("visited", false)):
			continue
		var xy: Array = q["position"]
		var near := boat.global_position.distance_to(Vector2(float(xy[0]), float(xy[1]))) <= float(q["radius"])
		var period := str(q.get("period", "any"))
		var clock := scene.get_node_or_null("DayNight")
		var correct_time: bool = period == "any" or (clock != null and clock.period() == period)
		if not near or not correct_time or (boat is CharacterBody2D and boat.velocity.length() > 15.0):
			state["observed"] = 0.0
			continue
		state["observed"] = float(state.get("observed", 0)) + delta
		if float(state["observed"]) >= float(q["observe_seconds"]):
			state["visited"] = true
			Save.mark_dirty()
			commissions_changed.emit()
			if scene.has_method("show_toast"):
				scene.show_toast(str(q["visit_text"]), 3.0)


func progress_text() -> String:
	var q := current_quest()
	if q.is_empty():
		return ""
	if q.has("choices"):
		if not is_accepted():
			return "可接取 · 不影响主线"
		if str(q.get("quest_type", "")) == "visit":
			if bool(_accepted[str(q["id"])].get("visited", false)):
				return str(q["visit_text"])
			var xy: Array = q["position"]
			return "%s · %s附近停船观察三秒" % ["夜晚" if q.get("period", "any") == "night" else "任意时段", FishingZones.coordinates(Vector2(float(xy[0]), float(xy[1])))]
		return "任选一道菜，备齐鱼后返港。"
	return "%s %d/%d" % [str(q["fish_name"]), Inventory.count_of(str(q["fish_id"])), int(q["count"])]


func tracked_text() -> String:
	var q := current_quest()
	if q.is_empty() or not is_accepted():
		return ""
	return "支线 · %s\n%s" % [str(q.get("title", q["npc"])), progress_text()]


func choice_ready(choice_id: String) -> bool:
	var q := current_quest()
	if q.is_empty() or not is_accepted():
		return false
	if str(q.get("quest_type", "")) == "visit" and not bool(_accepted[str(q["id"])].get("visited", false)):
		return false
	for choice: Dictionary in q.get("choices", []):
		if str(choice["id"]) == choice_id:
			return Inventory.count_of(str(choice.get("fish_id", ""))) >= int(choice.get("count", 0))
	return false


func can_complete() -> bool:
	var q := current_quest()
	return not _completing and not q.is_empty() and not q.has("choices") and Inventory.count_of(str(q["fish_id"])) >= int(q["count"])


func complete_quest() -> String:
	if not can_complete():
		return ""
	return _complete(current_quest(), current_quest())


func complete_choice(choice_id: String) -> String:
	if _completing or not choice_ready(choice_id):
		return ""
	var q := current_quest()
	for choice: Dictionary in q["choices"]:
		if str(choice["id"]) == choice_id:
			return _complete(q, choice)
	return ""


func _complete(q: Dictionary, outcome: Dictionary) -> String:
	_completing = true
	# 先锁定完成状态，再扣物品；库存信号重入不能重复提交。
	_completed[str(q["id"])] = str(outcome.get("id", "done"))
	for i in int(outcome.get("count", 0)):
		Inventory.remove_fish(str(outcome["fish_id"]))
	Inventory.add_coins(int(outcome.get("reward_coins", 0)))
	Buildings.add_bait(int(outcome.get("reward_bait", 0)))
	_pending_dialogs.append_array(outcome.get("lines", []))
	_completing = false
	Save.mark_dirty()
	commissions_changed.emit()
	return str(outcome["reward_text"])


func poll_completion_lines() -> Array:
	var lines := _pending_dialogs.duplicate()
	_pending_dialogs.clear()
	if not lines.is_empty():
		Save.mark_dirty()
	return lines


func poll_unlocks() -> Array:
	var result := []
	for i in _quests.size():
		var id := str(_quests[i]["id"])
		if is_available(i) and not bool(_announced.get(id, false)):
			_announced[id] = true
			# 新故事只在委托板介绍，避免同时解锁时连弹多个对话。
			if _quests[i].has("unlock_lines"):
				result.append(i)
			Save.mark_dirty()
	return result


func unlock_lines(idx: int) -> Array:
	return _quests[idx].get("unlock_lines", []) if idx >= 0 and idx < _quests.size() else []


func save_data() -> Dictionary:
	return {"version": 2, "selected_id": str(next_quest().get("id", "")), "completed": _completed.duplicate(true), "accepted": _accepted.duplicate(true), "announced": _announced.duplicate(), "pending_dialogs": _pending_dialogs.duplicate()}


func load_data(data: Dictionary) -> void:
	_completed = {}
	_accepted = {}
	_announced = {}
	_pending_dialogs = []
	_index = 0
	if int(data.get("version", 0)) >= 2:
		_completed = (data.get("completed", {}) as Dictionary).duplicate(true)
		_accepted = (data.get("accepted", {}) as Dictionary).duplicate(true)
		_announced = (data.get("announced", {}) as Dictionary).duplicate()
		_pending_dialogs = (data.get("pending_dialogs", []) as Array).duplicate()
		for i in _quests.size():
			if str(_quests[i]["id"]) == str(data.get("selected_id", "")):
				_index = i
	else:
		var count := int(data.get("index", 0))
		var announced: Array = data.get("unlock_announced", [])
		if announced.size() > 2:
			count = 0 if count <= 0 else 1 if count <= 2 else 2
		for i in mini(count, 2):
			_completed[str(_quests[i]["id"])] = "done"
			_announced[str(_quests[i]["id"])] = true
		if announced.size() > 0:
			_announced[str(_quests[0]["id"])] = bool(announced[0])
		var boss_idx := 2 if announced.size() > 2 else 1
		if announced.size() > boss_idx:
			_announced[str(_quests[1]["id"])] = bool(announced[boss_idx])
		_index = mini(count, _quests.size() - 1)
	commissions_changed.emit()


func reset_save() -> void:
	load_data({"version": 2})
