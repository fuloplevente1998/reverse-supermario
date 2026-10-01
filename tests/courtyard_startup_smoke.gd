extends SceneTree

func _initialize() -> void:
    call_deferred("_verify")

func _check(ok: bool, message: String) -> bool:
    if not ok:
        push_error(message)
        quit(1)
    return ok

func _verify() -> void:
    var stage = load("res://scenes/main.tscn").instantiate()
    root.add_child(stage)
    await physics_frame
    if not _check(stage.get_node_or_null("CourtyardEnvironmentVisual") == null, "Startup loaded the unused 3D yard"): return
    if not _check(is_equal_approx(stage.player.move_speed, 5.4) and is_equal_approx(stage.player.jump_velocity, 6.4), "Requested movement tuning was not applied"): return
    var streamer = stage.get_node("LongStageStreamer")
    var total: int = streamer.actors.size()
    var opening_count: int = streamer.active_actor_count
    if not _check(streamer.active_actor_count > 0 and streamer.active_actor_count < total, "Startup processes every long-stage actor"): return
    var far_actor: Node3D
    for actor: Node3D in streamer.actors:
        if actor.position.z > 300.0:
            far_actor = actor
            break
    if not _check(far_actor != null and far_actor.process_mode == Node.PROCESS_MODE_DISABLED and not far_actor.visible, "Far rig animation and physics remain active"): return
    stage.player.set_physics_process(false)
    stage.player.position.z = far_actor.position.z - 10.0
    streamer._refresh(true)
    if not _check(far_actor.process_mode == Node.PROCESS_MODE_INHERIT and far_actor.visible, "Streamed actor failed to reactivate"): return
    stage.player.camera_pivot.set_view(false)
    var yard: Node3D = stage.get_node("CourtyardEnvironmentVisual")
    var child_count: int = stage.get_child_count()
    if not _check(yard.visible, "Requested 3D view did not load its yard"): return
    stage.player.camera_pivot.set_view(true)
    stage.player.camera_pivot.set_view(false)
    if not _check(stage.get_child_count() == child_count, "Camera toggling duplicates legacy scenery"): return
    stage.player.camera_pivot.set_view(true)
    if not _check(not yard.visible, "Legacy yard kept shadow/render work in side view"): return
    print("COURTYARD_STARTUP_SMOKE_OK: %.0fms local construction, %d/%d opening actors active, lazy 3D yard, reversible streaming and tuned movement" % [float(stage.get_meta("stage_build_ms")),opening_count,total])
    stage.queue_free()
    await process_frame
    quit(0)
