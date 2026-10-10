extends CanvasLayer
## 主人公对话框：底部头像 + 名字 + 文字，按 E/点击关闭，支持排队。
## 用于叙事性提示（进深海、碎片、委托等），系统反馈（做饵/睡觉）仍用 toast。
## 水彩风：米白底 + 深青描边，与 ui_style.gd 一致。

const UI_STYLE := preload("res://scripts/ui_style.gd")
const AVATAR := preload("res://assets/final/fisher_avatar.png")

var _panel: PanelContainer
var _avatar: TextureRect
var _name_label: Label
var _text_label: Label
var _queue: Array = []
var _is_showing := false
var _auto_timer := 0.0
const AUTO_DISMISS := 4.0


func _ready() -> void:
	layer = 50
	_build()
	hide_box()


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UI_STYLE.panel_box())
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.offset_top = -180.0
	_panel.offset_bottom = -20.0
	_panel.offset_left = -320.0
	_panel.offset_right = 320.0
	add_child(_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_panel.add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 4)
	margin.add_child(outer)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	outer.add_child(hbox)
	_avatar = TextureRect.new()
	_avatar.texture = AVATAR
	_avatar.custom_minimum_size = Vector2(64, 64)
	_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(_avatar)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	_name_label = Label.new()
	_name_label.text = "阿舟"
	UI_STYLE.style_title(_name_label)
	_name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_name_label)
	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size = Vector2(480, 66)
	UI_STYLE.style_body(_text_label)
	vbox.add_child(_text_label)
	var hint := Label.new()
	hint.text = "按 E / 点击跳过 ▸"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI_STYLE.style_secondary(hint)
	hint.add_theme_font_size_override("font_size", 13)
	outer.add_child(hint)


func say(text: String) -> void:
	_queue.append(text)
	if not _is_showing:
		_next()


func _next() -> void:
	if _queue.is_empty():
		hide_box()
		return
	_is_showing = true
	_text_label.text = _queue.pop_front()
	_panel.visible = true
	_auto_timer = AUTO_DISMISS


func hide_box() -> void:
	_is_showing = false
	_panel.visible = false


func is_showing() -> bool:
	return _is_showing


func _process(delta: float) -> void:
	if not _is_showing:
		return
	_auto_timer -= delta
	if _auto_timer <= 0.0:
		_next()


func _input(event: InputEvent) -> void:
	if not _is_showing:
		return
	var ending := get_tree().current_scene.get_node_or_null("EndingPanel")
	if ending != null and ending.is_open():
		return
	if event.is_action_pressed("fish") or event.is_action_pressed("ui_accept"):
		_next()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_next()
		get_viewport().set_input_as_handled()
