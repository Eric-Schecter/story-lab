extends CanvasLayer
## 终局面板：第 4 个委托完成后，老林与你的最终抉择。
## 三选一：点亮探照灯 / 交给老林 / 柔光（需集齐 5 碎片）。
## 流程：开场白（点击推进）→ 选项 → 结局文本 → 关闭。

const UI_STYLE := preload("res://scripts/ui_style.gd")

const INTRO_LINES := [
	"鲸落之光在你手里微微发烫。老林站在灯塔下，等了你很久。",
	"“东西拿到了……那就到了做决定的时候了。”",
	"“点亮探照灯，雾会散，真相大白——但光会把它引醒。”",
	"“或者把光给我，我把它沉进海里。我们继续守着这个秘密。”",
]

const ENDINGS := {
	"light": {
		"title": "点亮探照灯",
		"desc": "亲手点亮，驱散雾海，直面未知。",
		"text": [
			"你亲手把鲸落之光装进探照灯。",
			"光柱刺破雾海，深海的雾开始散了。码头上的人们欢呼起来。",
			"但海面下，有巨大的阴影翻了个身。",
			"老林按住你的肩膀：“从今天起，守夜的人，多了一个。”",
			"—— 主线完成。雾海散了，但深海里有什么，醒了。",
		],
	},
	"entrust": {
		"title": "交给老林",
		"desc": "把选择权交给守了三年的人。",
		"text": [
			"你把鲸落之光交给了老林。",
			"他看了很久，把它沉进了海里。“有些秘密，守比说难。”",
			"“三年了，我一个人守。现在，有你陪我了。”",
			"他塞给你 500 金币：“拿去，别说出去。”",
			"—— 主线完成。雾还在，但你们守住了比雾更重要的东西。",
		],
		"reward_coins": 500,
	},
	"gentle": {
		"title": "柔光",
		"desc": "集齐 5 个漂流瓶碎片、补全鱼类图鉴后，用碎片中的知识打造柔光罩。",
		"requires_fragments": true,
		"requires_codex": true,
		"text": [
			"你想起碎片里的记载：雾鲸怕的不是光，是强光。",
			"你用剩下的碎片图纸，在作坊里打出了柔光罩。",
			"光变得温和，既照亮了航道，又没有惊醒它。",
			"雾散了。雾鲸还在睡。老林第一次笑了：“你比我聪明。”",
			"—— 主线完成（隐藏结局）。你找到了第三条路。",
		],
	},
}

var _panel: PanelContainer
var _title_label: Label
var _body_label: Label
var _btn_box: VBoxContainer
var _hint_label: Label

var _state := "idle"
var _intro_idx := 0
var _ending_id := ""


func _ready() -> void:
	layer = 60
	_build()
	visible = false


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UI_STYLE.panel_box())
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.custom_minimum_size = Vector2(560, 0)
	add_child(_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	_title_label = Label.new()
	_title_label.text = "终局：雾鲸之梦"
	UI_STYLE.style_title(_title_label)
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title_label)
	_body_label = Label.new()
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.custom_minimum_size = Vector2(520, 120)
	UI_STYLE.style_body(_body_label)
	vbox.add_child(_body_label)
	_btn_box = VBoxContainer.new()
	_btn_box.add_theme_constant_override("separation", 8)
	vbox.add_child(_btn_box)
	_hint_label = Label.new()
	_hint_label.text = "点击 / 按 E 继续 ▸"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UI_STYLE.style_secondary(_hint_label)
	_hint_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_hint_label)


func open() -> void:
	visible = true
	_state = "intro"
	_intro_idx = 0
	_show_intro()


func is_open() -> bool:
	return visible


func _show_intro() -> void:
	_clear_buttons()
	if _intro_idx < INTRO_LINES.size():
		_body_label.text = INTRO_LINES[_intro_idx]
		_hint_label.visible = true
	else:
		_show_choices()


func _show_choices() -> void:
	_state = "choice"
	_body_label.text = "鲸落之光在你手里。你会怎么做？"
	_hint_label.visible = false
	_clear_buttons()
	var has_fragments := Fragments.collected_count() >= 5
	var codex_done := Codex.is_complete()
	for eid in ["light", "entrust", "gentle"]:
		var e: Dictionary = ENDINGS[eid]
		var btn := Button.new()
		# 隐藏结局：条件不满足时只显示问号，不报还差N个这类任务式提示，不做引导
		var gentle_locked: bool = eid == "gentle" and not (has_fragments and codex_done)
		if gentle_locked:
			btn.text = "？？？——似乎还有第三条路……"
			btn.disabled = true
		else:
			var desc := str(e["desc"])
			btn.text = "%s——%s" % [str(e["title"]), desc]
			btn.pressed.connect(_on_choice.bind(eid))
		_btn_box.add_child(btn)


func _show_ending() -> void:
	_state = "ending"
	var e: Dictionary = ENDINGS[_ending_id]
	var lines: Array = e["text"]
	_body_label.text = "\n\n".join(lines)
	_hint_label.visible = true
	_clear_buttons()


func _clear_buttons() -> void:
	for c in _btn_box.get_children():
		c.queue_free()


func _on_choice(eid: String) -> void:
	_ending_id = eid
	_show_ending()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	# 选择阶段交给 GUI 按钮处理鼠标/确认键，不能在 _input 提前吞掉。
	if _state == "choice":
		if event.is_action_pressed("fish") or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
		return
	var advance := false
	if event.is_action_pressed("fish") or event.is_action_pressed("ui_accept"):
		advance = true
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			advance = true
	if not advance:
		return
	get_viewport().set_input_as_handled()
	if _state == "intro":
		_intro_idx += 1
		_show_intro()
	elif _state == "ending":
		_finish()


func _finish() -> void:
	var e: Dictionary = ENDINGS[_ending_id]
	var coins := int(e.get("reward_coins", 0))
	if coins > 0:
		Inventory.add_coins(coins)
	Objectives.set_ending(_ending_id)
	visible = false
	_state = "idle"
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("show_toast"):
		scene.show_toast("故事告一段落。现在，这片海是你的了——自由钓鱼吧！", 4.0)
