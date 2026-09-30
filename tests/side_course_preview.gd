extends SceneTree

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = Vector2i(1280,720)
    DirAccess.make_dir_recursive_absolute("res://previews")
    var stage = load("res://scenes/main.tscn").instantiate()
    root.add_child(stage)
    await physics_frame
    stage.player.set_physics_process(false)
    for enemy in get_nodes_in_group("enemies"):
        enemy.set_physics_process(false)
    for z in [-6.0,25.0,60.0,91.0,130.0,171.0,212.0]:
        stage.player.position = Vector3(0,stage.side_ground_height(z)+0.93,z)
        stage.player.camera_pivot.set_view(true)
        for i in range(3): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://previews/side_course_%03d.png" % int(z+10))
    root.size = Vector2i(1600,720)
    stage.player.position = Vector3(0,0.93,91)
    stage.player.camera_pivot.set_view(true)
    for i in range(3): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://previews/side_course_wide.png")
    stage.queue_free()
    await process_frame
    quit(0)
