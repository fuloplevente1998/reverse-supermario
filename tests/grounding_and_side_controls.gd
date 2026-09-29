extends SceneTree

# This exercises the actual player physics after settling on the stage floor.
# The legacy CI screenshot captured the character before gravity finished.
func _initialize() -> void:
    call_deferred("_verify")


func _fail(message: String) -> void:
    push_error("GROUNDING/CONTROLS: " + message)
    quit(1)


func _verify() -> void:
    var stage = load("res://scenes/main.tscn").instantiate()
    root.add_child(stage)
    for _frame in range(45):
        await physics_frame
    await process_frame

    var player = stage.player
    if not player.is_on_floor():
        _fail("Player has not settled on the stage-one ground")
        return
    var collision := player.get_node("Collision") as CollisionShape3D
    var capsule := collision.shape as CapsuleShape3D
    if capsule == null:
        _fail("The original player capsule was lost")
        return
    var expected_offset := collision.position.y - capsule.height * 0.5
    var visible_model := player.visual_root.get_child(0) as Node3D
    if visible_model == null or visible_model.find_child("HumanoidArmature", true, false) == null:
        _fail("The rigged Blender model is no longer active")
        return
    if absf(visible_model.position.y - expected_offset) > 0.035:
        _fail("Imported model feet are floating above physics floor: offset %.3f, expected %.3f" %
                [visible_model.position.y, expected_offset])
        return
    var physics_foot_y: float = player.global_position.y + expected_offset
    if absf(physics_foot_y) > 0.09:
        _fail("Player capsule not grounded: bottom world Y %.3f" % physics_foot_y)
        return
    # Godot can sanitize Blender's Boot.L name to Boot_L during glTF import.
    # Look up the semantic boot mesh rather than assuming a literal dot.
    var boot: MeshInstance3D
    for node in visible_model.find_children("*", "MeshInstance3D", true, false):
        if String(node.name).begins_with("Boot") and not String(node.name).contains("Gold"):
            boot = node as MeshInstance3D
            break
    if boot == null or boot.mesh == null:
        _fail("Imported Blender boot mesh missing after glTF name sanitization")
        return
    var boot_min_local_y: float = boot.get_aabb().position.y
    var boot_foot_y: float = boot.global_position.y + boot_min_local_y
    if absf(boot_foot_y) > 0.16:
        _fail("Visible boot sole must meet the pavement: Y=%.3f" % boot_foot_y)
        return

    var camera = player.get_node("CameraPivot")
    camera.toggle_view()
    await process_frame
    if not camera.side_view:
        _fail("Side camera toggle stopped working")
        return

    # User reported only left/right inverted. Forward/back remains unchanged.
    player.velocity = Vector3.ZERO
    player.set_touch_axis(Vector2(1.0, 0.0))
    for _frame in range(8):
        await physics_frame
    if player.velocity.z >= -0.5:
        _fail("Side view RIGHT joystick must drive negative world Z")
        return
    player.velocity = Vector3.ZERO
    player.set_touch_axis(Vector2(-1.0, 0.0))
    for _frame in range(8):
        await physics_frame
    if player.velocity.z <= 0.5:
        _fail("Side view LEFT joystick must drive positive world Z")
        return
    player.velocity = Vector3.ZERO
    player.set_touch_axis(Vector2(0.0, 1.0))
    for _frame in range(8):
        await physics_frame
    if player.velocity.x >= -0.5:
        _fail("Side view forward/backward controls must remain unchanged")
        return
    player.set_touch_axis(Vector2.ZERO)
    print("PASS: original collision grounded, visible Blender boots aligned, side-view joystick corrected")
    stage.queue_free()
    await process_frame
    quit(0)
