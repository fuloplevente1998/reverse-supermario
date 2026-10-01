extends RefCounted

# Shared CC0 courtyard art and physical obstacle kit for the complete Stage 1.
# The established opening lesson remains stable across all three layouts.
const Scenery = preload("res://scripts/world_scenery.gd")
const Director = preload("res://scripts/generation/encounter_director.gd")
const Pilot = preload("res://scripts/generation/courtyard_material_pilot.gd")
const START := -15.0
const SAMPLE_END := 85.0
const DIRECTORY := "res://assets/vendor/quaternius/"
static var meshes: Dictionary = {}
static var scenes: Dictionary = {}

static func mesh_for(id: String) -> Mesh:
    if not meshes.has(id):
        var model := scene_for(id).instantiate()
        var visual := model.find_child("*", true, false) as MeshInstance3D
        meshes[id] = visual.mesh
        model.free()
    return meshes[id]

static func scene_for(id: String) -> PackedScene:
    if not scenes.has(id):
        scenes[id] = load(DIRECTORY + id + ".gltf") as PackedScene
    return scenes[id]

static func place(parent: Node3D, id: String, at: Vector3, dimensions: Vector3, yaw: float = 0.0) -> Node3D:
    var model := scene_for(id).instantiate() as Node3D
    model.name = "Quaternius_%s" % id
    model.position = at
    model.rotation.y = yaw
    model.scale = dimensions
    parent.add_child(model)
    if Pilot.enabled and id in ["stone", "stone_alt"]:
        for visual: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
            visual.mesh = Pilot.mesh_variant(visual.mesh)
    return model

static func gap_for(difficulty: int) -> Vector2:
    # Hard's archer ambush is followed by a mandatory recovery. No extra pit.
    return Vector2(77.0, 77.0 + [1.8, 2.2, 0.0][difficulty]) if difficulty < 2 else Vector2.ZERO

static func opening_obstacle_specs(difficulty: int, plan: Dictionary) -> Array[Dictionary]:
    var occupied: Array[float] = [8.0]
    for segment: Dictionary in plan["segments"]:
        var start := START + float(segment["start"])
        if start >= SAMPLE_END: break
        for entry: Dictionary in Director.build_encounter(1, difficulty, segment):
            occupied.append(start + float(entry["offset_z"]))
        if str(segment["id"]) == "archer_ambush" and difficulty == 2:
            occupied.append(start + float(segment["length"]) * 0.72)
    var result: Array[Dictionary] = []
    var kinds := ["crate", "barrels", "bench", "crate_steps", "stone", "barrels"]
    var candidates := [0.0, 17.0 if difficulty == 2 else 18.0, 27.0, 40.0, 53.0, 65.0]
    for i in range(candidates.size()):
        for delta in [0.0, -1.0, 1.0, -2.0, 2.0, -4.0, 4.0]:
            var z: float = candidates[i] + delta
            var allowed := true
            for enemy_z: float in occupied:
                if absf(z - enemy_z) < 4.0: allowed = false
            if not result.is_empty() and z - float(result.back()["z"]) < 9.0: allowed = false
            for segment: Dictionary in plan["segments"]:
                var begin := START + float(segment["start"])
                var end := START + float(segment["end"])
                if z + 2.4 > begin and z - 2.4 < end:
                    if bool(segment.get("safe_recovery", false)) or bool(segment.get("boss_approach", false)) or str(segment["kind"]) == "checkpoint":
                        allowed = false
            if allowed:
                result.append({"z": z, "kind": kinds[i], "height": [0.85, 1.0, 1.15][difficulty]})
                break
    return result

static func recovery_length(segment: Dictionary) -> float:
    if bool(segment.get("boss_approach", false)) or str(segment["id"]) in ["checkpoint", "finish"]:
        return float(segment["length"])
    if str(segment["id"]) == "mini_boss": return 8.0
    if bool(segment.get("safe_recovery", false)):
        # Preserve the first-100m archer lesson; later recovery is a clear 18m
        # prefix, followed by at most one low obstacle in the remaining tail.
        return float(segment["length"]) if START + float(segment["start"]) < SAMPLE_END else 18.0
    return 0.0

static func obstacle_specs(difficulty: int, plan: Dictionary) -> Array[Dictionary]:
    var result := opening_obstacle_specs(difficulty, plan)
    var occupied: Array[float] = [8.0]
    for segment: Dictionary in plan["segments"]:
        var begin := START + float(segment["start"])
        for entry: Dictionary in Director.build_encounter(1, difficulty, segment):
            occupied.append(begin + float(entry["offset_z"]))
        if str(segment["id"]) == "hazard" or (str(segment["id"]) == "archer_ambush" and difficulty == 2):
            occupied.append(begin + float(segment["length"]) * (0.72 if str(segment["id"]) == "archer_ambush" else 0.52))
    var kinds := ["crate", "barrels", "bench", "crate_steps", "stone"]
    for segment: Dictionary in plan["segments"]:
        var begin := START + float(segment["start"])
        var end := START + float(segment["end"])
        var id := str(segment["id"])
        if end <= SAMPLE_END or id in ["gap", "bridge", "hazard", "archer_ambush", "checkpoint", "finish"] or bool(segment.get("boss_approach", false)):
            continue
        var recovery := recovery_length(segment)
        var min_z := maxf(SAMPLE_END + 7.0, begin + recovery + (4.0 if recovery > 0 else 7.0))
        var cursor := begin + 17.0 if id == "mini_boss" else min_z
        var cadence: float = 23.0 if id == "mini_boss" else [15.5, 14.5, 13.5][difficulty]
        var ordinal := int(segment["variant_seed"]) % kinds.size()
        while cursor <= end - 6.0:
            var added := false
            for delta in [0.0, 1.0, -1.0, 2.0, -2.0, 3.0, -3.0]:
                var z: float = cursor + delta
                if z < min_z or z > end - 6.0: continue
                var allowed := true
                for occupied_z: float in occupied:
                    if absf(z - occupied_z) < 4.0: allowed = false
                if not result.is_empty() and z - float(result.back()["z"]) < 12.0: allowed = false
                if not allowed: continue
                var progress := clampf(float(segment["start"]) / float(plan["total_length"]), 0, 1)
                var height := minf(1.20, float([0.85, 1.0, 1.15][difficulty]) + progress * 0.15)
                var kind := str(kinds[ordinal % kinds.size()])
                if id == "mini_boss":
                    kind = "stone"
                    height = float([0.65, 0.8, 0.9][difficulty])
                elif recovery > 0:
                    kind = "bench"
                    height = float([0.70, 0.85, 1.0][difficulty])
                result.append({"z": z, "kind": kind, "height": height, "recovery_tail": bool(segment.get("safe_recovery", false))})
                ordinal += 1
                added = true
                break
            cursor += cadence
            if bool(segment.get("safe_recovery", false)) and added: break
    return result

static func build_obstacles(parent: Node3D, specs: Array[Dictionary], segment_z: float, length: float, ground_height: Callable, hurdles: Array[float]) -> void:
    for spec: Dictionary in specs:
        var z := float(spec["z"])
        if z < segment_z or z >= segment_z + length: continue
        var group := Node3D.new()
        group.name = ("First100Obstacle_%s_%d" if z < SAMPLE_END else "CourseObstacle_%s_%d") % [spec["kind"], int(z)]
        group.position.z = z - segment_z
        group.set_meta("kind", spec["kind"])
        group.set_meta("course_z", z)
        parent.add_child(group)
        group.add_to_group("courtyard_obstacles")
        if z < SAMPLE_END: group.add_to_group("first100_obstacles")
        var height := float(spec["height"])
        var kind := str(spec["kind"])
        if kind == "crate_steps":
            for step in range(2):
                var at_z := z + step * 1.15
                var y: float = ground_height.call(at_z)
                var step_height := height * (0.65 if step == 0 else 1.30)
                for row in range(5):
                    _solid(group, "crate", Vector3(-2.08 + row * 1.04, y, step * 1.15), Vector3(1.04, step_height, 1.15))
                hurdles.append(at_z)
        elif kind == "barrels":
            for row in range(5):
                var y: float = ground_height.call(z)
                _solid(group, "barrel", Vector3(-2.08 + row * 1.04, y, 0), Vector3(1.04, height * 1.20, 1.04), true)
            hurdles.append(z)
        elif kind == "bench":
            # Benches present a readable side silhouette: seat and legs are
            # visible across the jump, with no giant invisible depth collider.
            for row in range(5):
                var y: float = ground_height.call(z)
                _solid(group, "bench", Vector3(-2.08 + row * 1.04, y, 0), Vector3(1.04, height * 0.85, 1.70))
            hurdles.append(z)
        else:
            var count := 5 if kind == "crate" else 4
            var cell := 5.2 / count
            for row in range(count):
                var y: float = ground_height.call(z)
                _solid(group, kind, Vector3(-2.6 + cell * (row + 0.5), y, 0), Vector3(cell, height, 1.05))
            hurdles.append(z)
        group.set_meta("jump_height", height * 1.30 if kind == "crate_steps" else height * 1.20 if kind == "barrels" else height * 0.85 if kind == "bench" else height)

static func _solid(parent: Node3D, id: String, at: Vector3, dimensions: Vector3, cylinder: bool = false) -> void:
    var body := StaticBody3D.new()
    body.name = "Physical_%s" % id
    body.position = at
    parent.add_child(body)
    body.add_to_group("courtyard_solids")
    if float(parent.get_meta("course_z")) < SAMPLE_END: body.add_to_group("first100_solids")
    var collision := CollisionShape3D.new()
    if cylinder:
        var shape := CylinderShape3D.new()
        shape.radius = dimensions.x * 0.5
        shape.height = dimensions.y
        collision.shape = shape
    else:
        var shape := BoxShape3D.new()
        shape.size = dimensions
        collision.shape = shape
    collision.position.y = dimensions.y * 0.5
    body.add_child(collision)
    var model_at := Vector3(0, dimensions.y * 0.5, 0) if id == "stone" else Vector3.ZERO
    var model_dimensions := Vector3(dimensions.z, dimensions.y, dimensions.x) if id == "bench" else dimensions
    place(body, id, model_at, model_dimensions, -PI * 0.5 if id == "bench" else 0.0)
    body.set_meta("dimensions", dimensions)

static func dress(parent: Node3D, spans: Array[Vector4], height_at: Callable) -> void:
    var begin := parent.position.z
    var end := begin + float(parent.get_meta("length"))
    var segment_id := str(parent.get_meta("segment_id"))
    var open_court := segment_id in ["vista", "fountain_court", "checkpoint", "bridge", "hazard"] or bool(parent.get_meta("safe_recovery", false))
    if begin >= end: return
    var root := Node3D.new()
    root.name = "First100Scenery" if begin < SAMPLE_END else "CourtyardAssetScenery"
    root.add_to_group("courtyard_scenery")
    root.set_meta("segment_id", segment_id)
    root.set_meta("asset_author", "Quaternius")
    parent.add_child(root)
    # Global cadence crosses segment boundaries without stacked duplicate walls.
    var z := START + 2.0 + ceilf((begin - START - 2.0) / 4.0) * 4.0
    while z < end:
        var local_z := z - parent.position.z
        var y: float = height_at.call(z)
        var index := int((z - START) / 4.0)
        var id := "window" if index % 4 == 1 else "wall"
        var wall_height := 2.4 if open_court and begin >= SAMPLE_END else 3.4 if index % 7 in [4, 5] else 4.6
        place(root, id, Vector3(6.5, y - 0.2, local_z), Vector3(4.0, wall_height, 0.42), -PI * 0.5)
        # A stone buttress/cap gives the flat modular wall actual depth.
        place(root, "stone", Vector3(6.15, y + wall_height * 0.5, local_z - 1.8), Vector3(0.68, wall_height, 0.62))
        place(root, "stone", Vector3(6.35, y + wall_height - 0.05, local_z), Vector3(0.9, 0.28, 4.0))
        if index % 3 == 0:
            place(root, "banner", Vector3(5.94, y + 1.1, local_z), Vector3(1.2, 2.5, 0.15), -PI * 0.5)
        if index % 3 != 1:
            place(root, "ivy" if index % 2 else "ivy_alt", Vector3(5.97, y + 1.0, local_z + 1.0), Vector3(1.7, 3.1, 0.25), -PI * 0.5)
        if index % 4 == 2 and segment_id not in ["bridge", "hazard"]:
            Scenery.place(root, "courtyard_first100_cypress", Vector3(4.25, y, local_z + 0.3), Vector3(0.7, 1.10, 0.7))
        # Visible climbing ivy on the near masonry, without a hidden collider.
        if index % 2 == 0 and _solid_span(spans, local_z):
            place(root, "ivy_alt", Vector3(-2.86, y - 2.3, local_z), Vector3(1.8, 2.25, 0.22), -PI * 0.5)
        z += 4.0
    var landmarks := [10.0, 34.0, 58.0, 82.0]
    if begin >= SAMPLE_END or (begin < SAMPLE_END and end > SAMPLE_END + 12.0):
        landmarks.append(maxf(begin + 8.0, begin + (end - begin) * 0.52))
    for landmark_z: float in landmarks:
        if landmark_z < begin or landmark_z >= end: continue
        var y: float = height_at.call(landmark_z)
        var local_z: float = landmark_z - parent.position.z
        # Each court has an arch between two projecting stone piers.
        place(root, "arch", Vector3(7.2, y, local_z), Vector3(5.0, 6.1, 0.55), -PI * 0.5)
        place(root, "door", Vector3(7.38, y, local_z), Vector3(2.7, 4.6, 0.20), -PI * 0.5)
        for side in [-1.0, 1.0]:
            place(root, "stone", Vector3(6.8, y + 3.3, local_z + side * 2.7), Vector3(1.25, 6.6, 1.0))
            place(root, "stone", Vector3(6.8, y + 6.7, local_z + side * 2.7), Vector3(1.65, 0.35, 1.35))
            place(root, "banner", Vector3(6.05, y + 2.1, local_z + side * 2.7), Vector3(1.1, 2.6, 0.18), -PI * 0.5)
        if landmark_z == 58.0 or segment_id in ["fountain_court", "vista"]:
            Scenery.place(root, "courtyard_course_fountain", Vector3(4.9, y, local_z), Vector3.ONE)
        else:
            place(root, "bench", Vector3(3.9, y, local_z - 3.5), Vector3(2.6, 0.60, 0.65), -PI * 0.5)
    for cart_z in [-7.0, 46.0]:
        if cart_z >= begin and cart_z < end:
            var y: float = height_at.call(cart_z)
            place(root, "cart", Vector3(4.0, y, cart_z - parent.position.z), Vector3(3.0, 2.5, 1.2), -PI * 0.5)
    if begin >= SAMPLE_END:
        var middle := (begin + end) * 0.5
        var y: float = height_at.call(middle)
        if segment_id == "tower":
            _watchtower(root, Vector3(7.4, y, middle - begin))
        if segment_id == "bridge":
            for span: Vector4 in spans:
                var local_z := (span.x + span.y) * 0.5
                place(root, "arch", Vector3(6.0, -3.45, local_z), Vector3(minf(5.0, span.y - span.x), 3.7, 0.65), -PI * 0.5)
        if segment_id in ["checkpoint", "gate_approach", "mini_boss", "finish"]:
            for offset in [-3.0, 3.0]:
                place(root, "lantern", Vector3(4.2, y + 1.5, middle - begin + offset), Vector3(0.5, 1.1, 0.8), -PI * 0.5)
        if segment_id in ["combat_small", "combat_large", "stairs", "gate"]:
            place(root, "cart", Vector3(4.1, y, middle - begin - 3.0), Vector3(2.8, 2.4, 1.1), -PI * 0.5)
    if end - begin < 4.0:
        var middle := (begin + end) * 0.5
        var y: float = height_at.call(middle)
        place(root, "stone", Vector3(5.8, y + 0.65, middle - begin), Vector3(0.45, 1.3, maxf(0.2,end-begin)))
        place(root, "ivy_alt", Vector3(5.4, y - 0.2, middle - begin), Vector3(0.7, 1.1, 0.15), -PI * 0.5)
    _batch_scenery(root)

static func _watchtower(root: Node3D, at: Vector3) -> void:
    for side in range(4):
        var yaw := side * PI * 0.5
        var offset := Vector3(sin(yaw), 0, cos(yaw)) * 2.2
        place(root, "window", at + offset, Vector3(4.4, 7.5, 0.5), yaw)
    for side in [-1.0, 1.0]:
        for forward in [-1.0, 1.0]:
            place(root, "stone", at + Vector3(side * 2.15, 3.85, forward * 2.15), Vector3(0.7, 7.7, 0.7))
    place(root, "stone", at + Vector3(0, 7.55, 0), Vector3(5.0, 0.45, 5.0))
    for side in range(4):
        var yaw := side * PI * 0.5
        for offset in [-1.5, 0.0, 1.5]:
            var at_edge := Basis(Vector3.UP, yaw) * Vector3(offset, 8.1, 2.1)
            place(root, "stone", at + at_edge, Vector3(0.85, 0.65, 0.75), yaw)
    place(root, "banner", at + Vector3(-2.6, 2.6, 0), Vector3(1.4, 3.8, 0.16), -PI * 0.5)

static func _batch_scenery(root: Node3D) -> void:
    # Static decorations share a MultiMesh per source mesh per streamed segment.
    # Colliders/gameplay remain separate. This keeps the longer art pass from
    # multiplying draw calls by the number of individual stone/plant modules.
    var buckets := {}
    var inverse := root.global_transform.affine_inverse()
    var originals := root.get_children()
    var original_count := 0
    for instance: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
        var key := instance.mesh.get_rid().get_id()
        if not buckets.has(key): buckets[key] = {"mesh": instance.mesh, "transforms": []}
        buckets[key]["transforms"].append(inverse * instance.global_transform)
        original_count += 1
    for key in buckets:
        var bucket: Dictionary = buckets[key]
        var batch := MultiMesh.new()
        batch.transform_format = MultiMesh.TRANSFORM_3D
        batch.mesh = Pilot.mesh_variant(bucket["mesh"]) if Pilot.applies(root.get_parent().position.z) else bucket["mesh"]
        batch.instance_count = bucket["transforms"].size()
        for i in range(batch.instance_count): batch.set_instance_transform(i, bucket["transforms"][i])
        var visual := MultiMeshInstance3D.new()
        visual.name = "AssetBatch_%d" % key
        visual.multimesh = batch
        visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        root.add_child(visual)
    for original in originals: original.free()
    root.set_meta("mesh_count", original_count)
    root.set_meta("batch_count", buckets.size())

static func _solid_span(spans: Array[Vector4], z: float) -> bool:
    for span: Vector4 in spans:
        if z >= span.x and z <= span.y: return true
    return false
