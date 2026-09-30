extends CharacterBody3D

@export var speed := 5.2
@export var mouse_sensitivity := 0.0025
@onready var pivot: Node3D = $Pivot
@onready var camera: Camera3D = $Pivot/SpringArm3D/Camera3D
@onready var ray: RayCast3D = $Pivot/SpringArm3D/Camera3D/RayCast3D
@onready var inventory := get_node("/root/Main/InventorySystem")
@onready var main := get_node("/root/Main")

var gravity := 18.0

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    $Pivot/SpringArm3D.add_excluded_object(get_rid())

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("restart"):
        main.restart_run()
        return
    if main.won:
        return
    if event.is_action_pressed("ui_cancel"):
        main.toggle_pause()
        return
    if main.paused:
        return
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        pivot.rotate_x(-event.relative.y * mouse_sensitivity)
        pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-45), deg_to_rad(25))
    if event.is_action_pressed("interact"):
        _interact()
    if event.is_action_pressed("switch_heirloom"):
        inventory.switch_heirloom()
    if event.is_action_pressed("use_heirloom"):
        if main.state.active_heirloom == "Grandfather's Watch":
            main.show_message(inventory.use_active())
        else:
            _interact()

func _physics_process(delta: float) -> void:
    if main.won or main.paused:
        return
    var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var dir := (transform.basis * Vector3(input_vec.x, 0, input_vec.y)).normalized()
    var pace: float = speed * (0.65 if main.state.time_effect == "slow" else 1.0)
    velocity.x = dir.x * pace
    velocity.z = dir.z * pace
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = -0.2
    move_and_slide()

func nearby_target():
    var closest = null
    var distance := 2.8
    for object in main.get_node("World").get_children():
        if not object.has_method("interact") or not object.visible or object.collision_layer == 0:
            continue
        var d: float = global_position.distance_to(object.global_position)
        if d >= distance:
            continue
        var query := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.4, 0), object.global_position, 1, [get_rid()])
        var hit := get_world_3d().direct_space_state.intersect_ray(query)
        if not hit.is_empty() and hit.collider != object:
            continue
        closest = object
        distance = d
    return closest

func _interact() -> void:
    var target = nearby_target()
    if target:
        target.interact(self)
    else:
        main.show_message("Move closer to a labeled object.")
