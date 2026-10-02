extends Node3D
## Furnishes the mansion while keeping gameplay objects and rules separate.

const ModelBuilder = preload("res://scripts/visual_builder.gd")
var art = ModelBuilder.new()
var targets: Array[Node3D] = []
var player: CharacterBody3D
var walk_phase: float = 0.0
var character: Node3D

func build(world: Node3D, actor: CharacterBody3D) -> Dictionary:
    player = actor
    var decoration := art.group(self, "MansionInterior")
    _floor(decoration)
    _walls(decoration)
    _furniture(decoration)
    _heirlooms(world)
    _puzzles(world, decoration)
    _lighting(world, decoration)
    actor.get_node("MeshInstance3D").hide()
    character = art.girl(actor)
    var materials: Dictionary = {}
    for pair in [["MusicPuzzle", "b67433"], ["PortraitPuzzle", "496b95"]]:
        var material: StandardMaterial3D = art.materials["gold"].duplicate()
        material.emission = Color(str(pair[1]))
        material.emission_energy_multiplier = 1.0
        materials[pair[0]] = material
        var object: Node3D = world.get_node(str(pair[0]))
        for sign_x in [-1.0, 1.0]:
            var strip := art.box(object, Vector3(0.028, 1.02 if pair[0] == "MusicPuzzle" else 2.02, 0.025), Vector3(sign_x * (0.49 if pair[0] == "MusicPuzzle" else 0.76), 0, 0.12), "gold")
            strip.material_override = material
    var titles := {
        "Watch": "Grandfather's Watch", "Mirror": "Mother's Mirror",
        "MusicBox": "Music Box", "MusicPuzzle": "Carved melody seal",
        "PortraitPuzzle": "James family portrait", "AtticDoor": "Sealed passage",
        "ExitDoor": "Front door", "HiddenKey": "Family key", "Lore": "Family letter"
    }
    for object_name in titles:
        var object: Node3D = world.get_node(object_name)
        object.set_meta("title", titles[object_name])
        var text := art.label(object, titles[object_name], Vector3(0, 1.15, 0), 28, 0.006)
        if object_name in ["PortraitPuzzle", "AtticDoor", "ExitDoor"]:
            text.position.y = 1.9
        if object_name in ["Watch", "MusicBox", "Lore", "HiddenKey"]:
            text.position.y = 0.75
        text.name = "ObjectLabel"
        text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        text.modulate = Color("f1dec0")
        text.outline_size = 5
        text.outline_modulate = Color("231c17")
        targets.append(object)
    return materials

func _process(delta: float) -> void:
    if not is_instance_valid(player):
        return
    for target in targets:
        target.get_node("ObjectLabel").visible = target.visible and player.global_position.distance_to(target.global_position) < 5.0
    var moving: float = minf(Vector2(player.velocity.x, player.velocity.z).length() / 5.2, 1.0)
    if not player.main.can_act():
        moving = 0.0
    walk_phase += delta * 8.0 * moving
    character.get_node("ArmLeft").rotation.x = sin(walk_phase) * 0.35 * moving
    character.get_node("ArmRight").rotation.x = -sin(walk_phase) * 0.35 * moving

func _floor(parent: Node3D) -> void:
    var floor_tiles := art.group(parent, "CheckeredMarble")
    for x in range(-11, 12, 2):
        for z in range(-13, 14, 2):
            art.box(floor_tiles, Vector3(2, 0.014, 2), Vector3(x, 0.107, z), "marble" if (x + z) % 4 == 0 else "dark_marble")
    var rug := art.group(parent, "ParlorRug", Vector3(-7.0, 0.123, 5.8))
    art.box(rug, Vector3(6.5, 0.012, 5.0), Vector3.ZERO, "velvet")
    art.box(rug, Vector3(6.10, 0.014, 4.60), Vector3(0, 0.006, 0), "cloth")
    art.box(rug, Vector3(5.92, 0.016, 4.42), Vector3(0, 0.01, 0), "velvet")
    for x in [-2.5, -1.5, -0.5, 0.5, 1.5, 2.5]:
        for z in [-1.6, -0.7, 0.2, 1.1]:
            var motif := art.box(rug, Vector3(0.25, 0.018, 0.25), Vector3(x, 0.012, z), "cloth")
            motif.rotation.y = PI / 4.0
    art.box(parent, Vector3(2.20, 0.014, 17.5), Vector3(0, 0.124, 1.8), "red")
    for x in [-1.02, 1.02]:
        art.box(parent, Vector3(0.045, 0.014, 17.4), Vector3(x, 0.132, 1.8), "cloth")

func _wall_panel(parent: Node3D, position: Vector3, width: float, rotation: float = 0.0) -> void:
    var wall := art.group(parent, "WallpaperAndWainscot", position)
    wall.rotation.y = rotation
    art.box(wall, Vector3(width, 3.25, 0.055), Vector3(0, 3.22, 0), "wallpaper")
    art.box(wall, Vector3(width, 1.48, 0.065), Vector3(0, 0.85, 0.015), "wood")
    for y in [0.21, 1.48, 1.59, 4.71, 4.87]:
        art.box(wall, Vector3(width, 0.07, 0.13), Vector3(0, y, 0.05), "ivory" if y > 4.0 else "wood")
    var panels: int = maxi(1, int(width / 1.8))
    for i in range(panels):
        var x: float = -width * 0.5 + (i + 0.5) * width / panels
        art.box(wall, Vector3(width / panels - 0.17, 1.03, 0.012), Vector3(x, 0.84, 0.06), "dark")
        art.box(wall, Vector3(width / panels - 0.25, 0.95, 0.012), Vector3(x, 0.84, 0.073), "wood")

func _walls(parent: Node3D) -> void:
    _wall_panel(parent, Vector3(0, 0, -13.78), 23.6)
    _wall_panel(parent, Vector3(0, 0, 13.78), 23.6, PI)
    _wall_panel(parent, Vector3(-11.78, 0, 0), 27.6, PI / 2.0)
    _wall_panel(parent, Vector3(11.78, 0, 0), 27.6, -PI / 2.0)
    art.box(parent, Vector3(24, 0.13, 28), Vector3(0, 5.03, 0), "ivory")
    for x in [-7.0, 7.0]:
        var wall := art.group(parent, "RearChamberWall", Vector3(x, 0, -8))
        art.box(wall, Vector3(10, 5, 0.30), Vector3(0, 2.5, 0), "wood")
        art.collider(wall, Vector3(10, 5, 0.30), Vector3(0, 2.5, 0))
        _wall_panel(wall, Vector3(0, 0, 0.17), 10)
        _wall_panel(wall, Vector3(0, 0, -0.17), 10, PI)
    art.box(parent, Vector3(4.15, 1.57, 0.32), Vector3(0, 4.21, -8), "wood")
    for side in [-1.0, 1.0]:
        for z in [-10.7, -3.1, 7.3]:
            art.window(parent, Vector3(side * 11.67, 2.86, z), -side * PI / 2.0)
    for x in [-7.7, 7.7]:
        art.window(parent, Vector3(x, 2.85, 13.62), PI)
    # A wood fireplace gives the sitting room an architectural focal point.
    var fireplace := art.group(parent, "Fireplace", Vector3(-11.35, 0.12, 4.0))
    fireplace.rotation.y = PI / 2.0
    art.box(fireplace, Vector3(2.2, 1.75, 0.16), Vector3(0, 0.87, 0), "wood")
    art.box(fireplace, Vector3(1.30, 1.22, 0.02), Vector3(0, 0.70, 0.10), "dark")
    for x in [-0.93, 0.93]:
        art.box(fireplace, Vector3(0.22, 1.72, 0.45), Vector3(x, 0.87, 0.15), "ivory")
    art.box(fireplace, Vector3(2.35, 0.13, 0.59), Vector3(0, 1.8, 0.17), "wood")
    art.box(fireplace, Vector3(2.5, 0.10, 0.83), Vector3(0, 0.06, 0.22), "dark_marble")
    art.collider(fireplace, Vector3(2.5, 1.85, 0.62), Vector3(0, 0.92, 0.17))
    for z in [0.18, 0.32]:
        art.rod(fireplace, Vector3(-0.4, 0.22, z), Vector3(0.4, 0.25, z), 0.085, "wood")

func _furniture(parent: Node3D) -> void:
    # The central aisle and both sides of the sealed passage stay clear.
    art.sofa(parent, Vector3(-7.0, 0.12, 7.6))
    art.table(parent, "ParlorCoffeeTable", Vector3(-7.0, 0.12, 5.75), 2.7, 1.25, 0.45)
    art.chair(parent, Vector3(-9.25, 0.12, 5.0), -PI / 2.0)
    art.chair(parent, Vector3(-4.5, 0.12, 5.8), PI / 2.0)
    var watch_table := art.table(parent, "WatchTable", Vector3(-6, 0.12, 1), 1.65, 1.1, 0.54)
    art.lamp(watch_table, Vector3(-0.58, 0.57, -0.22))
    art.table(parent, "MusicBoxTable", Vector3(-4, 0.12, -4), 1.65, 1.10, 0.54)
    var vanity := art.table(parent, "MirrorVanity", Vector3(6, 0.12, -2), 2.35, 1.00, 0.57)
    art.lamp(vanity, Vector3(0.87, 0.60, -0.10))
    art.chair(parent, Vector3(7.7, 0.12, -0.35), -0.25)
    var writing_desk := art.table(parent, "WritingDesk", Vector3(5, 0.12, 4), 2.6, 1.35, 0.64)
    art.lamp(writing_desk, Vector3(0.95, 0.67, -0.28))
    art.chair(parent, Vector3(6.3, 0.12, 5.7), 0.15)
    for x in [5.4, 9.1]:
        art.bookcase(parent, Vector3(x, 0.12, -7.48))
    art.bookcase(parent, Vector3(-11.23, 0.12, -3.8), PI / 2.0)
    art.bookcase(parent, Vector3(11.20, 0.12, 3.0), -PI / 2.0)
    art.bookcase(parent, Vector3(-6.8, 0.12, -13.35))
    art.bookcase(parent, Vector3(-3.2, 0.12, -13.35))
    art.table(parent, "PortraitConsole", Vector3(4, 0.12, -13.05), 2.65, 0.76, 0.54)
    art.chair(parent, Vector3(8.6, 0.12, -11.1), -0.35)
    var study := art.table(parent, "RearStudyDesk", Vector3(-7.6, 0.12, -10.7), 2.3, 1.1, 0.78)
    art.lamp(study, Vector3(-0.82, 0.81, -0.21))
    art.chair(parent, Vector3(-7.6, 0.12, -9.1))
    for i in range(3):
        art.box(parent, Vector3(0.31, 0.045, 0.42), Vector3(-7.70 + i * 0.035, 0.59 + i * 0.05, 5.75), "blue" if i % 2 else "red")

func _replace_shape(object: Node3D, size: Vector3, offset: Vector3 = Vector3.ZERO) -> void:
    object.get_node("MeshInstance3D").hide()
    var shape := BoxShape3D.new()
    shape.size = size
    var collision: CollisionShape3D = object.get_node("CollisionShape3D")
    collision.shape = shape
    collision.scale = Vector3.ONE
    collision.position = offset

func _heirlooms(world: Node3D) -> void:
    var watch: Node3D = world.get_node("Watch")
    _replace_shape(watch, Vector3(0.74, 0.30, 0.82), Vector3(0, 0.10, 0))
    art.pocket_watch(watch)
    var mirror: Node3D = world.get_node("Mirror")
    _replace_shape(mirror, Vector3(0.73, 0.97, 0.28), Vector3(0, 0.14, 0))
    art.mirror(mirror)
    var music: Node3D = world.get_node("MusicBox")
    _replace_shape(music, Vector3(0.88, 0.36, 0.57), Vector3(0, 0.15, 0))
    art.music_box(music)
    var letter: Node3D = world.get_node("Lore")
    _replace_shape(letter, Vector3(0.72, 0.10, 0.47))
    art.letter(letter)

func _door_frame(parent: Node3D, position: Vector3, width: float, height: float) -> void:
    var frame := art.group(parent, "DoorFrame", position)
    for x in [-width * 0.5 - 0.08, width * 0.5 + 0.08]:
        art.box(frame, Vector3(0.18, height + 0.15, 0.34), Vector3(x, 0, 0), "ivory")
    art.box(frame, Vector3(width + 0.35, 0.17, 0.35), Vector3(0, height * 0.5 + 0.04, 0), "ivory")

func _puzzles(world: Node3D, decoration: Node3D) -> void:
    var seal: Node3D = world.get_node("MusicPuzzle")
    seal.position = Vector3(-8, 1.8, -7.64)
    _replace_shape(seal, Vector3(1.0, 1.06, 0.22))
    art.seal(seal)
    var portrait: Node3D = world.get_node("PortraitPuzzle")
    portrait.position = Vector3(4, 2.12, -13.58)
    _replace_shape(portrait, Vector3(1.6, 2.07, 0.20))
    art.framed_portrait(portrait)
    var key: Node3D = world.get_node("HiddenKey")
    key.position = Vector3(4, 0.70, -12.94)
    _replace_shape(key, Vector3(0.40, 0.16, 0.22))
    art.family_key(key)
    var gate: Node3D = world.get_node("AtticDoor")
    _replace_shape(gate, Vector3(4.0, 3.36, 0.25))
    art.door(gate, 4.0, 3.36)
    _door_frame(decoration, gate.position, 4.0, 3.36)
    var exit: Node3D = world.get_node("ExitDoor")
    exit.position.z = 13.64
    _replace_shape(exit, Vector3(2.6, 3.36, 0.23))
    art.door(exit, 2.6, 3.36, true)
    _door_frame(decoration, exit.position, 2.6, 3.36)

func _lighting(world: Node3D, decoration: Node3D) -> void:
    var chandelier: OmniLight3D = world.get_node("Chandelier")
    chandelier.shadow_enabled = true
    chandelier.omni_range = 17.0
    art.chandelier(chandelier)
    var rear_light: OmniLight3D = world.get_node("UpstairsLight")
    rear_light.position = Vector3(0, 3.8, -10.7)
    rear_light.light_color = Color("a49cae")
    rear_light.omni_range = 13.0
    art.chandelier(rear_light)
    world.get_node("MoonLight").light_energy = 0.25
    for x in [-7.5, 7.5]:
        var hall_light := OmniLight3D.new()
        hall_light.position = Vector3(x, 3.1, -2)
        hall_light.light_color = Color("ffcf99")
        hall_light.light_energy = 1.1
        hall_light.omni_range = 8.0
        decoration.add_child(hall_light)
