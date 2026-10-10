extends Node2D
## 主场景：相机平滑跟随小船；BGM 常驻无缝循环；M 键全局静音（Master 总线）。
## 存档：_ready 开头消费 Save（新游戏 → reset_all，否则 → apply_save(self) 读档）。
## Esc 暂停菜单（pause_menu.gd）：音量/静音/全屏/回到标题/退出游戏；关窗口先落盘。
## 深水区提示：船进出深海区时顶部弹条提示（渔获更值钱，但有海怪出没）。
## 昼夜单局循环：白天出海、夜晚海怪加难（见 sea_monster.gd）、码头睡觉到天亮 + 存档。

const UIStyle := preload("res://scripts/ui_style.gd")
const Ripples := preload("res://scripts/ripples.gd")
const SeaMonster := preload("res://scripts/sea_monster.gd")
const WorkshopBuilding := preload("res://scripts/workshop_building.gd")
const BuildingsVisual := preload("res://scripts/buildings_visual.gd")
const PauseMenu := preload("res://scripts/pause_menu.gd")
const TutorialMarker := preload("res://scripts/tutorial_marker.gd")
const FragmentPickup := preload("res://scripts/fragment_pickup.gd")
const FragmentUI := preload("res://scripts/fragment_ui.gd")

const CAMERA_FOLLOW := 4.0  # 指数平滑系数 (1/s)，越大跟得越紧、拖尾越小
const MASTER_BUS := 0       # 默认 Master 总线索引
const SHAKE_DECAY := 22.0   # 震屏衰减 (1/s)
const SHAKE_SCALE := 0.35   # 镜头偏移 = trauma² × SHAKE_SCALE (px)
const MONSTER_COUNT := 4     # 深水区海怪数量：出生时互相拉开、分散在深水区各处

var _trauma := 0.0  # 震屏强度：fishing.gd 上钩/钓起时经 add_shake 往里加，随时间衰减
var _island_positions: Array = []  # 水域判定用（场景里的岛不会动，启动时缓存）
var _was_deep := false  # 上一帧船是否在深水区（进出提示用）
var _dialog: CanvasLayer
var _ending_panel: CanvasLayer  # 主人公对话框
var _chapter_card: CanvasLayer  # 章节大屏卡
var _zone_toast: Label
var _zone_toast_timer := 0.0
var _fear_overlay: TextureRect  # 深海恐惧遮罩：未解锁深海准入时进深海区显示，暗红边缘呼吸

@onready var _boat: Node2D = $Boat
@onready var _camera: Camera2D = $Camera2D
@onready var _bgm: AudioStreamPlayer = $BGM


## 震屏接口（fishing.gd 调用）：trauma 叠加，上限 10
func add_shake(amount: float) -> void:
	_trauma = minf(_trauma + amount, 10.0)


func _ready() -> void:
	UIStyle.ensure_cjk_fallback()  # 补齐中文字形：「图/鉴」等缺字显示为方框的问题
	if _camera != null and _boat != null:
		_camera.position = _boat.position  # 相机出生即在船上，避免第一帧从原点 lerp 导致雾中心偏离
	if Save.consume_new_game():
		Save.reset_all()
		call_deferred("_start_tutorial")
	else:
		Save.apply_save(self)
		if not Objectives.is_story_done():
			call_deferred("_on_tutorial_objective")
	if Objectives.has_signal("objectives_changed"):
		Objectives.objectives_changed.connect(_check_commission_unlocks)
		Objectives.objectives_changed.connect(_on_tutorial_objective)
	if Buildings.has_signal("buildings_changed"):
		Buildings.buildings_changed.connect(_check_commission_unlocks)
	if Commissions.has_signal("commissions_changed"):
		Commissions.commissions_changed.connect(_check_commission_unlocks)
	call_deferred("_check_commission_unlocks")  # 有存档则读档（无存档是空操作）
	# BGM 无缝循环：4.6.3 的 wav 导入器不把 edit/loop_* 写进资源（load 后恒为默认值），
	# 且 loop_end 默认 0 时 LOOP_FORWARD 会立即停播；运行时按流全长补上循环终点。
	var stream := _bgm.stream as AudioStreamWAV
	if stream != null:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	_bgm.process_mode = Node.PROCESS_MODE_ALWAYS  # 暂停菜单打开时音乐继续播
	_bgm.play()
	# 鱼群涟漪：海面随机刷水花，抛竿落进圈内本次稀有度加成
	var ripples := Ripples.new()
	ripples.name = "Ripples"
	add_child(ripples)
	# 海怪：游荡黑影，近船追击，摸到抢金币和鱼；多只出生，彼此拉开、分散在深水区
	var monster_spots: Array = []
	for i in MONSTER_COUNT:
		var monster := SeaMonster.new()
		monster.name = "SeaMonster%d" % (i + 1)
		add_child(monster)
		monster.spread_from(monster_spots)
		move_child(monster, _boat.get_index())  # 水下影子，画在船下面
	# 饵料作坊建筑：workshop_1 建造后在码头边“长”出水彩小木屋
	var workshop := WorkshopBuilding.new()
	workshop.name = "WorkshopBuilding"
	add_child(workshop)
	# 被动建筑：仓库 / 灯塔 / 鱼市，建造后在码头边长出来
	var bvisual := BuildingsVisual.new()
	bvisual.name = "BuildingsVisual"
	add_child(bvisual)
	var DialogBox := preload("res://scripts/dialog_box.gd")
	_dialog = DialogBox.new()
	_dialog.name = "DialogBox"
	add_child(_dialog)
	var EndingPanel := preload("res://scripts/ending_panel.gd")
	_ending_panel = EndingPanel.new()
	_ending_panel.name = "EndingPanel"
	add_child(_ending_panel)
	# 章节大屏卡：Story 推进章节时显示
	var ChapterCard := preload("res://scripts/chapter_card.gd")
	_chapter_card = ChapterCard.new()
	_chapter_card.name = "ChapterCard"
	add_child(_chapter_card)
	Story.chapter_advanced.connect(_on_chapter_advanced)
	Story.milestone_achieved.connect(_on_milestone_achieved)
	# 新手引导：世界里的金色脉冲圆环，标出第一个钓点；spot 目标完成后自删
	var marker := TutorialMarker.new()
	marker.name = "TutorialMarker"
	add_child(marker)
	# 漂流瓶碎片：深海区 5 个，拼出"灯塔熄灭之谜"；已收集的不再生成
	var fragment_ui := FragmentUI.new()
	fragment_ui.name = "FragmentUI"
	add_child(fragment_ui)
	# 先填岛屿位置（碎片生成要判定深水区）
	for island in get_tree().get_nodes_in_group("islands"):
		if island is Node2D:
			_island_positions.append((island as Node2D).global_position)
	# 海面 v3 深水压暗：把岛屿坐标传给 shader（不足 4 个用超远点填充）
	_update_sea_islands_uniform()
	_spawn_fragments()
	# 碎片循环：集齐 5 个 → 发奖励 toast；增益到期 → 碎片重置，在深海重生新一轮
	Fragments.buff_started.connect(_on_fragments_buff_started)
	Fragments.buff_expired.connect(_on_fragments_buff_expired)
	# Esc 暂停菜单：继续 / 音量 / 静音 / 全屏 / 回到标题 / 退出游戏
	var pause_menu := PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)
	# 关窗口先落盘：防 0.5 秒防抖没写完就退出
	get_tree().set_auto_accept_quit(false)
	_build_zone_toast()
	_was_deep = _boat_in_deep()


## M 键：Master 总线静音开关，BGM 和 SFX 一起静音/恢复
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		AudioServer.set_bus_mute(MASTER_BUS, not AudioServer.is_bus_mute(MASTER_BUS))


## 关窗口：先写盘再退出（set_auto_accept_quit(false) 后走这里）
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Save.save_now()
		get_tree().quit()


## 船当前是否在深水区
func _boat_in_deep() -> bool:
	return FishingZones.zone_at(_boat.global_position, _island_positions) == FishingZones.DEEP


## 船当前是否在深水区（公开版：day_night 的雾效用）
func is_boat_in_deep() -> bool:
	return _boat_in_deep()


## 是否夜晚：问 DayNight 节点；没找到按白天算
func _is_night() -> bool:
	var daynight := get_node_or_null("DayNight")
	if daynight != null and daynight.has_method("period"):
		return daynight.period() == "night"
	return false


## 漂流瓶碎片生成：5 个分散在深水区；已收集的跳过（读档后不重生）
func _spawn_fragments() -> void:
	var ids := ["log_1", "salvage", "log_2", "fisher_tale", "last_note"]
	var spots: Array = []
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	# 以岛屿为圆心撒点：深海区 = 离所有岛 1650px+，取 2000~3200 环带保证命中
	var center := Vector2.ZERO
	if not _island_positions.is_empty():
		center = _island_positions[0]
	var tries := 0
	while spots.size() < ids.size() and tries < 500:
		tries += 1
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(2000.0, 3200.0)
		var p := center + Vector2(cos(ang), sin(ang)) * dist
		if FishingZones.zone_at(p, _island_positions) != FishingZones.DEEP:
			continue
		var ok := true
		for s in spots:
			if p.distance_to(s) < 800.0:
				ok = false
				break
		if ok:
			spots.append(p)
	# 兜底：随机撒点失败时用固定角度补齐，保证 5 个一定生成
	var fallback_ang := 0.0
	while spots.size() < ids.size():
		var p := center + Vector2(cos(fallback_ang), sin(fallback_ang)) * 2600.0
		fallback_ang += TAU / float(ids.size())
		if FishingZones.zone_at(p, _island_positions) == FishingZones.DEEP:
			spots.append(p)
		else:
			break  # 连兜底都不行就不硬塞了
	for i in ids.size():
		if Fragments.is_collected(ids[i]):
			continue
		if i >= spots.size():
			break
		var pickup := FragmentPickup.new()
		pickup.name = "Fragment_" + ids[i]
		pickup.global_position = spots[i]
		add_child(pickup)
		pickup.setup(ids[i], _boat)


## 集齐 5 碎片："守塔人的遗产"奖励提示
func _on_fragments_buff_started() -> void:
	say("拼出来了！这是守塔人的遗产……金币、鱼饵，还有一层庇护。海怪应该更难发现我了。")


## 增益到期：清掉旧瓶子（理论上已收完，防万一），在深海重生新一轮
func _on_fragments_buff_expired() -> void:
	for child in get_children():
		if child.name.begins_with("Fragment_"):
			child.queue_free()
	_spawn_fragments()
	say("深海里好像又有漂流瓶出现了……去找找看。")


## 深水区提示条：小字顶部居中，几秒后自动消失
func _build_zone_toast() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 15
	add_child(layer)
	_zone_toast = Label.new()
	_zone_toast.visible = false
	_zone_toast.add_theme_font_size_override("font_size", 26)
	_zone_toast.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0))
	_zone_toast.add_theme_color_override("font_outline_color", Color(0.05, 0.15, 0.2))
	_zone_toast.add_theme_constant_override("outline_size", 5)
	_zone_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(_zone_toast)
	_zone_toast.anchor_left = 0.5
	_zone_toast.anchor_right = 0.5
	_zone_toast.anchor_top = 0.0
	_zone_toast.anchor_bottom = 0.0
	_zone_toast.offset_left = -500.0
	_zone_toast.offset_right = 500.0
	_zone_toast.offset_top = 150.0
	_zone_toast.offset_bottom = 190.0
	_build_fear_overlay(layer)


## 深海恐惧遮罩：径向渐变，中心透明、边缘暗红；未解锁深海准入时进深海区显示
func _build_fear_overlay(layer: CanvasLayer) -> void:
	var grad := Gradient.new()
	grad.set_color(0, Color(0.35, 0.0, 0.0, 0.0))
	grad.set_color(1, Color(0.30, 0.0, 0.05, 0.6))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	_fear_overlay = TextureRect.new()
	_fear_overlay.texture = tex
	_fear_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fear_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fear_overlay.visible = false
	layer.add_child(_fear_overlay)
	layer.move_child(_fear_overlay, 0)  # 遮罩在提示条下面


func _show_zone_toast(text: String, duration: float) -> void:
	_zone_toast.text = text
	_zone_toast.visible = true
	_zone_toast_timer = duration


## 通用顶部提示条（码头睡觉等子系统调用）
func show_toast(text: String, duration: float) -> void:
	_show_zone_toast(text, duration)


## 主人公说话：底部对话框（叙事性提示用）
func say(text: String) -> void:
	if _interaction_busy() or _chapter_transition_pending():
		_deferred_fishing_dialogs.append(text)
		return
	if _dialog != null and _dialog.has_method("say"):
		_dialog.say(text)
	else:
		show_toast(text, 3.0)


## 新手教程：故事开场 + 目标链每步解说（只在新游戏触发）
## 卖鱼/钓具/睡觉三步由码头菜单的分步指引（TutorialGuide）接管：高亮按钮 + 一句话提示，
## 不再弹对话框，避免一口气讲完。
var _tutorial_step_dialogs := {
	"move": "W/S 前进后退，A/D 转向。按住 F 加速赶路，但转弯会变钝。",
	"spot": "小地图下方是当前坐标：向东（右）X 增大，向南（下）Y 增大，负数表示在原点以西或以北。以后任务给出的钓点坐标，就用这里对照。先去金色标记处。",
	"cast": "到了。按 E 抛竿，试试手气。",
	"catch": "上钩了！看到「!」按 E 收线，看准时机条。多钓几条，3 条后再回去卖。",
	"dock": "钓了几条了！开回码头，靠近后按 E 进入菜单，跟着金色指引走。",
	"codex": "图鉴在记录你的发现。继续探索吧，阿舟——深海的雾在等你。",
}

func _start_tutorial() -> void:
	say("三年前那个晚上，灯塔的灯突然灭了。第二天一早，深海就被雾吞了，再没散过。")
	say("守塔的老林说，灯里藏着这片海最大的秘密——探照灯修好的那天，雾就会散。可他不肯再多说一个字。")
	say("我得先活下去。钓鱼，卖钱，攒家当……然后去深海，把真相捞出来。")
	_on_tutorial_objective()

func _check_commission_unlocks() -> void:
	if _interaction_busy() or _chapter_transition_pending():
		_pending_commission_check = true
		return
	if _dialog == null:
		return
	# 支线解锁对话（阿海/老板娘）
	for idx in Commissions.poll_unlocks():
		for line in Commissions.unlock_lines(idx):
			say(str(line))
	# 主线事件：进入"打捞鲸落之光" → 老林说出真相 + 标记深海最深处
	_check_whalefall_intro()
	# 主线事件：进入"终章·抉择" → 打开终局面板
	if Objectives.current_id() == "m_choice" and not Objectives.is_story_done():
		if _ending_panel != null and not _ending_panel.is_open():
			_ending_panel.open()


## 章节推进：显示大屏章节卡
func _on_chapter_advanced(chapter_id: String) -> void:
	if _chapter_card == null:
		return
	var info := Story.chapter_info()
	# 序章不显示大屏（游戏一开始就是序章）
	if str(info.get("id", "")) == "prologue":
		return
	# 本帧任务信号处理完后统一播放章节卡；剧情对话排在过渡后。
	_pending_fishing_chapter = info.duplicate(true)


## 里程碑达成：自动发奖，toast 提示
func _on_milestone_achieved(milestone_id: String) -> void:
	var m := Story.get_milestone(milestone_id)
	if m.is_empty():
		return
	var reward := ""
	if int(m.get("reward_coins", 0)) > 0:
		reward += "+%d金 " % int(m["reward_coins"])
	if int(m.get("reward_bait", 0)) > 0:
		reward += "+%d饵" % int(m["reward_bait"])
	var text := "🏅 里程碑达成：%s（%s）" % [str(m["desc"]), reward.strip_edges()]
	if _interaction_busy():
		_deferred_fishing_toasts.append({"text": text, "duration": 3.5})
	else:
		show_toast(text, 3.5)


## 海面 v3：把岛屿世界坐标传给水面 shader，供深水压暗用
func _update_sea_islands_uniform() -> void:
	var sea := get_node_or_null("Sea") as Polygon2D
	if sea == null or sea.material == null:
		return
	var arr := PackedVector2Array()
	for ip in _island_positions:
		arr.append(ip)
	while arr.size() < 4:
		arr.append(Vector2(1.0e6, 1.0e6))  # 填充超远点，不影响判定
	(sea.material as ShaderMaterial).set_shader_parameter("islands", arr)


## 深海最深处：离所有岛最远的深海点
func _compute_deepest_point() -> Vector2:
	var center := Vector2.ZERO
	if not _island_positions.is_empty():
		center = _island_positions[0]
	var best := center + Vector2.RIGHT * 2600.0
	var best_dist := -1.0
	for i in 16:
		var ang := TAU * float(i) / 16.0
		var p := center + Vector2(cos(ang), sin(ang)) * 2600.0
		if FishingZones.zone_at(p, _island_positions) != FishingZones.DEEP:
			continue
		var nearest := 1e9
		for ip in _island_positions:
			nearest = minf(nearest, p.distance_to(ip))
		if nearest > best_dist:
			best_dist = nearest
			best = p
	return best


## 主线"打捞鲸落之光"：进入时老林说出真相 + 标记深海最深处 + 生成打捞物
## 读档时若目标点已存档（_whalefall_target_set），只生成打捞物，不重复对话
func _check_whalefall_intro() -> void:
	if Objectives.current_id() != "m_whalefall":
		return
	if Objectives.is_whalefall_recovered():
		return
	# 读档：目标点已存档，直接生成打捞物（不重复播对话）
	if Objectives.has_whalefall_target():
		_spawn_whalefall_pickup()
		return
	# 首次进入：老林说出真相
	say("老林：雾鲸……是我害死的。当年我为了多打鱼，用强光把它从深海里逼了出来。")
	say("老林：它临死前掉了一块光——'鲸落之光'。拿回来，也许雾就能散了。")
	say("老林：去深海最深处找它。小心，海怪最近很暴躁。")
	Objectives.set_whalefall_target(_compute_deepest_point())
	_spawn_whalefall_pickup()


## 在深海目标点生成鲸落之光打捞物（若已存在则不重复）
func _spawn_whalefall_pickup() -> void:
	if not Objectives.has_whalefall_target():
		return
	if Objectives.is_whalefall_recovered():
		return
	# 已有打捞物在场：不重复生成
	for child in get_children():
		if child.has_method("setup") and child.get_script() != null:
			if str(child.get_script().resource_path).ends_with("whalefall_pickup.gd"):
				return
	var scene := load("res://scripts/whalefall_pickup.gd")
	if scene == null:
		return
	var node := Node2D.new()
	node.set_script(scene)
	add_child(node)
	node.global_position = Objectives.whalefall_target()
	node.setup(_boat)


var _deferred_fishing_dialogs: Array[String] = []
var _deferred_fishing_toasts: Array[Dictionary] = []
var _pending_fishing_chapter: Dictionary = {}
var _pending_commission_check := false
var _pending_gear_dialog := ""
var _last_objective_dialog := ""


func _on_tutorial_objective() -> void:
	var step_id := Objectives.current_id()
	if step_id == "" or step_id == _last_objective_dialog:
		return
	_last_objective_dialog = step_id
	_pending_gear_dialog = step_id if step_id in ["t_gear_trial", "t_gear_return"] else ""
	if _pending_gear_dialog != "":
		return
	if step_id == "dock":
		_waiting_dock_prompt = true
		_last_cast_count = _get_cast_count()
		_last_fish_time = Time.get_ticks_msec() / 1000.0
		return
	if _tutorial_step_dialogs.has(step_id):
		say(_tutorial_step_dialogs[step_id])
	elif Objectives.current_dialog() != "":
		say(Objectives.current_dialog())

## 统一保护整杆钓鱼：等待、上钩、连钓间歇、逐条渔获展示都算忙碌。
func _fishing_busy() -> bool:
	if _boat == null:
		return false
	var fishing := _boat.get_node_or_null("Fishing")
	return fishing != null and fishing.is_fishing_active()


## 任务交接同时等待港口菜单、卖鱼/升级等子面板关闭。
func _interaction_busy() -> bool:
	if _fishing_busy():
		return true
	if _boat == null:
		return false
	var docking := _boat.get_node_or_null("docking")
	return docking != null and docking.is_interaction_open()


func _chapter_transition_pending() -> bool:
	return not _pending_fishing_chapter.is_empty() or (_chapter_card != null and _chapter_card.visible)


func _flush_fishing_events() -> void:
	if _interaction_busy():
		return
	if not _pending_fishing_chapter.is_empty():
		var info := _pending_fishing_chapter
		_pending_fishing_chapter = {}
		_chapter_card.show_chapter(str(info.get("title", "")), str(info.get("quote", "")))
	if _chapter_card != null and _chapter_card.visible:
		return
	if _pending_commission_check:
		_pending_commission_check = false
		_check_commission_unlocks()
	var lines := _deferred_fishing_dialogs.duplicate()
	_deferred_fishing_dialogs.clear()
	for line: String in lines:
		say(line)
	for notice: Dictionary in _deferred_fishing_toasts:
		show_toast(str(notice["text"]), float(notice["duration"]))
	_deferred_fishing_toasts.clear()


## 升级/试钓任务通过已有对话框交接，避开港口面板和渔获展示。
func _check_pending_gear_dialog() -> void:
	if _chapter_transition_pending():
		return
	if _pending_gear_dialog == "" or _pending_gear_dialog != Objectives.current_id():
		return
	var docking := _boat.get_node_or_null("docking")
	if docking != null and docking.is_interaction_open():
		return
	var fishing := _boat.get_node_or_null("Fishing")
	if fishing != null and fishing.is_fishing_active():
		return
	if _dialog == null or _dialog.is_showing():
		return
	_pending_gear_dialog = ""
	say(Objectives.current_dialog())


var _waiting_dock_prompt := false
var _last_cast_count := 0
var _last_fish_time := 0.0
const DOCK_PROMPT_IDLE := 20.0
const DOCK_PROMPT_SPEED := 80.0

func _get_cast_count() -> int:
	var fishing := _boat.get_node_or_null("Fishing")
	if fishing != null:
		return int(fishing.get("cast_count"))
	return 0

func _check_dock_prompt() -> void:
	if not _waiting_dock_prompt:
		return
	var cc := _get_cast_count()
	if cc > _last_cast_count:
		_last_cast_count = cc
		_last_fish_time = Time.get_ticks_msec() / 1000.0
		return
	var idle := Time.get_ticks_msec() / 1000.0 - _last_fish_time
	var moving := false
	if _boat is CharacterBody2D:
		moving = (_boat as CharacterBody2D).velocity.length() > DOCK_PROMPT_SPEED
	if idle >= DOCK_PROMPT_IDLE or moving:
		_waiting_dock_prompt = false
		say(_tutorial_step_dialogs["dock"])


func _physics_process(delta: float) -> void:
	var weight := 1.0 - exp(-CAMERA_FOLLOW * delta)
	_camera.position = _camera.position.lerp(_boat.position, weight)
	_trauma = maxf(_trauma - SHAKE_DECAY * delta, 0.0)  # 震屏衰减
	_flush_fishing_events()
	_check_dock_prompt()
	_check_pending_gear_dialog()
	var s := _trauma * _trauma * SHAKE_SCALE
	_camera.offset = Vector2(randf_range(-s, s), randf_range(-s, s))
	if _zone_toast_timer > 0.0:
		_zone_toast_timer -= delta
		if _zone_toast_timer <= 0.0:
			_zone_toast.visible = false
	var deep := _boat_in_deep()
	var deep_unlocked := Objectives.is_deep_unlocked()
	if deep and not _was_deep:
		if not Objectives.is_sleep_unlocked() and _is_night():
			# 首次深海之夜：解锁睡觉，重点解释夜晚海怪（只说一次）
			Objectives.mark_night_deep_seen()
			say("夜晚的深海完全不一样！海怪看得更远、游得更快，直线跑是跑不掉的，只能躲回浅水区。撑不住就回港睡一觉，直接跳到天亮。")
		elif deep_unlocked:
			say("这里就是深海区了……鱼应该更值钱，但愿别碰上海怪。")
		else:
			say("雾里好像有什么在盯着我……还是先回去吧。（完成灯塔看守老林的委托，修好探照灯再来）")
	elif not deep and _was_deep:
		_show_zone_toast("回到浅水区，安全了", 2.5)
	_was_deep = deep
	# 恐惧遮罩：未解锁深海准入时在深海区显示，呼吸闪烁
	var fear := deep and not deep_unlocked
	_fear_overlay.visible = fear
	if fear:
		var breath := 0.75 + 0.25 * sin(Time.get_ticks_msec() / 600.0)
		_fear_overlay.modulate = Color(breath, breath, breath, 1.0)
