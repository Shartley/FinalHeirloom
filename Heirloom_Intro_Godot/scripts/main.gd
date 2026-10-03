extends Node3D
## Coordinates the three systems and presents their state to the player.

@onready var state = get_node("/root/GameState")
@onready var time_system = $TimeSystem
@onready var inventory = $InventorySystem
@onready var environment_system = $EnvironmentSystem
@onready var timer_label: Label = $UI/Margin/VBox/Timer
@onready var heirloom_label: Label = $UI/Margin/VBox/Heirloom
@onready var objective_label: Label = $UI/Margin/VBox/Objective
@onready var message_label: Label = $UI/Message
@onready var loop_label: Label = $UI/Margin/VBox/Loop

var won: bool = false
var paused: bool = false
var message_tween: Tween
var prompt: Label
var pause_label: Label
var effects_label: Label
var night_label: Label
var spawn_transform: Transform3D
var intro_active: bool = true
var intro_layer: CanvasLayer

func _ready() -> void:
	spawn_transform = $Player.global_transform
	_build_ui()
	state.time_remaining_changed.connect(_on_time_changed)
	state.active_heirloom_changed.connect(_on_heirloom_changed)
	state.loop_restarted.connect(_on_loop_restarted)
	state.dawn_reached.connect(_on_dawn_reached)
	time_system.reset_run()
	_build_intro()

func can_act() -> bool:
	return not won and not paused and state.run_status == "playing"

func _process(_delta: float) -> void:
	objective_label.text = environment_system.objective_text()
	var target = $Player.nearby_target() if can_act() else null
	prompt.text = "[E] " + str(target.get_meta("title", target.name)) if target else "Approach a labeled object to interact"
	if target and target.get("kind") in ["music_puzzle", "mirror_puzzle"]:
		prompt.text += "  •  [Q] use held heirloom"
	if not can_act():
		prompt.text = ""
	effects_label.text = inventory.curse_text()
	night_label.text = {"quiet": "The house waits.", "restless": "Less than a minute. The house is stirring.", "dawn": "Dawn is close. Finish the family's mission."}[environment_system.night_stage]
	heirloom_label.text = "Holding: " + state.active_heirloom
	if inventory.has_item("Family Key"):
		heirloom_label.text += "  •  Family key"

func restart_run() -> void:
	if intro_active:
		return
	time_system.reset_run()

func toggle_pause() -> void:
	if won or intro_active:
		return
	paused = not paused
	pause_label.visible = paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED

func _on_loop_restarted(loop_count: int) -> void:
	won = false
	paused = intro_active
	inventory.reset_for_loop()
	environment_system.reset_for_loop()
	$Player.global_transform = spawn_transform
	$Player.velocity = Vector3.ZERO
	$Player/Pivot.rotation = Vector3.ZERO
	$UI/WinPanel.visible = false
	pause_label.visible = false
	loop_label.text = "Generation: %d" % (loop_count + 1)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if intro_active else Input.MOUSE_MODE_CAPTURED
	_on_time_changed(state.time_remaining)
	if loop_count == 0:
		var limit_text: String = "Carry one heirloom; picking up another swaps it." if inventory.max_carried_heirlooms == 1 else "Carry up to %d heirlooms; Tab switches." % inventory.max_carried_heirlooms
		show_message("Escape the James family home before dawn. " + limit_text)
	else:
		show_message("Generation %d inherits the unfinished curse. The house resets; %.0f seconds remain until dawn." % [loop_count + 1, state.generation_duration])

func _on_dawn_reached(_generation: int) -> void:
	$Player.velocity = Vector3.ZERO
	show_message("Dawn has trapped you. The unfinished curse passes to the next generation.")

func _on_time_changed(value: float) -> void:
	var seconds: int = int(ceil(value))
	var minutes: int = seconds / 60
	timer_label.text = "Dawn in %02d:%02d" % [minutes, seconds % 60]
	timer_label.modulate = Color("ff9868") if value <= 30.0 else Color.WHITE

func _on_heirloom_changed(value: String) -> void:
	heirloom_label.text = "Holding: " + value

func show_message(text: String) -> void:
	message_label.text = text
	message_label.modulate.a = 1.0
	if message_tween:
		message_tween.kill()
	message_tween = create_tween()
	message_tween.tween_interval(6.0)
	message_tween.tween_property(message_label, "modulate:a", 0.0, 0.6)

func win_game() -> void:
	if not can_act() or not inventory.has_item("Family Key"):
		return
	won = true
	state.run_status = "won"
	time_system.running = false
	$Player.velocity = Vector3.ZERO
	$UI/WinPanel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	state.game_won.emit()

func _start_game() -> void:
	if not intro_active:
		return
	intro_active = false
	intro_layer.hide()
	$UI.show()
	time_system.reset_run()

func _build_intro() -> void:
	$UI.hide()
	intro_layer = CanvasLayer.new()
	intro_layer.name = "Intro"
	intro_layer.layer = 10
	add_child(intro_layer)
	var background := ColorRect.new()
	background.color = Color(0.035, 0.025, 0.030, 0.90)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_layer.add_child(background)
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(780, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("211b1a")
	style.border_color = Color("9b7749")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.name = "VBox"
	content.add_theme_constant_override("separation", 18)
	margin.add_child(content)
	var title := Label.new()
	title.text = "HEIRLOOM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.modulate = Color("ddbd82")
	content.add_child(title)
	var objective := Label.new()
	objective.text = "Escape the cursed family home before dawn."
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective.add_theme_font_size_override("font_size", 22)
	objective.modulate = Color("f0e5d2")
	content.add_child(objective)
	var instructions := Label.new()
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.add_theme_font_size_override("font_size", 20)
	instructions.modulate = Color("e0d3bf")
	content.add_child(instructions)
	var controls := Label.new()
	controls.text = "WASD — move     Mouse — look     E — interact / swap\nQ — use heirloom     G — drop     Esc — pause     R — new game"
	if inventory.max_carried_heirlooms > 1:
		controls.text += "\nTab — equip another heirloom"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 18)
	controls.modulate = Color("c4b397")
	content.add_child(controls)
	var start := Button.new()
	start.name = "StartButton"
	start.text = "START GAME"
	start.custom_minimum_size.y = 52
	start.add_theme_font_size_override("font_size", 22)
	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color("bb935e")
	button_style.set_corner_radius_all(4)
	start.add_theme_stylebox_override("normal", button_style)
	var hover_style: StyleBoxFlat = button_style.duplicate()
	hover_style.bg_color = Color("d6b27e")
	start.add_theme_stylebox_override("hover", hover_style)
	start.add_theme_stylebox_override("focus", hover_style)
	start.add_theme_color_override("font_color", Color("211b1a"))
	start.add_theme_color_override("font_hover_color", Color("211b1a"))
	start.add_theme_color_override("font_focus_color", Color("211b1a"))
	start.pressed.connect(_start_game)
	content.add_child(start)
	start.grab_focus()

func _build_ui() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.055, 0.043, 0.040, 0.84)
	panel_style.border_color = Color(0.64, 0.48, 0.27, 0.75)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	var status_panel := Panel.new()
	status_panel.position = Vector2(16, 16)
	status_panel.size = Vector2(520, 277)
	status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_panel.add_theme_stylebox_override("panel", panel_style)
	$UI.add_child(status_panel)
	$UI.move_child(status_panel, 0)
	$UI/Margin.offset_left = 32.0
	$UI/Margin.offset_top = 27.0
	$UI/Margin.offset_right = 520.0
	var title := Label.new()
	title.text = "HEIRLOOM   /   THE JAMES HOUSE"
	title.add_theme_font_size_override("font_size", 19)
	title.modulate = Color("ddbd82")
	$UI/Margin/VBox.add_child(title)
	$UI/Margin/VBox.move_child(title, 0)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size.y = 45.0
	effects_label = Label.new()
	effects_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effects_label.add_theme_font_size_override("font_size", 17)
	effects_label.modulate = Color("dfbd8b")
	$UI/Margin/VBox.add_child(effects_label)
	night_label = Label.new()
	night_label.add_theme_font_size_override("font_size", 17)
	night_label.modulate = Color("c6bed5")
	$UI/Margin/VBox.add_child(night_label)
	prompt = Label.new()
	prompt.position = Vector2(90, 560)
	prompt.size = Vector2(1100, 40)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 21)
	$UI.add_child(prompt)
	message_label.offset_left = 90.0
	message_label.offset_right = 1190.0
	message_label.offset_top = 610.0
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var controls := Label.new()
	controls.text = "WASD move   •   Mouse look   •   E interact / swap   •   Q use   •   G drop   •   Esc pause   •   R new game"
	if inventory.max_carried_heirlooms > 1:
		controls.text += "   •   Tab equip"
	controls.position = Vector2(115, 690)
	controls.add_theme_font_size_override("font_size", 17)
	controls.add_theme_color_override("font_shadow_color", Color.BLACK)
	controls.add_theme_constant_override("shadow_offset_y", 2)
	$UI.add_child(controls)
	pause_label = Label.new()
	pause_label.text = "PAUSED\nEsc to resume • R to start over"
	pause_label.position = Vector2(390, 290)
	pause_label.add_theme_font_size_override("font_size", 30)
	pause_label.visible = false
	$UI.add_child(pause_label)
	$UI/WinPanel.add_theme_stylebox_override("panel", panel_style.duplicate())
	for text_label in [prompt, message_label, pause_label]:
		text_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		text_label.add_theme_constant_override("shadow_offset_x", 2)
		text_label.add_theme_constant_override("shadow_offset_y", 2)
	$UI/Crosshair.visible = false
