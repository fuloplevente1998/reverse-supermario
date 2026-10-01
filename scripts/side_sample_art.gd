extends RefCounted
const Art = preload("res://scripts/art.gd")
const WorldScenery = preload("res://scripts/world_scenery.gd")

static func build(game: Node3D) -> void:
    var root := Node3D.new()
    root.name = "SideArtSample"
    game.add_child(root)
    root.set_meta("sample_start_z", -15.0)
    root.set_meta("sample_end_z", 10.0)
    root.set_meta("reference_pass", "2026-10-01")

    var limestone := Art.material(Color("#e8d8b8"))
    limestone.albedo_texture = preload("res://assets/terrain/sample_limestone.svg")
    limestone.roughness = 0.82
    limestone.vertex_color_use_as_albedo = true

    var darker_limestone := Art.material(Color("#bda98a"))
    darker_limestone.albedo_texture = preload("res://assets/terrain/sample_limestone.svg")
    darker_limestone.roughness = 0.92
    darker_limestone.vertex_color_use_as_albedo = true

    var mortar := Art.material(Color("#6b6256"))
    mortar.roughness = 1.0

    # A recessed warm-grey backing is visible in the joints so the wall reads as
    # stacked masonry instead of a flat repeated tile strip.
    var backing := Art.box(root, Vector3(0.12, 3.12, 25.0), Vector3(-2.53, -1.54, -2.5), mortar)
    backing.name = "MortarBacking"
    backing.layers = 4
    backing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

    var blocks: Array[Transform3D] = []
    var base_blocks: Array[Transform3D] = []
    var lengths := [1.22, 1.52, 1.38, 1.70, 1.44]
    for row in range(5):
        var cursor: float = -15.0 - (0.57 if row % 2 else 0.0)
        var index := 0
        while cursor < 10.0:
            var block_length: float = lengths[(row * 2 + index) % lengths.size()]
            var a: float = maxf(-15.0, cursor)
            var b: float = minf(10.0, cursor + block_length)
            if b - a > 0.07:
                var y: float = -0.36 - row * 0.58 + (0.018 if (row + index) % 3 == 0 else 0.0)
                var transform := Transform3D(
                    Basis.IDENTITY.scaled(Vector3(0.30, 0.54, b - a - 0.045)),
                    Vector3(-2.70, y, (a + b) * 0.5)
                )
                if row == 4:
                    base_blocks.append(transform)
                else:
                    blocks.append(transform)
            cursor += block_length + 0.035
            index += 1
    _batch(root, "ReliefMasonry", blocks, limestone, true)
    _batch(root, "DarkBaseMasonry", base_blocks, darker_limestone, true)

    # The top walking surface keeps the existing collision height. Visual slabs
    # are staggered and slightly inset so their seams do not line up with the
    # facade courses below.
    var paving: Array[Transform3D] = []
    for row in range(4):
        for col in range(17):
            var tile_length := 25.0 / 17.0 - 0.030
            var z0: float = -15.0 + col * 25.0 / 17.0
            var z_shift := (0.09 if row % 2 else -0.04)
            paving.append(Transform3D(
                Basis.IDENTITY.scaled(Vector3(1.27, 0.10, tile_length)),
                Vector3(-1.95 + row * 1.3, -0.045, z0 + 12.5 / 17.0 + z_shift)
            ))
    _batch(root, "WalkwayPaving", paving, limestone, true)

    var cornice: Array[Transform3D] = []
    var cap_cursor := -15.0
    var cap_index := 0
    var cap_lengths := [0.82, 1.05, 0.94, 1.12]
    while cap_cursor < 10.0:
        var cap_length: float = minf(cap_lengths[cap_index % cap_lengths.size()], 10.0 - cap_cursor)
        cornice.append(Transform3D(
            Basis.IDENTITY.scaled(Vector3(0.34, 0.19, maxf(0.08, cap_length - 0.025))),
            Vector3(-2.73, -0.095, cap_cursor + cap_length * 0.5)
        ))
        cap_cursor += cap_length
        cap_index += 1
    _batch(root, "PaleStoneCornice", cornice, limestone, true)

    _build_middle_distance(game)
    _build_props(game)
    _build_garden(root, game)

    # Two warm accents make the real-time foreground share the same light story
    # as the supplied courtyard target without relying on expensive bloom.
    _brazier(root, Vector3(3.65, 0.0, -6.0), "ReferenceBrazierA")
    _brazier(root, Vector3(3.85, 0.0, 7.0), "ReferenceBrazierB")

    game.set_meta("side_art_sample", true)
    game.set_meta("side_reference_layers", 3)

static func _build_middle_distance(game: Node3D) -> void:
    var left_wall := WorldScenery.place(game, "castle_wall", Vector3(7.2, 0.0, -10.5), Vector3(0.82, 0.92, 0.82), PI * 0.5)
    if left_wall:
        left_wall.name = "Sample_CastleWall_Left"
        WorldScenery.set_render_layer(left_wall, 4)
        _set_shadows(left_wall, true)

    var right_wall := WorldScenery.place(game, "castle_wall", Vector3(7.2, 0.0, 8.0), Vector3(0.82, 0.92, 0.82), PI * 0.5)
    if right_wall:
        right_wall.name = "Sample_CastleWall_Right"
        WorldScenery.set_render_layer(right_wall, 4)
        _set_shadows(right_wall, true)

    var gate := WorldScenery.place(game, "fortress_gate", Vector3(8.5, 0.0, -0.5), Vector3.ONE * 0.52, PI * 0.5)
    if gate:
        gate.name = "Sample_CastleGate"
        WorldScenery.set_render_layer(gate, 4)
        _set_shadows(gate, true)

    for item in [["stage1_banner", -11.7], ["stage1_banner", 8.6]]:
        var banner := WorldScenery.place(game, item[0], Vector3(4.7, 0.0, item[1]), Vector3.ONE * 0.92, PI * 0.5)
        if banner:
            banner.name = "Sample_%s_%s" % [str(item[0]), str(item[1])]
            WorldScenery.set_render_layer(banner, 4)
            _set_shadows(banner, true)

static func _build_props(game: Node3D) -> void:
    for item in [["stage1_barrel", -7.3, 0.96], ["stage1_crate", -5.6, 1.05]]:
        var model := WorldScenery.place(game, item[0], Vector3(3.45, 0.0, item[1]), Vector3.ONE * float(item[2]), PI * 0.5)
        if model:
            model.name = "Sample_%s_%s" % [str(item[0]), str(item[1])]
            WorldScenery.set_render_layer(model, 4)
            _set_shadows(model, true)

static func _build_garden(root: Node3D, game: Node3D) -> void:
    # Existing Blender pines are stretched into narrow courtyard silhouettes.
    # They remain deliberately behind the gameplay plane.
    for z in [-12.5, -2.7, 5.9]:
        var tree := WorldScenery.place(game, "pine_tree", Vector3(6.0, 0.0, z), Vector3(0.30, 0.92, 0.30))
        if tree:
            tree.name = "SampleCypress_%s" % str(z)
            WorldScenery.set_render_layer(tree, 4)
            _set_shadows(tree, true)

    var leaf := Art.material(Color("#496f38"))
    leaf.roughness = 0.95
    var leaf_light := Art.material(Color("#6f8f49"))
    leaf_light.roughness = 0.95
    var berry := Art.material(Color("#a7354b"))
    berry.roughness = 0.88

    for z in [-9.4, 4.9]:
        var bush := Node3D.new()
        bush.name = "SampleFlowerBed%s" % str(z)
        bush.position = Vector3(3.05, 0.0, z)
        root.add_child(bush)
        for i in range(9):
            var sphere := SphereMesh.new()
            sphere.radius = 0.24 + 0.035 * float(i % 3)
            sphere.height = sphere.radius * 2.0
            sphere.radial_segments = 10
            sphere.rings = 6
            var px := -0.18 + 0.08 * float(i % 3)
            var py := 0.19 + 0.09 * float((i * 5) % 3)
            var pz := (float(i) - 4.0) * 0.16
            Art.piece(bush, sphere, Vector3(px, py, pz), leaf if i % 2 else leaf_light)
            if i % 2 == 0:
                var bloom := SphereMesh.new()
                bloom.radius = 0.065
                bloom.height = 0.13
                bloom.radial_segments = 8
                bloom.rings = 4
                Art.piece(bush, bloom, Vector3(-0.24, py + 0.23, pz + 0.03), berry)
        WorldScenery.set_render_layer(bush, 4)
        _set_shadows(bush, true)

        var rock := WorldScenery.place(game, "cliff_rock", Vector3(3.5, -0.08, z + 0.65), Vector3.ONE * 0.34)
        if rock:
            rock.name = "SampleGardenRock%s" % str(z)
            WorldScenery.set_render_layer(rock, 4)
            _set_shadows(rock, true)

static func _brazier(root: Node3D, at: Vector3, node_name: String) -> void:
    var brazier := Node3D.new()
    brazier.name = node_name
    brazier.position = at
    root.add_child(brazier)

    var dark_metal := Art.material(Color("#24262b"), 0.72)
    dark_metal.roughness = 0.42
    var bronze := Art.material(Color("#a97434"), 0.64)
    bronze.roughness = 0.38
    var ember := Art.material(Color("#ff8c32"))
    ember.emission_enabled = true
    ember.emission = Color("#ff6a1a")
    ember.emission_energy_multiplier = 2.2
    ember.roughness = 0.6
    var flame := Art.material(Color("#ffd66d"))
    flame.emission_enabled = true
    flame.emission = Color("#ff9a32")
    flame.emission_energy_multiplier = 3.0
    flame.roughness = 0.5

    Art.cylinder(brazier, 0.16, 0.72, Vector3(0.0, 0.36, 0.0), dark_metal)
    Art.cylinder(brazier, 0.34, 0.16, Vector3(0.0, 0.77, 0.0), bronze)
    Art.cylinder(brazier, 0.27, 0.08, Vector3(0.0, 0.87, 0.0), ember)
    Art.cylinder(brazier, 0.16, 0.54, Vector3(0.0, 1.10, 0.0), flame, true)
    Art.cylinder(brazier, 0.09, 0.36, Vector3(0.12, 1.03, 0.04), ember, true)

    var light := OmniLight3D.new()
    light.name = "WarmFireLight"
    light.position = Vector3(0.0, 1.05, 0.0)
    light.light_color = Color("#ffb56a")
    light.light_energy = 0.62
    light.omni_range = 4.0
    light.shadow_enabled = false
    brazier.add_child(light)
    WorldScenery.set_render_layer(brazier, 4)

static func _set_shadows(node: Node, enabled: bool) -> void:
    if node is GeometryInstance3D:
        node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if enabled else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    for child in node.get_children():
        _set_shadows(child, enabled)

static func _batch(root: Node3D, node_name: String, transforms: Array[Transform3D], material: Material, cast_shadows: bool = false) -> void:
    var cube := BoxMesh.new()
    cube.size = Vector3.ONE
    var mesh := MultiMesh.new()
    mesh.transform_format = MultiMesh.TRANSFORM_3D
    mesh.use_colors = true
    mesh.mesh = cube
    mesh.instance_count = transforms.size()
    for i in range(transforms.size()):
        mesh.set_instance_transform(i, transforms[i])
        var value: float = 0.90 + float((i * 7) % 10) * 0.01
        mesh.set_instance_color(i, Color(value, value * 0.985, value * 0.96, 1))
    var visual := MultiMeshInstance3D.new()
    visual.name = node_name
    visual.multimesh = mesh
    visual.material_override = material
    visual.layers = 4
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    root.add_child(visual)
