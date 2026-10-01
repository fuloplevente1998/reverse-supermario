extends RefCounted

const Art = preload("res://scripts/art.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Hazard = preload("res://scripts/stage_hazard.gd")
const Kit = preload("res://scripts/generation/courtyard_asset_kit.gd")
const WorldScenery = preload("res://scripts/world_scenery.gd")
const PlanGenerator = preload("res://scripts/generation/stage_plan_generator.gd")
const EncounterDirector = preload("res://scripts/generation/encounter_director.gd")
const SegmentStreamer = preload("res://scripts/generation/segment_streamer.gd")
const DifficultyProfiles = preload("res://scripts/generation/difficulty_profiles.gd")

const CourseArt = preload("res://scripts/generation/courtyard_course_art.gd")

const START_Z := -15.0
const HALF_WIDTH := 2.6
const COURSE_WIDTH := HALF_WIDTH * 2.0

static var _plans: Dictionary = {}

static func plan_for(difficulty_index: int) -> Dictionary:
    if not _plans.has(difficulty_index):
        var plan := PlanGenerator.generate(1, difficulty_index)
        for segment: Dictionary in plan["segments"]:
            segment["terrain_points"] = terrain_points(segment, difficulty_index)
        _plans[difficulty_index] = plan
    return _plans[difficulty_index]

static func end_z(difficulty_index: int) -> float:
    return START_Z + float(plan_for(difficulty_index)["total_length"])

static func terrain_points(segment: Dictionary, difficulty_index: int) -> Array[Vector2]:
    var length := float(segment["length"])
    var id := str(segment["id"])
    if length < 10.0 or id in ["start", "checkpoint", "gap", "bridge", "hazard", "archer_ambush"]:
        return [Vector2.ZERO, Vector2(length, 0)]
    var rise: float = [1.6, 2.0, 2.4][difficulty_index]
    if bool(segment.get("safe_recovery", false)) or bool(segment.get("boss_approach", false)):
        rise = 0.8
    elif id == "fountain_court":
        rise = -0.65
    elif id == "vista":
        rise = -1.0 if int(segment["variant_seed"]) % 2 else 1.2
    elif id == "finish":
        rise = 0.9
    elif id == "mini_boss":
        rise = 1.1
    rise = clampf(rise, -length * 0.065, length * 0.065)
    return [Vector2.ZERO, Vector2(length * 0.16, 0), Vector2(length * 0.38, rise), Vector2(length * 0.62, rise), Vector2(length * 0.84, 0), Vector2(length, 0)]

static func height_at(difficulty_index: int, z: float) -> float:
    for segment: Dictionary in plan_for(difficulty_index)["segments"]:
        var local_z := z - START_Z - float(segment["start"])
        if local_z >= 0.0 and local_z <= float(segment["length"]):
            var points: Array[Vector2] = segment["terrain_points"]
            for i in range(points.size() - 1):
                if local_z <= points[i + 1].x:
                    return lerpf(points[i].y, points[i + 1].y, (local_z - points[i].x) / (points[i + 1].x - points[i].x))
    return 0.0

static func build(game: Node3D) -> void:
    game.player.floor_snap_length = 0.35
    game.player.floor_constant_speed = true

    var plan: Dictionary = plan_for(game.difficulty_index)
    var course_end: float = START_Z + float(plan["total_length"])

    game.set_meta("generator_rebuild", true)
    game.set_meta("stage_plan", plan)
    game.set_meta("side_course_length", float(plan["total_length"]))
    game.set_meta("side_course_end_z", course_end)
    game.set_meta("stage_seed", int(plan["seed"]))
    game.set_meta("stage_biome", str(plan["biome"]))
    game.set_meta("first100_obstacles", Kit.opening_obstacle_specs(game.difficulty_index, plan))
    game.set_meta("courtyard_obstacles", Kit.obstacle_specs(game.difficulty_index, plan))
    game.set_meta("first100_range", Vector2(Kit.START, Kit.SAMPLE_END))
    game.set_meta("side_reference_layers", 3)

    var mortar := Art.material(Color("#807057"))

    var trim := Art.material(Color("#d7b36c"))
    trim.roughness = 0.82
    var hazard_mat := Art.material(Color("#8f3e36"))
    hazard_mat.roughness = 0.88

    var stage_root := Node3D.new()
    stage_root.name = "GeneratedLongStage"
    stage_root.set_meta("total_length", float(plan["total_length"]))
    stage_root.set_meta("seed", int(plan["seed"]))
    game.add_child(stage_root)

    var gaps: Array[Vector2] = []
    var checkpoint_positions: Array[float] = []
    var hurdles: Array[float] = []

    # Stable opening lesson/reference encounter retained across all generated
    # layouts so the first seconds remain immediately readable.
    _enemy(game, "guard", 8.0, false)

    for segment: Dictionary in plan["segments"]:
        _build_segment_geometry(stage_root, game, segment, mortar, trim, hazard_mat, gaps, hurdles)
        _build_segment_gameplay(game, segment, checkpoint_positions)

    game.set_meta("side_course_gaps", gaps)
    game.set_meta("generated_checkpoints", checkpoint_positions)
    game.set_meta("course_hurdles", hurdles)

    game.get_node("Goal").position = Vector3(0, height_at(game.difficulty_index, course_end - 4.0) + 1.5, course_end - 4.0)

    _background(game, course_end)
    _finish_flag(game, course_end)


    var streamer := SegmentStreamer.new()
    streamer.name = "LongStageStreamer"
    game.add_child(streamer)
    streamer.configure(stage_root, game.player, 100.0, 240.0)

static func _build_segment_geometry(stage_root: Node3D, game: Node3D, segment: Dictionary, mortar: Material, trim: Material, hazard_mat: Material, gaps: Array[Vector2], hurdles: Array[float]) -> void:
    var segment_root := Node3D.new()
    segment_root.name = "Segment_%03d_%s" % [int(segment["index"]), str(segment["id"])]
    segment_root.position.z = START_Z + float(segment["start"])
    for key in ["id", "kind", "length", "variant_seed", "safe_recovery", "boss_approach"]:
        if segment.has(key):
            segment_root.set_meta("segment_id" if key == "id" else key, segment[key])
    segment_root.set_meta("recovery_clear_length", Kit.recovery_length(segment))
    stage_root.add_child(segment_root)
    var id := str(segment["id"])
    var length := float(segment["length"])
    var spans: Array[Vector4] = []
    if id == "gap":
        var profile := DifficultyProfiles.get_profile(game.difficulty_index)
        var gap := minf(float(profile["gap_width"]), maxf(2.6, length * 0.30))
        var ledge := (length - gap) * 0.5
        spans = [Vector4(0, ledge, 0, 0), Vector4(ledge + gap, length, 0, 0)]
        gaps.append(Vector2(segment_root.position.z + ledge, segment_root.position.z + ledge + gap))
    elif id == "bridge":
        var profile := DifficultyProfiles.get_profile(game.difficulty_index)
        var gap := float(profile["bridge_gap_width"])
        var landing := float(profile["bridge_landing_length"])
        var ledge := (length - landing - gap * 2.0) * 0.5
        spans = [Vector4(0, ledge, 0, 0), Vector4(ledge + gap, ledge + gap + landing, 0, 0), Vector4(ledge + gap * 2 + landing, length, 0, 0)]
        for offset in [ledge, ledge + gap + landing]:
            gaps.append(Vector2(segment_root.position.z + offset, segment_root.position.z + offset + gap))
        segment_root.set_meta("bridge_gap_width", gap)
        segment_root.set_meta("bridge_landing_length", landing)
    else:
        var points: Array[Vector2] = segment["terrain_points"]
        for i in range(points.size() - 1):
            spans.append(Vector4(points[i].x, points[i + 1].x, points[i].y, points[i + 1].y))
    var first_gap := Kit.gap_for(game.difficulty_index)
    var local_gap := first_gap - Vector2.ONE * segment_root.position.z
    if first_gap != Vector2.ZERO and local_gap.x < length and local_gap.y > 0:
        spans = _cut_spans(spans, local_gap)
        gaps.append(first_gap)
    for i in range(spans.size()):
        var width := float(DifficultyProfiles.get_profile(game.difficulty_index)["bridge_width"]) if id == "bridge" else COURSE_WIDTH
        _terrain(segment_root, spans[i], ("BridgeDeck%d" % i) if id == "bridge" else ("Floor" if i == 0 else "Floor%d" % i), mortar, width)
    var art_width := float(DifficultyProfiles.get_profile(game.difficulty_index)["bridge_width"]) if id == "bridge" else COURSE_WIDTH
    CourseArt.dress_segment(segment_root, segment, spans, art_width)
    var ground_query := func(z: float) -> float: return height_at(game.difficulty_index, z)
    Kit.dress(segment_root, spans, ground_query)
    var obstacles: Array[Dictionary] = game.get_meta("courtyard_obstacles")
    Kit.build_obstacles(segment_root, obstacles, segment_root.position.z, length, ground_query, hurdles)
    if id == "bridge":
        for span: Vector4 in spans:
            var cursor := span.x
            while cursor < span.y - 0.01:
                var piece := minf(2.0, span.y - cursor)
                for side in [-1.0, 1.0]:
                    Kit.place(segment_root, "fence", Vector3(side * art_width * 0.5, -0.01, cursor + piece * 0.5), Vector3(piece, 0.55, 0.14), -PI * 0.5)
                cursor += piece
    elif id == "hazard":
        _hazard_ground_marker(segment_root, length, hazard_mat)

static func _cut_spans(spans: Array[Vector4], gap: Vector2) -> Array[Vector4]:
    var result: Array[Vector4] = []
    for span: Vector4 in spans:
        if span.y <= gap.x or span.x >= gap.y:
            result.append(span)
            continue
        if span.x < gap.x:
            var t := (gap.x - span.x) / (span.y - span.x)
            result.append(Vector4(span.x, gap.x, span.z, lerpf(span.z, span.w, t)))
        if span.y > gap.y:
            var t := (gap.y - span.x) / (span.y - span.x)
            result.append(Vector4(gap.y, span.y, lerpf(span.z, span.w, t), span.w))
    return result

static func _terrain(parent: Node3D, span: Vector4, node_name: String, material: Material, width: float) -> void:
    var half := width * 0.5
    var vertices := PackedVector3Array([
        Vector3(-half, span.z - 3.5, span.x), Vector3(half, span.z - 3.5, span.x),
        Vector3(-half, span.z, span.x), Vector3(half, span.z, span.x),
        Vector3(-half, span.w - 3.5, span.y), Vector3(half, span.w - 3.5, span.y),
        Vector3(-half, span.w, span.y), Vector3(half, span.w, span.y)
    ])
    var body := StaticBody3D.new()
    body.name = node_name
    var shape := ConvexPolygonShape3D.new()
    shape.points = vertices
    var collision := CollisionShape3D.new()
    collision.shape = shape
    body.add_child(collision)
    var mesh := SurfaceTool.new()
    mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
    mesh.set_smooth_group(-1)
    for face in [[0,4,6,2],[1,3,7,5],[2,6,7,3],[0,1,5,4],[0,2,3,1],[4,5,7,6]]:
        for k in [0,2,1,0,3,2]:
            mesh.add_vertex(vertices[face[k]])
    mesh.generate_normals()
    var visual := MeshInstance3D.new()
    visual.name = "MortarCore"
    visual.mesh = mesh.commit()
    visual.material_override = material
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    body.add_child(visual)
    parent.add_child(body)

static func _build_segment_gameplay(game: Node3D, segment: Dictionary, checkpoint_positions: Array[float]) -> void:
    var id := str(segment["id"])
    var kind := str(segment["kind"])
    var start_z := START_Z + float(segment["start"])
    var length := float(segment["length"])

    if kind == "checkpoint":
        var checkpoint_z := start_z + length * 0.5
        _checkpoint(game, checkpoint_z)
        checkpoint_positions.append(checkpoint_z)

    if id == "hazard":
        _hazard(game, "spikes", start_z + length * 0.52, float(segment["hazard_speed"]), int(segment["variant_seed"]))
    elif id == "archer_ambush" and game.difficulty_index == 2:
        # Hard is allowed one extra readable pressure source in this segment.
        _hazard(game, "spikes", start_z + length * 0.72, float(segment["hazard_speed"]), int(segment["variant_seed"]) + 17)

    var encounter: Array[Dictionary] = EncounterDirector.build_encounter(1, game.difficulty_index, segment)
    for entry: Dictionary in encounter:
        var z := start_z + float(entry["offset_z"])
        var enemy := _enemy(game, str(entry["legacy_archetype"]), z, bool(entry["elite"]))
        enemy.encounter_health_scale = float(entry["health_scale"])
        enemy.encounter_damage_scale = float(entry["damage_scale"])

static func _hazard_ground_marker(parent: Node3D, length: float, material: Material) -> void:
    Art.box(parent, Vector3(3.9, 0.08, minf(5.5, length * 0.30)), Vector3(0, 0.05, length * 0.52), material)

static func _enemy(game: Node3D, kind: String, z: float, elite: bool) -> Enemy:
    var enemy := Enemy.new()
    enemy.archetype = kind
    enemy.name = "%s_%d" % [kind.capitalize(), int(z)]
    enemy.position = Vector3(0, height_at(game.difficulty_index, z) + 1.1, z)
    if elite:
        enemy.name = "Elite_%s_%d" % [kind.capitalize(), int(z)]
        enemy.scale = Vector3.ONE * 1.08

    var shape := CapsuleShape3D.new()
    shape.height = 1.8
    shape.radius = 0.55
    var collision := CollisionShape3D.new()
    collision.shape = shape
    enemy.add_child(collision)
    game.add_child(enemy)
    return enemy

static func _hazard(game: Node3D, kind: String, z: float, speed_scale: float, phase_seed: int) -> void:
    var trap := Hazard.new()
    trap.name = "Generated%s_%d" % [kind.capitalize(), int(z)]
    trap.kind = kind
    trap.position = Vector3(0, height_at(game.difficulty_index, z) + 0.45, z)
    trap.dimensions = Vector3(4.0, 0.7, 1.5)
    trap.period = 3.6 / maxf(0.5, speed_scale)
    trap.phase = float(abs(phase_seed % 1000)) / 317.0
    trap.damage = game._hazard_damage(20)
    game.add_child(trap)

static func _checkpoint(game: Node3D, z: float) -> void:
    var area := Area3D.new()
    area.name = "Checkpoint" if game.get_tree().get_nodes_in_group("course_checkpoints").is_empty() else "Checkpoint%d" % int(z)
    area.add_to_group("course_checkpoints")
    var spawn := Vector3(0, height_at(game.difficulty_index, z) + 1.1, z)
    area.position = spawn

    var shape := BoxShape3D.new()
    shape.size = Vector3(COURSE_WIDTH, 4.5, 2.2)
    var collision := CollisionShape3D.new()
    collision.shape = shape
    area.add_child(collision)

    var mat := Art.material(Color("#69ddc0"))
    Art.box(area, Vector3(COURSE_WIDTH, 0.08, 0.30), Vector3(0, -1.06, 0), mat)
    Art.cylinder(area, 0.055, 2.6, Vector3(1.9, 0.2, 0), Art.material(Color("#d9b46c")))
    Art.box(area, Vector3(0.04, 0.55, 0.85), Vector3(1.9, 1.1, 0.4), mat)

    game.add_child(area)
    area.body_entered.connect(Callable(game, "_on_checkpoint_entered").bind(spawn))

static func _background(game: Node3D, course_end: float) -> void:
    var root := Node3D.new()
    root.name = "SideBackdrop"
    game.add_child(root)

    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_texture = load("res://assets/backgrounds/courtyard_side_panorama.jpg")
    mat.albedo_color = Color(0.86, 0.87, 0.84, 1)
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED

    var z := -48.0
    var index := 0
    while z <= course_end + 64.0:
        var mesh := QuadMesh.new()
        mesh.size = Vector2(96, 32)
        var panel := MeshInstance3D.new()
        panel.name = "BackdropPanel"
        panel.mesh = mesh
        panel.material_override = mat
        panel.position = Vector3(14, 9, z)
        panel.rotation.y = -PI * 0.5
        if index % 2 == 1:
            panel.scale.x = -1.0
        panel.layers = 4
        panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        root.add_child(panel)
        z += 96.0
        index += 1

static func _finish_flag(game: Node3D, course_end: float) -> void:
    var flag := Node3D.new()
    flag.name = "SideFinishFlag"
    flag.position = Vector3(1.5, height_at(game.difficulty_index, course_end - 5.0), course_end - 5.0)
    game.add_child(flag)
    Art.cylinder(flag, 0.09, 5, Vector3(0, 2.5, 0), Art.material(Color("#dfb85d")))
    Art.box(flag, Vector3(0.09, 1.2, 1.8), Vector3(0, 4.1, 0.9), Art.material(Color("#941e3f")))
    WorldScenery.set_render_layer(flag, 4)
