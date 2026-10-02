extends SceneTree
## Integration checks through player input, world targeting and real physics gates.

var failures: int = 0
var checks: int = 0
var main
var state
var inventory
var time_system
var environment_system
var player

func _initialize() -> void:
    call_deferred("run")

func check(condition: bool, description: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error("FAIL: " + description)

func press(action: String) -> void:
    var event := InputEventAction.new()
    event.action = action
    event.pressed = true
    player._unhandled_input(event)

func approach(object_name: String, offset: Vector3 = Vector3(0, 0, 1.8)) -> Node3D:
    var object: Node3D = main.get_node("World/" + object_name)
    player.global_position = object.global_position + offset
    player.global_position.y = 1.1
    player.velocity = Vector3.ZERO
    await physics_frame
    await physics_frame
    check(player.nearby_target() == object, "nearby targeting: " + object_name)
    return object

func gate_hit() -> Dictionary:
    var query := PhysicsRayQueryParameters3D.create(Vector3(0, 1.1, -6), Vector3(0, 1.1, -10), 1, [player.get_rid()])
    return player.get_world_3d().direct_space_state.intersect_ray(query)

func run() -> void:
    change_scene_to_file("res://scenes/Main.tscn")
    await process_frame
    await physics_frame
    main = current_scene
    main.get_node("Intro/Center/Panel/Margin/VBox/StartButton").pressed.emit()
    state = root.get_node("GameState")
    inventory = main.get_node("InventorySystem")
    time_system = main.get_node("TimeSystem")
    environment_system = main.get_node("EnvironmentSystem")
    player = main.get_node("Player")
    # Deterministic countdown; test ticks are explicit while physics still runs.
    time_system.set_process(false)
    inventory.set_process(false)
    check(InputMap.has_action("drop_heirloom"), "G drop input exists")
    check(InputMap.action_get_events("drop_heirloom")[0].physical_keycode == KEY_G, "drop bound to G")
    check(state.time_remaining == 180.0 and state.loop_count == 0, "initial timer and generation")
    check(not main.get_node("World/HiddenKey").visible, "secret initially hidden")
    check(not gate_hit().is_empty(), "sealed passage physically blocks movement")

    await approach("ExitDoor", Vector3(0, 0, -1.8))
    press("interact")
    check(not main.won, "cannot escape without key")
    await approach("MusicPuzzle")
    press("use_heirloom")
    check(not state.puzzle_flags["attic_unlocked"], "no item cannot solve seal")

    await approach("Watch")
    press("interact")
    press("use_heirloom")
    check(state.time_effect == "slow", "watch publishes TimeEffect")
    check(inventory.movement_multiplier() == 0.65, "watch curse changes movement")
    var before: float = state.time_remaining
    time_system._process(10.0)
    check(is_equal_approx(state.time_remaining, before - 3.5), "Time reads watch seam")
    press("drop_heirloom")
    check(state.active_heirloom == "None" and state.time_effect == "normal", "drop clears held item and watch effect")
    check(main.get_node("World/Watch").visible, "dropped item restored to world")
    await physics_frame
    await physics_frame
    check(player.nearby_target() == main.get_node("World/Watch"), "dropped item reachable")
    press("interact")
    check(state.active_heirloom == "Grandfather's Watch", "dropped item can be picked up")
    var watch_origin: Transform3D = inventory.initial_transforms["Grandfather's Watch"]

    await approach("MusicBox")
    var swap_location: Vector3 = main.get_node("World/MusicBox").global_position
    press("interact")
    check(state.collected_heirlooms.size() == 1, "one carried heirloom enforced")
    check(state.active_heirloom == "Music Box", "swap publishes new ActiveHeirloom")
    check(main.get_node("World/Watch").visible and main.get_node("World/Watch").global_position.is_equal_approx(swap_location), "previous heirloom stays reachable at swap location")
    await approach("MusicPuzzle")
    before = state.time_remaining
    press("use_heirloom")
    check(state.puzzle_flags["attic_unlocked"], "music unlocks passage")
    check(is_equal_approx(state.time_remaining, before - 8.0), "successful song curse costs eight seconds")
    before = state.time_remaining
    press("use_heirloom")
    check(state.time_remaining == before, "repeating solved puzzle does not charge another curse")
    check(not state.puzzle_flags["attic_open"], "unlocking and physically opening are separate")

    await approach("AtticDoor")
    press("interact")
    await physics_frame
    check(state.puzzle_flags["attic_open"] and gate_hit().is_empty(), "opened gate removes physical collision")
    await approach("PortraitPuzzle")
    press("use_heirloom")
    check(not state.puzzle_flags["mirror_revealed"], "wrong ActiveHeirloom cannot reveal key")
    await approach("Mirror")
    press("interact")
    await approach("PortraitPuzzle")
    before = state.time_remaining
    press("use_heirloom")
    check(state.puzzle_flags["mirror_revealed"], "mirror solves portrait")
    check(main.get_node("World/HiddenKey").visible, "mirror reveals secret object")
    check(is_equal_approx(state.time_remaining, before - 5.0), "successful reflection curse costs five seconds")
    await approach("HiddenKey", Vector3(0, 0, 0.9))
    press("interact")
    check(inventory.has_item("Family Key"), "Inventory owns collected key")
    check(state.active_heirloom == "Mother's Mirror", "ordinary key does not occupy heirloom slot")
    check(state.puzzle_flags["front_door_unlocked"], "Environment responds to key collection")
    check(not main.get_node("World/HiddenKey").visible, "collected secret cannot reappear")
    await approach("ExitDoor", Vector3(0, 0, -1.8))
    press("interact")
    check(main.won and state.run_status == "won", "complete escape route")
    before = state.time_remaining
    time_system._process(100.0)
    check(state.time_remaining == before, "victory freezes countdown")

    press("restart")
    check(not main.won and state.loop_count == 0 and state.time_remaining == 180.0, "new run clears victory and generation")
    check(state.collected_items.is_empty() and state.active_heirloom == "None", "new run clears inventory")
    check(main.get_node("World/Watch").global_transform.is_equal_approx(watch_origin), "new run restores heirloom locations")
    await physics_frame
    check(not gate_hit().is_empty() and not main.get_node("World/HiddenKey").visible, "new run restores gate and secret")
    await approach("Watch")
    main.toggle_pause()
    before = state.time_remaining
    time_system._process(5.0)
    press("interact")
    Input.action_press("move_forward")
    var position_before: Vector3 = player.global_position
    player._physics_process(1.0)
    Input.action_release("move_forward")
    check(state.time_remaining == before and state.active_heirloom == "None", "pause freezes timer and interaction")
    check(player.global_position.is_equal_approx(position_before), "pause freezes movement")
    main.toggle_pause()
    press("interact")
    press("use_heirloom")
    check(state.time_effect == "slow", "resume restores interaction")

    before = state.time_remaining
    time_system.consume_time(before - 59.0)
    check(environment_system.night_stage == "restless", "TimeRemaining makes house restless at sixty seconds")
    environment_system._process(0.2)
    check(main.get_node("World/Chandelier").light_energy < 5.0, "late countdown affects actual light")
    time_system.consume_time(40.0)
    check(environment_system.night_stage == "dawn", "last twenty seconds change environment stage")
    time_system.consume_time(100.0)
    check(state.run_status == "dawn" and not main.can_act(), "zero time freezes gameplay for dawn")
    var transition_before: float = time_system.transition_remaining
    main.toggle_pause()
    time_system._process(5.0)
    check(time_system.transition_remaining == transition_before, "pause also freezes dawn transition")
    main.toggle_pause()
    var node_count: int = main.get_node("World").get_child_count()
    time_system._process(2.0)
    check(state.loop_count == 1 and state.time_remaining == 170.0, "automatic next generation with stronger curse")
    check(state.active_heirloom == "None" and state.time_effect == "normal", "generation clears inventory and ability")
    check(not state.puzzle_flags["attic_unlocked"] and not state.puzzle_flags["mirror_revealed"], "generation resets all puzzle state")
    check(environment_system.night_stage == "quiet", "generation restores environment")
    check(main.get_node("World").get_child_count() == node_count, "generation does not duplicate world geometry")
    check(player.global_position.is_equal_approx(main.spawn_transform.origin), "generation restores player spawn")

    time_system.consume_time(200.0)
    press("restart")
    time_system._process(2.0)
    check(state.loop_count == 0 and state.run_status == "playing", "restart during dawn has no stale pending reset")
    time_system.start_generation(99)
    check(state.time_remaining == 90.0, "difficulty has playable minimum")
    press("restart")

    # The optional original multi-item mode still clears effects when Tab switches.
    inventory.max_carried_heirlooms = 3
    await approach("Watch")
    press("interact")
    press("use_heirloom")
    await approach("MusicBox")
    press("interact")
    check(state.time_effect == "normal", "switching away cancels watch")
    await approach("Mirror")
    press("interact")
    press("switch_heirloom")
    check(state.active_heirloom == "Grandfather's Watch", "optional Tab mode cycles collected heirlooms")
    inventory.max_carried_heirlooms = 1
    press("restart")
    check(state.collected_heirlooms.is_empty(), "final clean reset")

    print("Integration checks: %d passed, %d failed" % [checks - failures, failures])
    quit(1 if failures else 0)
