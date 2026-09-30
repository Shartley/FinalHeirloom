extends StaticBody3D
@onready var main := get_node("/root/Main")
@onready var state := get_node("/root/GameState")
func interact(_player) -> void:
    if visible:
        state.puzzle_flags["front_door_unlocked"] = true
        main.show_message("You found the James family key. The front door can now be opened.")
        visible = false
        collision_layer = 0
