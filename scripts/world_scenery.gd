extends RefCounted

# Shared Blender models supply volume across the remaining nine biomes.
# All decorations sit outside the tested playable corridor and bridge gaps.
static var prefabs: Dictionary = {}
static var terrain_materials: Dictionary = {}

static func terrain_material(number: int) -> StandardMaterial3D:
    var biome := "snow" if number == 4 else ("grass" if number in [1,3,6] else "earth")
    if not terrain_materials.has(biome):
        var mat := StandardMaterial3D.new()
        mat.albedo_texture = load("res://assets/terrain/terrain_%s.png" % biome) as Texture2D
        mat.roughness = 1.0
        mat.uv1_triplanar = true
        mat.uv1_scale = Vector3.ONE * 0.13
        terrain_materials[biome] = mat
    return terrain_materials[biome]

static func landscape_piece(game: Node3D, number: int, dimensions: Vector3, at: Vector3, node_name: String) -> void:
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    var ground := MeshInstance3D.new()
    ground.name = node_name
    ground.mesh = mesh
    ground.material_override = terrain_material(number)
    ground.position = at
    ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    game.add_child(ground)

static func add_landscape(game: Node3D, number: int, lane_width: float) -> void:
    for side in [-1.0,1.0]:
        landscape_piece(game,number,Vector3(30,0.7,96),Vector3(side*(lane_width*0.5+15),-0.4,15),"LandscapeShelf")
    for z in [-25.0,57.0]:
        landscape_piece(game,number,Vector3(lane_width,0.7,20),Vector3(0,-0.4,z),"LandscapeBeyondRoute")
    if number in [2,8]:
        landscape_piece(game,number,Vector3(90,0.7,110),Vector3(0,-8.3,15),"LandscapeValley")

static func configure_yard(node: Node) -> void:
    if node is MeshInstance3D:
        var mesh := node as MeshInstance3D
        if str(mesh.name).begins_with("SceneryRuntime"):
            mesh.visibility_range_end = 70.0
            mesh.visibility_range_end_margin = 5.0
        elif str(mesh.name).begins_with("Pavement"):
            mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    for child in node.get_children():
        configure_yard(child)

static func place(game: Node3D, id: String, at: Vector3, scale_value: Vector3 = Vector3.ONE, yaw: float = 0.0) -> Node3D:
    if not prefabs.has(id):
        prefabs[id] = load("res://assets/models/%s.glb" % id) as PackedScene
    var packed := prefabs[id] as PackedScene
    if packed == null:
        return null
    var model := packed.instantiate() as Node3D
    model.name = "World_%s" % id
    model.position = at
    model.scale = scale_value
    model.rotation.y = yaw
    game.add_child(model)
    return model

static func tint(model: Node, color: Color) -> void:
    if model is MeshInstance3D:
        var instance := model as MeshInstance3D
        for index in range(instance.mesh.get_surface_count()):
            var source := instance.mesh.surface_get_material(index) as StandardMaterial3D
            if source:
                var mat := source.duplicate() as StandardMaterial3D
                mat.albedo_color = mat.albedo_color.lerp(color, 0.72)
                instance.set_surface_override_material(index, mat)
    for child in model.get_children():
        tint(child, color)

static func build(game: Node3D, number: int, lane_width: float) -> void:
    var outer := lane_width * 0.5 + 2.6
    for side in [-1.0, 1.0]:
        for z in range(-9, 44, 8):
            var at := Vector3(side * outer, 0, z)
            match number:
                2, 8:
                    place(game, "cliff_rock", at + Vector3(0, -1.4, 0), Vector3(1.7, 2.0, 1.7))
                3:
                    place(game, "oak_tree", at, Vector3(1.1, 1.2, 1.1))
                    place(game, "cliff_rock", at + Vector3(side * 1.1, -0.2, 2.2), Vector3(0.8, 0.8, 0.8))
                4:
                    var tree := place(game, "pine_tree", at, Vector3(1.0, 1.25, 1.0))
                    if tree:
                        tint(tree, Color("#b8c7c4"))
                    var rock := place(game, "cliff_rock", at + Vector3(side, 0, 3))
                    if rock:
                        tint(rock, Color("#bfced7"))
                5:
                    var rock := place(game, "cliff_rock", at, Vector3(1.3, 1.7, 1.3))
                    if rock:
                        tint(rock, Color("#654b39"))
                6:
                    place(game, "oak_tree", at, Vector3(0.95, 1.1, 0.95))
                    place(game, "stage1_crate", at + Vector3(side * 0.5, 0, 2.4), Vector3.ONE * 1.5)
                7, 10:
                    place(game, "cliff_rock", at, Vector3.ONE)
                    place(game, "stage1_banner", at + Vector3(-side, 0, 2))
                9:
                    place(game, "pine_tree", at, Vector3(1.0, 1.25, 1.0))
                    place(game, "cliff_rock", at + Vector3(side, 0, 3))
        var house_id := "forge_house" if number == 5 else ("mill_house" if number == 6 else "timber_house")
        for z in [3.0, 29.0]:
            place(game, house_id, Vector3(side * (outer + 4.0), 0, z), Vector3.ONE, -side * PI * 0.5)
    add_landscape(game, number, lane_width)
    game.set_meta("uses_blender_scenery", true)
