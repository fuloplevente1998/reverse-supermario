extends SceneTree

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = Vector2i(1280, 720)
    DirAccess.make_dir_recursive_absolute("res://previews")
    var progress := ConfigFile.new()
    progress.set_value("progress", "difficulty", 1)
    progress.save("user://reverse_platformer_progress.cfg")
    for number in [1,3,5,7,10]:
        var path := "res://scenes/main.tscn" if number == 1 else "res://scenes/stage%d.tscn" % number
        var stage = load(path).instantiate()
        root.add_child(stage)
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        var captured := root.get_texture().get_image()
        captured.save_png("res://previews/stage%d.png" % number)
        stage.queue_free()
        await process_frame
    quit(0)
