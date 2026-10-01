extends SceneTree

const PlanGenerator = preload("res://scripts/generation/stage_plan_generator.gd")
const RuntimeBuilder = preload("res://scripts/generation/runtime_stage_builder.gd")
const EncounterDirector = preload("res://scripts/generation/encounter_director.gd")
const SegmentStreamer = preload("res://scripts/generation/segment_streamer.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _check(condition: bool, message: String) -> bool:
    if not condition:
        push_error(message)
        quit(1)
        return false
    return true

func _verify() -> void:
    var world := Node3D.new()
    root.add_child(world)
    var plan := PlanGenerator.generate(1, 1, 20261001)
    var stage := RuntimeBuilder.build_blockout(world, plan, 8.0)

    var player := Node3D.new()
    player.name = "StreamingProbe"
    world.add_child(player)
    player.global_position = Vector3(0, 1, 20)

    var streamer := SegmentStreamer.new()
    world.add_child(streamer)
    streamer.configure(stage, player)
    await process_frame

    if not _check(streamer.get_active_count() > 0, "Streamer activated no segments"):
        return
    if not _check(streamer.get_active_count() < stage.get_child_count(), "Streamer kept the whole long stage active"):
        return

    var initial_active := streamer.get_active_count()
    player.global_position.z = float(plan["total_length"]) - 80.0
    streamer._refresh(true)
    if not _check(streamer.get_active_count() > 0, "Streamer lost the stage near the finish"):
        return
    if not _check(streamer.get_active_count() != initial_active or stage.get_child_count() < 4, "Streaming window did not move"):
        return

    var combat_segment: Dictionary = {}
    for segment: Dictionary in plan["segments"]:
        if str(segment["kind"]) == "combat":
            combat_segment = segment
            break
    if not _check(not combat_segment.is_empty(), "Stage 1 plan contains no combat segment"):
        return

    var easy := EncounterDirector.build_encounter(1, 0, combat_segment)
    var normal := EncounterDirector.build_encounter(1, 1, combat_segment)
    var hard := EncounterDirector.build_encounter(1, 2, combat_segment)
    if not _check(easy.size() <= normal.size() and normal.size() <= hard.size(), "Encounter density does not scale with difficulty"):
        return

    for entry: Dictionary in hard:
        if not _check(str(entry["legacy_archetype"]) in ["guard", "brute", "archer", "captain", "scout"], "Encounter has no migration-compatible enemy archetype"):
            return

    print("ENCOUNTER_STREAMING_SMOKE_OK: difficulty-scaled encounters and moving long-stage active window")
    quit(0)
