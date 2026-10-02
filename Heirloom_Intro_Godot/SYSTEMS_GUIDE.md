# HEIRLOOM: connecting the three systems

This updated prototype builds on the Godot project in your repository, rather
than the HTML build. It implements the September 23, 2026 COMP 440 GDD's three
systems and their shared seams.

## Open the game

1. Extract **Heirloom_Three_Systems_Godot.zip** into a new folder.
2. In Godot Project Manager, click **Import** and select
   **project.godot**.
3. Open **scenes/Main.tscn**. Press **F5** to play.
4. In the scene tree, confirm that **TimeSystem**, **InventorySystem** and
   **EnvironmentSystem** are direct children of **Main**.
5. In Project Settings > Globals > Autoload, **GameState** is already configured
   with **res://scripts/game_state.gd**. Do not add a duplicate.

Validated with Godot 4.5.1 and its Compatibility renderer. Use Godot 4, not Godot 3.

## What each teammate owns

| System | Owner | State and behavior | Main script |
| --- | --- | --- | --- |
| Time | Lionel B. | Time remaining, generation duration/count, dawn transition; slow countdown, time costs and loop reset | time_system.gd |
| Inventory | Daniel A. | Carried heirloom(s), selection, normal key, memories, ability/curses; pick up, swap, drop and use | inventory_system.gd |
| Environment/Puzzle | Samaii H. | Puzzle flags, hidden key, passage collision, front-door lock, lights; respond to items, time and progress | environment_system.gd |

**game_state.gd** is the shared signal/value channel. It does not decide which
puzzle is solved. **main.gd** coordinates the systems, player reset and HUD.
**interactable.gd** and **key.gd** forward object interactions to EnvironmentSystem.
**player.gd** handles movement, input and nearby targets with a line-of-sight check.

This keeps your puzzle work in one place. Adding a puzzle means extending
EnvironmentSystem and its scene object, rather than putting game rules in Main.

## The seams from your GDD

| GDD seam | Actual value/signal | Writer | Reader | Example |
| --- | --- | --- | --- | --- |
| ActiveHeirloom | active_heirloom / active_heirloom_changed | Inventory | Environment/Puzzle | Carrying Mother's Mirror allows the portrait to reveal the key |
| TimeRemaining | time_remaining / time_remaining_changed | Time | Environment/Puzzle and HUD | At 60 seconds, the chandelier starts pulsing; at 20 seconds the warning changes |
| TimeEffect | time_effect / time_effect_changed | Inventory | Time | The active Watch changes countdown speed to 0.35 |

The scripts use snake_case names for Godot code while retaining the GDD names in
comments and this mapping.

Inventory also emits **heirloom_used(item, target)**. Environment checks the target,
correct item and puzzle progress. On a first successful use, it emits
**ability_applied(item)**. Inventory applies that item's curse and requests the
time cost through **time_cost_requested(seconds)**; Time performs the countdown
change. Environment never directly subtracts time.

When Inventory collects the normal key, **inventory_changed** tells Environment
to unlock the front door. Collecting a key does not replace the carried heirloom.

## A playthrough demonstrating all three

1. Find Grandfather's Watch and press **E**. Its memory appears.
2. Press **Q**. Time slows; movement becomes heavy. Press **Q** again, or **G** to
   drop it. Normal countdown returns.
3. Take the Music Box to the carved melody seal at the back left. **Q** or **E**
   releases the passage lock. The successful song costs eight seconds and makes
   your steps heavy for four seconds.
4. Open the central passage with **E**. Unlocking it and removing its collision
   blocker are separate steps.
5. Pick up Mother's Mirror. With the default carry limit, the old heirloom remains
   where the new one was picked up.
6. Walk through the passage to the portrait. **Q** or **E** reveals the key. This
   successful reveal costs five seconds and gives four seconds of heavy steps.
7. Pick up the key with **E**, then return to the front door and press **E**.
8. Let another run expire to demonstrate inheritance: the next generation begins
   with ten fewer seconds, up to the difficulty cap.

Using the wrong heirloom never solves a puzzle. Repeating an already solved puzzle
does not apply another curse. **Q** uses the carried item; it does not pick up a
different object.

## Reset behavior

At zero seconds, Time publishes **dawn_reached**. Gameplay stops for a short
transition, then Time starts the next generation and publishes **loop_restarted**.

Main responds by asking Inventory and Environment to reset their own state and
restoring the player. The world is reused, so labels, floor tiles and walls are not
duplicated on every generation.

**Esc** freezes countdown, player movement, effects and the dawn transition.
**R** starts a new run from generation one, including during dawn or after victory.
There is no delayed scene-reload callback left over from the previous run.

## Your Environment/Puzzle editing points

In **scripts/environment_system.gd**:

- **interact_object()** routes E interactions and rejects out-of-reach targets.
- **_on_heirloom_used()** checks the required item and completes puzzles.
- **_set_flag()** publishes a changed puzzle state.
- **_on_time_remaining_changed()** sets the quiet/restless/dawn house stage.
- **_process()** animates the late-night lights.
- **reset_for_loop()** restores the physical gate, secret and puzzle flags.
- **objective_text()** gives the player their next goal.

For a new puzzle, add a named flag to reset_for_loop(), add its object to Main.tscn,
and handle its kind/required heirloom in this system. If a successful ability has a
new downside, publish ability_applied and let Inventory define that downside.

## Inspector controls

Select **TimeSystem** to change starting_seconds, generation_penalty,
minimum_seconds, watch_time_scale or dawn_transition_seconds.

Select **InventorySystem** to change max_carried_heirlooms. The default is **1**.
Set it to **3** if your team prefers the previous collected-inventory approach;
**Tab** then cycles carried heirlooms.

For a quick late-night demonstration, set starting_seconds to **70** and
minimum_seconds to **30**. The lights become restless after ten seconds. Restore
the default 180 / 90 values before your normal playtest.

## Bringing the changes into your repository

For the simplest update, copy the extracted project contents into the
repository's existing **Heirloom_Game** folder. This includes project.godot,
Main.tscn, the revised scripts, the new environment_system.gd and the test.

Alternatively, import the extracted project separately first. The archive also
includes **docs/Heirloom_Three_Systems.patch** with changes against repository commit
85ffeac for reviewing/applying with git. If the remote project has since changed,
review conflicts before applying. The HTML folder is not part of this update.

## Verification

The integration suite covers the complete escape, collision gate, hidden key,
wrong/no-item attempts, single-item swap, reachable drop/pickup, curse costs,
pause, victory, reset, automatic generations and restart during dawn. It also
checks the optional Tab inventory mode.

Run from Heirloom_Game:

~~~sh
godot --headless --path . --script res://tests/smoke.gd
~~~

The graphics upgrade uses detailed native mesh props, furniture, patterned
wallpaper, bookshelves, lamps, chandeliers, and a stylized character. The room
and models are constructed by **house_visuals.gd** and **visual_builder.gd** when
EnvironmentSystem decorates the world. These builders contain no puzzle rules.
The rear chamber remains a compact stand-in for the attic.

Godot 4.5.1 passed all 70 integration checks. A separate navigation suite walks
the furnished escape route with the real player collision body. Actual Godot
renders of the gameplay camera, rooms, and heirlooms were visually inspected.
See README.md for the graphics editing files and launch instructions.

For interview questions about the current remote repository, use
**docs/INTERVIEW_PREP_CURRENT_GITHUB.md**. It describes commit 85ffeac and keeps
that implementation distinct from this updated download.

## Godot references

- [Using signals](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html)
- [Autoloads](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html)

Signals let a system notify another when its state changes, which is why these
three seams connect through signals rather than duplicated puzzle checks.
