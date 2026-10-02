# Heirloom interview prep — current GitHub Godot build

Source: [Shartley/Heirloom](https://github.com/Shartley/Heirloom), commit
`85ffeac7673d29f47d18056d8a2b7d6d164701c3`, inspected October 2, 2026.
This guide describes **Heirloom_Game's Godot files at that commit**.
The graphics download has additional changes; its SYSTEMS_GUIDE.md describes that
new version. Keep the two versions clear during an interview.

## Your 30-second introduction

“Heirloom is a third-person escape puzzle game set in a cursed family house. We
split it into Time, Inventory, and Environment/Puzzles. Time creates the deadline,
Inventory decides which heirloom is equipped and its effect, and Environment
uses that item and the remaining time to change the house and puzzle progress.
GameState connects them through shared values and signals. You use the Music Box
to open the passage, the Mirror to reveal the key, and the key to escape before
dawn. The Watch gives more time at the cost of slower movement.”

## The three assigned systems

These names describe your team's assigned responsibilities. The code alone does
not establish who personally wrote every line.

| Assigned owner | System | What it does in the current Godot code | Files to point to |
| --- | --- | --- | --- |
| Lionel B. | Time | Counts down from 180 seconds, reads the Watch effect, handles dawn and the next generation | scripts/time_system.gd; reset rules in game_state.gd |
| Daniel A. | Inventory | Collects heirlooms, selects the active one, cycles with Tab, toggles the Watch effect | scripts/inventory_system.gd |
| Samaii H. | Environment/Puzzles | Checks the equipped item, unlocks the passage, reveals the key, opens the exit, changes late-night lighting | scripts/interactable.gd, key.gd, main.gd; scenes/Main.tscn |

**There is no separate EnvironmentSystem script/node in this GitHub snapshot.**
The environment responsibilities are spread across object scripts and Main.
GameState, Player, and Main support all three systems rather than becoming three
additional assigned systems.

## How Time works

Each frame, TimeSystem subtracts `delta × multiplier` from `time_remaining`.
`delta` is elapsed seconds, so the timer does not depend on the frame rate.
The multiplier is normally 1.0 and becomes **0.35** when `time_effect == "slow"`.
For example, ten real seconds use only 3.5 countdown seconds with the Watch on.
This changes the deadline; it does not slow the whole engine.

At zero, Time stops, waits 0.7 seconds, calls `GameState.reset_for_loop()`, and
reloads the scene. The reset clears collected heirlooms, the active item, effects,
and puzzle flags. Generations start at 180, 170, 160 seconds, and so on, with a
90-second minimum. R resets the generation count and reloads a fresh run.
Normal pause stops countdown and movement. Escape stops TimeSystem permanently
for that run.

## How Inventory works

E near a visible heirloom calls `collect_heirloom()`. The item name goes into
`collected_heirlooms`, becomes `active_heirloom`, and the world object disappears
with its collision disabled. Tab cycles through collected items.

The current GitHub build lets you **collect several heirlooms and equip one**.
It does not enforce a one-item carry limit and has no drop action.

Q with the Watch toggles `time_effect` between normal and slow. Switching away
from the Watch clears slow time. Player also reads that effect and changes
movement from 5.2 to 3.38 units/second — **65%** of normal speed. That is the
implemented Watch tradeoff; the character does not visibly age.

For the Mirror and Music Box, Q follows Player's ordinary interaction path, just
like E. The target object's script checks `active_heirloom` and solves the right
puzzle. The descriptive Mirror/Music strings in Inventory's `use_active()` are
not what actually completes those puzzles in the normal player input path.

## How Environment/Puzzles works

`interactable.gd` uses the object's exported `kind` to choose its behavior:

- **Music seal:** requires `active_heirloom == "Music Box"`; sets
  `music_box_open` and `attic_unlocked`, then calls `Main.unlock_attic()`.
- **Passage door:** checks `attic_unlocked`; a separate E interaction calls
  `Main.open_attic_door()`, which hides the door and disables its collision.
- **Family portrait:** requires `active_heirloom == "Mother's Mirror"`; sets
  `mirror_revealed` and calls `Main.reveal_hidden_key()`.
- **Key:** its separate `key.gd` sets `front_door_unlocked` and hides itself.
  It does not enter the heirloom collection.
- **Exit:** checks the unlock flag and calls `Main.win_game()`.

Main updates objectives from puzzle flags. When time drops **below 45 seconds**,
Main makes the upstairs light flicker. The rear chamber is a compact stand-in for
the attic, with walls and a physical passage blocker, not a complete second floor.

Player selects the closest visible interactable within 2.8 units. A physics ray
checks that a wall or another object is not blocking the interaction.

## Everyone's “intertwine”: the three seams

A seam is the agreed piece of information passed between systems.

| Seam | Who writes it | Who reads it | Visible result |
| --- | --- | --- | --- |
| ActiveHeirloom | Inventory | Environment's object scripts and HUD | The song works only with the Music Box equipped; the portrait needs the Mirror |
| TimeEffect | Inventory | TimeSystem and Player | The Watch slows the countdown and the player's movement |
| TimeRemaining | TimeSystem | Main's environment reaction and HUD | The timer updates and the upstairs light flickers below 45 seconds |

GameState is configured as an **Autoload** in project.godot, so all scripts can
reach the same `/root/GameState`. Its setters emit change signals; Main connects
the item/time signals to HUD methods. Some readers, including TimeSystem and the
puzzle scripts, read the current value directly. Do not say every interaction is
signal-driven: this version also uses direct method calls and flag writes.

Dawn connects all three because the shared state resets and the scene reload
restores the physical objects. Winning connects them in the other direction:
the environment's successful exit interaction tells Main to stop Time.

## What Samaii can say about the assigned role

“My Environment/Puzzle responsibility connects the other two systems to the
world. I check Inventory's active item before allowing a puzzle to complete, use
Time's remaining seconds for the house's lighting reaction, and record puzzle
progress so the passage, secret key, objectives, and exit agree. For example,
collecting the Music Box alone does not open the passage: the player must bring
it to the seal, solve the lock, and then interact with the door.”

Adapt this to the work you actually contributed. An assigned responsibility is
not evidence that you personally implemented every method.

## Likely interview questions

**How would you demonstrate the integration?**
Pick up the Watch, press Q, and show the slower timer and movement. Collect the
Music Box, use the seal, and open the passage. Equip the Mirror with Tab, reveal
and collect the key, then escape. Use another run to show dawn and inheritance.

**Why not let every script keep its own timer and equipped item?**
They could disagree. GameState gives them one current timer and one active item,
while the individual scripts implement the behavior that uses those values.

**Which seam is easiest to break?**
ActiveHeirloom is a good example: puzzle checks use exact strings. A misspelling
or changing the active item without updating the shared state could make a
correct pickup fail. Tests should cover the right item, wrong item, and switching.

**How did you verify it?**
The repository includes tests/smoke.gd. It covers the escape sequence, locked
puzzles, Watch effect, switching, proximity/line of sight, pause, restart, and dawn.
It passed in Godot 4.5.1 during this review. These checks establish behavior;
a manual playthrough is still how you judge pacing and camera feel.

**What would you improve next?**
Move the environment rules into a dedicated system, make the carry rule match
the intended design, and add more developed mansion art. Describe these as
improvements to this GitHub snapshot, not features already present in it.

## Version facts to remember

| Current GitHub snapshot | New graphics download |
| --- | --- |
| Environment code in Main and object scripts | Dedicated EnvironmentSystem plus graphics-only builders |
| Collect multiple heirlooms; Tab equips one | One carried heirloom by default; E swaps, G drops |
| Late-night flicker below 45 seconds | House stages at 60 and 20 seconds |
| Watch slowdown and movement cost | Watch plus 5s Mirror / 8s Music success costs |
| Placeholder props and capsule character | Detailed native props, furniture, wallpaper, and a stylized character |

Only claim the right column if you are presenting the downloaded updated build.

## Exact source files

All paths below refer to Heirloom_Game at the reviewed commit:

- [TimeSystem](https://github.com/Shartley/Heirloom/blob/85ffeac7673d29f47d18056d8a2b7d6d164701c3/Heirloom_Game/scripts/time_system.gd)
- [InventorySystem](https://github.com/Shartley/Heirloom/blob/85ffeac7673d29f47d18056d8a2b7d6d164701c3/Heirloom_Game/scripts/inventory_system.gd)
- [Environment interactions](https://github.com/Shartley/Heirloom/blob/85ffeac7673d29f47d18056d8a2b7d6d164701c3/Heirloom_Game/scripts/interactable.gd)
- [Main](https://github.com/Shartley/Heirloom/blob/85ffeac7673d29f47d18056d8a2b7d6d164701c3/Heirloom_Game/scripts/main.gd)
- [GameState](https://github.com/Shartley/Heirloom/blob/85ffeac7673d29f47d18056d8a2b7d6d164701c3/Heirloom_Game/scripts/game_state.gd)
- [Player](https://github.com/Shartley/Heirloom/blob/85ffeac7673d29f47d18056d8a2b7d6d164701c3/Heirloom_Game/scripts/player.gd)
- [Key](https://github.com/Shartley/Heirloom/blob/85ffeac7673d29f47d18056d8a2b7d6d164701c3/Heirloom_Game/scripts/key.gd)
