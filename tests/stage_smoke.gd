extends SceneTree

func _initialize() -> void:
    call_deferred("_verify")

func _check(condition: bool, message: String) -> bool:
    if not condition:
        push_error(message)
        quit(1)
    return condition

func _verify() -> void:
    var progress := ConfigFile.new()
    progress.set_value("progress", "unlocked_stage", 1)
    progress.set_value("progress", "difficulty", 1)
    progress.save("user://reverse_platformer_progress.cfg")
    var title = load("res://scenes/title.tscn").instantiate()
    root.add_child(title)
    await process_frame
    if not _check(title.stage_panel.get_node("Stage2").disabled, "Title exposes a locked stage"):
        return
    title.queue_free()
    await process_frame
    var kinds := {}
    var layouts := {}
    var easy_counts := {}
    for difficulty in range(3):
        progress.set_value("progress", "difficulty", difficulty)
        progress.save("user://reverse_platformer_progress.cfg")
        for number in range(1, 11):
            var path := "res://scenes/main.tscn" if number == 1 else "res://scenes/stage%d.tscn" % number
            var stage = load(path).instantiate()
            root.add_child(stage)
            await process_frame
            await physics_frame
            await process_frame
            var joystick = stage.get_node("UI/Controls/Joystick")
            var rect: Rect2 = joystick.get_global_rect()
            if not _check(rect.size.is_equal_approx(Vector2(186, 186)) and rect.position.x < 40, "Compact joystick stretched or moved away from the left edge"):
                return
            if number == 1 and difficulty == 0:
                for dimensions in [Vector2i(1280,720), Vector2i(1600,720), Vector2i(1536,691)]:
                    root.size = dimensions
                    await process_frame
                    await process_frame
                    rect = joystick.get_global_rect()
                    var viewport_size: Vector2 = root.get_visible_rect().size
                    if not _check(rect.size.x == 186 and rect.end.x < viewport_size.x * 0.25 and rect.get_center().y > viewport_size.y * 0.65 and rect.end.y < viewport_size.y, "Joystick layout fails at %s" % dimensions):
                        return
                root.size = Vector2i(1280,720)
                await process_frame
                var press := InputEventScreenTouch.new()
                press.index = 3
                press.pressed = true
                press.position = joystick.size * 0.5 + Vector2(70,0)
                joystick._gui_input(press)
                if not _check(stage.player.touch_axis.x > 0.5, "Joystick does not control player"):
                    return
                press.pressed = false
                joystick._input(press)
                if not _check(stage.player.touch_axis == Vector2.ZERO, "Joystick sticks after finger release"):
                    return
                stage._open_stage_panel()
                if not _check(paused and not stage.player.can_process(), "Level selector does not pause gameplay"):
                    return
                stage._close_stage_panel()
            if not _check(stage.player.hp == [120,100,80][difficulty], "Difficulty health is wrong"):
                return
            if not _check(stage.get_node_or_null("Checkpoint") != null, "Checkpoint missing"):
                return
            # Verify physical outer walls using ray hits, not just node names.
            var rays := [Vector3(-30,8,15), Vector3(30,8,15), Vector3(0,8,-25), Vector3(0,8,55)]
            var names := ["BoundaryWest","BoundaryEast","BoundaryRear","BoundaryFront"]
            for i in range(4):
                var query := PhysicsRayQueryParameters3D.create(Vector3(0,8,15), rays[i])
                var hit: Dictionary = stage.get_world_3d().direct_space_state.intersect_ray(query)
                if not _check(not hit.is_empty() and str(hit["collider"].name) == names[i], "Outer collision missing at stage %d" % number):
                    return
            for enemy in get_nodes_in_group("enemies"):
                kinds[enemy.archetype] = true
            if difficulty == 0:
                easy_counts[number] = stage.enemies_total
                var signature := ""
                for child in stage.get_children():
                    if child is StaticBody3D or child is AnimatableBody3D:
                        signature += str(child.position) + str(child.get_class())
                layouts[signature] = true
            elif not _check(stage.enemies_total == int(easy_counts[number]) + difficulty, "Difficulty did not change encounters"):
                return
            if number == 2 and difficulty == 1:
                stage.player.global_position = Vector3(0,-8,15)
                stage._physics_process(0.016)
                if not _check(stage.player.hp == 75 and stage.player.global_position.y > 0, "Pit recovery failed"):
                    return
            if number == 10:
                stage._on_goal_body_entered(stage.player)
                if not _check(not stage.ended, "Captain can be skipped"):
                    return
                stage.get_node("Captain").take_damage(10000)
            stage._on_goal_body_entered(stage.player)
            if not _check(stage.ended and (number == 10 or stage._is_stage_unlocked(number+1)), "Level progression failed"):
                return
            stage.queue_free()
            await process_frame
    if not _check(layouts.size() == 10 and kinds.size() == 5, "Expected ten layouts and five enemy types"):
        return
    if not await _verify_combat():
        return
    print("PASS: 30 stage/difficulty combinations, five enemies, outer physics, joystick aspect ratios, pause, captain gate, projectile damage and timed traps")
    quit(0)


func _verify_combat() -> bool:
    var stage = load("res://scenes/main.tscn").instantiate()
    root.add_child(stage)
    await process_frame
    await physics_frame
    stage.player.set_physics_process(false)
    for enemy in get_nodes_in_group("enemies"):
        enemy.set_physics_process(false)
    var shooter: Node = get_nodes_in_group("enemies")[0]
    for blocked in [false, true]:
        stage.player.blocking = blocked
        var before: int = stage.player.hp
        var shot = load("res://scripts/projectile.gd").new()
        shot.owner_rid = shooter.get_rid()
        shot.damage = 10
        shot.speed = 120
        shot.direction = Vector3(0,0,1)
        stage.add_child(shot)
        shot.global_position = stage.player.global_position + Vector3(0,0,-3)
        for frame in range(5):
            await physics_frame
        if not _check(stage.player.hp == before - (3 if blocked else 10), "Projectile collision or blocking failed"):
            return false
    stage.player.blocking = false
    var trap = load("res://scripts/stage_hazard.gd").new()
    trap.damage = 20
    trap.period = 100.0
    trap.position = stage.player.position - Vector3(0,0.6,0)
    stage.add_child(trap)
    var before_trap: int = stage.player.hp
    for frame in range(3):
        await physics_frame
    if not _check(stage.player.hp == before_trap, "Inactive trap damages player"):
        return false
    trap.elapsed = 60.0
    for frame in range(3):
        await physics_frame
    if not _check(stage.player.hp == before_trap - 20, "Active trap does not damage player or repeats every frame"):
        return false
    stage.queue_free()
    await process_frame
    return true
