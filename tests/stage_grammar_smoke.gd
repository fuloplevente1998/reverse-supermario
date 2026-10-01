extends SceneTree

const StageCatalog = preload("res://scripts/generation/stage_catalog.gd")
const PlanGenerator = preload("res://scripts/generation/stage_plan_generator.gd")
const SegmentCatalog = preload("res://scripts/generation/segment_catalog.gd")

const BRIDGE_LIKE := ["bridge", "rope_bridge", "stone_bridge", "ice_bridge", "bone_bridge", "broken_bridge", "chain_crossing", "siege_bridge"]
const BIG_COMBAT := ["combat_large", "archer_ambush", "farmyard", "siege_approach", "crypt_hall", "forest_ambush", "palisade_gate", "fortress_approach", "grand_gate", "final_courtyard", "citadel_approach"]
const SAFE_RECOVERY := ["traversal", "vista", "tower", "gate"]

func _initialize() -> void:
    call_deferred("_verify")

func _check(condition: bool, message: String) -> bool:
    if not condition:
        push_error(message)
        quit(1)
        return false
    return true

func _safe(segment: Dictionary) -> bool:
    var id := str(segment["id"])
    return (id in SAFE_RECOVERY or str(segment["kind"]) == "vista" or id == "gate_approach") and id not in BRIDGE_LIKE

func _verify() -> void:
    var stage1_signatures: Array[String] = []

    for stage_number in range(1, 11):
        var spec: Dictionary = StageCatalog.get_stage(stage_number)
        for difficulty in range(3):
            var plan: Dictionary = PlanGenerator.generate(stage_number, difficulty)
            var total_length := float(plan["total_length"])
            if not _check(total_length >= float(spec["min_length"]) and total_length <= float(spec["max_length"]), "Stage %d difficulty %d length escaped target: %.2f" % [stage_number, difficulty, total_length]):
                return

            if stage_number == 1:
                stage1_signatures.append(PlanGenerator.signature(plan))

            var segments: Array = plan["segments"]
            for i in range(1, segments.size()):
                var previous: Dictionary = segments[i - 1]
                var current: Dictionary = segments[i]
                var previous_id := str(previous["id"])
                var current_id := str(current["id"])
                var previous_kind := str(previous["kind"])
                var current_kind := str(current["kind"])
                var progress := float(current["start"]) / maxf(total_length, 1.0)

                if previous_kind == "hazard" and current_kind == "hazard":
                    if not _check(false, "Consecutive hazards at stage %d difficulty %d" % [stage_number, difficulty]):
                        return

                if previous_id in BRIDGE_LIKE and current_id in BRIDGE_LIKE:
                    if not _check(false, "Consecutive bridges at stage %d difficulty %d" % [stage_number, difficulty]):
                        return

                if previous_id in BIG_COMBAT and current_id in BIG_COMBAT:
                    if not _check(false, "Consecutive major combats at stage %d difficulty %d" % [stage_number, difficulty]):
                        return

                if current_id == "checkpoint":
                    if not _check(_safe(previous), "Checkpoint has no safe approach"):
                        return
                if current_id == "mini_boss":
                    if not _check(_safe(previous) and float(previous["length"]) >= 38.0, "Mini-boss lacks a full safe approach"):
                        return
                if previous_id == "checkpoint":
                    if not _check(_safe(current), "Checkpoint lacks safe recovery at stage %d difficulty %d" % [stage_number, difficulty]):
                        return

                var requires_recovery := previous_kind == "hazard" or previous_id in BRIDGE_LIKE or previous_id in BIG_COMBAT
                var hard_archer_exception := difficulty == 2 and progress > 0.55 and current_id == "archer_ambush" and previous_kind != "combat"
                if requires_recovery and not hard_archer_exception:
                    if not _check(_safe(current), "Unsafe segment order %s -> %s at stage %d difficulty %d" % [previous_id, current_id, stage_number, difficulty]):
                        return

            for signature_segment in spec["signature_segments"]:
                var found := false
                for segment: Dictionary in segments:
                    if str(segment["id"]) == str(signature_segment):
                        found = true
                        break
                if not _check(found, "Stage %d lost signature segment %s" % [stage_number, signature_segment]):
                    return

    var checked_seeds := 0
    for stage_number in range(1, 11):
        var spec: Dictionary = StageCatalog.get_stage(stage_number)
        for difficulty in range(3):
            for seed_index in range(64):
                var plan: Dictionary = PlanGenerator.generate(stage_number, difficulty, 424242 + seed_index * 7919 + stage_number * 100)
                checked_seeds += 1
                if not _check(is_equal_approx(float(plan["total_length"]), float(plan["target_length"])), "Seed sweep changed requested course length"):
                    return
                var cursor := 0.0
                var ids := {}
                var checkpoint_count := 0
                var segments: Array = plan["segments"]
                for i in range(segments.size()):
                    var segment: Dictionary = segments[i]
                    var id := str(segment["id"])
                    ids[id] = true
                    if not _check(is_equal_approx(cursor, float(segment["start"])) and float(segment["length"]) > 0.0, "Generated segments overlap or leave a hole"):
                        return
                    cursor = float(segment["end"])
                    if id in spec["signature_segments"]:
                        if not _check(is_equal_approx(float(segment["length"]), SegmentCatalog.length(id)), "A landmark was shortened to fit"):
                            return
                    if i > 0:
                        var previous: Dictionary = segments[i - 1]
                        if id == "checkpoint":
                            checkpoint_count += 1
                            if not _check(_safe(previous) and i + 1 < segments.size() and _safe(segments[i + 1]), "Unsafe checkpoint in seed sweep"):
                                return
                        if id == "mini_boss":
                            if not _check(_safe(previous) and float(previous["length"]) >= 38.0, "Unsafe boss approach in seed sweep"):
                                return
                        if (str(previous["kind"]) == "hazard" or str(previous["id"]) in BRIDGE_LIKE or str(previous["id"]) in BIG_COMBAT) and not _safe(segment):
                            if not _check(false, "Missing recovery in seed sweep"):
                                return
                for required in spec["signature_segments"]:
                    if not _check(ids.has(str(required)), "Seed sweep lost landmark %s" % required):
                        return
                if stage_number == 1:
                    if not _check(checkpoint_count >= [5, 4, 3][difficulty], "Stage 1 seed lost difficulty-scaled checkpoints"):
                        return

    if not _check(stage1_signatures.size() == 3, "Missing Stage 1 difficulty layouts"):
        return
    if not _check(stage1_signatures[0] != stage1_signatures[1] and stage1_signatures[1] != stage1_signatures[2] and stage1_signatures[0] != stage1_signatures[2], "Stage 1 geometry should be difficulty-aware"):
        return

    print("STAGE_GRAMMAR_SMOKE_OK: 30 default layouts plus %d seeded plans retain full landmarks, safe checkpoints and boss approaches" % checked_seeds)
    quit(0)
