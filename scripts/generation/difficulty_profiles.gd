extends RefCounted

const PROFILES := [
    {
        "id": 0,
        "name": "KÖNNYŰ",
        "player_health": 120,
        "enemy_move_multiplier": 0.85,
        "hazard_damage_multiplier": 0.75,
        "gap_width": 3.0,
        "bridge_width": 4.8,
        "bridge_gap_width": 2.4,
        "bridge_landing_length": 8.0,
        "enemy_count_multiplier": 0.72,
        "enemy_damage_multiplier": 0.75,
        "enemy_health_multiplier": 0.82,
        "hazard_speed_multiplier": 0.80,
        "healing_multiplier": 1.35,
        "checkpoint_interval": 110.0,
        "elite_chance": 0.02
    },
    {
        "id": 1,
        "name": "NORMÁL",
        "player_health": 100,
        "enemy_move_multiplier": 1.00,
        "hazard_damage_multiplier": 1.00,
        "gap_width": 4.4,
        "bridge_width": 3.9,
        "bridge_gap_width": 3.3,
        "bridge_landing_length": 6.0,
        "enemy_count_multiplier": 1.00,
        "enemy_damage_multiplier": 1.00,
        "enemy_health_multiplier": 1.00,
        "hazard_speed_multiplier": 1.00,
        "healing_multiplier": 1.00,
        "checkpoint_interval": 145.0,
        "elite_chance": 0.08
    },
    {
        "id": 2,
        "name": "NEHÉZ",
        "player_health": 80,
        "enemy_move_multiplier": 1.12,
        "hazard_damage_multiplier": 1.25,
        "gap_width": 5.6,
        "bridge_width": 3.2,
        "bridge_gap_width": 4.2,
        "bridge_landing_length": 4.5,
        "enemy_count_multiplier": 1.35,
        "enemy_damage_multiplier": 1.25,
        "enemy_health_multiplier": 1.25,
        "hazard_speed_multiplier": 1.20,
        "healing_multiplier": 0.65,
        "checkpoint_interval": 180.0,
        "elite_chance": 0.20
    }
]

static func get_profile(index: int) -> Dictionary:
    assert(index >= 0 and index < PROFILES.size())
    return PROFILES[index].duplicate(true)
