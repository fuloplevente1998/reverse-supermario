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
    var decorations: Array[Node] = yard.find_children("SceneryRuntime*", "MeshInstance3D", true, false)
    assert(decorations.size()>1, "Courtyard must be spatially chunked")
    var triangles := 0
    for decoration: MeshInstance3D in decorations:
        assert(decoration.mesh.get_surface_count() < 24, "Duplicate materials cause excess draw surfaces")
        for surface in range(decoration.mesh.get_surface_count()):
            var arrays := decoration.mesh.surface_get_arrays(surface)
            triangles += arrays[Mesh.ARRAY_INDEX].size()/3 if arrays[Mesh.ARRAY_INDEX]!=null else arrays[Mesh.ARRAY_VERTEX].size()/3
    assert(triangles < 80000, "Courtyard runtime is still too heavy")
    assert(stage.get_node_or_null("FortressGateVisual") != null)
    assert(stage.get_node("GeneratedLongStage").get_child(0).get_node("Floor") is StaticBody3D, "Generated opening lost its physical floor")
    assert(stage.get_node_or_null("SideBackdrop") != null)
    assert(stage.get_node("Player/CameraPivot").camera.cull_mask == 5)
    assert(stage.get_node("Player").model_animation != null)
    assert(stage.get_node("LandscapeShelf").material_override.albedo_texture != null)
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
        assert(stage.get_node("LandscapeShelf").material_override.albedo_texture != null, "Outside ground needs a texture on every stage")
        stage.queue_free()
        await process_frame
    print("WORLD_ART_SMOKE_OK: textured courtyard, batched decoration, walls, props, five defenders and all ten biomes")
    quit(0)
