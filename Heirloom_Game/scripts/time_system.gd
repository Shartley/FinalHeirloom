extends Node

@onready var state := get_node("/root/GameState")
var running := true

func _process(delta: float) -> void:
    if not running or get_node("/root/Main").paused:
        return
    var multiplier := 1.0
    if state.time_effect == "slow":
        multiplier = 0.35
    state.set_time_remaining(state.time_remaining - delta * multiplier)
    if state.time_remaining <= 0.0:
        running = false
        await get_tree().create_timer(0.7).timeout
        state.reset_for_loop()
        get_tree().reload_current_scene()
