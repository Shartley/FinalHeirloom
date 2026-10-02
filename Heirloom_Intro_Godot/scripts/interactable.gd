extends StaticBody3D
## Scene objects forward interactions. The systems own the game rules.

@export_enum("heirloom", "mirror_puzzle", "music_puzzle", "attic_door", "exit_door", "lore") var kind := "lore"
@export var heirloom_name := ""
@export var text := "The house remembers you."
@onready var environment_system = get_node("/root/Main/EnvironmentSystem")

func interact(player: CharacterBody3D) -> void:
    environment_system.interact_object(self, player)
