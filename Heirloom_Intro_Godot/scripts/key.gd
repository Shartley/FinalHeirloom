extends StaticBody3D

var kind: String = "key"
@onready var environment_system = get_node("/root/Main/EnvironmentSystem")

func interact(player: CharacterBody3D) -> void:
    environment_system.interact_object(self, player)
