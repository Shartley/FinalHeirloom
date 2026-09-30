extends SceneTree

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    change_scene_to_file("res://scenes/Main.tscn")
    await process_frame
    await physics_frame
    var main = current_scene
    var state = root.get_node("GameState")
    var inventory = main.get_node("InventorySystem")
    var player = main.get_node("Player")
    main.get_node("TimeSystem").running = false
    assert(InputMap.action_get_events("switch_heirloom")[0].physical_keycode == KEY_TAB)
    main.get_node("World/ExitDoor").interact(player)
    assert(not main.won)
    main.get_node("World/PortraitPuzzle").interact(player)
    assert(not state.puzzle_flags.mirror_revealed)
    main.get_node("World/Watch").interact(player)
    inventory.use_active()
    var before: float = state.time_remaining
    main.get_node("TimeSystem").running = true
    main.get_node("TimeSystem")._process(10.0)
    main.get_node("TimeSystem").running = false
    assert(is_equal_approx(state.time_remaining, before - 3.5))
    main.get_node("World/MusicBox").interact(player)
    assert(state.time_effect == "normal")
    main.get_node("World/MusicPuzzle").interact(player)
    assert(state.puzzle_flags.attic_unlocked)
    main.get_node("World/AtticDoor").interact(player)
    assert(main.get_node("World/AtticDoor").collision_layer == 0)
    main.get_node("World/Mirror").interact(player)
    main.get_node("World/PortraitPuzzle").interact(player)
    assert(main.get_node("World/HiddenKey").visible)
    main.get_node("World/HiddenKey").interact(player)
    main.get_node("World/PortraitPuzzle").interact(player)
    assert(not main.get_node("World/HiddenKey").visible)
    main.get_node("World/ExitDoor").interact(player)
    assert(main.won)
    state.reset_for_loop()
    assert(state.loop_count == 1 and state.time_remaining == 170.0)
    assert(state.collected_heirlooms.is_empty())
    state.reset_run()
    assert(state.loop_count == 0 and state.time_remaining == 180.0)
    change_scene_to_file("res://scenes/Main.tscn")
    await process_frame
    await physics_frame
    main = current_scene
    main.toggle_pause()
    before = state.time_remaining
    main.get_node("TimeSystem")._process(5.0)
    assert(state.time_remaining == before)
    main.toggle_pause()
    var watch = main.get_node("World/Watch")
    main.get_node("Player").position = watch.position + Vector3(0, 0.4, 1.8)
    await physics_frame
    assert(main.get_node("Player").nearby_target() == watch)
    main.get_node("Player").position = Vector3(0, 1.1, 9)
    main.get_node("TimeSystem").running = true
    state.set_time_remaining(0.01)
    main.get_node("TimeSystem")._process(0.1)
    await create_timer(0.85).timeout
    assert(state.loop_count == 1)
    assert(current_scene != main)
    assert(state.time_remaining > 168.0)
    print("PASS: escape, locked puzzles, watch, Tab, key, pause, reset, proximity, automatic dawn reload")
    if DisplayServer.get_name() != "headless":
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://../../preview.png")
    quit()
