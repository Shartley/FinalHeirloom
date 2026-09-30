extends Node3D

@onready var state: Node = get_node("/root/GameState")
@onready var timer_label: Label = $UI/Margin/VBox/Timer
@onready var heirloom_label: Label = $UI/Margin/VBox/Heirloom
@onready var objective_label: Label = $UI/Margin/VBox/Objective
@onready var message_label: Label = $UI/Message
@onready var loop_label: Label = $UI/Margin/VBox/Loop
@onready var hidden_key: StaticBody3D = $World/HiddenKey
@onready var attic_blocker: StaticBody3D = $World/AtticDoor
@onready var upstairs_light: OmniLight3D = $World/UpstairsLight
var won := false
var paused := false
var message_tween: Tween
var prompt: Label
var pause_label: Label

func _ready() -> void:
    _decorate()
    state.time_remaining_changed.connect(_on_time_changed)
    state.active_heirloom_changed.connect(_on_heirloom_changed)
    hidden_key.visible = false
    hidden_key.collision_layer = 0
    _on_time_changed(state.time_remaining)
    _on_heirloom_changed(state.active_heirloom)
    loop_label.text = "Generation: %d" % (state.loop_count + 1)
    show_message("Escape before dawn. E interact • TAB switch • Q use heirloom")

func _process(_delta: float) -> void:
    if state.time_remaining < 45.0:
        upstairs_light.light_energy = 2.0 + sin(Time.get_ticks_msec() / 110.0) * 0.7
    objective_label.text = _objective_text()
    var target = $Player.nearby_target()
    prompt.text = "[E / Q] " + target.get_meta("title", target.name) if target else "Explore the house • Approach an object to interact"
    if won or paused:
        prompt.text = ""
    heirloom_label.text = "Heirloom: " + state.active_heirloom + ("  • TIME SLOWED / MOVEMENT HEAVY" if state.time_effect == "slow" else "")

func _objective_text() -> String:
    if state.puzzle_flags["front_door_unlocked"]:
        return "Return to the front door and escape."
    if state.puzzle_flags["mirror_revealed"]:
        return "Collect the key beneath the portrait."
    if not state.puzzle_flags["attic_unlocked"]:
        return "Find the Music Box. Play it at the carved melody seal."
    return "Open the attic passage. Use Mother's Mirror at the portrait."

func restart_run() -> void:
    state.reset_run()
    get_tree().reload_current_scene()

func toggle_pause() -> void:
    paused = not paused
    pause_label.visible = paused
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED

func _on_time_changed(value: float) -> void:
    var secs := int(ceil(value))
    timer_label.text = "Dawn in %02d:%02d" % [secs / 60, secs % 60]
    if value < 30:
        timer_label.modulate = Color(1.0, 0.55, 0.35)

func _on_heirloom_changed(value: String) -> void:
    heirloom_label.text = "ActiveHeirloom: " + value

func show_message(text: String) -> void:
    message_label.text = text
    message_label.modulate.a = 1.0
    if message_tween:
        message_tween.kill()
    message_tween = create_tween()
    message_tween.tween_interval(4.0)
    message_tween.tween_property(message_label, "modulate:a", 0.0, 0.6)

func reveal_hidden_key() -> void:
    if state.puzzle_flags["front_door_unlocked"]:
        return
    hidden_key.visible = true
    hidden_key.collision_layer = 1

func unlock_attic() -> void:
    attic_blocker.scale = Vector3(1.04, 1.04, 1.04)

func open_attic_door() -> void:
    attic_blocker.visible = false
    attic_blocker.collision_layer = 0

func win_game() -> void:
    if won:
        return
    won = true
    $TimeSystem.running = false
    $UI/WinPanel.visible = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    state.game_won.emit()

func _decorate() -> void:
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("17121e")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("b5acc1")
    environment.ambient_light_energy = 0.65
    $World/WorldEnvironment.environment = environment
    var titles := {"Watch": "Grandfather's Watch", "Mirror": "Mother's Mirror", "MusicBox": "Music Box", "MusicPuzzle": "Carved melody seal", "PortraitPuzzle": "James family portrait", "AtticDoor": "Attic passage", "ExitDoor": "Front door", "HiddenKey": "Family key", "Lore": "Family letter"}
    for object_name in titles:
        var object = $World.get_node(object_name)
        object.set_meta("title", titles[object_name])
        var label := Label3D.new()
        label.text = titles[object_name]
        label.position.y = 1.5
        label.font_size = 38
        label.pixel_size = 0.008
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        label.modulate = Color("e5d4ad")
        object.add_child(label)
    for x in range(-11, 12, 2):
        for z in range(-13, 14, 2):
            var tile := MeshInstance3D.new()
            var mesh := BoxMesh.new()
            mesh.size = Vector3(2, 0.015, 2)
            tile.mesh = mesh
            var mat := StandardMaterial3D.new()
            mat.albedo_color = Color("837969") if (x + z) % 4 == 0 else Color("301703")
            mat.roughness = 0.35
            tile.material_override = mat
            tile.position = Vector3(x, 0.11, z)
            $World.add_child(tile)
    # A sealed rear chamber makes the music puzzle gate actual exploration.
    for x in [-7.0, 7.0]:
        var wall := StaticBody3D.new()
        wall.position = Vector3(x, 2.5, -8)
        var shape := BoxShape3D.new()
        shape.size = Vector3(10, 5, 0.3)
        var collision := CollisionShape3D.new()
        collision.shape = shape
        wall.add_child(collision)
        var visual := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = shape.size
        visual.mesh = box
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color("261809")
        visual.material_override = mat
        wall.add_child(visual)
        $World.add_child(wall)
    prompt = Label.new()
    prompt.position = Vector2(260, 560)
    prompt.size = Vector2(760, 40)
    prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt.add_theme_font_size_override("font_size", 21)
    $UI.add_child(prompt)
    var controls := Label.new()
    controls.text = "WASD move   •   Mouse look   •   E interact   •   Q use   •   Tab equip   •   Esc pause   •   R new game"
    controls.position = Vector2(120, 690)
    controls.add_theme_font_size_override("font_size", 17)
    $UI.add_child(controls)
    pause_label = Label.new()
    pause_label.text = "PAUSED\nEsc to resume • R to start over"
    pause_label.position = Vector2(390, 290)
    pause_label.add_theme_font_size_override("font_size", 30)
    pause_label.visible = false
    $UI.add_child(pause_label)
    $UI/Crosshair.visible = false
