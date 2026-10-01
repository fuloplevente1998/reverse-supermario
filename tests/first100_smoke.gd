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
        var progress := ConfigFile.new()
        progress.set_value("progress", "difficulty", difficulty)
        progress.save("user://reverse_platformer_progress.cfg")
        var stage = load("res://scenes/main.tscn").instantiate()
        root.add_child(stage)
        for i in range(4): await physics_frame
        var groups := get_nodes_in_group("first100_obstacles")
        var types := {}
        if not _check(groups.size() >= 5, "First 100m still has too few physical challenge groups"): return
        for group: Node3D in groups:
            types[group.get_meta("kind")] = true
            if not _check(float(group.get_meta("course_z")) >= -15.0 and float(group.get_meta("course_z")) < 85.0, "Obstacle outside sample range"): return
            if not _check(float(group.get_meta("jump_height")) < 1.6, "Sample jump exceeds readable introductory height"): return
            for body: StaticBody3D in group.get_children():
                var shape := body.get_child(0) as CollisionShape3D
                if not _check(shape != null and not shape.disabled and body.collision_layer == 1, "Obstacle is only cosmetic"): return
                var visuals := body.find_children("*", "MeshInstance3D", true, false)
                if not _check(not visuals.is_empty(), "Collider has no corresponding visible asset"): return
                for visual: MeshInstance3D in visuals:
                    var material := visual.get_active_material(0) as StandardMaterial3D
                    if not _check(material != null and material.albedo_texture != null, "Sample reverted to untextured placeholders"): return
        if not _check(types.size() >= 4, "Sample just repeats one kind of obstacle"): return
        var root_course: Node3D = stage.get_node("GeneratedLongStage")
        for segment: Node3D in root_course.get_children():
            if bool(segment.get_meta("safe_recovery", false)) or bool(segment.get_meta("boss_approach", false)):
                if not _check(segment.find_children("First100Obstacle*", "Node3D", false, false).is_empty(), "Obstacle added to a protected recovery"): return
        var player = stage.player
        for enemy in get_nodes_in_group("enemies"):
            enemy.set_physics_process(false)
            enemy.collision_layer = 0
            enemy.collision_mask = 0
        for hazard in get_nodes_in_group("hazards"):
            hazard.set_physics_process(false)
            hazard.collision_layer = 0
            hazard.collision_mask = 0
        player.position = Vector3(0,1.1,-10)
        player.velocity = Vector3.ZERO
        player.touch_jump = false
        for frame in range(150):
            player.touch_axis = Vector2(1,0)
            await physics_frame
        if not _check(player.position.z > -2.0 and player.position.z < -0.4 and player.is_on_floor(), "Walking without jumping passed through the opening crate"): return
        player.touch_jump = true
        for frame in range(110):
            player.touch_axis = Vector2(1,0)
            await physics_frame
        if not _check(player.position.z > 5.0 and player.is_on_floor(), "Real player jump cannot clear the first physical obstacle"): return
        if difficulty < 2:
            var exclude: Array[RID] = [player.get_rid()]
            var query := PhysicsRayQueryParameters3D.create(Vector3(0,8,78.2),Vector3(0,-9,78.2))
            query.exclude = exclude
            if not _check(stage.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "Sample pit contains a hidden floor"): return
        print("First100 difficulty %d OK: %d physical groups, %d types; walking blocked, real jump clears crate" % [difficulty,groups.size(),types.size()])
        stage.queue_free()
        await process_frame
    print("FIRST100_SMOKE_OK: CC0 textured assets, physical obstacle variety, difficulty recovery, real collision and jump")
    quit(0)
