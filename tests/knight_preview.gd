extends SceneTree

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = Vector2i(1280, 720)
    var stage = load("res://scenes/main.tscn").instantiate()
    root.add_child(stage)
    await process_frame
    var player = stage.get_node("Player")
    player.set_physics_process(false)
    player.get_node("CameraPivot").set_process(false)
    player.get_node("CameraPivot").set_physics_process(false)
    var camera := Camera3D.new()
    stage.add_child(camera)
    camera.position = player.position + Vector3(2.5, 1.35, 3.3)
    camera.look_at(player.position + Vector3(0, 0.3, 0))
    camera.current = true
    camera.fov = 46
    for clip in ["idle", "run", "attack", "block"]:
        player.model_animation.play(clip)
        player.model_animation.advance(0.22 if clip == "attack" else 0.17)
        player.model_animation.pause()
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://art/source/game_" + clip + ".png")
    stage.queue_free()
    await process_frame
    quit(0)
