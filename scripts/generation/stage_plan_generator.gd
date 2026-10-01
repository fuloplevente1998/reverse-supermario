extends RefCounted

const StageCatalog = preload("res://scripts/generation/stage_catalog.gd")
const DifficultyProfiles = preload("res://scripts/generation/difficulty_profiles.gd")
const SegmentCatalog = preload("res://scripts/generation/segment_catalog.gd")

const SAFE_RECOVERY := ["traversal", "vista", "tower", "gate"]
const BRIDGE_LIKE := ["bridge", "rope_bridge", "stone_bridge", "ice_bridge", "bone_bridge", "broken_bridge", "chain_crossing", "siege_bridge"]
const BIG_COMBAT := ["combat_large", "archer_ambush", "farmyard", "siege_approach", "crypt_hall", "forest_ambush", "palisade_gate", "fortress_approach", "grand_gate", "final_courtyard", "citadel_approach", "mini_boss"]

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

    var start_length: float = SegmentCatalog.length("start")
    cursor = _append_segment(segments, "start", cursor, start_length, rng, spec, difficulty)

    var signatures: Array = spec["signature_segments"].duplicate()
    _shuffle(signatures, rng)
    var mini_length: float = SegmentCatalog.length("mini_boss")
    var finish_length: float = SegmentCatalog.length("finish")
    var lead_in_length: float = SegmentCatalog.length("traversal")
    # Checkpoints are mandatory too. Interleave them with the landmarks so
    # neither can be crowded out by random filler near the end of the course.
    var checkpoint_count := maxi(1, floori((target_length - mini_length - finish_length) / float(difficulty["checkpoint_interval"])))
    var body_target: float = target_length - lead_in_length - mini_length - finish_length
    var mandatory: Array[String] = _mandatory_segments(signatures, checkpoint_count)
    # Hazard-heavy future biome specs may require more recovery terrain. Keep
    # all landmarks and reduce checkpoint count only if the skeleton cannot fit.
    while checkpoint_count > 1 and _remaining_signature_budget(mandatory, "start", difficulty_index) > body_target - cursor:
        checkpoint_count -= 1
        mandatory = _mandatory_segments(signatures, checkpoint_count)
    var mandatory_count: int = mandatory.size()
    var mandatory_used := 0
    var previous_id: String = "start"

    while cursor < body_target - 0.001:
        var remaining: float = body_target - cursor
        var progress: float = clampf(cursor / maxf(body_target, 1.0), 0.0, 1.0)
        var reserve: float = _remaining_signature_budget(mandatory, previous_id, difficulty_index)
        assert(reserve <= remaining + 0.001, "Required segment budget exceeds remaining course")

        var signature_threshold: float = float(mandatory_used + 1) / float(mandatory_count + 1)
        var candidate := "traversal"
        if not mandatory.is_empty() and (progress >= signature_threshold or remaining <= reserve + 42.0):
            candidate = str(mandatory.front())
            if not _allowed_after(previous_id, candidate, difficulty_index, progress):
                candidate = "traversal"
        elif previous_id != "checkpoint" and not _requires_recovery(previous_id):
            candidate = _weighted_pick_allowed(spec["segment_weights"], previous_id, difficulty_index, progress, rng)

        var pending: Array = mandatory.duplicate()
        if not pending.is_empty() and candidate == str(pending.front()):
            pending.pop_front()
        var variation: float = 1.0 if candidate == "checkpoint" or candidate in spec["signature_segments"] else rng.randf_range(0.90, 1.10)
        var segment_length: float = SegmentCatalog.length(candidate) * variation
        var tail_budget: float = _remaining_signature_budget(pending, candidate, difficulty_index)

        # Reject filler that would crowd out any mandatory segment or required
        # recovery. Only filler may be shortened; signatures retain full length.
        if segment_length + tail_budget > remaining:
            if not mandatory.is_empty():
                candidate = str(mandatory.front())
                if not _allowed_after(previous_id, candidate, difficulty_index, progress):
                    candidate = "traversal"
                pending = mandatory.duplicate()
                if candidate == str(pending.front()):
                    pending.pop_front()
                segment_length = SegmentCatalog.length(candidate)
                tail_budget = _remaining_signature_budget(pending, candidate, difficulty_index)
            else:
                candidate = "traversal"
                segment_length = remaining
                tail_budget = 0.0
        assert(segment_length + tail_budget <= remaining + 0.001, "Candidate consumes required tail budget")
        cursor = _append_segment(segments, candidate, cursor, segment_length, rng, spec, difficulty)
        if not mandatory.is_empty() and candidate == str(mandatory.front()):
            mandatory.pop_front()
            mandatory_used += 1
        previous_id = candidate

    assert(mandatory.is_empty(), "Missing required landmarks or checkpoints")
    cursor = _append_segment(segments, "traversal", cursor, lead_in_length, rng, spec, difficulty)
    segments.back()["boss_approach"] = true
    assert(_allowed_after("traversal", "mini_boss", difficulty_index, 1.0))
    cursor = _append_segment(segments, "mini_boss", cursor, mini_length, rng, spec, difficulty)
    assert(_allowed_after("mini_boss", "finish", difficulty_index, 1.0))
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
        "safe_recovery": not segments.is_empty() and (_requires_recovery(str(segments.back()["id"])) or str(segments.back()["id"]) == "checkpoint"),
        "biome": spec["biome"],
        "enemy_pool": spec["enemy_pool"],
        "hazard_pool": spec["hazard_pool"],
        "enemy_scale": difficulty["enemy_count_multiplier"],
        "hazard_speed": difficulty["hazard_speed_multiplier"]
    })
    return cursor + segment_length

static func _mandatory_segments(signatures: Array, checkpoint_count: int) -> Array[String]:
    var result: Array[String] = []
    var count: int = signatures.size() + checkpoint_count
    var signature_index := 0
    for i in range(count):
        if floori(float(i + 1) * checkpoint_count / count) > floori(float(i) * checkpoint_count / count):
            result.append("checkpoint")
        else:
            result.append(str(signatures[signature_index]))
            signature_index += 1
    return result

static func _remaining_signature_budget(signatures: Array, previous_id: String, difficulty_index: int) -> float:
    var total := 0.0
    var previous := previous_id
    for segment_id in signatures:
        var id := str(segment_id)
        # Use the stricter early-course rules for budgeting even on Hard.
        if not _allowed_after(previous, id, difficulty_index, 0.0):
            total += SegmentCatalog.length("traversal")
        total += SegmentCatalog.length(id)
        previous = id
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
        if weight == 0:
            continue
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
    if previous_id == "mini_boss" and candidate == "finish":
        return true

    if candidate == "mini_boss":
        return _is_safe_recovery(previous_id)

    if candidate == "checkpoint":
        return _is_safe_recovery(previous_id)

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
    return (segment_id in SAFE_RECOVERY or SegmentCatalog.kind(segment_id) == "vista" or segment_id == "gate_approach") and segment_id not in BRIDGE_LIKE and SegmentCatalog.kind(segment_id) != "hazard"

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
