extends SceneTree
## Walk the furnished escape route using the player's real collision body.
## This catches furniture blocking routes that teleport-based checks cannot.

var main
var player: CharacterBody3D
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
    call_deferred("run")

func check(condition: bool, description: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error("FAIL: " + description)

func walk(point: Vector2) -> void:
    var steps: int = 0
    var goal := Vector3(point.x, 1.06, point.y)
    while Vector2(player.position.x, player.position.z).distance_to(point) > 0.16 and steps < 500:
        await physics_frame
        var direction: Vector3 = goal - player.position
        direction.y = 0
        direction = direction.normalized()
        var pace: float = main.get_node("InventorySystem").movement_multiplier() * 5.2
        player.velocity = Vector3(direction.x * pace, -0.2, direction.z * pace)
        player.move_and_slide()
        steps += 1
    player.velocity = Vector3.ZERO
    check(steps < 500, "walkable route to " + str(point))

func interact(expected_name: String) -> void:
    var target = player.nearby_target()
    check(target != null and target.name == expected_name, "reachable " + expected_name)
    if target != null:
        player._interact()

func run() -> void:
    change_scene_to_file("res://scenes/Main.tscn")
    await process_frame
    await physics_frame
    main = current_scene
    main.get_node("Intro/Center/Panel/Margin/VBox/StartButton").pressed.emit()
    player = main.get_node("Player")
    player.set_physics_process(false)
    main.get_node("TimeSystem").set_process(false)
    main.get_node("InventorySystem").set_process(false)
    await walk(Vector2(-3, 7))
    await walk(Vector2(-3, 2.8))
    await walk(Vector2(-6, 2.8))
    interact("Watch")
    player.inventory.use_active()
    check(root.get_node("GameState").time_effect == "slow", "watch still works in furnished room")
    player.inventory.use_active()
    await walk(Vector2(-3, 2.8))
    await walk(Vector2(-3, -2.2))
    await walk(Vector2(-4, -2.2))
    interact("MusicBox")
    await walk(Vector2(-8, -5.8))
    interact("MusicPuzzle")
    await walk(Vector2(0, -5.8))
    interact("AtticDoor")
    await walk(Vector2(0, -10.0))
    await walk(Vector2(0, -5.8))
    await walk(Vector2(3.4, -5.8))
    await walk(Vector2(3.4, -0.2))
    await walk(Vector2(6, -0.2))
    interact("Mirror")
    await walk(Vector2(3.4, -0.2))
    await walk(Vector2(3.4, -5.8))
    await walk(Vector2(0, -5.8))
    await walk(Vector2(0, -10.0))
    await walk(Vector2(4, -11.8))
    interact("PortraitPuzzle")
    await walk(Vector2(4, -12.0))
    interact("HiddenKey")
    await walk(Vector2(0, -10.0))
    await walk(Vector2(0, -5.8))
    await walk(Vector2(0, 11.8))
    interact("ExitDoor")
    check(main.won, "escape by walking through the furnished mansion")
    print("Navigation checks: %d passed, %d failed" % [checks - failures, failures])
    quit(1 if failures else 0)
