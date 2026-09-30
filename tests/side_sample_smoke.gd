extends SceneTree
func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    root.size = Vector2i(1280,720)
    var stage = load("res://scenes/main.tscn").instantiate()
    root.add_child(stage)
    for i in range(3): await physics_frame
    var sample = stage.get_node("SideArtSample")
    assert(sample.get_meta("sample_end_z")-sample.get_meta("sample_start_z")==25.0)
    assert(sample.get_node("ReliefMasonry") is MultiMeshInstance3D)
    var terrain = stage.get_node("SideTerrain0").get_child(1)
    var normals: PackedVector3Array = terrain.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
    assert(normals[0].x < -0.99 and normals[12].y > 0.99,"Terrain normals must point toward camera and sky")
    assert(sample.get_node("WalkwayPaving").multimesh.instance_count==68)
    var guard = stage.get_node("Guard_8")
    assert(guard.get_meta("detailed_side_guard",false))
    assert(guard.detail_animation.has_animation("run") and guard.detail_animation.has_animation("attack"))
    assert(guard.body_mesh.material_override is ShaderMaterial)
    assert(guard.visual_root.find_child("Skeleton3D",true,false).get_bone_count()==17)
    stage.player._update_side_presentation()
    assert(stage.player.visual_root.scale.is_equal_approx(Vector3.ONE))
    assert(absf(stage.player.visual_root.rotation.y)>0.5)
    assert(stage.hp_bar.get_theme_stylebox("fill").bg_color.r>0.7)
    for dimensions in [Vector2i(1280,720),Vector2i(1600,720),Vector2i(2400,1080)]:
        root.size = dimensions
        for i in range(3): await process_frame
        var view := root.get_visible_rect()
        for node in ["UI/HealthPanel","UI/Controls/Actions/Jump","UI/Controls/Actions/Block","UI/Controls/Actions/Attack","UI/Controls/Joystick"]:
            assert(view.encloses(stage.get_node(node).get_global_rect()),"Clipped HUD at "+str(dimensions)+": "+node)
    var safe := Rect2(Vector2(70,24),root.get_visible_rect().size-Vector2(110,48))
    stage._layout_mobile_interface(safe)
    for node in ["UI/HealthPanel","UI/Controls/Actions/Attack","UI/Controls/Joystick"]:
        assert(safe.encloses(stage.get_node(node).get_global_rect()),"Safe-area layout ignored")
    var joystick = stage.get_node("UI/Controls/Joystick")
    var stick := InputEventScreenTouch.new()
    stick.index=0
    stick.pressed=true
    stick.position=joystick.size*0.5+Vector2(60,0)
    joystick._gui_input(stick)
    var jump = stage.get_node("UI/Controls/Actions/Jump")
    var block = stage.get_node("UI/Controls/Actions/Block")
    var tap := InputEventScreenTouch.new()
    tap.index=1
    tap.pressed=true
    tap.position=jump.get_global_rect().get_center()
    jump._input(tap)
    assert(stage.player.touch_jump and stage.player.touch_axis.x>0.2,"Movement + jump touch failed")
    tap.pressed=false
    tap.position=Vector2.ZERO
    jump._input(tap)
    tap.index=2
    tap.pressed=true
    tap.position=block.get_global_rect().get_center()
    block._input(tap)
    assert(stage.player.touch_block and stage.player.touch_axis.x>0.2,"Movement + block touch failed")
    tap.pressed=false
    tap.position=Vector2.ZERO
    block._input(tap)
    assert(not stage.player.touch_block and block.pointer==-1,"Outside release stuck")
    stick.pressed=false
    joystick._input(stick)
    # Use the real attack selection, range, HP and defeat path against the guard.
    stage.player.set_physics_process(false)
    for enemy in get_nodes_in_group("enemies"):
        enemy.set_physics_process(false)
    stage.player.position=Vector3(0,0.93,6)
    stage.player.rotation.y=0
    guard.position=Vector3(0,0.93,8)
    await physics_frame
    var hp: int = guard.hp
    stage.player.attack()
    assert(guard.hp<hp,"Detailed guard did not receive the actual player attack")
    await create_timer(0.5).timeout
    stage.player.attack()
    await create_timer(0.5).timeout
    stage.player.attack()
    await create_timer(0.5).timeout
    assert(stage.enemies_defeated>0,"Detailed guard defeat path failed")
    print("SIDE_SAMPLE_SMOKE_OK: 25m masonry/paving, 17-bone blue guard, hero presentation, HUD at 16:9/20:9/wide, safe area, multitouch/outside release and actual combat defeat")
    stage.queue_free()
    await process_frame
    quit(0)
