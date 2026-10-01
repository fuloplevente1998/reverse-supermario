extends RefCounted

const Art = preload("res://scripts/art.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Hazard = preload("res://scripts/stage_hazard.gd")
const SampleArt = preload("res://scripts/side_sample_art.gd")
const WorldScenery = preload("res://scripts/world_scenery.gd")
const PlanGenerator = preload("res://scripts/generation/stage_plan_generator.gd")
const EncounterDirector = preload("res://scripts/generation/encounter_director.gd")
const SegmentStreamer = preload("res://scripts/generation/segment_streamer.gd")

const START_Z := -15.0
const HALF_WIDTH := 2.6
const COURSE_WIDTH := HALF_WIDTH * 2.0

static func plan_for(difficulty_index: int) -> Dictionary:
    return PlanGenerator.generate(1, difficulty_index)

static func end_z(difficulty_index: int) -> float:
    var plan: Dictionary = plan_for(difficulty_index)
    return START_Z + float(plan["total_length"])

static func height_at(_difficulty_index: int, _z: float) -> float:
    # First migration pass deliberately keeps the generator baseline at Y=0.
    # Vertical variety is introduced inside authored segment scenes, while the
    # camera keeps a stable side-view frame.
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

    var stone := Art.material(Color("#d8c29a"))
    stone.albedo_texture = load("res://assets/models/courtyard_environment_pavestone_0.png")
    stone.uv1_triplanar = true
    stone.uv1_scale = Vector3.ONE * 0.46
    stone.roughness = 1.0

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

    for segment: Dictionary in plan["segments"]:
        _build_segment_geometry(stage_root, game, segment, stone, trim, hazard_mat, gaps)
        _build_segment_gameplay(game, segment, checkpoint_positions)

    game.set_meta("side_course_gaps", gaps)
    game.set_meta("generated_checkpoints", checkpoint_positions)

    game.get_node("Goal").position = Vector3(0, 1.5, course_end - 4.0)

    _background(game, course_end)
    _finish_flag(game, course_end)

    # Keep the proven opening reference art while the long route's authored
    # PackedScene kit is produced segment by segment.
    SampleArt.build(game)

    var streamer := SegmentStreamer.new()
    streamer.name = "LongStageStreamer"
    game.add_child(streamer)
    streamer.configure(stage_root, game.player, 100.0, 240.0)

static func _build_segment_geometry(stage_root: Node3D, game: Node3D, segment: Dictionary, stone: Material, trim: Material, hazard_mat: Material, gaps: Array[Vector2]) -> void:
    var segment_root := Node3D.new()
    segment_root.name = "Segment_%03d_%s" % [int(segment["index"]), str(segment["id"])]
    segment_root.position.z = START_Z + float(segment["start"])
    segment_root.set_meta("segment_id", str(segment["id"]))
    segment_root.set_meta("kind", str(segment["kind"]))
    segment_root.set_meta("length", float(segment["length"]))
    segment_root.set_meta("variant_seed", int(segment["variant_seed"]))
    stage_root.add_child(segment_root)

    var id := str(segment["id"])
    var length := float(segment["length"])

    match id:
        "gap":
            _real_gap(segment_root, game.difficulty_index, length, stone, gaps)
        "stairs":
            _stairs(segment_root, length, stone)
        "bridge":
            _bridge(segment_root, game.difficulty_index, length, stone, trim)
        "fountain_court":
            _floor(segment_root, length, stone)
            _fountain_marker(segment_root, length, trim)
        "tower":
            _floor(segment_root, length, stone)
            _tower_marker(segment_root, length, trim)
        "gate_approach":
            _floor(segment_root, length, stone)
            _gate_marker(segment_root, length, trim)
        "hazard":
            _floor(segment_root, length, stone)
            _hazard_ground_marker(segment_root, length, hazard_mat)
        _:
            _floor(segment_root, length, stone)

    # Visual rhythm marker only. These are outside the gameplay corridor and
    # are placeholders for the authored castle kit, not final art.
    if str(segment["kind"]) == "vista" and id != "fountain_court":
        _vista_marker(segment_root, length, trim)

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
        _enemy(game, str(entry["legacy_archetype"]), z, bool(entry["elite"]))

static func _floor(parent: Node3D, length: float, material: Material) -> void:
    _solid(parent, "Floor", Vector3(COURSE_WIDTH, 0.8, length), Vector3(0, -0.4, length * 0.5), material)

static func _real_gap(parent: Node3D, difficulty_index: int, length: float, material: Material, gaps: Array[Vector2]) -> void:
    var desired_gap: float = [3.0, 4.4, 5.6][difficulty_index]
    var gap_width: float = minf(desired_gap, maxf(2.6, length * 0.30))
    var ledge_length: float = (length - gap_width) * 0.5

    _solid(parent, "GapLedgeA", Vector3(COURSE_WIDTH, 0.8, ledge_length), Vector3(0, -0.4, ledge_length * 0.5), material)
    _solid(parent, "GapLedgeB", Vector3(COURSE_WIDTH, 0.8, ledge_length), Vector3(0, -0.4, length - ledge_length * 0.5), material)

    var global_start := parent.position.z + ledge_length
    gaps.append(Vector2(global_start, global_start + gap_width))
    parent.set_meta("gap_start", global_start)
    parent.set_meta("gap_end", global_start + gap_width)

static func _bridge(parent: Node3D, difficulty_index: int, length: float, stone: Material, trim: Material) -> void:
    # Side view remains traversable while 3D mode gets a narrower bridge on
    # higher difficulties.
    var widths := [4.8, 3.9, 3.2]
    _solid(parent, "BridgeDeck", Vector3(widths[difficulty_index], 0.42, length), Vector3(0, -0.21, length * 0.5), trim)
    for side in [-1.0, 1.0]:
        var x := side * widths[difficulty_index] * 0.5
        Art.box(parent, Vector3(0.10, 0.55, length), Vector3(x, 0.28, length * 0.5), stone)

static func _stairs(parent: Node3D, length: float, material: Material) -> void:
    var count := 8
    var step_length := length / float(count)
    for i in range(count):
        var ridge_index := mini(i, count - 1 - i)
        var rise := float(ridge_index) * 0.34
        var height := 0.8 + rise
        _solid(parent, "Step%d" % i, Vector3(COURSE_WIDTH, height, step_length * 0.96), Vector3(0, -0.4 + rise * 0.5, step_length * (i + 0.5)), material)

static func _fountain_marker(parent: Node3D, length: float, material: Material) -> void:
    var marker := Node3D.new()
    marker.name = "FountainCourtMarker"
    marker.position = Vector3(HALF_WIDTH + 3.1, 0.0, length * 0.52)
    parent.add_child(marker)
    Art.cylinder(marker, 1.3, 0.32, Vector3(0, 0.16, 0), material)
    Art.cylinder(marker, 0.22, 2.0, Vector3(0, 1.1, 0), material)
    Art.cylinder(marker, 0.68, 0.20, Vector3(0, 2.0, 0), material)

static func _tower_marker(parent: Node3D, length: float, material: Material) -> void:
    var marker := Node3D.new()
    marker.name = "TowerMarker"
    marker.position = Vector3(HALF_WIDTH + 4.8, 0.0, length * 0.55)
    parent.add_child(marker)
    Art.box(marker, Vector3(4.0, 6.2, 4.3), Vector3(0, 3.1, 0), material)

static func _gate_marker(parent: Node3D, length: float, material: Material) -> void:
    var z := length * 0.70
    for x in [-HALF_WIDTH - 1.2, HALF_WIDTH + 1.2]:
        Art.box(parent, Vector3(1.0, 5.0, 1.0), Vector3(x, 2.5, z), material)
    Art.box(parent, Vector3(COURSE_WIDTH + 3.4, 0.75, 1.0), Vector3(0, 4.8, z), material)

static func _hazard_ground_marker(parent: Node3D, length: float, material: Material) -> void:
    Art.box(parent, Vector3(3.9, 0.08, minf(5.5, length * 0.30)), Vector3(0, 0.05, length * 0.52), material)

static func _vista_marker(parent: Node3D, length: float, material: Material) -> void:
    Art.box(parent, Vector3(2.0, 2.0, 2.0), Vector3(HALF_WIDTH + 4.0, 1.0, length * 0.5), material)

static func _solid(parent: Node3D, node_name: String, dimensions: Vector3, at: Vector3, material: Material) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = at

    var shape := BoxShape3D.new()
    shape.size = dimensions
    var collision := CollisionShape3D.new()
    collision.shape = shape
    body.add_child(collision)

    Art.box(body, dimensions, Vector3.ZERO, material)
    parent.add_child(body)
    return body

static func _enemy(game: Node3D, kind: String, z: float, elite: bool) -> void:
    var enemy := Enemy.new()
    enemy.archetype = kind
    enemy.name = "%s_%d" % [kind.capitalize(), int(z)]
    enemy.position = Vector3(0, 1.1, z)
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

static func _hazard(game: Node3D, kind: String, z: float, speed_scale: float, phase_seed: int) -> void:
    var trap := Hazard.new()
    trap.name = "Generated%s_%d" % [kind.capitalize(), int(z)]
    trap.kind = kind
    trap.position = Vector3(0, 0.45, z)
    trap.dimensions = Vector3(4.0, 0.7, 1.5)
    trap.period = 3.6 / maxf(0.5, speed_scale)
    trap.phase = float(abs(phase_seed % 1000)) / 317.0
    trap.damage = game._hazard_damage(20)
    game.add_child(trap)

static func _checkpoint(game: Node3D, z: float) -> void:
    var area := Area3D.new()
    area.name = "Checkpoint" if game.get_tree().get_nodes_in_group("course_checkpoints").is_empty() else "Checkpoint%d" % int(z)
    area.add_to_group("course_checkpoints")
    var spawn := Vector3(0, 1.1, z)
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
    flag.position = Vector3(1.5, 0, course_end - 5.0)
    game.add_child(flag)
    Art.cylinder(flag, 0.09, 5, Vector3(0, 2.5, 0), Art.material(Color("#dfb85d")))
    Art.box(flag, Vector3(0.09, 1.2, 1.8), Vector3(0, 4.1, 0.9), Art.material(Color("#941e3f")))
    WorldScenery.set_render_layer(flag, 4)
