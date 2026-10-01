extends RefCounted

# Logical lengths only. Authored PackedScene variants may override these later.
const SEGMENTS := {
    "start": {"length": 36.0, "kind": "start"},
    "traversal": {"length": 38.0, "kind": "traversal"},
    "combat_small": {"length": 42.0, "kind": "combat"},
    "combat_large": {"length": 52.0, "kind": "combat"},
    "bridge": {"length": 38.0, "kind": "traversal"},
    "gap": {"length": 32.0, "kind": "hazard"},
    "stairs": {"length": 34.0, "kind": "traversal"},
    "hazard": {"length": 38.0, "kind": "hazard"},
    "archer_ambush": {"length": 44.0, "kind": "combat"},
    "vista": {"length": 46.0, "kind": "vista"},
    "tower": {"length": 42.0, "kind": "traversal"},
    "gate": {"length": 44.0, "kind": "traversal"},
    "checkpoint": {"length": 20.0, "kind": "checkpoint"},
    "mini_boss": {"length": 58.0, "kind": "combat"},
    "finish": {"length": 48.0, "kind": "finish"},

    # Named signature segments currently use safe logical lengths. Runtime
    # PackedScene variants are added biome-by-biome.
    "fountain_court": {"length": 46.0, "kind": "vista"},
    "gate_approach": {"length": 48.0, "kind": "traversal"},
    "garden_maze": {"length": 48.0, "kind": "traversal"},
    "rose_arch": {"length": 36.0, "kind": "vista"},
    "stone_bridge": {"length": 40.0, "kind": "traversal"},
    "gazebo_vista": {"length": 44.0, "kind": "vista"},
    "cliff_vista": {"length": 48.0, "kind": "vista"},
    "rope_bridge": {"length": 44.0, "kind": "hazard"},
    "waterfall_crossing": {"length": 46.0, "kind": "traversal"},
    "crane_platform": {"length": 42.0, "kind": "hazard"},
    "watchtower": {"length": 42.0, "kind": "traversal"},
    "ice_bridge": {"length": 40.0, "kind": "hazard"},
    "frozen_waterfall": {"length": 44.0, "kind": "vista"},
    "ice_gate_vista": {"length": 46.0, "kind": "vista"},
    "snow_tower": {"length": 42.0, "kind": "traversal"},
    "breakable_ice": {"length": 38.0, "kind": "hazard"},
    "molten_channel": {"length": 42.0, "kind": "hazard"},
    "crusher_hall": {"length": 44.0, "kind": "hazard"},
    "lift_platform": {"length": 40.0, "kind": "hazard"},
    "furnace_vista": {"length": 44.0, "kind": "vista"},
    "industrial_gate": {"length": 46.0, "kind": "traversal"},
    "village_lane": {"length": 46.0, "kind": "traversal"},
    "windmill_vista": {"length": 48.0, "kind": "vista"},
    "farmyard": {"length": 42.0, "kind": "combat"},
    "siege_approach": {"length": 48.0, "kind": "combat"},
    "crypt_hall": {"length": 44.0, "kind": "combat"},
    "bone_bridge": {"length": 40.0, "kind": "hazard"},
    "cage_gallery": {"length": 42.0, "kind": "hazard"},
    "tomb_vista": {"length": 44.0, "kind": "vista"},
    "collapsed_crypt": {"length": 42.0, "kind": "hazard"},
    "broken_bridge": {"length": 44.0, "kind": "hazard"},
    "fog_chasm": {"length": 46.0, "kind": "vista"},
    "chain_crossing": {"length": 40.0, "kind": "hazard"},
    "ruined_watchtower": {"length": 42.0, "kind": "traversal"},
    "fortress_vista": {"length": 48.0, "kind": "vista"},
    "forest_ambush": {"length": 44.0, "kind": "combat"},
    "moss_ruin": {"length": 42.0, "kind": "traversal"},
    "wood_watchtower": {"length": 42.0, "kind": "traversal"},
    "palisade_gate": {"length": 44.0, "kind": "combat"},
    "fortress_approach": {"length": 48.0, "kind": "combat"},
    "siege_bridge": {"length": 46.0, "kind": "hazard"},
    "giant_statues": {"length": 44.0, "kind": "vista"},
    "grand_gate": {"length": 48.0, "kind": "combat"},
    "waterfall_bastion": {"length": 48.0, "kind": "vista"},
    "final_courtyard": {"length": 56.0, "kind": "combat"},
    "citadel_approach": {"length": 52.0, "kind": "combat"}
}

static func get_segment(segment_id: String) -> Dictionary:
    if SEGMENTS.has(segment_id):
        return SEGMENTS[segment_id].duplicate(true)
    return SEGMENTS["traversal"].duplicate(true)

static func length(segment_id: String) -> float:
    return float(get_segment(segment_id)["length"])

static func kind(segment_id: String) -> String:
    return str(get_segment(segment_id)["kind"])
