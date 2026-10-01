extends SceneTree

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    root.size = Vector2i(1280,720)
    var title = load("res://scenes/title.tscn").instantiate()
    root.add_child(title)
    current_scene = title
    title._open_stage(1)
    var stage: Node3D
    var ready := false
    for frame in range(600):
        await process_frame
        if current_scene is Node3D:
            stage = current_scene
            if stage.get_meta("startup_ready", false):
                ready = true
                break
    if not ready:
        push_error("Title threaded loading/warmup never enabled play")
        quit(1)
        return
    if stage.player.hp != stage.player.max_hp or stage.get_node_or_null("CourtyardEnvironmentVisual") != null:
        push_error("Startup loading allowed damage or loaded unused scenery")
        quit(1)
        return
    await process_frame
    await RenderingServer.frame_post_draw
    DirAccess.make_dir_recursive_absolute("res://previews")
    root.get_texture().get_image().save_png("res://previews/title_startup_ready.png")
    print("TITLE_STARTUP_PREVIEW_OK: threaded menu-to-level load, warmup completes without damage, opening rendered")
    quit(0)
