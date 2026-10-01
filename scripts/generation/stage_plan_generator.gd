extends RefCounted

const StageCatalog = preload("res://scripts/generation/stage_catalog.gd")
const DifficultyProfiles = preload("res://scripts/generation/difficulty_profiles.gd")
const SegmentCatalog = preload("res://scripts/generation/segment_catalog.gd")

static func generate(stage_number: int, difficulty_index: int = 1, seed_override: int = 0) -> Dictionary:
    var spec: Dictionary = StageCatalog.get_stage(stage_number)
    var difficulty: Dictionary = DifficultyProfiles.get_profile(difficulty_index)
    var seed_value := seed_override if seed_override != 0 else int(spec["base_seed"])
    seed_value += difficulty_index * 1000003

    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value

    var target_length := rng.randf_range(float(spec["min_length"]), float(spec["max_length"]))
    var segments: Array[Dictionary] = []
    var cursor := 0.0
    var next_checkpoint := float(difficulty["checkpoint_interval"])

    cursor = _append_segment(segments, "start", cursor, rng, spec, difficulty)

    # Every stage receives its mockup-defining hero moments once before weighted
    # filler is considered. Their order is shuffled deterministically.
    var signatures: Array = spec["signature_segments"].duplicate()
    _shuffle(signatures, rng)

    while cursor < target_length - SegmentCatalog.length("mini_boss") - SegmentCatalog.length("finish"):
        if cursor >= next_checkpoint:
            cursor = _append_segment(segments, "checkpoint", cursor, rng, spec, difficulty)
            next_checkpoint += float(difficulty["checkpoint_interval"])
            continue

        var segment_id := ""
        if not signatures.is_empty():
            segment_id = str(signatures.pop_front())
        else:
            segment_id = _weighted_pick(spec["segment_weights"], rng)

        var reserved := SegmentCatalog.length("mini_boss") + SegmentCatalog.length("finish")
        if cursor + SegmentCatalog.length(segment_id) + reserved > target_length + 18.0:
            segment_id = "traversal"

        cursor = _append_segment(segments, segment_id, cursor, rng, spec, difficulty)

        if segments.size() > 80:
            break

    cursor = _append_segment(segments, "mini_boss", cursor, rng, spec, difficulty)
    cursor = _append_segment(segments, "finish", cursor, rng, spec, difficulty)

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

static func _append_segment(segments: Array[Dictionary], segment_id: String, cursor: float, rng: RandomNumberGenerator, spec: Dictionary, difficulty: Dictionary) -> float:
    var base_length := SegmentCatalog.length(segment_id)
    var variation := 1.0
    if segment_id not in ["start", "checkpoint", "mini_boss", "finish"]:
        variation = rng.randf_range(0.90, 1.10)
    var segment_length := base_length * variation

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

static func _weighted_pick(weights: Dictionary, rng: RandomNumberGenerator) -> String:
    var total := 0
    for key in weights:
        total += maxi(0, int(weights[key]))
    if total <= 0:
        return "traversal"

    var pick := rng.randi_range(1, total)
    for key in weights:
        pick -= maxi(0, int(weights[key]))
        if pick <= 0:
            return str(key)
    return "traversal"

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
