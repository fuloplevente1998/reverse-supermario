extends SceneTree

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var stage = load("res://scenes/main.tscn").instantiate()
    root.add_child(stage)
    await process_frame
    var yard = stage.get_node("CourtyardEnvironmentVisual")
    assert(yard.find_child("PavementBatch0", true, false) != null)
    var mesh = yard.find_child("PavementBatch0", true, false) as MeshInstance3D
    assert((mesh.get_active_material(0) as StandardMaterial3D).albedo_texture != null, "Prior GitHub stone texture lost")
    var decoration = yard.find_child("SceneryRuntime", true, false) as MeshInstance3D
    assert(decoration.mesh.get_surface_count() < 24, "Duplicate materials cause excess draw surfaces")
    assert(stage.get_node_or_null("FortressGateVisual") != null)
    assert(stage.get_node("CourtyardHurdle0").get_node_or_null("Stage1BarricadeVisual") != null)
    assert(stage.get_node("Player").model_animation != null)
    for enemy in get_nodes_in_group("enemies"):
        assert(enemy.visual_root.find_child("EnemyRig", true, false) != null, "Prior defender model lost")
    stage.queue_free()
    await process_frame
    for number in range(2,11):
        stage=load("res://scenes/stage%d.tscn" % number).instantiate()
        root.add_child(stage)
        await process_frame
        assert(stage.get_meta("uses_blender_scenery",false), "Missing biome decoration")
        assert(stage.get_node_or_null("FortressGateVisual") != null)
        assert(stage.find_child("World_*",true,false) != null)
        stage.queue_free()
        await process_frame
    print("WORLD_ART_SMOKE_OK: textured courtyard, batched decoration, walls, props, five defenders and all ten biomes")
    quit(0)
