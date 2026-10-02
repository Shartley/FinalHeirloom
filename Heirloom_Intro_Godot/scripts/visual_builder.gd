extends RefCounted
## Native, editable 3D models and materials. Contains no gameplay state.

var materials: Dictionary = {}

func _init() -> void:
    for entry in {
        "ivory": "d4c9ac", "white": "e7e3d7", "dark": "211a17",
        "velvet": "55343f", "cloth": "8b7560", "skin": "925f43",
        "hair": "201615", "ink": "282322", "paper": "ddc99f",
        "green": "3b4b3d", "blue": "3a4857", "red": "693e36",
        "gold": "b67433", "glass": "839eae", "light": "ffd5a0"
    }:
        var material := StandardMaterial3D.new()
        material.albedo_color = Color(entry_color(entry))
        material.roughness = 0.75
        if entry == "gold":
            material.metallic = 0.75
            material.roughness = 0.25
        if entry == "glass":
            material.metallic = 0.85
            material.roughness = 0.10
            material.emission_enabled = true
            material.emission = Color("233949")
            material.emission_energy_multiplier = 0.3
        if entry == "light":
            material.emission_enabled = true
            material.emission = Color("ffd5a0")
            material.emission_energy_multiplier = 1.5
        materials[entry] = material
    materials["wood"] = shader_material("wood", {})
    materials["wallpaper"] = shader_material("wallpaper", {})
    materials["marble"] = shader_material("marble", {})
    materials["dark_marble"] = shader_material("marble", {"tint": Color("332419")})

func entry_color(entry: String) -> String:
    return {
        "ivory": "d4c9ac", "white": "e7e3d7", "dark": "211a17",
        "velvet": "55343f", "cloth": "8b7560", "skin": "925f43",
        "hair": "201615", "ink": "282322", "paper": "ddc99f",
        "green": "3b4b3d", "blue": "3a4857", "red": "693e36",
        "gold": "b67433", "glass": "839eae", "light": "ffd5a0"
    }[entry]

func shader_material(shader_name: String, parameters: Dictionary) -> ShaderMaterial:
    var material := ShaderMaterial.new()
    material.shader = load("res://assets/" + shader_name + ".gdshader")
    for parameter in parameters:
        material.set_shader_parameter(parameter, parameters[parameter])
    return material

func group(parent: Node3D, object_name: String, position: Vector3 = Vector3.ZERO) -> Node3D:
    var node := Node3D.new()
    node.name = object_name
    node.position = position
    parent.add_child(node)
    return node

func mesh(parent: Node3D, resource: Mesh, position: Vector3, key: String) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.mesh = resource
    instance.material_override = materials[key]
    instance.position = position
    parent.add_child(instance)
    return instance

func box(parent: Node3D, size: Vector3, position: Vector3, key: String = "wood") -> MeshInstance3D:
    var resource := BoxMesh.new()
    resource.size = size
    return mesh(parent, resource, position, key)

func cylinder(parent: Node3D, radius: float, height: float, position: Vector3, key: String, top_radius: float = -1.0) -> MeshInstance3D:
    var resource := CylinderMesh.new()
    resource.bottom_radius = radius
    resource.top_radius = radius if top_radius < 0.0 else top_radius
    resource.height = height
    resource.radial_segments = 24
    return mesh(parent, resource, position, key)

func sphere(parent: Node3D, radius: float, position: Vector3, key: String, scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
    var resource := SphereMesh.new()
    resource.radius = radius
    resource.height = radius * 2.0
    resource.radial_segments = 20
    resource.rings = 12
    var instance := mesh(parent, resource, position, key)
    instance.scale = scale
    return instance

func torus(parent: Node3D, inner: float, outer: float, position: Vector3, key: String) -> MeshInstance3D:
    var resource := TorusMesh.new()
    resource.inner_radius = inner
    resource.outer_radius = outer
    resource.rings = 32
    resource.ring_segments = 12
    return mesh(parent, resource, position, key)

func rod(parent: Node3D, start: Vector3, end: Vector3, radius: float, key: String) -> MeshInstance3D:
    var instance := cylinder(parent, radius, start.distance_to(end), (start + end) * 0.5, key)
    var direction: Vector3 = (end - start).normalized()
    var axis: Vector3 = Vector3.UP.cross(direction)
    if axis.length_squared() > 0.001:
        instance.basis = Basis(axis.normalized(), Vector3.UP.angle_to(direction))
    elif direction.y < 0.0:
        instance.rotation.x = PI
    return instance

func collider(parent: Node3D, size: Vector3, position: Vector3) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.position = position
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    parent.add_child(body)
    return body

func label(parent: Node3D, text: String, position: Vector3, font_size: int = 22, pixel_size: float = 0.004) -> Label3D:
    var node := Label3D.new()
    node.text = text
    node.position = position
    node.font_size = font_size
    node.pixel_size = pixel_size
    node.modulate = Color("322921")
    node.outline_size = 0
    parent.add_child(node)
    return node

func pocket_watch(parent: Node3D) -> Node3D:
    var root := group(parent, "PocketWatch", Vector3(0, 0.055, 0))
    root.rotation.x = deg_to_rad(8)
    cylinder(root, 0.35, 0.09, Vector3.ZERO, "gold")
    cylinder(root, 0.31, 0.012, Vector3(0, 0.054, 0), "ivory")
    torus(root, 0.304, 0.348, Vector3(0, 0.063, 0), "gold")
    for i in range(60):
        var angle: float = i * TAU / 60.0
        var tick := box(root, Vector3(0.007, 0.004, 0.025 if i % 5 else 0.042), Vector3(sin(angle) * 0.283, 0.067, -cos(angle) * 0.283), "ink")
        tick.rotation.y = -angle
    for pair in [[0, "XII"], [3, "III"], [6, "VI"], [9, "IX"]]:
        var angle: float = float(pair[0]) * TAU / 12.0
        var numeral := label(root, str(pair[1]), Vector3(sin(angle) * 0.228, 0.072, -cos(angle) * 0.228), 26, 0.0015)
        numeral.rotation.x = -PI / 2.0
    var hour := box(root, Vector3(0.021, 0.009, 0.16), Vector3(-0.031, 0.082, -0.071), "ink")
    hour.rotation.y = -0.38
    box(root, Vector3(0.012, 0.010, 0.235), Vector3(0.012, 0.092, -0.11), "ink").rotation.y = 0.10
    cylinder(root, 0.025, 0.018, Vector3(0, 0.094, 0), "gold")
    cylinder(root, 0.038, 0.06, Vector3(0, 0, -0.38), "gold").rotation.x = PI / 2.0
    torus(root, 0.042, 0.064, Vector3(0, 0.008, -0.45), "gold")
    for i in range(12):
        var link := torus(parent, 0.019, 0.029, Vector3(0.04 + i * 0.045, -0.025, -0.43 + sin(i * 0.55) * 0.055), "gold")
        link.rotation.z = 0.45 if i % 2 else -0.45
    return root

func mirror(parent: Node3D) -> Node3D:
    var root := group(parent, "VanityMirror")
    var rim := torus(root, 0.285, 0.338, Vector3(0, 0.17, 0), "gold")
    rim.rotation.x = PI / 2.0
    rim.scale.z = 1.4
    var glass := cylinder(root, 0.286, 0.035, Vector3(0, 0.17, 0.01), "glass")
    glass.rotation.x = PI / 2.0
    glass.scale.z = 1.4
    for sign_x in [-1.0, 1.0]:
        rod(root, Vector3(sign_x * 0.3, -0.16, 0), Vector3(sign_x * 0.3, 0.18, 0), 0.026, "gold")
        sphere(root, 0.042, Vector3(sign_x * 0.32, 0.17, 0), "gold")
    box(root, Vector3(0.58, 0.06, 0.30), Vector3(0, -0.29, 0), "wood")
    for angle in range(0, 360, 45):
        var radians: float = deg_to_rad(float(angle))
        sphere(root, 0.03, Vector3(sin(radians) * 0.32, 0.17 + cos(radians) * 0.44, 0), "gold")
    return root

func music_box(parent: Node3D) -> Node3D:
    var root := group(parent, "CarvedMusicBox")
    box(root, Vector3(0.72, 0.25, 0.48), Vector3(0, 0.14, 0), "wood")
    box(root, Vector3(0.77, 0.06, 0.53), Vector3(0, 0.29, 0), "wood")
    for x in [-0.36, 0.36]:
        for z in [-0.24, 0.24]:
            sphere(root, 0.032, Vector3(x, 0.065, z), "gold")
            box(root, Vector3(0.026, 0.24, 0.026), Vector3(x, 0.16, z), "gold")
    box(root, Vector3(0.75, 0.012, 0.012), Vector3(0, 0.30, 0.27), "gold")
    box(root, Vector3(0.12, 0.07, 0.03), Vector3(0, 0.14, 0.25), "gold")
    torus(root, 0.085, 0.097, Vector3(0, 0.327, 0), "gold")
    for i in range(5):
        cylinder(root, 0.012, 0.012, Vector3(-0.20 + i * 0.10, 0.325, 0.16), "gold")
    rod(root, Vector3(0.37, 0.14, 0), Vector3(0.46, 0.14, 0), 0.02, "gold")
    rod(root, Vector3(0.46, 0.14, 0), Vector3(0.46, 0.20, 0), 0.02, "gold")
    return root

func family_key(parent: Node3D) -> void:
    var root := group(parent, "BrassKey", Vector3(0, 0.05, 0))
    torus(root, 0.065, 0.093, Vector3(-0.14, 0, 0), "gold")
    rod(root, Vector3(-0.07, 0, 0), Vector3(0.20, 0, 0), 0.018, "gold")
    for x in [0.11, 0.18]:
        box(root, Vector3(0.036, 0.035, 0.072), Vector3(x, 0, 0.034), "gold")

func letter(parent: Node3D) -> void:
    box(parent, Vector3(0.68, 0.018, 0.43), Vector3(0, 0.03, 0), "paper")
    for i in range(6):
        box(parent, Vector3(0.46 - i % 3 * 0.07, 0.002, 0.007), Vector3(-0.035, 0.041, -0.14 + i * 0.043), "ink")
    cylinder(parent, 0.045, 0.01, Vector3(0.22, 0.045, 0.14), "red")

func framed_portrait(parent: Node3D) -> void:
    var root := group(parent, "FamilyPortrait")
    box(root, Vector3(1.45, 1.95, 0.08), Vector3.ZERO, "wood")
    box(root, Vector3(1.20, 1.69, 0.03), Vector3(0, 0, 0.06), "paper")
    for x in [-0.675, 0.675]:
        box(root, Vector3(0.12, 1.97, 0.10), Vector3(x, 0, 0.08), "gold")
    for y in [-0.915, 0.915]:
        box(root, Vector3(1.45, 0.12, 0.10), Vector3(0, y, 0.08), "gold")
    # Raised silhouettes give the portrait a readable family composition.
    for figure in [[-0.29, 0.20, 0.15, "dark"], [0.27, 0.16, 0.16, "velvet"], [0.0, -0.27, 0.10, "white"]]:
        sphere(root, float(figure[2]), Vector3(float(figure[0]), float(figure[1]) + 0.21, 0.09), "skin", Vector3(1, 1, 0.15))
        sphere(root, float(figure[2]) * 1.8, Vector3(float(figure[0]), float(figure[1]) - 0.18, 0.09), str(figure[3]), Vector3(1, 1.35, 0.10))

func seal(parent: Node3D) -> void:
    box(parent, Vector3(0.9, 0.95, 0.12), Vector3.ZERO, "wood")
    var ring := torus(parent, 0.29, 0.33, Vector3(0, 0, 0.1), "gold")
    ring.rotation.x = PI / 2.0
    rod(parent, Vector3(-0.08, -0.15, 0.16), Vector3(-0.08, 0.18, 0.16), 0.025, "gold")
    sphere(parent, 0.065, Vector3(-0.11, -0.17, 0.16), "gold", Vector3(1, 0.7, 0.35))
    rod(parent, Vector3(-0.08, 0.18, 0.16), Vector3(0.16, 0.10, 0.16), 0.025, "gold")

func door(parent: Node3D, width: float, height: float, flip: bool = false) -> void:
    var root := group(parent, "PanelledDoor")
    if flip:
        root.rotation.y = PI
    box(root, Vector3(width, height, 0.18), Vector3.ZERO, "wood")
    for x in [-width * 0.25, width * 0.25]:
        for y in [-height * 0.23, height * 0.23]:
            box(root, Vector3(width * 0.37, height * 0.34, 0.035), Vector3(x, y, 0.115), "dark")
            box(root, Vector3(width * 0.33, height * 0.30, 0.018), Vector3(x, y, 0.139), "wood")
    for x in [-0.12, 0.12]:
        sphere(root, 0.065, Vector3(x, -0.08, 0.17), "gold")
        box(root, Vector3(0.07, 0.21, 0.015), Vector3(x, -0.08, 0.148), "gold")

func table(parent: Node3D, object_name: String, position: Vector3, width: float, depth: float, height: float) -> Node3D:
    var root := group(parent, object_name, position)
    box(root, Vector3(width, 0.10, depth), Vector3(0, height - 0.05, 0), "wood")
    box(root, Vector3(width - 0.12, 0.16, depth - 0.12), Vector3(0, height - 0.18, 0), "wood")
    for x in [-width * 0.38, width * 0.38]:
        for z in [-depth * 0.34, depth * 0.34]:
            cylinder(root, 0.065, height - 0.12, Vector3(x, (height - 0.12) * 0.5, z), "wood", 0.045)
    collider(root, Vector3(width, height, depth), Vector3(0, height * 0.5, 0))
    return root

func sofa(parent: Node3D, position: Vector3) -> Node3D:
    var root := group(parent, "ChesterfieldSofa", position)
    box(root, Vector3(3.1, 0.42, 1.05), Vector3(0, 0.35, 0), "velvet")
    box(root, Vector3(2.95, 0.92, 0.30), Vector3(0, 0.86, 0.44), "velvet")
    for x in [-1.47, 1.47]:
        cylinder(root, 0.18, 1.05, Vector3(x, 0.73, 0), "velvet").rotation.x = PI / 2.0
    for x in [-0.91, 0.0, 0.91]:
        sphere(root, 0.48, Vector3(x, 0.59, -0.09), "velvet", Vector3(0.95, 0.25, 0.96))
    for x in [-1.02, 1.02]:
        var pillow := sphere(root, 0.26, Vector3(x, 0.88, 0.16), "cloth", Vector3(1.0, 1.0, 0.33))
        pillow.rotation.z = 0.18 * signf(x)
    for x in [-1.05, -0.55, 0.0, 0.55, 1.05]:
        for y in [0.82, 1.12]:
            sphere(root, 0.025, Vector3(x, y, 0.275), "dark")
    for x in [-1.32, 1.32]:
        for z in [-0.35, 0.36]:
            cylinder(root, 0.075, 0.22, Vector3(x, 0.11, z), "wood")
    collider(root, Vector3(3.15, 1.35, 1.10), Vector3(0, 0.68, 0))
    return root

func chair(parent: Node3D, position: Vector3, rotation: float = 0.0) -> Node3D:
    var root := group(parent, "Armchair", position)
    root.rotation.y = rotation
    box(root, Vector3(0.78, 0.11, 0.73), Vector3(0, 0.49, 0), "wood")
    sphere(root, 0.36, Vector3(0, 0.57, -0.02), "cloth", Vector3(1, 0.22, 0.98))
    box(root, Vector3(0.74, 0.72, 0.12), Vector3(0, 1.0, 0.30), "wood")
    sphere(root, 0.31, Vector3(0, 1.0, 0.22), "cloth", Vector3(1, 1.08, 0.14))
    for x in [-0.30, 0.30]:
        for z in [-0.27, 0.28]:
            cylinder(root, 0.043, 0.49, Vector3(x, 0.245, z), "wood")
    collider(root, Vector3(0.80, 1.36, 0.80), Vector3(0, 0.68, 0))
    return root

func book(parent: Node3D, position: Vector3, width: float, height: float, key: String) -> void:
    box(parent, Vector3(width, height, 0.22), position, key)
    for y in [-height * 0.34, height * 0.34]:
        box(parent, Vector3(width * 0.9, 0.014, 0.014), position + Vector3(0, y, 0.118), "ivory")

func bookcase(parent: Node3D, position: Vector3, rotation: float = 0.0) -> Node3D:
    var root := group(parent, "Bookshelf", position)
    root.rotation.y = rotation
    box(root, Vector3(2.30, 2.75, 0.08), Vector3(0, 1.375, -0.22), "wood")
    for x in [-1.13, 1.13]:
        box(root, Vector3(0.13, 2.75, 0.50), Vector3(x, 1.375, 0), "wood")
    for y in [0.20, 0.80, 1.42, 2.04, 2.68]:
        box(root, Vector3(2.30, 0.10, 0.52), Vector3(0, y, 0), "wood")
    box(root, Vector3(2.52, 0.16, 0.61), Vector3(0, 2.79, 0), "wood")
    var colors := ["green", "red", "blue", "dark", "cloth"]
    for shelf in range(4):
        for i in range(10):
            var width: float = 0.12 + (i % 3) * 0.035
            var height: float = 0.35 + ((i + shelf) % 4) * 0.035
            book(root, Vector3(-0.95 + i * 0.20, 0.27 + shelf * 0.62 + height * 0.5, 0.02), width, height, colors[(i + shelf * 2) % colors.size()])
    collider(root, Vector3(2.4, 2.85, 0.57), Vector3(0, 1.43, 0))
    return root

func window(parent: Node3D, position: Vector3, rotation: float = 0.0) -> void:
    var root := group(parent, "CurtainedWindow", position)
    root.rotation.y = rotation
    box(root, Vector3(1.85, 2.20, 0.04), Vector3.ZERO, "glass")
    for x in [-0.97, 0.97]:
        box(root, Vector3(0.13, 2.40, 0.17), Vector3(x, 0, 0.05), "ivory")
    for y in [-1.14, 1.14]:
        box(root, Vector3(2.05, 0.13, 0.17), Vector3(0, y, 0.05), "ivory")
    box(root, Vector3(0.065, 2.20, 0.08), Vector3(0, 0, 0.08), "ivory")
    box(root, Vector3(1.9, 0.065, 0.08), Vector3(0, 0, 0.08), "ivory")
    box(root, Vector3(2.24, 0.10, 0.36), Vector3(0, -1.24, 0.13), "wood")
    rod(root, Vector3(-1.25, 1.36, 0.18), Vector3(1.25, 1.36, 0.18), 0.028, "dark")
    for side in [-1.0, 1.0]:
        for i in range(4):
            cylinder(root, 0.074, 2.50, Vector3(side * (0.88 + i * 0.09), 0.01, 0.16), "velvet")

func lamp(parent: Node3D, position: Vector3) -> void:
    cylinder(parent, 0.13, 0.05, position, "dark")
    cylinder(parent, 0.025, 0.30, position + Vector3(0, 0.17, 0), "gold")
    cylinder(parent, 0.23, 0.28, position + Vector3(0, 0.40, 0), "ivory", 0.12)
    var light := OmniLight3D.new()
    light.position = position + Vector3(0, 0.35, 0)
    light.light_color = Color("ffcc96")
    light.light_energy = 0.7
    light.omni_range = 4.0
    parent.add_child(light)

func chandelier(parent: Node3D) -> void:
    rod(parent, Vector3(0, 0, 0), Vector3(0, 1.2, 0), 0.04, "dark")
    torus(parent, 0.80, 0.85, Vector3(0, -0.10, 0), "dark")
    for i in range(6):
        var angle: float = i * TAU / 6.0
        var end := Vector3(cos(angle) * 0.82, 0.05, sin(angle) * 0.82)
        rod(parent, Vector3(0, 0.2, 0), end, 0.026, "dark")
        cylinder(parent, 0.055, 0.22, end + Vector3(0, 0.13, 0), "ivory")
        sphere(parent, 0.048, end + Vector3(0, 0.275, 0), "light", Vector3(0.7, 1.4, 0.7))
    for part in parent.get_children():
        if part is MeshInstance3D:
            part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func girl(parent: Node3D) -> Node3D:
    var root := group(parent, "CharacterModel")
    cylinder(root, 0.44, 0.88, Vector3(0, -0.30, 0), "white", 0.21)
    cylinder(root, 0.443, 0.07, Vector3(0, -0.71, 0), "cloth", 0.423)
    sphere(root, 0.24, Vector3(0, 0.19, 0), "white", Vector3(1, 1.2, 0.82))
    cylinder(root, 0.075, 0.13, Vector3(0, 0.44, 0), "skin")
    sphere(root, 0.22, Vector3(0, 0.64, 0), "skin", Vector3(0.9, 1.05, 0.88))
    sphere(root, 0.23, Vector3(0, 0.69, 0.075), "hair", Vector3(1, 1.0, 0.74))
    for x in [-0.14, 0.14]:
        sphere(root, 0.09, Vector3(x, 0.79, 0.04), "hair")
    for x in [-0.07, 0.07]:
        sphere(root, 0.017, Vector3(x, 0.66, -0.194), "ink")
    for sign_x in [-1.0, 1.0]:
        var arm := group(root, "ArmLeft" if sign_x < 0 else "ArmRight", Vector3(sign_x * 0.24, 0.28, 0))
        rod(arm, Vector3.ZERO, Vector3(sign_x * 0.05, -0.40, 0), 0.065, "skin")
        sphere(arm, 0.065, Vector3(sign_x * 0.05, -0.43, 0), "skin")
        cylinder(root, 0.063, 0.24, Vector3(sign_x * 0.13, -0.78, 0), "skin")
        box(root, Vector3(0.14, 0.08, 0.23), Vector3(sign_x * 0.13, -0.92, -0.025), "dark")
    return root
