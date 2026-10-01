extends SceneTree
const Pilot = preload("res://scripts/generation/courtyard_material_pilot.gd")

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = Vector2i(1280, 720)
    DirAccess.make_dir_recursive_absolute("res://previews")
    var progress := ConfigFile.new()
    progress.set_value("progress", "difficulty", 1)
    progress.save("user://reverse_platformer_progress.cfg")
    for use_ai in [false, true]:
        Pilot.enabled = use_ai
        var stage = load("res://scenes/main.tscn").instantiate()
        root.add_child(stage)
        await physics_frame
        stage.player.set_physics_process(false)
        for enemy in get_nodes_in_group("enemies"):
            enemy.set_physics_process(false)
        stage.player.position = Vector3(0, stage.side_ground_height(-7.0) + 0.93, -7.0)
        stage.player.camera_pivot.set_view(true)
        for frame in range(6): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://previews/material_pilot_%s.png" % ("ai" if use_ai else "original"))
        stage.queue_free()
        await process_frame
    Pilot.enabled = true
    print("MATERIAL_PILOT_PREVIEW_OK")
    quit(0)
