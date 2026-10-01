extends SceneTree

const StageCatalog = preload("res://scripts/generation/stage_catalog.gd")
const DifficultyProfiles = preload("res://scripts/generation/difficulty_profiles.gd")
const PlanGenerator = preload("res://scripts/generation/stage_plan_generator.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _check(condition: bool, message: String) -> bool:
    if not condition:
        push_error(message)
        quit(1)
        return false
    return true

func _verify() -> void:
    var stages := StageCatalog.all()
    if not _check(stages.size() == 10, "Generator rebuild must define exactly ten stages"):
        return
    if not _check(DifficultyProfiles.PROFILES.size() == 3, "Generator rebuild must define exactly three difficulties"):
        return

    var names := {}
    var biomes := {}
    var stage_signatures := {}
    var total_plans := 0

    for stage_number in range(1, 11):
        var spec := StageCatalog.get_stage(stage_number)
        names[StageCatalog.title(stage_number)] = true
        biomes[spec["biome"]] = true

        if not _check(float(spec["min_length"]) >= 700.0, "Stage %d is not a long-form stage" % stage_number):
            return
        if not _check(float(spec["max_length"]) >= float(spec["min_length"]), "Stage %d length range invalid" % stage_number):
            return
        if not _check(not spec["signature_segments"].is_empty(), "Stage %d lacks mockup signature segments" % stage_number):
            return
        if not _check(not spec["enemy_pool"].is_empty(), "Stage %d lacks enemy pool" % stage_number):
            return

        for difficulty in range(3):
            var seed := 424242 + stage_number * 100
            var plan := PlanGenerator.generate(stage_number, difficulty, seed)
            var repeat := PlanGenerator.generate(stage_number, difficulty, seed)
            total_plans += 1

            if not _check(PlanGenerator.signature(plan) == PlanGenerator.signature(repeat), "Stage %d difficulty %d is not deterministic" % [stage_number, difficulty]):
                return
            if not _check(plan["segments"].front()["id"] == "start", "Stage %d does not start correctly" % stage_number):
                return
            if not _check(plan["segments"][-1]["id"] == "finish", "Stage %d does not finish correctly" % stage_number):
                return
            if not _check(float(plan["total_length"]) >= float(spec["min_length"]) - 30.0, "Stage %d generated too short" % stage_number):
                return
            if not _check(float(plan["total_length"]) <= float(spec["max_length"]) + 80.0, "Stage %d generated too long" % stage_number):
                return

            for signature_segment in spec["signature_segments"]:
                var found := false
                for segment: Dictionary in plan["segments"]:
                    if segment["id"] == signature_segment:
                        found = true
                        break
                if not _check(found, "Stage %d lost signature segment %s" % [stage_number, signature_segment]):
                    return

            if difficulty == 1:
                stage_signatures[PlanGenerator.signature(plan)] = true

    if not _check(names.size() == 10, "Stage names are not unique"):
        return
    if not _check(biomes.size() == 10, "Biome identities are not unique"):
        return
    if not _check(stage_signatures.size() == 10, "Normal difficulty layouts do not differ across stages"):
        return
    if not _check(total_plans == 30, "Expected all 30 stage/difficulty plans"):
        return

    var easy := DifficultyProfiles.get_profile(0)
    var normal := DifficultyProfiles.get_profile(1)
    var hard := DifficultyProfiles.get_profile(2)
    if not _check(float(easy["enemy_count_multiplier"]) < float(normal["enemy_count_multiplier"]), "Easy enemy density is not lower"):
        return
    if not _check(float(hard["enemy_count_multiplier"]) > float(normal["enemy_count_multiplier"]), "Hard enemy density is not higher"):
        return
    if not _check(float(easy["checkpoint_interval"]) < float(normal["checkpoint_interval"]) and float(normal["checkpoint_interval"]) < float(hard["checkpoint_interval"]), "Checkpoint spacing does not scale with difficulty"):
        return

    print("GENERATOR_REBUILD_SMOKE_OK: 10 mockup biomes, 30 deterministic long-stage plans, 3 difficulties, signature segments and unique layouts")
    quit(0)
