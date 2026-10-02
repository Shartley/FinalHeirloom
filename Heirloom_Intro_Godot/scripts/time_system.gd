extends Node
## Owner: Lionel B. Owns countdown, generation number and dawn transition.

@export var starting_seconds: float = 180.0
@export var generation_penalty: float = 10.0
@export var minimum_seconds: float = 90.0
@export var watch_time_scale: float = 0.35
@export var dawn_transition_seconds: float = 1.2
@onready var state = get_node("/root/GameState")
@onready var main = get_parent()

var running: bool = true
var transition_remaining: float = 0.0

func _ready() -> void:
    state.time_cost_requested.connect(consume_time)

func reset_run() -> void:
    start_generation(0)

func start_generation(generation_index: int) -> void:
    transition_remaining = 0.0
    running = true
    state.loop_count = generation_index
    state.run_status = "playing"
    state.generation_duration = maxf(minimum_seconds, starting_seconds - generation_index * generation_penalty)
    state.set_time_remaining(state.generation_duration)
    state.loop_restarted.emit(generation_index)

func _process(delta: float) -> void:
    if not running or main.paused or main.won:
        return
    if state.run_status == "dawn":
        transition_remaining -= delta
        if transition_remaining <= 0.0:
            start_generation(state.loop_count + 1)
        return
    var multiplier: float = watch_time_scale if state.time_effect == "slow" else 1.0
    state.set_time_remaining(state.time_remaining - delta * multiplier)
    if state.time_remaining <= 0.0:
        _reach_dawn()

func consume_time(seconds: float) -> void:
    if not main.can_act():
        return
    state.set_time_remaining(state.time_remaining - maxf(seconds, 0.0))
    if state.time_remaining <= 0.0:
        _reach_dawn()

func _reach_dawn() -> void:
    if state.run_status != "playing":
        return
    state.run_status = "dawn"
    transition_remaining = dawn_transition_seconds
    state.dawn_reached.emit(state.loop_count + 1)
