extends Node
## Owner: Samaii H. Owns puzzles, physical gates, secrets and house reactions.

@onready var state = get_node("/root/GameState")
@onready var main = get_parent()
@onready var inventory = main.get_node("InventorySystem")
@onready var world: Node3D = main.get_node("World")
@onready var hidden_key: StaticBody3D = world.get_node("HiddenKey")
@onready var attic_door: StaticBody3D = world.get_node("AtticDoor")
@onready var chandelier: OmniLight3D = world.get_node("Chandelier")
@onready var upstairs_light: OmniLight3D = world.get_node("UpstairsLight")
var night_stage: String = "quiet"
var elapsed: float = 0.0
var puzzle_materials: Dictionary = {}

func _ready() -> void:
	_decorate_house()
	state.active_heirloom_changed.connect(_on_active_heirloom_changed)
	state.time_remaining_changed.connect(_on_time_remaining_changed)
	state.heirloom_used.connect(_on_heirloom_used)
	state.inventory_changed.connect(_on_inventory_changed)

func reset_for_loop() -> void:
	state.puzzle_flags = {
		"music_box_open": false,
		"attic_unlocked": false,
		"attic_open": false,
		"mirror_revealed": false,
		"front_door_unlocked": false
	}
	hidden_key.visible = false
	hidden_key.collision_layer = 0
	attic_door.visible = true
	attic_door.collision_layer = 1
	attic_door.scale = Vector3.ONE
	night_stage = "quiet"
	elapsed = 0.0
	_on_time_remaining_changed(state.time_remaining)
	_on_active_heirloom_changed(state.active_heirloom)
	_on_inventory_changed()

func _process(delta: float) -> void:
	if main.paused or main.won:
		return
	elapsed += delta
	var pulse: float = sin(elapsed * (5.0 if night_stage == "restless" else 9.0))
	chandelier.light_energy = 2.4 if night_stage == "quiet" else 1.65 + pulse * 0.30
	upstairs_light.light_energy = 1.65 if night_stage == "quiet" else 1.45 + pulse * 0.45

func interact_object(object: Node3D, player: CharacterBody3D) -> void:
	if not main.can_act() or not object.visible or object.collision_layer == 0:
		return
	if player.nearby_target() != object:
		main.show_message("Move closer to the object; walls block interactions.")
		return
	match object.get("kind"):
		"heirloom":
			inventory.collect_heirloom(object.heirloom_name, object)
		"mirror_puzzle", "music_puzzle":
			inventory.use_active(object)
		"attic_door":
			if state.puzzle_flags["attic_unlocked"]:
				_set_flag("attic_open", true)
				attic_door.visible = false
				attic_door.collision_layer = 0
				main.show_message("The passage opens. Take Mother's Mirror to the portrait beyond it.")
			else:
				main.show_message("The passage is sealed. Its carving needs the Music Box's melody.")
		"exit_door":
			if state.puzzle_flags["front_door_unlocked"]:
				main.win_game()
			else:
				main.show_message("The front door is locked. Find the James family key.")
		"key":
			if inventory.collect_key():
				hidden_key.visible = false
				hidden_key.collision_layer = 0
				main.show_message("The family key is yours. Return to the front door before dawn.")
		"lore":
			main.show_message(object.text)

func objective_text() -> String:
	if state.puzzle_flags.get("front_door_unlocked", false):
		return "Return to the front door and escape."
	if state.puzzle_flags.get("mirror_revealed", false):
		return "Pick up the key beneath the portrait."
	if not state.puzzle_flags.get("attic_unlocked", false):
		return "Take the Music Box to the carved melody seal."
	if not state.puzzle_flags.get("attic_open", false):
		return "The seal is broken. Open the central passage."
	return "Take Mother's Mirror to the portrait in the rear chamber."

func _on_heirloom_used(heirloom_name: String, target: Node3D) -> void:
	if not main.can_act():
		return
	if target == null or main.get_node("Player").nearby_target() != target:
		main.show_message("Use the Music Box near the carved seal, or the Mirror near the family portrait.")
		return
	if heirloom_name == "Music Box" and target.get("kind") == "music_puzzle":
		if state.puzzle_flags["music_box_open"]:
			main.show_message("The melody seal is already open. Head to the central passage.")
			return
		_set_flag("music_box_open", true)
		_set_flag("attic_unlocked", true)
		main.show_message("Grandmother's song releases the seal. The curse takes 8 seconds; your steps grow heavy.")
		state.ability_applied.emit(heirloom_name)
	elif heirloom_name == "Mother's Mirror" and target.get("kind") == "mirror_puzzle":
		if not state.puzzle_flags["attic_open"]:
			main.show_message("Open the passage before trying to reach the portrait.")
			return
		if state.puzzle_flags["mirror_revealed"]:
			main.show_message("The mirror has already revealed this secret.")
			return
		_set_flag("mirror_revealed", true)
		hidden_key.visible = true
		hidden_key.collision_layer = 1
		main.show_message("Mother's reflection exposes the key. The curse takes 5 seconds; your steps grow heavy.")
		state.ability_applied.emit(heirloom_name)
	else:
		main.show_message("This object needs a different heirloom. The seal needs a song; the portrait needs a reflection.")

func _on_active_heirloom_changed(value: String) -> void:
	# ActiveHeirloom: the puzzle visuals respond to the item being held.
	var music_material: StandardMaterial3D = puzzle_materials["MusicPuzzle"]
	var portrait_material: StandardMaterial3D = puzzle_materials["PortraitPuzzle"]
	music_material.emission_enabled = value == "Music Box"
	portrait_material.emission_enabled = value == "Mother's Mirror"

func _on_time_remaining_changed(value: float) -> void:
	# TimeRemaining: late-night changes use the actual slowed countdown.
	night_stage = "dawn" if value <= 20.0 else ("restless" if value <= 60.0 else "quiet")
	var environment: Environment = world.get_node("WorldEnvironment").environment
	environment.ambient_light_energy = 0.35 if night_stage == "quiet" else 0.27

func _on_inventory_changed() -> void:
	# Inventory owns the normal key; only Environment changes the door lock.
	if not state.puzzle_flags.is_empty():
		_set_flag("front_door_unlocked", inventory.has_item("Family Key"))

func _set_flag(flag: String, value: bool) -> void:
	if state.puzzle_flags.get(flag, false) == value:
		return
	state.puzzle_flags[flag] = value
	state.puzzle_changed.emit(flag, value)

func _decorate_house() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("17121e")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b5acc1")
	environment.ambient_light_energy = 0.35
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.get_node("WorldEnvironment").environment = environment
	var visuals = preload("res://scripts/house_visuals.gd").new()
	visuals.name = "HouseVisuals"
	world.add_child(visuals)
	puzzle_materials = visuals.build(world, main.get_node("Player"))
