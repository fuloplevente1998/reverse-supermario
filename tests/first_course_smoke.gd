extends SceneTree

func _initialize() -> void:
    call_deferred("_verify")

func _check(ok: bool, message: String) -> bool:
    if not ok:
        push_error(message)
        quit(1)
    return ok

func _verify() -> void:
    for difficulty in range(3):
        if not await _verify_difficulty(difficulty):
            return
    print("FIRST_COURSE_SMOKE_OK: all three 700-800m Stage 1 difficulty routes physically traversed, including bridge landings and checkpoint recovery")
    quit(0)

func _verify_difficulty(difficulty: int) -> bool:
    root.size = Vector2i(1280, 720)
    var progress := ConfigFile.new()
    progress.set_value("progress", "difficulty", difficulty)
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

    if not _check(stage.side_view and rig.side_view, "First stage must start in side view"): return false
    if not _check(bool(stage.get_meta("generator_rebuild", false)), "Stage 1 is not using the generator rebuild"): return false
    if not _check(course_length >= 700.0 and course_length <= 800.0, "Generated Stage 1 must stay in the 700-800m target: %s" % course_length): return false
    if not _check(course_end > 685.0, "Generated Stage 1 end is too close: %s" % course_end): return false
    if not _check(checkpoints.size() >= [5, 4, 3][difficulty], "Long Stage 1 needs at least four checkpoints"): return false
    if not _check(gaps.size() >= 1, "Generated Stage 1 needs at least one real gap"): return false

    var plan: Dictionary = stage.get_meta("stage_plan")
    var ids := {}
    for segment: Dictionary in plan["segments"]:
        ids[str(segment["id"])] = true
    for required in ["fountain_court", "tower", "bridge", "gate_approach", "mini_boss", "finish"]:
        if not _check(ids.has(required), "Stage 1 lost required segment: %s" % required): return false

    var floor_screen: Vector2 = rig.camera.unproject_position(Vector3(0, 0, -10))
    if not _check(floor_screen.y / 720.0 > 0.70 and floor_screen.y / 720.0 < 0.82, "Ground is not in the lower part of the screen"): return false
    var player_screen: Vector2 = rig.camera.unproject_position(player.position)
    if not _check(player_screen.x / 1280.0 > 0.25 and player_screen.x / 1280.0 < 0.42, "Camera must show more of the route ahead"): return false

    var yard: Node = stage.get_node_or_null("CourtyardEnvironmentVisual")
    if yard:
        for mesh: MeshInstance3D in yard.find_children("*", "MeshInstance3D", true, false):
            if not _check(mesh.layers == 2, "Near-side 3D scenery leaks into side camera"): return false

    var actors: Array[RID] = [player.get_rid()]
    for enemy in get_nodes_in_group("enemies"):
        actors.append(enemy.get_rid())

    # Real gaps must have no invisible floor at their center.
    for gap_value in gaps:
        var gap: Vector2 = gap_value
        var z := (gap.x + gap.y) * 0.5
        var query := PhysicsRayQueryParameters3D.create(Vector3(0, 8, z), Vector3(0, -9, z))
        query.exclude = actors
        if not _check(stage.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "Generated gap has an invisible floor at %s" % z): return false

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
        # A raised stair face requires a real jump as well as the marked pits.
        if player.is_on_floor() and player.position.z > -5.0 and absf(player.velocity.z) < 0.5:
            player.touch_jump = true

        for gap_value in gaps:
            var gap: Vector2 = gap_value
            if player.position.z >= gap.x - 3.1 and player.position.z <= gap.x + 0.35 and player.is_on_floor():
                player.touch_jump = true
                break

        await physics_frame

        if not _check(absf(player.position.x) < 0.001, "Player left the gameplay plane"): return false
        if not _check(player.position.z >= farthest - 12.0, "Traversal fell and respawned unexpectedly near %s" % farthest): return false
        farthest = maxf(farthest, player.position.z)

        if player.position.z > -1 and player.position.z < 5:
            if not _check(absf(rig.global_position.y - camera_y) < 0.20, "Camera bobs with a normal jump"): return false

        if stage.ended:
            reached = true
            break

    if not reached:
        print("TRAVERSAL_STUCK: position=%s velocity=%s on_floor=%s ground=%s" % [player.position, player.velocity, player.is_on_floor(), stage.side_ground_height(player.position.z)])
        for segment: Dictionary in plan["segments"]:
            if player.position.z >= float(segment["start"]) - 15 and player.position.z <= float(segment["end"]) - 15:
                print("TRAVERSAL_SEGMENT: ", segment)
    if not _check(reached and farthest > course_end - 12.0, "Full 700-800m traversal did not reach the gate: %s / %s" % [farthest, course_end]): return false
    if not _check(stage.checkpoint_position.z > course_end * 0.60, "Late checkpoints were not activated"): return false

    # Pit recovery must use the latest generated checkpoint.
    stage.ended = false
    var health: int = player.hp
    player.position = Vector3(0, -8.0, stage.checkpoint_position.z + 5.0)
    stage._physics_process(0.016)
    if not _check(player.position.is_equal_approx(stage.checkpoint_position) and player.hp < health, "Generated pit recovery failed"): return false

    print("Stage 1 difficulty %d physical traversal OK: %.1fm, %d gaps, %d checkpoints" % [difficulty, course_length, gaps.size(), checkpoints.size()])
    stage.queue_free()
    await process_frame
    return true
