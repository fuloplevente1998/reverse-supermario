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

    var start_z := -10.0
    var end_z := float(stage.get_meta("side_course_end_z"))
    var span := end_z - start_z
    var positions := [
        start_z + span * 0.02,
        start_z + span * 0.17,
        start_z + span * 0.34,
        start_z + span * 0.50,
        start_z + span * 0.67,
        start_z + span * 0.83,
        start_z + span * 0.96
    ]

    for i in range(positions.size()):
        var z: float = positions[i]
        stage.player.position = Vector3(0, stage.side_ground_height(z) + 0.93, z)
        stage.player.camera_pivot.set_view(true)
        for frame in range(3):
            await process_frame
        await RenderingServer.frame_post_draw
        var captured := root.get_texture().get_image()
        captured.save_png("res://previews/side_course_%02d_%03d.png" % [i, int(z)])
        if i in [0,3,6]:
            print("VISUAL_QA_IMAGE:" + str(i) + ":" + Marshalls.raw_to_base64(captured.save_jpg_to_buffer(0.75)))

    root.size = Vector2i(1600,720)
    var middle_z := start_z + span * 0.50
    stage.player.position = Vector3(0, stage.side_ground_height(middle_z) + 0.93, middle_z)
    stage.player.camera_pivot.set_view(true)
    for i in range(3):
        await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://previews/side_course_wide.png")
    stage.queue_free()
    await process_frame
    quit(0)
