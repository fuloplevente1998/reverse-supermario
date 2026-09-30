extends SceneTree

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size=Vector2i(1280,720)
    for number in [1,2,4,5,6,10]:
        var path := "res://scenes/main.tscn" if number==1 else "res://scenes/stage%d.tscn" % number
        var stage=load(path).instantiate()
        root.add_child(stage)
        for i in range(20):await physics_frame
        var player=stage.get_node("Player")
        player.set_physics_process(false)
        for enemy in get_nodes_in_group("enemies"):enemy.set_physics_process(false)
        if number==1:
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("res://art/source/world/gameplay_courtyard.png")
        stage.get_node("UI").hide()
        var camera:=Camera3D.new()
        stage.add_child(camera)
        camera.position=Vector3(-9,7.5,-15)
        camera.look_at(Vector3(0,1.5,14))
        camera.fov=64
        camera.current=true
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://art/source/world/stage%d_world.png" % number)
        if number==1:
            camera.position=Vector3(11,7,26)
            camera.look_at(Vector3(0,3.5,40))
            await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("res://art/source/world/castle_gate.png")
        stage.queue_free()
        await process_frame
    quit(0)
