extends RefCounted

# Canonical mockup-driven definitions for the generator rebuild.
# Runtime geometry still migrates stage-by-stage; these specs are the new source
# of truth for names, goals, lengths, biome identity and segment emphasis.
const STAGES := [
    {
        "id": 1,
        "name": "VÁRUDVAR",
        "subtitle": "A BELSŐ KAPU",
        "goal": "ÉRD EL A BELSŐ KAPUT",
        "biome": "courtyard",
        "min_length": 700.0,
        "max_length": 800.0,
        "base_seed": 11001,
        "segment_weights": {"traversal": 4, "combat_small": 3, "combat_large": 2, "bridge": 1, "gap": 1, "stairs": 2, "hazard": 1, "archer_ambush": 2, "vista": 2, "tower": 2, "gate": 1},
        "signature_segments": ["vista", "fountain_court", "tower", "bridge", "gate_approach"],
        "enemy_pool": ["guard", "shield_guard", "archer"],
        "hazard_pool": ["spikes", "gap"],
        "features": ["pale_limestone", "red_gold_banners", "cypress", "fountain", "lion_statue", "brazier"]
    },
    {
        "id": 2,
        "name": "A KIRÁLYI KERTEK",
        "subtitle": "AZ ELVESZETT ÖSVÉNY",
        "goal": "TALÁLD MEG AZ ÖSVÉNYT",
        "biome": "royal_gardens",
        "min_length": 750.0,
        "max_length": 850.0,
        "base_seed": 22002,
        "segment_weights": {"traversal": 3, "combat_small": 2, "combat_large": 1, "bridge": 2, "stairs": 1, "hazard": 1, "archer_ambush": 1, "vista": 3, "tower": 1, "garden_maze": 3},
        "signature_segments": ["garden_maze", "rose_arch", "fountain_court", "stone_bridge", "gazebo_vista"],
        "enemy_pool": ["guard", "shield_guard", "archer"],
        "hazard_pool": ["water", "hedge_maze", "gap"],
        "features": ["hedge", "rose", "gazebo", "pond", "stone_bridge", "statue", "cypress"]
    },
    {
        "id": 3,
        "name": "SAS-SZIRT",
        "subtitle": "A MÉLYSÉG FELETT",
        "goal": "JUSS ÁT A SZAKADÉKON",
        "biome": "eagle_cliff",
        "min_length": 800.0,
        "max_length": 900.0,
        "base_seed": 33003,
        "segment_weights": {"traversal": 2, "combat_small": 2, "combat_large": 2, "bridge": 4, "gap": 3, "stairs": 2, "hazard": 2, "archer_ambush": 3, "vista": 4, "tower": 2},
        "signature_segments": ["cliff_vista", "rope_bridge", "waterfall_crossing", "crane_platform", "watchtower"],
        "enemy_pool": ["guard", "archer", "cliff_elite"],
        "hazard_pool": ["abyss", "falling_rock", "broken_bridge"],
        "features": ["cliff", "waterfall", "rope_bridge", "crane", "mountain_fortress", "cloud_sea"]
    },
    {
        "id": 4,
        "name": "DERMEDT BÁSTYA",
        "subtitle": "A JÉGKAPU",
        "goal": "NYISD MEG A JÉGKAPUT",
        "biome": "frozen_bastion",
        "min_length": 800.0,
        "max_length": 900.0,
        "base_seed": 44004,
        "segment_weights": {"traversal": 3, "combat_small": 2, "combat_large": 2, "bridge": 2, "gap": 2, "stairs": 1, "hazard": 4, "archer_ambush": 2, "vista": 3, "tower": 2},
        "signature_segments": ["ice_bridge", "frozen_waterfall", "ice_gate_vista", "snow_tower", "breakable_ice"],
        "enemy_pool": ["ice_guard", "ice_shield", "ice_archer"],
        "hazard_pool": ["slippery_ice", "ice_spike", "breakable_ice"],
        "features": ["snow", "ice", "icicle", "blue_heraldry", "frozen_waterfall", "ice_gate"]
    },
    {
        "id": 5,
        "name": "VASKOHÓ",
        "subtitle": "A TŰZ NEGYEDE",
        "goal": "JUSS ÁT A KOHÓN",
        "biome": "forge",
        "min_length": 850.0,
        "max_length": 950.0,
        "base_seed": 55005,
        "segment_weights": {"traversal": 2, "combat_small": 2, "combat_large": 3, "bridge": 2, "stairs": 2, "hazard": 5, "archer_ambush": 1, "vista": 2, "tower": 2},
        "signature_segments": ["molten_channel", "crusher_hall", "lift_platform", "furnace_vista", "industrial_gate"],
        "enemy_pool": ["forge_guard", "hammer_brute", "fire_archer"],
        "hazard_pool": ["molten_metal", "crusher", "moving_lift", "fire_jet"],
        "features": ["iron_platform", "chain", "furnace", "molten_metal", "gear", "lift"]
    },
    {
        "id": 6,
        "name": "SZÉLMALOM-VÖLGY",
        "subtitle": "AZ OSTROM ELŐTT",
        "goal": "HALADJ A FALU FELÉ",
        "biome": "windmill_valley",
        "min_length": 850.0,
        "max_length": 950.0,
        "base_seed": 66006,
        "segment_weights": {"traversal": 4, "combat_small": 3, "combat_large": 2, "bridge": 2, "stairs": 1, "hazard": 2, "archer_ambush": 2, "vista": 4, "tower": 1},
        "signature_segments": ["village_lane", "windmill_vista", "stone_bridge", "farmyard", "siege_approach"],
        "enemy_pool": ["guard", "pikeman", "archer"],
        "hazard_pool": ["barricade", "cart_crash", "burning_field"],
        "features": ["timber_house", "wheat", "windmill", "wagon", "fence", "village_bridge"]
    },
    {
        "id": 7,
        "name": "AZ ELFELEDETT KATAKOMBÁK",
        "subtitle": "A HOLTAK ÚTJA",
        "goal": "TALÁLD MEG A KIJÁRATOT",
        "biome": "catacombs",
        "min_length": 900.0,
        "max_length": 1000.0,
        "base_seed": 77007,
        "segment_weights": {"traversal": 3, "combat_small": 3, "combat_large": 3, "bridge": 1, "gap": 2, "stairs": 3, "hazard": 4, "archer_ambush": 2, "vista": 2, "tower": 1},
        "signature_segments": ["crypt_hall", "bone_bridge", "cage_gallery", "tomb_vista", "collapsed_crypt"],
        "enemy_pool": ["skeleton_sword", "skeleton_shield", "skeleton_archer"],
        "hazard_pool": ["spike_pit", "falling_cage", "collapsed_floor"],
        "features": ["crypt", "bones", "candle", "chain", "cage", "tomb_niche"]
    },
    {
        "id": 8,
        "name": "ÁRNYÉKSZURDOK",
        "subtitle": "A TÖRÖTT HÍD",
        "goal": "JUSS ÁT A HÍDON",
        "biome": "shadow_canyon",
        "min_length": 900.0,
        "max_length": 1050.0,
        "base_seed": 88008,
        "segment_weights": {"traversal": 2, "combat_small": 2, "combat_large": 3, "bridge": 5, "gap": 4, "stairs": 2, "hazard": 3, "archer_ambush": 3, "vista": 4, "tower": 2},
        "signature_segments": ["broken_bridge", "fog_chasm", "chain_crossing", "ruined_watchtower", "fortress_vista"],
        "enemy_pool": ["dark_guard", "dark_shield", "dark_archer"],
        "hazard_pool": ["abyss", "bridge_collapse", "swinging_cage"],
        "features": ["dark_cliff", "ruined_bridge", "chain", "fog", "watchtower", "isolated_fire"]
    },
    {
        "id": 9,
        "name": "FEKETEERDŐ ERŐDJE",
        "subtitle": "AZ UTOLSÓ ŐRSÉG",
        "goal": "TÖRD ÁT AZ ŐRSÉGET",
        "biome": "black_forest",
        "min_length": 950.0,
        "max_length": 1100.0,
        "base_seed": 99009,
        "segment_weights": {"traversal": 3, "combat_small": 3, "combat_large": 4, "bridge": 2, "gap": 1, "stairs": 2, "hazard": 3, "archer_ambush": 3, "vista": 3, "tower": 3},
        "signature_segments": ["forest_ambush", "moss_ruin", "wood_watchtower", "palisade_gate", "fortress_approach"],
        "enemy_pool": ["black_guard", "black_shield", "black_archer", "forest_elite"],
        "hazard_pool": ["stake_pit", "ambush", "falling_tree"],
        "features": ["dense_pine", "moss_ruin", "wood_watchtower", "palisade", "ground_fog", "black_red_banner"]
    },
    {
        "id": 10,
        "name": "A KORONA CITADELLÁJA",
        "subtitle": "A VÉGSŐ OSTROM",
        "goal": "TÖRJ BE A CITADELLÁBA",
        "biome": "crown_citadel",
        "min_length": 1100.0,
        "max_length": 1300.0,
        "base_seed": 101010,
        "segment_weights": {"traversal": 2, "combat_small": 3, "combat_large": 5, "bridge": 3, "gap": 2, "stairs": 3, "hazard": 4, "archer_ambush": 3, "vista": 5, "tower": 4, "gate": 3},
        "signature_segments": ["siege_bridge", "giant_statues", "grand_gate", "waterfall_bastion", "final_courtyard", "citadel_approach"],
        "enemy_pool": ["royal_guard", "royal_shield", "royal_archer", "royal_elite"],
        "hazard_pool": ["siege_fire", "falling_stone", "bridge_gap", "ballista"],
        "features": ["monumental_limestone", "grand_bridge", "giant_statue", "siege_machine", "waterfall", "crowd"]
    }
]

static func get_stage(number: int) -> Dictionary:
    assert(number >= 1 and number <= STAGES.size())
    return STAGES[number - 1].duplicate(true)

static func all() -> Array:
    return STAGES.duplicate(true)

static func title(number: int) -> String:
    var spec: Dictionary = STAGES[number - 1]
    return "%s — %s" % [spec["name"], spec["subtitle"]]

static func goal(number: int) -> String:
    return str(STAGES[number - 1]["goal"])

static func biome(number: int) -> String:
    return str(STAGES[number - 1]["biome"])
