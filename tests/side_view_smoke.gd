extends SceneTree

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    for number in range(1,11):
        var path := "res://scenes/main.tscn" if number==1 else "res://scenes/stage%d.tscn" % number
        var stage=load(path).instantiate()
        root.add_child(stage)
        await process_frame
        await physics_frame
        var player=stage.get_node("Player")
        player.set_physics_process(false)
        var enemies := get_nodes_in_group("enemies")
        var original_x: Array[float]=[]
        for enemy in enemies:
            enemy.set_physics_process(false)
            original_x.append(enemy.position.x)
        player.position=Vector3(4,0.93,-10)
        player.velocity=Vector3.ZERO
        var camera=player.get_node("CameraPivot")
        camera.set_view(false)
        player.position=Vector3(4,0.93,-10)
        camera.set_view(true)
        assert(player.position.x==0 and stage.side_view)
        assert(camera.camera.projection==Camera3D.PROJECTION_ORTHOGONAL)
        var screen_start: Vector2=camera.camera.unproject_position(player.global_position)
        var screen_forward: Vector2=camera.camera.unproject_position(player.global_position+Vector3(0,0,1))
        assert(screen_forward.x>screen_start.x, "Forward must appear to the right")
        player.touch_axis=Vector2(1,1)
        for i in range(20):
            player._physics_process(1.0/60)
            await physics_frame
        assert(player.position.z > -9.7 and absf(player.position.x)<0.001, "Side input must only move along Z")
        player.touch_axis=Vector2(0,1)
        for i in range(30):
            player._physics_process(1.0/60)
            await physics_frame
        var stopped_z: float=player.position.z
        for i in range(10):
            player._physics_process(1.0/60)
            await physics_frame
        assert(absf(player.position.z-stopped_z)<0.02, "Vertical joystick input must not move in side view")
        player.touch_axis=Vector2(-1,0)
        for i in range(25):
            player._physics_process(1.0/60)
            await physics_frame
        assert(player.position.z<stopped_z-0.3, "Left/back movement missing")
        player.touch_axis=Vector2.ZERO
        player.touch_jump=true
        for i in range(12):
            player._physics_process(1.0/60)
            await physics_frame
        assert(player.position.y>1.4 and absf(player.position.x)<0.001, "Jump must remain on the central plane")
        for group in ["enemies","hazards","moving_platforms"]:
            for actor in get_nodes_in_group(group):
                assert(absf(actor.position.x)<0.001, "Actor escaped center: "+group)
        for boundary in ["BoundaryWest","BoundaryEast","BoundaryRear","BoundaryFront"]:
            var body=stage.get_node(boundary)
            assert(body.get_child_count()==1 and body.get_child(0) is CollisionShape3D, "Boundary must be invisible")
        camera.toggle_view()
        assert(player.position.x==4 and not stage.side_view)
        assert(camera.camera.projection==Camera3D.PROJECTION_PERSPECTIVE)
        for index in range(enemies.size()):assert(enemies[index].position.x==original_x[index], "3D enemy placement lost")
        if number==1:
            # Probe the actual generated floor instead of a removed 240m-map barricade.
            player.position=Vector3(0,-0.2,-5)
            camera.toggle_view()
            assert(player.position.y>=0.92, "View switch placed player inside generated terrain")
        stage.queue_free()
        await process_frame
    print("SIDE_VIEW_SMOKE_OK: ten stages, forward/back only, centered actors, jump, orthographic camera, invisible bounds and safe view switching")
    quit(0)
