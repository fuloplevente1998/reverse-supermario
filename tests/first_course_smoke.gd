extends SceneTree

func _initialize() -> void:
    call_deferred("_verify")

func _check(ok: bool, message: String) -> bool:
    if not ok:
        push_error(message)
        quit(1)
    return ok

func _verify() -> void:
    root.size = Vector2i(1280,720)
    var stage = load("res://scenes/main.tscn").instantiate()
    root.add_child(stage)
    for i in range(3): await physics_frame
    var player = stage.player
    var rig = player.camera_pivot
    if not _check(stage.side_view and rig.side_view,"First stage must start in side view"): return
    if not _check(stage.get_meta("side_course_length")==240.0,"First course must be four times the former 60m"): return
    if not _check(get_nodes_in_group("course_checkpoints").size()==3,"Three safe checkpoints required"): return
    var floor_screen: Vector2 = rig.camera.unproject_position(Vector3(0,0,-10))
    if not _check(floor_screen.y/720.0>0.70 and floor_screen.y/720.0<0.82,"Ground is not in the lower part of the screen"): return
    var player_screen: Vector2 = rig.camera.unproject_position(player.position)
    if not _check(player_screen.x/1280.0>0.25 and player_screen.x/1280.0<0.42,"Camera must show more of the route ahead"): return
    for mesh: MeshInstance3D in stage.get_node("CourtyardEnvironmentVisual").find_children("*","MeshInstance3D",true,false):
        if not _check(mesh.layers==2,"Near-side 3D scenery leaks into side camera"): return
    var actors: Array[RID] = [player.get_rid()]
    for enemy in get_nodes_in_group("enemies"): actors.append(enemy.get_rid())
    for z in [-10.0,16.0,27.0,40.0,55.0,68.0,80.0,90.0,103.0,118.0,130.0,144.0,156.0,169.0,184.0,211.0]:
        var query := PhysicsRayQueryParameters3D.create(Vector3(0,8,z),Vector3(0,-9,z))
        query.exclude = actors
        var hit: Dictionary = stage.get_world_3d().direct_space_state.intersect_ray(query)
        if not _check(not hit.is_empty() and absf(hit.position.y-stage.side_ground_height(z))<0.05,"Bad terrain collision at %s" % z): return
    for gap: Vector2 in stage.get_meta("side_course_gaps"):
        var z := (gap.x+gap.y)*0.5
        var query := PhysicsRayQueryParameters3D.create(Vector3(0,8,z),Vector3(0,-9,z))
        query.exclude = actors
        if not _check(stage.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),"A gap has an invisible floor"): return
    for enemy in get_nodes_in_group("enemies"):
        enemy.set_physics_process(false)
        enemy.collision_layer = 0
        enemy.collision_mask = 0
    for hazard in get_nodes_in_group("hazards"):
        hazard.set_physics_process(false)
    # Test real movement over every slope and jump with the normal player physics.
    player.position = Vector3(0,1.1,-10)
    player.velocity = Vector3.ZERO
    var jump_points := [-3.0,22.0,43.5,62.5,91.5,105.0,134.5,171.5,193.0]
    var next_jump := 0
    var farthest := -10.0
    var reached := false
    var camera_y: float = rig.global_position.y
    for frame in range(3600):
        player.touch_axis = Vector2(1,0)
        if next_jump<jump_points.size() and player.position.z>=jump_points[next_jump] and player.is_on_floor():
            player.touch_jump = true
            next_jump += 1
        await physics_frame
        if not _check(absf(player.position.x)<0.001,"Player left the gameplay plane"): return
        if not _check(player.position.z>=farthest-8.0,"Traversal fell into a pit/water and respawned near %s" % farthest): return
        farthest = maxf(farthest,player.position.z)
        if player.position.z>-1 and player.position.z<5:
            if not _check(absf(rig.global_position.y-camera_y)<0.15,"Camera bobs with a normal jump"): return
        if stage.ended:
            reached = true
            break
    if not _check(reached and farthest>218.0,"Full course traversal did not reach the gate: %s" % farthest): return
    if not _check(stage.checkpoint_position.z==168.0,"Latest checkpoint was not activated"): return
    # Water and pit recovery must return to the checkpoint height, not y=1.1.
    stage.ended = false
    var health: int = player.hp
    player.position = Vector3(0,-2.0,97.0)
    for i in range(4): await physics_frame
    if not _check(player.position.is_equal_approx(stage.checkpoint_position) and player.hp<health,"Water recovery failed"): return
    print("FIRST_COURSE_SMOKE_OK: 240m, hills, slopes, valleys, four real gaps, water recovery, three checkpoints, clean camera and complete physical traversal")
    stage.queue_free()
    await process_frame
    quit(0)
