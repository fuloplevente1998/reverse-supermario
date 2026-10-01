extends SceneTree

const Profiles = preload("res://scripts/generation/difficulty_profiles.gd")
const Enemy = preload("res://scripts/enemy.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _check(condition: bool, message: String) -> bool:
    if not condition:
        push_error(message)
        quit(1)
    return condition

func _verify() -> void:
    var progress := ConfigFile.new()
    for difficulty in range(3):
        var profile: Dictionary = Profiles.get_profile(difficulty)
        progress.set_value("progress", "difficulty", difficulty)
        progress.save("user://reverse_platformer_progress.cfg")
        var stage = load("res://scenes/main.tscn").instantiate()
        root.add_child(stage)
        await process_frame
        stage.player.set_physics_process(false)
        if not _check(stage.player.max_hp == int(profile["player_health"]), "Player health ignores difficulty profile"): return
        if not _check(stage._hazard_damage(20) == roundi(20.0 * float(profile["hazard_damage_multiplier"])), "Hazard damage ignores profile"): return

        for enemy in get_nodes_in_group("enemies"):
            enemy.set_physics_process(false)
            var health_scale: float = enemy.encounter_health_scale if enemy.encounter_health_scale >= 0.0 else float(profile["enemy_health_multiplier"])
            var damage_scale: float = enemy.encounter_damage_scale if enemy.encounter_damage_scale >= 0.0 else float(profile["enemy_damage_multiplier"])
            if not _check(enemy.max_hp == maxi(1, roundi(enemy.base_max_hp * health_scale)), "Encounter health scale is not applied"): return
            if not _check(enemy.damage == maxi(1, roundi(enemy.base_damage * damage_scale)), "Encounter damage scale is not applied"): return
            if not _check(is_equal_approx(enemy.move_speed, enemy.base_move_speed * float(profile["enemy_move_multiplier"])), "Enemy movement ignores profile"): return
            var hp_before: int = enemy.max_hp
            var damage_before: int = enemy.damage
            enemy.apply_difficulty(profile)
            if not _check(enemy.max_hp == hp_before and enemy.damage == damage_before, "Difficulty multipliers stack when reapplied"): return

        # Exercise a guaranteed elite even when the random Easy encounter has none.
        var elite := Enemy.new()
        elite.archetype = "brute"
        elite.elite_health_multiplier = 1.25
        elite.elite_damage_multiplier = 1.15
        stage.add_child(elite)
        elite.set_physics_process(false)
        elite.apply_difficulty(profile)
        if not _check(elite.max_hp == roundi(110.0 * float(profile["enemy_health_multiplier"]) * 1.25), "Elite health bonus is cosmetic only"): return
        if not _check(elite.damage == roundi(22.0 * float(profile["enemy_damage_multiplier"]) * 1.15), "Elite damage bonus is not applied"): return

        for hazard in get_nodes_in_group("hazards"):
            hazard.set_physics_process(false)
            if not _check(is_equal_approx(hazard.period, 3.6 / float(profile["hazard_speed_multiplier"])), "Hazard timing ignores profile"): return

        var checkpoints: Array = stage.get_meta("generated_checkpoints")
        stage.player.hp = 10
        var spawn := Vector3(0, 1.1, float(checkpoints[0]))
        stage._on_checkpoint_entered(stage.player, spawn)
        var healed_hp: int = 10 + roundi(20.0 * float(profile["healing_multiplier"]))
        if not _check(stage.player.hp == healed_hp, "Checkpoint healing ignores profile"): return
        stage._on_checkpoint_entered(stage.player, spawn)
        if not _check(stage.player.hp == healed_hp, "Checkpoint can be farmed for healing"): return
        stage.player.hp = stage.player.max_hp - 1
        stage._on_checkpoint_entered(stage.player, Vector3(0, 1.1, float(checkpoints[1])))
        if not _check(stage.player.hp == stage.player.max_hp, "Healing exceeds maximum health"): return

        var found_bridge := false
        for segment in stage.get_node("GeneratedLongStage").get_children():
            if str(segment.get_meta("segment_id")) == "bridge":
                found_bridge = true
                if not _check(is_equal_approx(float(segment.get_meta("bridge_gap_width")), float(profile["bridge_gap_width"])), "Bridge jump distance ignores profile"): return
                if not _check(is_equal_approx(float(segment.get_meta("bridge_landing_length")), float(profile["bridge_landing_length"])), "Side-view landing length ignores profile"): return
                if not _check(segment.get_node_or_null("BridgeDeck1") != null, "Bridge lacks the intermediate landing"): return
        if not _check(found_bridge, "Stage 1 lost its bridge"): return
        stage.queue_free()
        await process_frame

    print("DIFFICULTY_RUNTIME_SMOKE_OK: three profiles control actual enemy/elite stats, hazard damage/timing, one-time healing and side-view bridge geometry")
    quit(0)
