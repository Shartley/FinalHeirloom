# Heirloom — furnished Godot graphics upgrade

A playable graphics upgrade of the working three-system game, based on
[Shartley/Heirloom](https://github.com/Shartley/Heirloom), commit 85ffeac.
The download contains a complete Godot 4 project with its assets and scripts.

## Open and play

1. Extract **Heirloom_Three_Systems_Godot.zip** into a **new folder**.
2. Open Godot 4's Project Manager and choose **Import**.
3. Select the extracted **project.godot**, then open the project.
4. Press **F5** to play. The detailed room and props are constructed when the
   game starts; the editor's unplayed Main scene still shows its base layout.

Godot's ZIP import also works: this archive contains explicit directory entries
and project.godot at its root. There is no Godot option inside Windows “Extract
All”; use Import in Godot after extracting.

Validated with **Godot 4.5.1**, using the **Compatibility** renderer.
Use Godot 4. The project declares a 4.3 feature baseline.

**WASD** move · **mouse** look · **E** interact/pick up/swap · **Q** use held
heirloom · **G** drop · **Esc** pause · **R** new run.

## What's new visually

- Grandpa's brass pocket watch: ivory clock face, 60 marks, Roman numerals,
  hands, winding crown, and linked chain.
- Mother's oval vanity mirror with a brass frame and wooden stand.
- A wooden music box with metal corners, latch, decorated lid, and winding crank.
- A family portrait, small brass key, readable letter, carved music seal,
  and panelled doors in proper frames.
- A sitting area with a couch, chairs, coffee table, patterned rug, and fireplace.
- Watch and music-box tables, a mirror vanity, writing desk, and rear study.
- Bookcases filled with individual books, framed windows with curtains,
  patterned wallpaper, wood panelling, baseboards, ceiling, and mouldings.
- Lamps, modelled chandeliers, warmer lights and furniture shadows.
- A stylized girl in a white dress, with hair, shoes, and moving arms.
- A more readable HUD, and object labels that appear nearby.

This is an editable **stylized 3D** art pass. Models use Godot meshes and native
shaders; there are no external asset packs or missing texture downloads. The
mirror uses a decorative reflective material rather than a live scene reflection.
The rear chamber still represents the attic; there is no full second floor yet.

## Escape route

1. Find the Music Box on its table toward the back left.
2. Carry it to the carved melody seal on the back-left wall. Press **Q** or **E**.
3. Open the central passage with **E**.
4. Collect Mother's Mirror from the vanity on the right side of the main room.
5. Carry it through the passage to the portrait on the rear wall. **Q** or **E**
   reveals the key on the console below it.
6. Pick up the key, return to the front door behind the starting position, and
   press **E** to escape.

Exactly one heirloom is carried by default. E on a different heirloom swaps them
and leaves the previous one at that object's position. The key uses a separate
item slot. G drops the heirloom nearby. To enable collecting several heirlooms,
set InventorySystem's max_carried_heirlooms to 3; Tab then cycles them.

The Watch is optional: **Q** changes countdown speed to 35% and movement to 65%.
Successful Mirror/Music puzzles cost 5/8 seconds and give four seconds of heavy
steps. Wrong or repeated uses cost nothing. The house reacts at 60 and 20 seconds.
At dawn, the next generation inherits ten fewer seconds, down to a 90-second
minimum, and the systems and objects reset together.

## Editing the graphics

| File | What to change |
| --- | --- |
| scripts/visual_builder.gd | The actual shapes, colours, and details of each prop or furniture model |
| scripts/house_visuals.gd | Furniture positions, wall trim, windows, rugs, lighting, and model placement |
| assets/wood.gdshader | Wood colour and grain |
| assets/wallpaper.gdshader | Wallpaper colour, pattern, and repeat count |
| assets/marble.gdshader | Marble colour, veins, and surface roughness |
| scenes/Main.tscn | Base world bounds, player/camera, and the named interaction objects |

These graphics files do not decide puzzle rules. EnvironmentSystem owns those
rules, Inventory owns items/effects, and Time owns countdown/generations.
Keep the named interactable roots, their scripts, and collision behaviour when
replacing a model. Keep enough clearance for the player's capsule and camera.

For a later art pass, you can import a Blender-exported .glb model and instantiate
it under the same object root in place of its builder call. Give assets a
consistent scale and material style. Review asset licences before shipping.
See [Godot's 3D scene import documentation](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/index.html).

## Team and interview notes

Assigned systems: **Lionel B. — Time**, **Daniel A. — Inventory**,
**Samaii H. — Environment/Puzzles**.

- **SYSTEMS_GUIDE.md** explains the updated downloaded game's architecture.
- **docs/INTERVIEW_PREP_CURRENT_GITHUB.md** prepares you for questions about the
  current GitHub Godot code, including responsibilities, seams, and exact sources.
  It explicitly distinguishes that snapshot from this updated download.
- **docs/Heirloom_Three_Systems.patch** contains the gameplay and graphics changes
  against the reviewed GitHub Godot folder.

To use this in your repository, copy the extracted project contents into its
**Heirloom_Game** folder. Test that separate copy before committing. This archive
has not been pushed to GitHub.

## Verification

The game was rendered in Godot 4.5.1 and its gameplay view, house interior,
watch, mirror, music box, and portrait were visually inspected.

Run the checks from this folder with Godot on your PATH:

~~~sh
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/navigation.gd
~~~

The first suite checks 70 gameplay behaviours. The second walks the furnished
escape route with the player's actual collision body, including pickups, puzzle
interactions, passage traversal and the final exit. This checks that furniture
does not block the route. Both passed before packaging.
