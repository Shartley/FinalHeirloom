extends Node
## Owner: Daniel A. Owns held items, selection, pickup/drop, abilities and curses.

# One carried heirloom matches the original concept. Increase this in Inspector
# to use the collected-inventory/Tab behavior of the previous prototype.
@export_range(1, 3, 1) var max_carried_heirlooms: int = 1
@onready var state = get_node("/root/GameState")
@onready var main = get_parent()
var selected_index: int = -1
var curse_remaining: float = 0.0
var world_heirlooms: Dictionary = {}
var initial_transforms: Dictionary = {}
var remembered_heirlooms: Array[String] = []

const MEMORIES: Dictionary = {
    "Grandfather's Watch": "Grandfather waited here for a dawn that never freed him.",
    "Mother's Mirror": "Mother hid the family key where only her reflection could see it.",
    "Music Box": "Grandmother's melody is the promise that opens the sealed passage."
}

func _ready() -> void:
    for object in main.get_node("World").get_children():
        if object.get("kind") == "heirloom":
            world_heirlooms[object.heirloom_name] = object
            initial_transforms[object.heirloom_name] = object.global_transform
    state.ability_applied.connect(_on_ability_applied)

func _process(delta: float) -> void:
    if main.can_act():
        curse_remaining = maxf(0.0, curse_remaining - delta)

func reset_for_loop() -> void:
    state.collected_heirlooms.clear()
    state.collected_items.clear()
    remembered_heirlooms.clear()
    selected_index = -1
    curse_remaining = 0.0
    state.set_time_effect("normal")
    state.set_active_heirloom("None")
    for heirloom_name in world_heirlooms:
        var object: Node3D = world_heirlooms[heirloom_name]
        object.global_transform = initial_transforms[heirloom_name]
        object.visible = true
        object.collision_layer = 1
    state.inventory_changed.emit()

func collect_heirloom(heirloom_name: String, source: Node3D = null) -> bool:
    if not main.can_act() or not world_heirlooms.has(heirloom_name):
        return false
    if heirloom_name in state.collected_heirlooms:
        return false
    if source == null:
        source = world_heirlooms[heirloom_name]
    if not source.visible:
        return false
    if state.collected_heirlooms.size() >= max_carried_heirlooms:
        # Exchange on the same pedestal so neither item becomes unreachable.
        _place_in_world(state.active_heirloom, source.global_transform)
        state.collected_heirlooms.erase(state.active_heirloom)
    state.collected_heirlooms.append(heirloom_name)
    source.visible = false
    source.collision_layer = 0
    _select(state.collected_heirlooms.find(heirloom_name))
    state.inventory_changed.emit()
    var memory: String = ""
    if heirloom_name not in remembered_heirlooms:
        remembered_heirlooms.append(heirloom_name)
        memory = "\nMemory: " + str(MEMORIES[heirloom_name])
    main.show_message("Holding " + heirloom_name + "." + memory)
    return true

func switch_heirloom() -> void:
    if not main.can_act() or state.collected_heirlooms.is_empty():
        return
    if state.collected_heirlooms.size() == 1:
        main.show_message("You can carry one heirloom. Pick up another to swap; G drops this one." if max_carried_heirlooms == 1 else "Find another heirloom before switching; G drops this one.")
        return
    _select((selected_index + 1) % state.collected_heirlooms.size())

func drop_active(player: CharacterBody3D) -> bool:
    if not main.can_act() or state.active_heirloom == "None":
        return false
    for offset in [Vector3(1.8, 0, 0), Vector3(-1.8, 0, 0), Vector3(0, 0, 1.8), Vector3(0, 0, -1.8)]:
        var point: Vector3 = player.global_position + offset
        point.y = 0.8
        var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3(0, 0.3, 0), point, 1, [player.get_rid()])
        if not player.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
            continue
        var dropped: String = state.active_heirloom
        _place_in_world(dropped, Transform3D(Basis.IDENTITY, point))
        state.collected_heirlooms.erase(dropped)
        _select(0 if not state.collected_heirlooms.is_empty() else -1)
        state.inventory_changed.emit()
        main.show_message("Dropped " + dropped + ". You can pick it up again.")
        return true
    main.show_message("Move into a clear space before dropping this heirloom.")
    return false

func collect_key() -> bool:
    if not main.can_act() or "Family Key" in state.collected_items:
        return false
    state.collected_items.append("Family Key")
    state.inventory_changed.emit()
    return true

func has_item(item_name: String) -> bool:
    return item_name in state.collected_items

func use_active(target: Node3D = null) -> void:
    if not main.can_act():
        return
    if state.active_heirloom == "None":
        main.show_message("Find an heirloom first.")
    elif state.active_heirloom == "Grandfather's Watch":
        state.set_time_effect("normal" if state.time_effect == "slow" else "slow")
        main.show_message("Time stretches. The watch ages your body; your steps grow heavy." if state.time_effect == "slow" else "The watch closes. Time and your steps return to normal.")
    else:
        if target == null:
            target = main.get_node("Player").nearby_target()
        state.heirloom_used.emit(state.active_heirloom, target)

func movement_multiplier() -> float:
    return 0.65 if state.time_effect == "slow" else (0.75 if curse_remaining > 0.0 else 1.0)

func curse_text() -> String:
    if state.time_effect == "slow":
        return "WATCH ACTIVE • Dawn slowed / body aged"
    if curse_remaining > 0.0:
        return "THE HOUSE STIRS • Heavy steps for %.0fs" % ceil(curse_remaining)
    match state.active_heirloom:
        "Grandfather's Watch": return "Q slows dawn • Curse: your steps slow while active"
        "Mother's Mirror": return "Q reveals secrets • Curse: a successful reveal costs 5s"
        "Music Box": return "Q opens melody seals • Curse: a successful song costs 8s"
        _: return "E picks up an heirloom • Each holds a memory, ability and curse"

func _on_ability_applied(heirloom_name: String) -> void:
    # Repeated or invalid puzzle attempts never charge another curse.
    if heirloom_name != state.active_heirloom:
        return
    curse_remaining = 4.0
    state.time_cost_requested.emit(5.0 if heirloom_name == "Mother's Mirror" else 8.0)

func _select(index: int) -> void:
    selected_index = index
    state.set_time_effect("normal")
    state.set_active_heirloom(state.collected_heirlooms[index] if index >= 0 else "None")

func _place_in_world(heirloom_name: String, placement: Transform3D) -> void:
    var object: Node3D = world_heirlooms[heirloom_name]
    object.global_transform = placement
    object.visible = true
    object.collision_layer = 1
