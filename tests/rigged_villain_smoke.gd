extends SceneTree

# Model and runtime integration test. Real Android FPS/touch QA remains separate.
func _initialize() -> void:
    call_deferred("_check")


func fail(reason: String) -> void:
    push_error("RIGGED VILLAIN: " + reason)
    quit(1)


func _check() -> void:
    var glb_path := "res://assets/models/villain.glb"
    var game_path := "res://assets/models/villain_knight.glb"
    if not ResourceLoader.exists(glb_path) or not ResourceLoader.exists(game_path):
        fail("No generated, exported GLB found")
        return

    var packed := load(glb_path) as PackedScene
    if packed == null:
        fail("Godot could not import the original rigged GLB")
        return
    var villain := packed.instantiate()
    root.add_child(villain)
    await process_frame

    var armatures := villain.find_children("*", "Skeleton3D", true, false)
    if armatures.is_empty():
        fail("The glTF armature did not import as Skeleton3D")
        return
    var skeleton := armatures[0] as Skeleton3D
    for bone in ["hips", "head", "hand.R", "thigh.L", "thigh.R", "cape.tip"]:
        if skeleton.find_bone(bone) == -1:
            fail("Humanoid bone missing: " + bone)
            return

    var clips := villain.find_children("*", "AnimationPlayer", true, false)
    if clips.is_empty():
        fail("The glTF animation player is missing")
        return
    var animator := clips[0] as AnimationPlayer
    var imported: Array[String] = []
    for item in animator.get_animation_list():
        imported.append(String(item).to_lower())
    for needed in ["idle", "run"]:
        var found := false
        for clip in imported:
            if clip.contains(needed):
                found = true
                break
        if not found:
            fail("Missing imported animation " + needed + "; clips: " + str(imported))
            return

    var chest := villain.find_child("Chest", true, false) as MeshInstance3D
    var sword := villain.find_child("WeaponPivot", true, false) as Node3D
    if chest == null or sword == null:
        fail("Gameplay node contract is incomplete: Chest / WeaponPivot")
        return
    for part in ["LegLeft", "LegRight", "WarlordBroadblade"]:
        if villain.find_child(part, true, false) == null:
            fail("Missing authored part: " + part)
            return
    var skinned := 0
    for mesh_node in villain.find_children("*", "MeshInstance3D", true, false):
        if (mesh_node as MeshInstance3D).skeleton != NodePath():
            skinned += 1
    if skinned < 10:
        fail("Expected more than ten skinned body pieces, found %d" % skinned)
        return
    villain.queue_free()
    await process_frame

    var stage := load("res://scenes/main.tscn").instantiate()
    root.add_child(stage)
    await process_frame
    if stage.player.visual_root.find_child("HumanoidArmature", true, false) == null:
        fail("Stage 1 player is not using the new humanoid Blender model")
        return
    if stage.player.model_animator == null:
        fail("Player is not driving the Blender Idle/Run clips")
        return
    print("PASS: Rigged Blender villain, %d bones, Idle/Run, hand-attached sword, in-stage animation" %
        skeleton.get_bone_count())
    stage.queue_free()
    await process_frame
    quit(0)
