extends SceneTree
const Pilot = preload("res://scripts/generation/courtyard_material_pilot.gd")
func _initialize() -> void:
    call_deferred("_verify")
func _check(ok: bool, message: String) -> bool:
    if not ok:
        push_error(message)
        quit(1)
    return ok
func _verify() -> void:
    for difficulty in range(3):
        var progress := ConfigFile.new()
        progress.set_value("progress","difficulty",difficulty)
        progress.save("user://reverse_platformer_progress.cfg")
        var stage = load("res://scenes/main.tscn").instantiate()
        root.add_child(stage)
        for i in range(3): await physics_frame
        stage.player.set_physics_process(false)
        for enemy in get_nodes_in_group("enemies"): enemy.set_physics_process(false)
        var course: Node3D = stage.get_node("GeneratedLongStage")
        var pilot_count := 0
        for segment: Node3D in course.get_children():
            var ground := segment.get_node("CourtyardCourseArt")
            var expected := Pilot.applies(segment.position.z)
            if not _check(bool(ground.get_meta("ai_material_pilot")) == expected, "AI pilot escaped opening segment"): return
            var masonry := ground.get_node("ReliefMasonry") as MultiMeshInstance3D
            if expected:
                pilot_count += 1
                if not _check(masonry.material_override == Pilot.MATERIAL, "AI albedo not applied to pilot ground"): return
            elif not _check(masonry.material_override != Pilot.MATERIAL, "AI pilot replaced whole course"): return
        if not _check(pilot_count == 1 and Pilot.MATERIAL.uv1_world_triplanar and Pilot.MATERIAL.albedo_texture != null, "Pilot mapping or isolation failed"): return
        var scenery := get_nodes_in_group("courtyard_scenery")
        if not _check(scenery.size() == course.get_child_count(), "A course segment has no kit scenery"): return
        var saved_draw_instances := 0
        var batches := 0
        for art: Node3D in scenery:
            if not _check(str(art.get_meta("asset_author")) == "Quaternius", "Scenery changed kit on the late route"): return
            var original_count := int(art.get_meta("mesh_count"))
            var batch_count := int(art.get_meta("batch_count"))
            if not _check(batch_count > 0 and batch_count <= original_count, "Static scenery was not batched"): return
            for visual in art.get_children():
                if not _check(visual is MultiMeshInstance3D, "Unbatched scenery model left in course"): return
                if not _check(visual.multimesh.instance_count > 0, "Empty scenery batch"): return
            saved_draw_instances += original_count - batch_count
            batches += batch_count
        if not _check(saved_draw_instances > 300, "Full course multiplied individual scenery draw instances"): return
        var groups := get_nodes_in_group("courtyard_obstacles")
        var thirds := [0,0,0]
        var kinds := {}
        var length := float(stage.get_meta("side_course_length"))
        if not _check(groups.size() >= 18, "Full course still has only opening obstacles"): return
        for group: Node3D in groups:
            var z := float(group.get_meta("course_z"))
            thirds[mini(2,int((z+15.0)/length*3))] += 1
            kinds[group.get_meta("kind")] = true
            var segment: Node3D = group.get_parent()
            var clear := float(segment.get_meta("recovery_clear_length",0))
            if not _check(group.position.z - 2.4 >= clear, "Physical obstacle infringes recovery or boss approach"): return
            if not _check(float(group.get_meta("jump_height")) <= 1.60, "Late obstacle too high"): return
            for body: StaticBody3D in group.get_children():
                if not _check(body.collision_layer == 1 and body.get_child(0) is CollisionShape3D, "Late obstacle is cosmetic"): return
                var textured := false
                for mesh: MeshInstance3D in body.find_children("*","MeshInstance3D",true,false):
                    var material := mesh.get_active_material(0) as StandardMaterial3D
                    if material != null and material.albedo_texture != null: textured = true
                if not _check(textured,"Late collider has no textured visible model"): return
        if not _check(kinds.size() >= 5, "Physical obstacle variety was lost"): return
        for count in thirds:
            if not _check(count >= 3, "A course third still has too few physical obstacle groups"): return
        print("Courtyard assets difficulty %d OK: %d obstacle groups, thirds %s, %d scenery batches replacing %d individual meshes" % [difficulty,groups.size(),thirds,batches,batches+saved_draw_instances])
        stage.queue_free()
        await process_frame
    print("COURTYARD_ASSETS_SMOKE_OK: same textured kit start-to-finish, varied colliders in every third, clear recovery/boss approach and batched scenery")
    quit(0)
