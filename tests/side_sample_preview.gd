extends SceneTree
func _initialize() -> void:
    call_deferred("_capture")

func _snap(name: String) -> void:
    for i in range(4): await process_frame
    await RenderingServer.frame_post_draw
    var captured := root.get_texture().get_image()
    captured.save_png("res://previews/"+name+".png")
    print("SAMPLE_QA_IMAGE:"+name+":"+Marshalls.raw_to_base64(captured.save_jpg_to_buffer(0.8)))

func _capture() -> void:
    root.size=Vector2i(1280,720)
    DirAccess.make_dir_recursive_absolute("res://previews")
    var stage=load("res://scenes/main.tscn").instantiate()
    root.add_child(stage)
    for i in range(3): await physics_frame
    stage.player.set_physics_process(false)
    for enemy in get_nodes_in_group("enemies"):
        enemy.set_physics_process(false)
    stage.player.position=Vector3(0,0.93,3)
    stage.player.rotation.y=0
    stage.player._update_side_presentation()
    var guard=stage.get_node("Guard_8")
    guard.position=Vector3(0,0.93,8)
    guard.rotation.y=PI
    guard.visual_root.rotation.y=0.55
    stage.player.camera_pivot.set_view(true)
    await _snap("sample_idle_16_9")
    stage.player.model_animation.play("run")
    stage.player.model_animation.advance(0.16)
    stage.player.model_animation.pause()
    await _snap("sample_run")
    stage.player.model_animation.play("attack")
    stage.player.model_animation.advance(0.22)
    stage.player.model_animation.pause()
    await _snap("sample_attack")
    stage.player.model_animation.play("block")
    stage.player.model_animation.advance(0.35)
    stage.player.model_animation.pause()
    await _snap("sample_block")
    stage.player.position=Vector3(0,0.93,-6)
    stage.player.velocity=Vector3.ZERO
    stage.player.set_physics_process(true)
    stage.player.touch_jump=true
    for i in range(16): await physics_frame
    stage.player.set_physics_process(false)
    stage.player.model_animation.pause()
    stage.player.camera_pivot.set_view(true)
    await _snap("sample_physical_jump")
    root.size=Vector2i(1600,720)
    stage.player.position=Vector3(0,0.93,3)
    stage.player.model_animation.play("idle")
    stage.player.camera_pivot.set_view(true)
    await _snap("sample_wide")
    stage.queue_free()
    await process_frame
    quit(0)
