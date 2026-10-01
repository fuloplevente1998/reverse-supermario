extends SceneTree

const StageCatalog = preload("res://scripts/generation/stage_catalog.gd")
const PlanGenerator = preload("res://scripts/generation/stage_plan_generator.gd")
const RuntimeBuilder = preload("res://scripts/generation/runtime_stage_builder.gd")

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
    world.name = "RuntimeGeneratorTestWorld"
    root.add_child(world)

    var plan := PlanGenerator.generate(1, 1, 987654)
    var blockout := RuntimeBuilder.build_blockout(world, plan, 8.0)
    await process_frame
    await physics_frame

    if not _check(blockout.get_meta("temporary_blockout") == true, "Runtime builder did not mark temporary blockout"):
        return
    if not _check(float(blockout.get_meta("total_length")) >= 670.0, "Stage 1 runtime blockout is still short"):
        return
    if not _check(blockout.get_child_count() == plan["segments"].size(), "Runtime builder did not create one root per segment"):
        return

    var static_bodies := 0
    var checkpoints := 0
    var gates := 0
    var vistas := 0
    for segment_root in blockout.get_children():
        for child in segment_root.get_children():
            if child is StaticBody3D:
                static_bodies += 1
            if child.name == "CheckpointMarker":
                checkpoints += 1
            if str(child.name).begins_with("Gate"):
                gates += 1
            if child.name == "VistaAnchor":
                vistas += 1

    if not _check(static_bodies >= plan["segments"].size() - 3, "Long blockout lacks physical traversal geometry"):
        return
    if not _check(checkpoints >= 3, "Stage 1 long blockout lacks checkpoints"):
        return
    if not _check(gates >= 2, "Stage 1 blockout lacks gate composition markers"):
        return
    if not _check(vistas >= 2, "Stage 1 blockout lacks visual hero moments"):
        return

    var first := blockout.get_child(0)
    var last := blockout.get_child(blockout.get_child_count() - 1)
    if not _check(str(first.get_meta("segment_id")) == "start", "Runtime blockout does not start with start segment"):
        return
    if not _check(str(last.get_meta("segment_id")) == "finish", "Runtime blockout does not end with finish segment"):
        return

    print("RUNTIME_GENERATOR_SMOKE_OK: Stage 1 long blockout physical segments, checkpoints, gates and vista anchors")
    quit(0)
