extends RefCounted

# Authored Blender meshes, instanced and batched per streamed segment.
# Spans describe actual solid ground only: [z0, z1, y0, y1]. Gaps stay empty.
const Kit = preload("res://scripts/generation/courtyard_asset_kit.gd")
const Pilot = preload("res://scripts/generation/courtyard_material_pilot.gd")

static func height_in(spans: Array[Vector4], z: float) -> float:
    for span: Vector4 in spans:
        if z >= span.x - 0.001 and z <= span.y + 0.001:
            return lerpf(span.z, span.w, clampf((z - span.x) / (span.y - span.x), 0, 1))
    return 0.0

static func dress_segment(parent: Node3D, segment: Dictionary, spans: Array[Vector4], width: float = 5.2) -> void:
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
    var stone := Kit.mesh_for("stone")
    var paving := Kit.mesh_for("paving")
    var stone_material := Pilot.MATERIAL if Pilot.applies(parent.position.z) else stone.surface_get_material(0)
    _batch(root, "ReliefMasonry", masonry, stone_material, rng, stone)
    _batch(root, "CarvedCornice", caps, stone_material, rng, stone)
    root.set_meta("ai_material_pilot", Pilot.applies(parent.position.z))
    _batch(root, "WalkwayPaving", tiles, paving.surface_get_material(0), rng, paving)
    root.set_meta("asset_author", "Quaternius")
    root.set_meta("ground_spans", spans)
    root.set_meta("stone_instances", masonry.size() + caps.size() + tiles.size())

static func _batch(parent: Node3D, node_name: String, transforms: Array[Transform3D], material: Material, rng: RandomNumberGenerator, source_mesh: Mesh) -> void:
    if transforms.is_empty():
        return
    var mesh := MultiMesh.new()
    mesh.transform_format = MultiMesh.TRANSFORM_3D
    mesh.use_colors = true
    mesh.mesh = source_mesh
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
