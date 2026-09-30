extends SceneTree

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size=Vector2i(1280,720)
    for number in [1,2,4]:
        var path := "res://scenes/main.tscn" if number==1 else "res://scenes/stage%d.tscn" % number
        var stage=load(path).instantiate()
        root.add_child(stage)
        for i in range(10):await physics_frame
        var player=stage.get_node("Player")
        player.set_physics_process(false)
        for enemy in get_nodes_in_group("enemies"):enemy.set_physics_process(false)
        stage.get_node("UI").hide()
        var view:=Camera3D.new()
        stage.add_child(view)
        view.position=Vector3(-10,7,-15)
        view.look_at(Vector3(0,1,12))
        view.current=true
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://previews/open_stage%d.png" % number)
        if number==1:
            view.current=false
            player.position=Vector3(0,.93,15)
            player.get_node("CameraPivot").toggle_view()
            player.get_node("CameraPivot").camera.current=true
            await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("res://previews/side_center.png")
        stage.queue_free()
        await process_frame
    quit(0)
