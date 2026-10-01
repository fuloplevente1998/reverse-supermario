extends SceneTree
func _initialize() -> void:
    call_deferred("_capture")
func _capture() -> void:
    root.size = Vector2i(1280,720)
    var progress := ConfigFile.new()
    progress.set_value("progress", "difficulty", 1)
    progress.save("user://reverse_platformer_progress.cfg")
    DirAccess.make_dir_recursive_absolute("res://previews")
    var stage = load("res://scenes/main.tscn").instantiate()
    root.add_child(stage)
    await physics_frame
    stage.player.set_physics_process(false)
    for enemy in get_nodes_in_group("enemies"):
        enemy.set_physics_process(false)
    var positions := [-7.0, 14.0, 35.0, 49.0, 68.0]
    for i in range(positions.size()):
        var z: float = positions[i]
        stage.player.position = Vector3(0, stage.side_ground_height(z) + 0.93, z)
        stage.player.camera_pivot.set_view(true)
        for frame in range(4): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://previews/first100_%02d.png" % i)
    root.size = Vector2i(1600,720)
    stage.player.position = Vector3(0,stage.side_ground_height(35)+0.93,35)
    stage.player.camera_pivot.set_view(true)
    for i in range(4): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://previews/first100_wide.png")
    print("FIRST100_PREVIEW_OK")
    stage.queue_free()
    await process_frame
    quit(0)
