extends RefCounted

const StageCatalog = preload("res://scripts/generation/stage_catalog.gd")
const DifficultyProfiles = preload("res://scripts/generation/difficulty_profiles.gd")
const SegmentCatalog = preload("res://scripts/generation/segment_catalog.gd")

const SAFE_RECOVERY := ["traversal", "vista", "tower", "gate"]
const BRIDGE_LIKE := ["bridge", "rope_bridge", "stone_bridge", "ice_bridge", "bone_bridge", "broken_bridge", "chain_crossing", "siege_bridge"]
const BIG_COMBAT := ["combat_large", "archer_ambush", "farmyard", "siege_approach", "crypt_hall", "forest_ambush", "palisade_gate", "fortress_approach", "grand_gate", "final_courtyard", "citadel_approach"]

static func generate(stage_number: int, difficulty_index: int = 1, seed_override: int = 0) -> Dictionary:
    var spec: Dictionary = StageCatalog.get_stage(stage_number)
    var difficulty: Dictionary = DifficultyProfiles.get_profile(difficulty_index)
    var seed_value: int = seed_override if seed_override != 0 else int(spec["base_seed"])
    # Difficulty is deliberately part of the geometry seed. Easy/Normal/Hard may
    # produce different layouts while retaining the same biome and landmarks.
    seed_value += difficulty_index * 1000003

    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value

    var target_length: float = rng.randf_range(float(spec["min_length"]), float(spec["max_length"]))
    var segments: Array[Dictionary] = []
    var cursor: float = 0.0
    var next_checkpoint: float = float(difficulty["checkpoint_interval"])

    var start_length: float = SegmentCatalog.length("start")
    cursor = _append_segment(segments, "start", cursor, start_length, rng, spec, difficulty)

    var signatures: Array = spec["signature_segments"].duplicate()
    _shuffle(signatures, rng)
    var signature_total: int = signatures.size()
    var signature_used: int = 0

    var mini_length: float = SegmentCatalog.length("mini_boss")
    var finish_length: float = SegmentCatalog.length("finish")
    var body_target: float = target_length - mini_length - finish_length
    var previous_id: String = "start"
    var force_safe_next := false

    while cursor < body_target - 18.0:
        var remaining: float = body_target - cursor

        var signature_reserve: float = _remaining_signature_length(signatures)

        # Checkpoints are inserted by distance, but never at the expense of
        # required biome signature segments. Recovery terrain is inserted first
        # when required.
        if cursor >= next_checkpoint and remaining > signature_reserve + SegmentCatalog.length("checkpoint") + 36.0:
            if not _is_safe_recovery(previous_id) and remaining >= SegmentCatalog.length("traversal") + SegmentCatalog.length("checkpoint") + 18.0:
                var recovery_length: float = minf(SegmentCatalog.length("traversal"), remaining)
                cursor = _append_segment(segments, "traversal", cursor, recovery_length, rng, spec, difficulty)
                previous_id = "traversal"
                remaining = body_target - cursor
            if remaining >= 18.0:
                var checkpoint_length: float = minf(SegmentCatalog.length("checkpoint"), remaining)
                cursor = _append_segment(segments, "checkpoint", cursor, checkpoint_length, rng, spec, difficulty)
                previous_id = "checkpoint"
                force_safe_next = true
                next_checkpoint += float(difficulty["checkpoint_interval"])
                continue

        var progress: float = clampf(cursor / maxf(body_target, 1.0), 0.0, 1.0)
        var candidate := ""

        # Spread mockup-defining hero moments across the whole course instead
        # of dumping all signature segments near the start.
        var signature_threshold: float = 1.0
        if signature_total > 0 and signature_used < signature_total:
            signature_threshold = float(signature_used + 1) / float(signature_total + 1)

        if force_safe_next:
            candidate = "traversal"
            force_safe_next = false
        elif not signatures.is_empty() and (progress >= signature_threshold or remaining <= signature_reserve + 36.0):
            candidate = str(signatures.front())
            if _allowed_after(previous_id, candidate, difficulty_index, progress):
                signatures.pop_front()
                signature_used += 1
            else:
                candidate = "traversal"
        else:
            candidate = _weighted_pick_allowed(spec["segment_weights"], previous_id, difficulty_index, progress, rng)

        if not _allowed_after(previous_id, candidate, difficulty_index, progress):
            candidate = "traversal"

        var base_length: float = SegmentCatalog.length(candidate)
        var variation: float = 1.0
        if candidate not in ["checkpoint"]:
            variation = rng.randf_range(0.90, 1.10)
        var segment_length: float = minf(base_length * variation, remaining)

        if segment_length < 18.0:
            break

        cursor = _append_segment(segments, candidate, cursor, segment_length, rng, spec, difficulty)

        if _requires_recovery(candidate):
            force_safe_next = true
        previous_id = candidate

        if segments.size() > 100:
            break

    # If a small body remainder exists, fill it with safe traversal so final
    # course length stays inside the stage definition's requested range.
    var body_remainder: float = body_target - cursor
    if body_remainder >= 8.0:
        cursor = _append_segment(segments, "traversal", cursor, body_remainder, rng, spec, difficulty)

    cursor = _append_segment(segments, "mini_boss", cursor, mini_length, rng, spec, difficulty)
    cursor = _append_segment(segments, "finish", cursor, finish_length, rng, spec, difficulty)

    return {
        "stage_id": stage_number,
        "stage_name": StageCatalog.title(stage_number),
        "goal": spec["goal"],
        "biome": spec["biome"],
        "difficulty": difficulty["name"],
        "difficulty_index": difficulty_index,
        "seed": seed_value,
        "target_length": target_length,
        "total_length": cursor,
        "enemy_count_multiplier": difficulty["enemy_count_multiplier"],
        "enemy_damage_multiplier": difficulty["enemy_damage_multiplier"],
        "hazard_speed_multiplier": difficulty["hazard_speed_multiplier"],
        "elite_chance": difficulty["elite_chance"],
        "segments": segments
    }

static func _append_segment(segments: Array[Dictionary], segment_id: String, cursor: float, segment_length: float, rng: RandomNumberGenerator, spec: Dictionary, difficulty: Dictionary) -> float:
    segments.append({
        "index": segments.size(),
        "id": segment_id,
        "kind": SegmentCatalog.kind(segment_id),
        "start": cursor,
        "length": segment_length,
        "end": cursor + segment_length,
        "variant_seed": rng.randi(),
        "biome": spec["biome"],
        "enemy_pool": spec["enemy_pool"],
        "hazard_pool": spec["hazard_pool"],
        "enemy_scale": difficulty["enemy_count_multiplier"],
        "hazard_speed": difficulty["hazard_speed_multiplier"]
    })
    return cursor + segment_length

static func _remaining_signature_length(signatures: Array) -> float:
    var total := 0.0
    for segment_id in signatures:
        total += SegmentCatalog.length(str(segment_id))
    return total

static func _weighted_pick_allowed(weights: Dictionary, previous_id: String, difficulty_index: int, progress: float, rng: RandomNumberGenerator) -> String:
    var candidates: Array[String] = []
    var candidate_weights: Array[int] = []
    var total := 0

    for key in weights:
        var id := str(key)
        if not _allowed_after(previous_id, id, difficulty_index, progress):
            continue

        var weight := maxi(0, int(weights[key]))
        if difficulty_index == 0 and (SegmentCatalog.kind(id) == "hazard" or id in BIG_COMBAT):
            weight = maxi(1, roundi(weight * 0.55))
        elif difficulty_index == 2 and (SegmentCatalog.kind(id) == "hazard" or id in BIG_COMBAT):
            weight = maxi(1, roundi(weight * 1.55))

        # Gentle opening, stronger final third.
        if progress < 0.18 and (id in BIG_COMBAT or SegmentCatalog.kind(id) == "hazard"):
            weight = maxi(1, roundi(weight * 0.45))
        elif progress > 0.68 and difficulty_index >= 1 and (id in BIG_COMBAT or SegmentCatalog.kind(id) == "hazard"):
            weight = maxi(1, roundi(weight * 1.30))

        if weight <= 0:
            continue
        candidates.append(id)
        candidate_weights.append(weight)
        total += weight

    if total <= 0:
        return "traversal"

    var pick := rng.randi_range(1, total)
    for i in range(candidates.size()):
        pick -= candidate_weights[i]
        if pick <= 0:
            return candidates[i]
    return "traversal"

static func _allowed_after(previous_id: String, candidate: String, difficulty_index: int, progress: float) -> bool:
    if previous_id == "checkpoint":
        return _is_safe_recovery(candidate)

    if _requires_recovery(previous_id):
        # Hard may combine ranged pressure with platforming late in the level,
        # but never chains two major hazards or two major combat encounters.
        if difficulty_index == 2 and progress > 0.55 and candidate == "archer_ambush" and SegmentCatalog.kind(previous_id) != "combat":
            return true
        return _is_safe_recovery(candidate)

    if previous_id in BIG_COMBAT and candidate in BIG_COMBAT:
        return false

    if SegmentCatalog.kind(previous_id) == "hazard" and SegmentCatalog.kind(candidate) == "hazard":
        return false

    if previous_id in BRIDGE_LIKE and candidate in BRIDGE_LIKE:
        return false

    return true

static func _requires_recovery(segment_id: String) -> bool:
    return SegmentCatalog.kind(segment_id) == "hazard" or segment_id in BRIDGE_LIKE or segment_id in BIG_COMBAT

static func _is_safe_recovery(segment_id: String) -> bool:
    return segment_id in SAFE_RECOVERY and segment_id not in BRIDGE_LIKE and SegmentCatalog.kind(segment_id) != "hazard"

static func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
    for i in range(values.size() - 1, 0, -1):
        var j := rng.randi_range(0, i)
        var temp = values[i]
        values[i] = values[j]
        values[j] = temp

static func signature(plan: Dictionary) -> String:
    var parts: PackedStringArray = []
    for segment: Dictionary in plan["segments"]:
        parts.append("%s:%d" % [segment["id"], roundi(float(segment["length"]) * 10.0)])
    return "|".join(parts)
