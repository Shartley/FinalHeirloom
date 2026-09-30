extends StaticBody3D

@export_enum("heirloom", "mirror_puzzle", "music_puzzle", "attic_door", "exit_door", "lore") var kind := "lore"
@export var heirloom_name := ""
@export var text := "The house remembers you."
@onready var main := get_node("/root/Main")
@onready var state := get_node("/root/GameState")
@onready var inventory := get_node("/root/Main/InventorySystem")

func interact(_player) -> void:
    match kind:
        "heirloom":
            inventory.collect_heirloom(heirloom_name)
            main.show_message("Collected " + heirloom_name + ".")
            visible = false
            collision_layer = 0
        "mirror_puzzle":
            if state.active_heirloom == "Mother's Mirror":
                state.puzzle_flags["mirror_revealed"] = true
                main.reveal_hidden_key()
                main.show_message("The mirror exposes a hidden key beneath the portrait.")
            else:
                main.show_message("The portrait looks ordinary. Something reflective may reveal more.")
        "music_puzzle":
            if state.active_heirloom == "Music Box":
                state.puzzle_flags["music_box_open"] = true
                state.puzzle_flags["attic_unlocked"] = true
                main.unlock_attic()
                main.show_message("The melody matches the carving. The attic lock releases.")
            else:
                main.show_message("A carved melody is missing its song.")
        "attic_door":
            if state.puzzle_flags["attic_unlocked"]:
                main.open_attic_door()
                main.show_message("The attic opens. The air bends around you.")
            else:
                main.show_message("The attic door is sealed by an old family sigil.")
        "exit_door":
            if state.puzzle_flags["front_door_unlocked"]:
                main.win_game()
            else:
                main.show_message("The front door will not open. Finish the family's mission first.")
        "lore":
            main.show_message(text)
