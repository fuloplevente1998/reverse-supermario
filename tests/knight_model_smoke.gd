extends SceneTree

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var stage = load("res://scenes/main.tscn").instantiate()
    root.add_child(stage)
    await process_frame
    await physics_frame
    var player = stage.get_node("Player")
    assert(player.model_animation != null, "Imported AnimationPlayer missing")
    assert(player.body_mesh != null, "Imported runtime mesh missing")
    var skeleton = player.visual_root.find_child("Skeleton3D", true, false) as Skeleton3D
    assert(skeleton != null and skeleton.get_bone_count() == 14, "Skeleton mismatch")
    var sockets := 0
    for child in skeleton.get_children():
        if child is BoneAttachment3D:
            assert(child.get_bone_idx() >= 0, "Invalid hand attachment")
            assert(child.get_child_count() == 1, "Weapon missing")
            sockets += 1
    assert(sockets == 2, "Sword and shield must both be attached")
    for clip in ["idle", "run", "attack", "block", "jump"]:
        assert(player.model_animation.has_animation(clip), "Missing clip: " + clip)
        player.model_animation.play(clip)
        player.model_animation.advance(0.15)
        assert(player.model_animation.current_animation == clip, "Clip not playing")
    player.blocking = false
    player.attack()
    assert(player.model_animation.current_animation == "attack", "Attack animation not connected")
    assert(player.model_attack_time > 0, "Attack animation hold missing")
    # Attack holds until the cooldown; then block must take priority.
    player.blocking = true
    player._update_model_animation(0.5)
    assert(player.model_animation.current_animation == "block", "Block transition failed")
    player.blocking = false
    player.velocity = Vector3(2, 0, 0)
    # Test all clip tracks resolve on the imported rig, then normal game processing.
    for i in range(10):
        await physics_frame
    print("KNIGHT_MODEL_SMOKE_OK: 14 bones, 5 clips, 2 attached weapons, attack/block transitions")
    stage.queue_free()
    await process_frame
    quit(0)
