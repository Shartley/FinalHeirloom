# Heirloom — playable Godot prototype

## Play
Open Godot 4.7.2, choose Import, select `project.godot`, then press F6 on Main.tscn or F5 to play the project. Tested with Godot 4.7.2.

WASD moves; mouse rotates the third-person camera. Approach labeled objects and press E to interact. Tab switches collected heirlooms. Q activates the watch or interacts with a nearby puzzle. Esc pauses/resumes. R starts a fresh game, including from the victory screen.

## Escape route
1. Collect the Music Box on the left side of the hall.
2. Equip it with Tab and interact with the carved melody seal toward the back left.
3. Open the central attic passage.
4. Collect Mother's Mirror on the right side of the main hall, then equip it.
5. Enter the rear chamber and interact with the James family portrait.
6. Pick up the revealed family key, then return to the front door and press E.

The optional Grandfather's Watch slows the countdown to 35% speed while active, but reduces movement to 65%. Switching away cancels its effect. Dawn starts another generation with ten fewer seconds, down to a 90-second minimum. Pause stops the timer and movement.

## Implementation
The Time, Inventory and Environment/Puzzle systems communicate through GameState. This repaired version retains the supplied third-person graybox project, adds camera collision, nearby interaction with line-of-sight checks, object labels, a checkered floor, a physically gated rear chamber, pause and reliable new-game/reset behavior. The rear chamber represents the attic passage in this compact prototype; it is not a full second floor. Geometry and character are placeholder art.

## Verification
Godot 4.7.2 imported the project and ran it headlessly with no script or scene errors. The smoke test verifies puzzle locks, full escape, time slowing, item switching, key collection, pause, new-game state, generation state, automatic dawn reload and nearby targeting:

```sh
godot --headless --path . --script res://tests/smoke.gd
```

Graphical launch was unavailable in the build environment, so appearance and mouse feel still need a local playthrough. Sandbox restrictions also produced Godot user-data and macOS certificate-access messages during testing; they were unrelated to game scripts.
