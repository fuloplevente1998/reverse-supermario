extends SceneTree

func _initialize() -> void:
    call_deferred("_verify")

func _check(condition: bool, message: String) -> bool:
    if not condition:
        push_error(message)
        quit(1)
    return condition

func _verify() -> void:
    for difficulty in range(3):
        var progress := ConfigFile.new()
        progress.set_value("progress", "difficulty", difficulty)
        progress.save("user://reverse_platformer_progress.cfg")
        var stage = load("res://scenes/main.tscn").instantiate()
        root.add_child(stage)
        await physics_frame
        stage.player.set_physics_process(false)
        var exclude: Array[RID] = [stage.player.get_rid()]
        for enemy in get_nodes_in_group("enemies"):
            enemy.set_physics_process(false)
            exclude.append(enemy.get_rid())
        for hazard in get_nodes_in_group("hazards"):
            hazard.set_physics_process(false)
        var end_z := float(stage.get_meta("side_course_end_z"))
        var gaps: Array = stage.get_meta("side_course_gaps")
        var hurdles: Array = stage.get_meta("course_hurdles")
        if not _check(hurdles.size() >= 5, "Courtyard needs repeated physical obstacles beyond the opening"): return
        var streamer = stage.get_node("LongStageStreamer")
        streamer.configure(stage.get_node("GeneratedLongStage"), stage.player, 2000.0, 2000.0)
        await physics_frame
        for gap: Vector2 in gaps:
            var gap_z := (gap.x + gap.y) * 0.5
            var pit_query := PhysicsRayQueryParameters3D.create(Vector3(0, 6, gap_z), Vector3(0, -9, gap_z))
            pit_query.exclude = exclude
            if not _check(stage.get_world_3d().direct_space_state.intersect_ray(pit_query).is_empty(), "All streamed ground enabled: pit has a hidden floor at %.2f" % gap_z): return
        var sample_count := 0
        for segment in stage.get_node("GeneratedLongStage").get_children():
            var art: Node = segment.get_node("CourtyardCourseArt")
            var masonry := art.get_node("ReliefMasonry") as MultiMeshInstance3D
            var paving := art.get_node("WalkwayPaving") as MultiMeshInstance3D
            if not _check(bool(art.get_meta("authored_kit")), "Late route lost the authored art kit"): return
            if not _check(masonry.multimesh.instance_count > 0 and paving.multimesh.instance_count > 0, "Ground relief is missing on segment %s" % segment.name): return
            if not _check((paving.material_override as StandardMaterial3D).albedo_texture != null, "Long course paving has no texture"): return
            var safe := bool(segment.get_meta("safe_recovery", false)) or bool(segment.get_meta("boss_approach", false))
            for child in segment.get_children():
                if safe and str(child.name).begins_with("CourtyardHurdle"):
                    if not _check(false, "Jump obstacle added to safe recovery/boss approach"): return
        # Compare terrain queries used by the camera/spawns with actual collision.
        # Avoid obstacle tops and pit edges where the expected height is different.
        var z := 28.0
        while z < end_z - 3.0:
            var skip := false
            for gap: Vector2 in gaps:
                if z >= gap.x - 0.7 and z <= gap.y + 0.7:
                    skip = true
            for hurdle: float in hurdles:
                if absf(z - hurdle) < 1.3:
                    skip = true
            if not skip:
                var expected: float = stage.side_ground_height(z)
                var query := PhysicsRayQueryParameters3D.create(Vector3(0, expected + 5, z), Vector3(0, expected - 5, z))
                query.exclude = exclude
                var hit: Dictionary = stage.get_world_3d().direct_space_state.intersect_ray(query)
                if not _check(not hit.is_empty(), "Missing physical ground at %.2f" % z): return
                if not _check(absf(hit.position.y - expected) < 0.07, "Camera/spawn terrain height disagrees with collision at %.2f" % z): return
                sample_count += 1
            z += 7.3
        # Every third must contain real changes in elevation, including the finish.
        for third in range(3):
            var low := INF
            var high := -INF
            var begin := -15.0 + (end_z + 15.0) * third / 3.0
            var end := -15.0 + (end_z + 15.0) * (third + 1) / 3.0
            z = begin
            while z <= end:
                var height: float = stage.side_ground_height(z)
                low = minf(low, height)
                high = maxf(high, height)
                z += 1.0
            if not _check(high - low >= 0.75, "Course third %d is still a flat line" % third): return
        # Verify late art is really visible after streaming follows the player.
        stage.player.position = Vector3(0, 1.1, end_z * 0.85)
        streamer.configure(stage.get_node("GeneratedLongStage"), stage.player, 100.0, 240.0)
        var active_late := 0
        for segment in stage.get_node("GeneratedLongStage").get_children():
            if segment.position.z > end_z * 0.7 and segment.is_visible_in_tree():
                active_late += 1
        if not _check(active_late > 0, "Streaming hides the last third's scenery"): return
        print("Courtyard coverage difficulty %d OK: %d hurdles, %d collision samples, decorated start/middle/end" % [difficulty, hurdles.size(), sample_count])
        stage.queue_free()
        await process_frame
    print("COURTYARD_COVERAGE_SMOKE_OK: textured authored ground across the full course, non-flat thirds, terrain/collision agreement and safe recovery")
    quit(0)
