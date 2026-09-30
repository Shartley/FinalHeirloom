extends Node

@onready var state := get_node("/root/GameState")
var selected_index := -1

func collect_heirloom(name: String) -> void:
    if name not in state.collected_heirlooms:
        state.collected_heirlooms.append(name)
    selected_index = state.collected_heirlooms.find(name)
    state.set_active_heirloom(name)
    _refresh_effect()

func switch_heirloom() -> void:
    if state.collected_heirlooms.is_empty():
        return
    selected_index = (selected_index + 1) % state.collected_heirlooms.size()
    state.set_active_heirloom(state.collected_heirlooms[selected_index])
    _refresh_effect()

func use_active() -> String:
    match state.active_heirloom:
        "Grandfather's Watch":
            state.set_time_effect("slow" if state.time_effect != "slow" else "normal")
            return "The watch bends time." if state.time_effect == "slow" else "Time returns to normal."
        "Mother's Mirror":
            return "The mirror reveals what the house hides."
        "Music Box":
            return "A forgotten melody echoes through the hall."
        _:
            return "You are not carrying an heirloom."

func _refresh_effect() -> void:
    if state.active_heirloom != "Grandfather's Watch" and state.time_effect == "slow":
        state.set_time_effect("normal")
