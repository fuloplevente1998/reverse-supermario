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

    var limestone := Art.material(Color("#cdb48d"))
    limestone.albedo_texture = preload("res://assets/terrain/sample_limestone.svg")
    limestone.roughness = 0.82
    limestone.vertex_color_use_as_albedo = true

    var darker_limestone := Art.material(Color("#8f7c63"))
    darker_limestone.albedo_texture = preload("res://assets/terrain/sample_limestone.svg")
    darker_limestone.roughness = 0.92
    darker_limestone.vertex_color_use_as_albedo = true

    var mortar := Art.material(Color("#6a5c4b"))
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
                var y: float = -0.36 - row * 0.58 + (0.018 if (row + index) % 3 == 0 else -0.010)
                var face_offset := 0.028 if (row + index) % 4 == 0 else (-0.018 if (row + index) % 5 == 0 else 0.0)
                var transform := Transform3D(
                    Basis.IDENTITY.scaled(Vector3(0.25, 0.48, b - a - 0.055)),
                    Vector3(-2.70 + face_offset, y, (a + b) * 0.5)
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
    # Screenshot-driven pass: remove the old grey cone-roof gate/towers from
    # the opening scene. A warm limestone arcade with battlements matches the
    # painted courtyard much more closely and keeps the silhouette medieval.
    var root := Node3D.new()
    root.name = "Sample_CastleArchitecture"
    game.add_child(root)

    var stone := Art.material(Color("#c8ae82"))
    stone.roughness = 0.90
    var light_stone := Art.material(Color("#e3cfaa"))
    light_stone.roughness = 0.88
    var shadow_stone := Art.material(Color("#8d785e"))
    shadow_stone.roughness = 0.96
    var deep := Art.material(Color("#2d2a27"))
    deep.roughness = 1.0
    var red := Art.material(Color("#8e2940"))
    red.roughness = 0.88
    var gold := Art.material(Color("#b9873e"), 0.42)
    gold.roughness = 0.48

    # Recessed wall mass: visible architecture, not a second gameplay floor.
    var wall := Art.box(root, Vector3(0.48, 4.2, 19.0), Vector3(6.8, 2.05, -1.0), stone)
    wall.name = "CourtyardWall"
    var wall_shadow := Art.box(root, Vector3(0.12, 3.35, 18.2), Vector3(6.52, 1.72, -1.0), shadow_stone)
    wall_shadow.name = "WallRecess"

    # Central open arch built from real blocks in the Y/Z plane.
    var arch := Node3D.new()
    arch.name = "Sample_CastleGate"
    root.add_child(arch)
    var gate_center_z := -0.4
    var gate_half := 2.0
    var gate_top := 4.55
    Art.box(arch, Vector3(0.70, 3.7, 1.12), Vector3(6.28, 1.85, gate_center_z-gate_half-0.52), light_stone)
    Art.box(arch, Vector3(0.70, 3.7, 1.12), Vector3(6.28, 1.85, gate_center_z+gate_half+0.52), light_stone)
    var opening := Art.box(arch, Vector3(0.10, 3.55, 3.95), Vector3(6.44, 1.72, gate_center_z), deep)
    opening.name = "GateRecess"
    for i in range(11):
        var angle := PI * float(i) / 10.0
        var z := gate_center_z + cos(angle) * 2.35
        var y := 3.28 + sin(angle) * 1.52
        var voussoir := Art.box(arch, Vector3(0.76, 0.55, 0.62), Vector3(6.20, y, z), light_stone if i % 2 else stone)
        voussoir.rotation.x = angle - PI * 0.5
    var keystone := Art.box(arch, Vector3(0.82, 0.72, 0.52), Vector3(6.14, gate_top, gate_center_z), gold)
    keystone.rotation.x = 0.0

    # Square battlement towers replace the toy-like silver cone roofs.
    for item in [[-7.0, "Left"], [6.2, "Right"]]:
        var z: float = item[0]
        var tower := Node3D.new()
        tower.name = "Sample_CastleTower_" + str(item[1])
        root.add_child(tower)
        Art.box(tower, Vector3(0.82, 5.25, 3.0), Vector3(6.45, 2.62, z), stone)
        Art.box(tower, Vector3(0.92, 0.34, 3.30), Vector3(6.40, 5.12, z), light_stone)
        Art.box(tower, Vector3(0.94, 0.24, 3.55), Vector3(6.39, 0.22, z), shadow_stone)
        for level in [1.35, 2.55, 3.75]:
            Art.box(tower, Vector3(0.12, 0.52, 0.20), Vector3(6.00, level, z), deep)
        for offset in [-1.18, -0.40, 0.40, 1.18]:
            Art.box(tower, Vector3(0.92, 0.82, 0.52), Vector3(6.40, 5.58, z+offset), light_stone)

    # Wall crenellations and inset joints break the large flat silhouette.
    for z in [-9.0, -5.0, 3.8, 8.0]:
        Art.box(root, Vector3(0.72, 0.62, 0.95), Vector3(6.40, 4.56, z), light_stone)
    for z in [-9.8, -8.2, -5.8, -4.2, 3.0, 4.6, 7.2, 8.8]:
        Art.box(root, Vector3(0.10, 2.8, 0.06), Vector3(6.48, 2.05, z), shadow_stone)

    # Long vertical banners with metal finials, visually closer to the target.
    for z in [-10.7, 10.0]:
        var pole := Art.cylinder(root, 0.045, 4.2, Vector3(5.65, 2.1, z), gold)
        pole.name = "BannerPole"
        Art.box(root, Vector3(0.18, 2.25, 0.92), Vector3(5.58, 2.75, z+0.50), red)
        Art.box(root, Vector3(0.20, 0.08, 0.96), Vector3(5.55, 3.86, z+0.50), gold)
        Art.cylinder(root, 0.09, 0.24, Vector3(5.65, 4.26, z), gold)

    WorldScenery.set_render_layer(root, 4)
    _set_shadows(root, true)

static func _build_props(game: Node3D) -> void:
    for item in [["stage1_barrel", -7.3, 0.96], ["stage1_crate", -5.6, 1.05]]:
        var model := WorldScenery.place(game, item[0], Vector3(3.45, 0.0, item[1]), Vector3.ONE * float(item[2]), PI * 0.5)
        if model:
            model.name = "Sample_%s_%s" % [str(item[0]), str(item[1])]
            WorldScenery.set_render_layer(model, 4)
            _set_shadows(model, true)

static func _build_garden(root: Node3D, game: Node3D) -> void:
    var bark := Art.material(Color("#5a412c"))
    bark.roughness = 1.0
    var cypress_dark := Art.material(Color("#23452f"))
    cypress_dark.roughness = 0.98
    var cypress_mid := Art.material(Color("#35613b"))
    cypress_mid.roughness = 0.98
    for z in [-12.3, -2.9, 6.1]:
        _cypress(root, Vector3(5.55, 0.0, z), bark, cypress_dark, cypress_mid, "SampleCypress_%s" % str(z))

    var leaf := Art.material(Color("#36583a"))
    leaf.roughness = 0.95
    var leaf_light := Art.material(Color("#557744"))
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

static func _cypress(root: Node3D, at: Vector3, bark: Material, dark: Material, mid: Material, node_name: String) -> void:
    var tree := Node3D.new()
    tree.name = node_name
    tree.position = at
    root.add_child(tree)
    Art.cylinder(tree, 0.11, 2.25, Vector3(0.0, 1.12, 0.0), bark)
    for item in [
        [0.58, 0.42, 0.78, -0.04],
        [1.20, 0.50, 0.95, 0.08],
        [1.92, 0.43, 0.92, -0.06],
        [2.62, 0.34, 0.74, 0.05],
        [3.17, 0.24, 0.54, -0.02]
    ]:
        var crown := SphereMesh.new()
        crown.radius = float(item[1])
        crown.height = float(item[2]) * 2.0
        crown.radial_segments = 12
        crown.rings = 8
        var node := Art.piece(tree, crown, Vector3(float(item[3]), float(item[0]), 0.0), dark if int(float(item[0])*10.0) % 2 == 0 else mid)
        node.scale = Vector3(0.72, 1.0, 0.88)
    # A few offset branch masses stop the tree reading like stacked green balls.
    for item in [[0.20,1.48,-0.06],[-0.18,2.22,0.08],[0.12,2.82,0.02]]:
        var branch := SphereMesh.new()
        branch.radius = 0.20
        branch.height = 0.52
        branch.radial_segments = 10
        branch.rings = 6
        var piece := Art.piece(tree, branch, Vector3(float(item[0]),float(item[1]),float(item[2])), mid)
        piece.scale = Vector3(0.72,1.0,0.78)
    WorldScenery.set_render_layer(tree, 4)
    _set_shadows(tree, true)

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
