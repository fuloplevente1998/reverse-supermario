extends RefCounted

# Shared Blender models supply volume across the remaining nine biomes.
# All decorations sit outside the tested playable corridor and bridge gaps.
static var prefabs: Dictionary = {}

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
                    place(game, "castle_wall", at + Vector3(0, -3.0, 0), Vector3(1, 1.4, 1), PI * 0.5)
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
                    place(game, "castle_wall", at, Vector3.ONE, PI * 0.5)
                    place(game, "stage1_banner", at + Vector3(-side, 0, 2))
                9:
                    place(game, "pine_tree", at, Vector3(1.0, 1.25, 1.0))
                    place(game, "cliff_rock", at + Vector3(side, 0, 3))
        var house_id := "forge_house" if number == 5 else ("mill_house" if number == 6 else "timber_house")
        for z in [3.0, 29.0]:
            place(game, house_id, Vector3(side * (outer + 4.0), 0, z), Vector3.ONE, -side * PI * 0.5)
        # Landscape shelves beyond the corridor provide actual ground beneath scenery.
        if number not in [2, 8]:
            var mat := StandardMaterial3D.new()
            mat.albedo_color = Color("#78836b") if number in [3, 6] else (Color("#b6c4cb") if number == 4 else Color("#7b7161"))
            mat.roughness = 1.0
            var mesh := BoxMesh.new()
            mesh.size = Vector3(14, 0.7, 70)
            var apron := MeshInstance3D.new()
            apron.name = "LandscapeShelf"
            apron.mesh = mesh
            apron.material_override = mat
            apron.position = Vector3(side * (lane_width * 0.5 + 7.0), -0.4, 15)
            game.add_child(apron)
    game.set_meta("uses_blender_scenery", true)
