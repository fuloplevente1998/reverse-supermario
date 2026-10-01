extends RefCounted

# Authored Blender meshes, instanced and batched per streamed segment.
# Spans describe actual solid ground only: [z0, z1, y0, y1]. Gaps stay empty.
const First100 = preload("res://scripts/generation/courtyard_first100.gd")
const WorldScenery = preload("res://scripts/world_scenery.gd")
static var stone_mesh: Mesh
static var limestone: StandardMaterial3D
static var paving: StandardMaterial3D

static func _prepare() -> void:
    if stone_mesh != null:
        return
    var scene := load("res://assets/models/courtyard_course_stone.glb") as PackedScene
    var model := scene.instantiate()
    stone_mesh = (model.find_child("*", true, false) as MeshInstance3D).mesh if model is not MeshInstance3D else model.mesh
    model.free()
    limestone = StandardMaterial3D.new()
    limestone.albedo_color = Color("#dfccaa")
    limestone.albedo_texture = load("res://assets/terrain/sample_limestone.svg")
    limestone.uv1_triplanar = true
    limestone.uv1_scale = Vector3.ONE * 0.5
    limestone.roughness = 0.95
    limestone.vertex_color_use_as_albedo = true
    paving = limestone.duplicate()
    paving.albedo_color = Color("#e9d6b0")

static func height_in(spans: Array[Vector4], z: float) -> float:
    for span: Vector4 in spans:
        if z >= span.x - 0.001 and z <= span.y + 0.001:
            return lerpf(span.z, span.w, clampf((z - span.x) / (span.y - span.x), 0, 1))
    return 0.0

static func dress_segment(parent: Node3D, segment: Dictionary, spans: Array[Vector4], width: float = 5.2) -> void:
    _prepare()
    var root := Node3D.new()
    root.name = "CourtyardCourseArt"
    parent.add_child(root)
    root.set_meta("authored_kit", true)
    var rng := RandomNumberGenerator.new()
    rng.seed = int(segment["variant_seed"])
    var masonry: Array[Transform3D] = []
    var caps: Array[Transform3D] = []
    var tiles: Array[Transform3D] = []
    var half := width * 0.5
    var first100 := parent.position.z < First100.END
    for original_span: Vector4 in spans:
        var span := original_span
        var angle := -atan2(span.w - span.z, span.y - span.x)
        var slope_basis := Basis(Vector3.RIGHT, angle)
        # Relief follows the same slope as the collision, with staggered joints.
        for row in range(6):
            var cursor := span.x
            while cursor < span.y - 0.01:
                var block_length := minf(rng.randf_range(1.05, 1.65), span.y - cursor)
                var z := cursor + block_length * 0.5
                var y := lerpf(span.z, span.w, (z - span.x) / (span.y - span.x))
                if block_length > 0.06:
                    masonry.append(Transform3D(slope_basis.scaled(Vector3(0.28, 0.48, block_length - 0.035)), Vector3(-half - 0.09, y - 0.37 - row * 0.53, z)))
                cursor += block_length
        var tile_cursor := span.x
        while tile_cursor < span.y - 0.01:
            var tile_length := minf(1.2, span.y - tile_cursor)
            var z := tile_cursor + tile_length * 0.5
            var y := lerpf(span.z, span.w, (z - span.x) / (span.y - span.x))
            caps.append(Transform3D(slope_basis.scaled(Vector3(0.40, 0.20, maxf(0.02, tile_length - 0.025))), Vector3(-half - 0.13, y - 0.10, z)))
            for row in range(4):
                tiles.append(Transform3D(slope_basis.scaled(Vector3(width / 4.0 - 0.04, 0.12, maxf(0.02, tile_length - 0.035))), Vector3(-half + width / 8.0 + row * width / 4.0, y - 0.06, z)))
            tile_cursor += tile_length
    if first100:
        var vendor_stone := First100.mesh_for("stone")
        var vendor_paving := First100.mesh_for("paving")
        _batch(root, "ReliefMasonry", masonry, vendor_stone.surface_get_material(0), rng, vendor_stone)
        _batch(root, "CarvedCornice", caps, vendor_stone.surface_get_material(0), rng, vendor_stone)
        _batch(root, "WalkwayPaving", tiles, vendor_paving.surface_get_material(0), rng, vendor_paving)
    else:
        _batch(root, "ReliefMasonry", masonry, limestone, rng)
        _batch(root, "CarvedCornice", caps, paving, rng)
        _batch(root, "WalkwayPaving", tiles, paving, rng)
    root.set_meta("ground_spans", spans)
    root.set_meta("stone_instances", masonry.size() + caps.size() + tiles.size())

    var length := float(segment["length"])
    if first100:
        return
    var opening := str(segment["id"]) == "start"
    var cursor := 30.0 if opening else 6.0
    while cursor + 6.0 <= length:
        var y := height_in(spans, cursor)
        # Architecture and greenery are always behind the gameplay corridor.
        var wall_height := 0.58 if str(segment["id"]) in ["vista", "fountain_court", "checkpoint"] else 0.78
        var wall := WorldScenery.place(root, "courtyard_course_wall", Vector3(8.2, y - 0.25, cursor), Vector3(1, wall_height, 1), -PI * 0.5)
        wall.name = "CourtyardWall_%d" % int(cursor)
        cursor += 12.0
    cursor = 28.0 if opening else 3.0
    var greenery_count := 0
    while cursor < length - 1.0:
        var y := height_in(spans, cursor)
        var scale_value := rng.randf_range(0.78, 1.04)
        WorldScenery.place(root, "courtyard_course_cypress", Vector3(rng.randf_range(4.1, 5.3), y, cursor), Vector3.ONE * scale_value)
        # Never lay foreground plants or paving across a real pit.
        if _is_solid(spans, cursor):
            WorldScenery.place(root, "courtyard_course_ivy", Vector3(-half - 0.31, y - 0.08, cursor), Vector3.ONE * rng.randf_range(0.7, 1.0), PI * 0.5)
        var prop := "stage1_barrel" if greenery_count % 2 else "stage1_crate"
        WorldScenery.place(root, prop, Vector3(3.5, y, cursor + 1.4), Vector3.ONE * 0.8, rng.randf_range(-0.4, 0.4))
        greenery_count += 1
        cursor += rng.randf_range(7.5, 10.0)
    root.set_meta("greenery_count", greenery_count)

    var center := length * 0.52
    var ground := height_in(spans, center)
    match str(segment["id"]):
        "fountain_court", "vista":
            WorldScenery.place(root, "courtyard_course_fountain", Vector3(4.7, ground, center), Vector3.ONE * 1.2)
        "tower", "gate_approach", "mini_boss", "finish":
            WorldScenery.place(root, "courtyard_course_tower", Vector3(6.3, ground, center), Vector3.ONE * 1.12, -PI * 0.5)
            WorldScenery.place(root, "stage1_banner", Vector3(3.7, ground, center - 4.0), Vector3.ONE, -PI * 0.5)

static func _is_solid(spans: Array[Vector4], z: float) -> bool:
    for span: Vector4 in spans:
        if z >= span.x and z <= span.y:
            return true
    return false

static func obstacle_visual(parent: Node3D, dimensions: Vector3) -> void:
    _prepare()
    var model := MeshInstance3D.new()
    model.name = "CarvedLimestoneHurdle"
    model.mesh = stone_mesh
    model.material_override = limestone
    model.scale = dimensions
    parent.add_child(model)

static func _batch(parent: Node3D, node_name: String, transforms: Array[Transform3D], material: Material, rng: RandomNumberGenerator, source_mesh: Mesh = null) -> void:
    if transforms.is_empty():
        return
    var mesh := MultiMesh.new()
    mesh.transform_format = MultiMesh.TRANSFORM_3D
    mesh.use_colors = true
    mesh.mesh = source_mesh if source_mesh != null else stone_mesh
    mesh.instance_count = transforms.size()
    for i in range(transforms.size()):
        mesh.set_instance_transform(i, transforms[i])
        var tone := rng.randf_range(0.88, 1.04)
        mesh.set_instance_color(i, Color(tone, tone, tone, 1))
    var visual := MultiMeshInstance3D.new()
    visual.name = node_name
    visual.multimesh = mesh
    visual.material_override = material
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(visual)
