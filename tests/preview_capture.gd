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
        # Settling the capsule takes time; an immediate render falsely looks
        # like the warlord is levitating above the pavement.
        for _settling_frame in range(48):
            await physics_frame
        await process_frame
        await RenderingServer.frame_post_draw
        var captured := root.get_texture().get_image()
        captured.save_png("res://previews/stage%d.png" % number)
        if number == 1:
            # Move closer only for the dedicated environmental art inspection
            # frame; this never changes the actual spawn point in the APK.
            stage.player.global_position = Vector3(0, 0.92, 26)
            stage.player.velocity = Vector3.ZERO
            for _near_frame in range(20):
                await physics_frame
            await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("res://previews/stage1-near-gate.png")
            # A real camera-side frame exposes joystick/character silhouettes.
            stage.player.get_node("CameraPivot").toggle_view()
            await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("res://previews/stage1-side.png")
        stage.queue_free()
        await process_frame
    quit(0)
