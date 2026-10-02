extends Node
## Shared GDD seams. Systems publish only the state they own.
## Inventory writes ActiveHeirloom/TimeEffect; Time writes TimeRemaining;
## EnvironmentSystem writes puzzle_flags. Main coordinates their resets.

signal active_heirloom_changed(value: String)
signal time_remaining_changed(value: float)
signal time_effect_changed(value: String)
signal inventory_changed
signal heirloom_used(heirloom_name: String, target: Node3D)
signal ability_applied(heirloom_name: String)
signal time_cost_requested(seconds: float)
signal puzzle_changed(flag: String, value: bool)
signal dawn_reached(generation: int)
signal loop_restarted(loop_count: int)
signal game_won

var active_heirloom: String = "None"
var time_remaining: float = 180.0
var generation_duration: float = 180.0
var time_effect: String = "normal"
var loop_count: int = 0
var run_status: String = "playing"
var collected_heirlooms: Array[String] = []
var collected_items: Array[String] = []
var puzzle_flags: Dictionary = {}

func set_active_heirloom(value: String) -> void:
    active_heirloom = value
    active_heirloom_changed.emit(value)

func set_time_remaining(value: float) -> void:
    time_remaining = maxf(value, 0.0)
    time_remaining_changed.emit(time_remaining)

func set_time_effect(value: String) -> void:
    time_effect = value
    time_effect_changed.emit(value)
