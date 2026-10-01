extends SceneTree

func _initialize() -> void:
    call_deferred("_verify")

func _check(ok: bool, message: String) -> bool:
    if not ok:
        push_error(message)
        quit(1)
    return ok

func _verify() -> void:
    root.size = Vector2i(1280, 720)
    var progress := ConfigFile.new()
    progress.set_value("progress", "difficulty", 1)
    progress.save("user://reverse_platformer_progress.cfg")

    var stage = load("res://scenes/main.tscn").instantiate()
    root.add_child(stage)
    for i in range(4):
        await physics_frame

    var player = stage.player
    var rig = player.camera_pivot
    var course_length := float(stage.get_meta("side_course_length", 0.0))
    var course_end := float(stage.get_meta("side_course_end_z", 0.0))
    var gaps: Array = stage.get_meta("side_course_gaps", [])
    var checkpoints := get_nodes_in_group("course_checkpoints")

    if not _check(stage.side_view and rig.side_view, "First stage must start in side view"): return
    if not _check(bool(stage.get_meta("generator_rebuild", false)), "Stage 1 is not using the generator rebuild"): return
    if not _check(course_length >= 700.0 and course_length <= 800.0, "Generated Stage 1 must stay in the 700-800m target: %s" % course_length): return
    if not _check(course_end > 685.0, "Generated Stage 1 end is too close: %s" % course_end): return
    if not _check(checkpoints.size() >= 4, "Long Stage 1 needs at least four checkpoints"): return
    if not _check(gaps.size() >= 1, "Generated Stage 1 needs at least one real gap"): return

    var plan: Dictionary = stage.get_meta("stage_plan")
    var ids := {}
    for segment: Dictionary in plan["segments"]:
        ids[str(segment["id"])] = true
    for required in ["fountain_court", "tower", "bridge", "gate_approach", "mini_boss", "finish"]:
        if not _check(ids.has(required), "Stage 1 lost required segment: %s" % required): return

    var floor_screen: Vector2 = rig.camera.unproject_position(Vector3(0, 0, -10))
    if not _check(floor_screen.y / 720.0 > 0.70 and floor_screen.y / 720.0 < 0.82, "Ground is not in the lower part of the screen"): return
    var player_screen: Vector2 = rig.camera.unproject_position(player.position)
    if not _check(player_screen.x / 1280.0 > 0.25 and player_screen.x / 1280.0 < 0.42, "Camera must show more of the route ahead"): return

    var yard := stage.get_node_or_null("CourtyardEnvironmentVisual")
    if yard:
        for mesh: MeshInstance3D in yard.find_children("*", "MeshInstance3D", true, false):
            if not _check(mesh.layers == 2, "Near-side 3D scenery leaks into side camera"): return

    var actors: Array[RID] = [player.get_rid()]
    for enemy in get_nodes_in_group("enemies"):
        actors.append(enemy.get_rid())

    # Real gaps must have no invisible floor at their center.
    for gap_value in gaps:
        var gap: Vector2 = gap_value
        var z := (gap.x + gap.y) * 0.5
        var query := PhysicsRayQueryParameters3D.create(Vector3(0, 8, z), Vector3(0, -9, z))
        query.exclude = actors
        if not _check(stage.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "Generated gap has an invisible floor at %s" % z): return

    # Disable combat/trap damage so this is a pure physical traversal test.
    for enemy in get_nodes_in_group("enemies"):
        enemy.set_physics_process(false)
        enemy.collision_layer = 0
        enemy.collision_mask = 0
    for hazard in get_nodes_in_group("hazards"):
        hazard.set_physics_process(false)
        hazard.collision_layer = 0
        hazard.collision_mask = 0

    player.position = Vector3(0, 1.1, -10)
    player.velocity = Vector3.ZERO
    var farthest := -10.0
    var reached := false
    var camera_y: float = rig.global_position.y

    for frame in range(11000):
        player.touch_axis = Vector2(1, 0)

        for gap_value in gaps:
            var gap: Vector2 = gap_value
            if player.position.z >= gap.x - 3.1 and player.position.z <= gap.x + 0.35 and player.is_on_floor():
                player.touch_jump = true
                break

        await physics_frame

        if not _check(absf(player.position.x) < 0.001, "Player left the gameplay plane"): return
        if not _check(player.position.z >= farthest - 12.0, "Traversal fell and respawned unexpectedly near %s" % farthest): return
        farthest = maxf(farthest, player.position.z)

        if player.position.z > -1 and player.position.z < 5:
            if not _check(absf(rig.global_position.y - camera_y) < 0.20, "Camera bobs with a normal jump"): return

        if stage.ended:
            reached = true
            break

    if not _check(reached and farthest > course_end - 12.0, "Full 700-800m traversal did not reach the gate: %s / %s" % [farthest, course_end]): return
    if not _check(stage.checkpoint_position.z > course_end * 0.60, "Late checkpoints were not activated"): return

    # Pit recovery must use the latest generated checkpoint.
    stage.ended = false
    var health: int = player.hp
    player.position = Vector3(0, -8.0, stage.checkpoint_position.z + 5.0)
    stage._physics_process(0.016)
    if not _check(player.position.is_equal_approx(stage.checkpoint_position) and player.hp < health, "Generated pit recovery failed"): return

    print("FIRST_COURSE_SMOKE_OK: generated 700-800m Stage 1, grammar landmarks, real gaps, checkpoints, streaming-ready geometry and full physical traversal")
    stage.queue_free()
    await process_frame
    quit(0)
