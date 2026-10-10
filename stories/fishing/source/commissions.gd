extends Node
## 支线任务（autoload "Commissions"）：码头 NPC 的可选委托，不卡主线。
## 阿海（3×沙丁鱼→80金，新手引导后）→ 老板娘（1×金枪鱼→300金+5饵，鱼市建成后）。
## 纯数据 + 轮询，各系统只提供鱼的数量（Inventory.count_of），不碰流程。
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

var _index := 0
var _unlock_announced := [false, false]  # 每个支线的解锁对话是否已播放


## 当前任务；未解锁或全部完成返回空字典
func current_quest() -> Dictionary:
	if _index >= _QUESTS.size():
		return {}
	if not is_available(_index):
		return {}
	return _QUESTS[_index]


## 下一个任务（即使未解锁也返回，面板用来显示锁定原因）
func next_quest() -> Dictionary:
	if _index >= _QUESTS.size():
		return {}
	return _QUESTS[_index]


## 指定序号的支线是否已解锁可接
func is_available(idx: int) -> bool:
	if idx < 0 or idx >= _QUESTS.size():
		return false
	if idx != _index:
		return false
	var q: Dictionary = _QUESTS[idx]
	if bool(q.get("requires_tutorial", false)) and not Objectives.is_tutorial_complete():
		return false
	var req := str(q.get("requires_building", ""))
	if req != "" and not Buildings.is_built(req):
		return false
	return true


## 下一个支线被锁定的原因文案；已解锁返回 ""
func lock_reason() -> String:
	var q := next_quest()
	if q.is_empty() or is_available(_index):
		return ""
	return str(q.get("lock_text", "暂未解锁。"))


## 轮询新解锁的支线：返回刚解锁且未播放过对话的序号列表，并标记为已播放
func poll_unlocks() -> Array:
	var result := []
	for i in _QUESTS.size():
		if i < _unlock_announced.size() and not _unlock_announced[i] and is_available(i):
			_unlock_announced[i] = true
			result.append(i)
			Save.mark_dirty()
	return result


## 指定支线的解锁对话
func unlock_lines(idx: int) -> Array:
	if idx < 0 or idx >= _QUESTS.size():
		return []
	return _QUESTS[idx].get("unlock_lines", [])


func is_all_done() -> bool:
	return _index >= _QUESTS.size()


## 当前任务进度文案，如"沙丁鱼 1/3"；无任务返回""
func progress_text() -> String:
	var q := current_quest()
	if q.is_empty():
		return ""
	var have := Inventory.count_of(str(q["fish_id"]))
	return "%s %d/%d" % [str(q["fish_name"]), have, int(q["count"])]


## 够不够交任务（未解锁的不能交）
func can_complete() -> bool:
	var q := current_quest()
	if q.is_empty():
		return false
	return Inventory.count_of(str(q["fish_id"])) >= int(q["count"])


## 交任务：扣鱼、发奖励、推进；返回奖励文案（面板/toast 用）
func complete_quest() -> String:
	var q := current_quest()
	if q.is_empty() or not can_complete():
		return ""
	var fish_id := str(q["fish_id"])
	for i in int(q["count"]):
		Inventory.remove_fish(fish_id)
	var coins := int(q["reward_coins"])
	if coins > 0:
		Inventory.add_coins(coins)
	var bait := int(q["reward_bait"])
	if bait > 0:
		Buildings.add_bait(bait)
	_index += 1
	commissions_changed.emit()
	Save.mark_dirty()
	return str(q["reward_text"])


## 存档
func save_data() -> Dictionary:
	return {
		"index": _index,
		"unlock_announced": _unlock_announced.duplicate(),
	}


func load_data(data: Dictionary) -> void:
	var old_idx := int(data.get("index", 0))
	# 老存档迁移：4 委托（阿海/老林/老板娘/鲸落）→ 2 支线（阿海/老板娘）；
	# 老林、鲸落已并入主线，这里只保留支线进度
	if old_idx <= 0:
		_index = 0
	elif old_idx <= 2:
		_index = 1
	else:
		_index = 2
	_index = clampi(_index, 0, _QUESTS.size())
	var ua: Array = data.get("unlock_announced", [])
	_unlock_announced = [false, false]
	if ua.size() > 0:
		_unlock_announced[0] = bool(ua[0])  # 阿海
	if ua.size() > 2:
		_unlock_announced[1] = bool(ua[2])  # 老板娘
	# 已完成的支线不再播解锁对话
	if _index >= 1:
		_unlock_announced[0] = true
	if _index >= 2:
		_unlock_announced[1] = true
	commissions_changed.emit()


func reset_save() -> void:
	_index = 0
	_unlock_announced = [false, false]
	commissions_changed.emit()
