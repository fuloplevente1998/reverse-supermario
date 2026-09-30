extends SceneTree

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = Vector2i(640, 480)
    DirAccess.make_dir_recursive_absolute("res://previews/cape")
    var stage = load("res://scenes/main.tscn").instantiate()
    root.add_child(stage)
    await process_frame
    var player = stage.get_node("Player")
    player.set_physics_process(false)
    player.get_node("CameraPivot").set_process(false)
    player.get_node("CameraPivot").set_physics_process(false)
    var camera := Camera3D.new()
    stage.add_child(camera)
    camera.position = player.position + Vector3(1.8, 1.2, -3.5)
    camera.look_at(player.position + Vector3(0, 0.25, 0))
    camera.current = true
    camera.fov = 43
    for node in stage.get_children():
        if node is CanvasLayer:
            node.visible = false
    player.model_animation.get_animation("run").loop_mode = Animation.LOOP_LINEAR
    player.model_animation.play("run")
    player.model_animation.pause()
    for i in range(24):
        player.model_animation.advance(1.0 / 30.0)
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://previews/cape/%03d.png" % i)
    stage.queue_free()
    await process_frame
    quit(0)
