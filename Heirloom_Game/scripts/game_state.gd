extends Node

signal active_heirloom_changed(value: String)
signal time_remaining_changed(value: float)
signal time_effect_changed(value: String)
signal loop_restarted(loop_count: int)
signal game_won

var active_heirloom: String = "None"
var time_remaining: float = 180.0
var time_effect: String = "normal"
var loop_count: int = 0
var collected_heirlooms: Array[String] = []
var puzzle_flags := {
    "mirror_revealed": false,
    "music_box_open": false,
    "attic_unlocked": false,
    "front_door_unlocked": false
}

func set_active_heirloom(value: String) -> void:
    active_heirloom = value
    active_heirloom_changed.emit(value)

func set_time_remaining(value: float) -> void:
    time_remaining = maxf(value, 0.0)
    time_remaining_changed.emit(time_remaining)

func set_time_effect(value: String) -> void:
    time_effect = value
    time_effect_changed.emit(value)

func reset_for_loop() -> void:
    loop_count += 1
    active_heirloom = "None"
    collected_heirlooms.clear()
    time_effect = "normal"
    time_remaining = maxf(90.0, 180.0 - loop_count * 10.0)
    puzzle_flags = {
        "mirror_revealed": false,
        "music_box_open": false,
        "attic_unlocked": false,
        "front_door_unlocked": false
    }
    active_heirloom_changed.emit(active_heirloom)
    time_effect_changed.emit(time_effect)
    time_remaining_changed.emit(time_remaining)
    loop_restarted.emit(loop_count)

func reset_run() -> void:
    loop_count = -1
    reset_for_loop()
