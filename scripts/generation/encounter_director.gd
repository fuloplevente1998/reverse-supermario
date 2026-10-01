extends RefCounted

const StageCatalog = preload("res://scripts/generation/stage_catalog.gd")
const DifficultyProfiles = preload("res://scripts/generation/difficulty_profiles.gd")

# Migration bridge: new biome roles map to the five currently implemented enemy
# controllers until dedicated meshes/behaviours are added.
const LEGACY_ARCHETYPE := {
    "guard": "guard",
    "shield_guard": "brute",
    "archer": "archer",
    "cliff_elite": "brute",
    "ice_guard": "guard",
    "ice_shield": "brute",
    "ice_archer": "archer",
    "forge_guard": "guard",
    "hammer_brute": "brute",
    "fire_archer": "archer",
    "pikeman": "guard",
    "skeleton_sword": "guard",
    "skeleton_shield": "brute",
    "skeleton_archer": "archer",
    "dark_guard": "guard",
    "dark_shield": "brute",
    "dark_archer": "archer",
    "black_guard": "guard",
    "black_shield": "brute",
    "black_archer": "archer",
    "forest_elite": "brute",
    "royal_guard": "guard",
    "royal_shield": "brute",
    "royal_archer": "archer",
    "royal_elite": "captain"
}

static func build_encounter(stage_number: int, difficulty_index: int, segment: Dictionary) -> Array[Dictionary]:
    var spec := StageCatalog.get_stage(stage_number)
    var difficulty := DifficultyProfiles.get_profile(difficulty_index)
    var segment_id := str(segment["id"])
    var kind := str(segment["kind"])

    var baseline := 0
    if segment_id == "mini_boss":
        baseline = 3
    elif segment_id == "archer_ambush":
        baseline = 3
    elif segment_id == "combat_large":
        baseline = 4
    elif segment_id == "combat_small":
        baseline = 2
    elif kind == "combat":
        baseline = 2

    if baseline <= 0:
        return []

    var count := maxi(1, roundi(float(baseline) * float(difficulty["enemy_count_multiplier"])))
    var rng := RandomNumberGenerator.new()
    rng.seed = int(segment["variant_seed"]) + stage_number * 131 + difficulty_index * 1009

    var pool: Array = spec["enemy_pool"]
    var encounter: Array[Dictionary] = []
    var length := float(segment["length"])

    for i in range(count):
        var role := str(pool[rng.randi_range(0, pool.size() - 1)])
        if segment_id == "archer_ambush":
            role = _best_archer(pool)
        elif segment_id == "mini_boss" and i == count - 1:
            role = _best_elite(pool)

        var elite := rng.randf() < float(difficulty["elite_chance"])
        var legacy := str(LEGACY_ARCHETYPE.get(role, "guard"))
        if elite and legacy == "guard":
            legacy = "brute"

        encounter.append({
            "role": role,
            "legacy_archetype": legacy,
            "elite": elite,
            "offset_z": length * float(i + 1) / float(count + 1),
            "offset_x": 0.0,
            "health_scale": float(difficulty["enemy_health_multiplier"]) * (1.25 if elite else 1.0),
            "damage_scale": float(difficulty["enemy_damage_multiplier"]) * (1.15 if elite else 1.0)
        })

    return encounter

static func _best_archer(pool: Array) -> String:
    for role in pool:
        if "archer" in str(role):
            return str(role)
    return str(pool.back())

static func _best_elite(pool: Array) -> String:
    for role in pool:
        var value := str(role)
        if "elite" in value:
            return value
    for role in pool:
        var value := str(role)
        if "shield" in value or "brute" in value:
            return value
    return str(pool.back())
