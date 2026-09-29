extends SceneTree

# Run after Blender generation and the initial Godot editor import.
# This is a structural smoke test, not a substitute for mobile visual QA.
func _initialize() -> void:
    call_deferred("_verify")


func _fail(message: String) -> void:
    push_error(message)
    quit(1)


func _verify() -> void:
    const KNIGHT := "res://assets/models/villain_knight.glb"
    const GATE := "res://assets/models/fortress_gate.glb"
    const YARD := "res://assets/models/courtyard_environment.glb"
    if not ResourceLoader.exists(KNIGHT) or not ResourceLoader.exists(GATE) or not ResourceLoader.exists(YARD):
        _fail("Missing generated Blender GLBs")
        return
    var knight_scene := load(KNIGHT) as PackedScene
    var gate_scene := load(GATE) as PackedScene
    var yard_scene := load(YARD) as PackedScene
    if knight_scene == null or gate_scene == null or yard_scene == null:
        _fail("Generated GLB could not be imported as PackedScene")
        return

    var knight := knight_scene.instantiate()
    root.add_child(knight)
    await process_frame
    for part in ["Chest", "LegLeft", "LegRight", "WeaponPivot"]:
        if knight.find_child(part, true, false) == null:
            _fail("Missing required animated mesh/pivot: " + part)
            return
    if knight.find_child("Chest", true, false) is not MeshInstance3D:
        _fail("Blender Chest must be a MeshInstance3D")
        return
    knight.queue_free()
    await process_frame

    var gate := gate_scene.instantiate()
    root.add_child(gate)
    await process_frame
    if gate.find_child("GatePillar", true, false) == null:
        _fail("Generated gate has no stone pillars")
        return
    gate.queue_free()
    await process_frame
    var yard := yard_scene.instantiate()
    root.add_child(yard)
    await process_frame
    if yard.find_child("FountainBase", true, false) == null or yard.find_child("PavementBatch0", true, false) == null:
        _fail("Courtyard is missing fountain or batched paved road")
        return
    yard.queue_free()
    await process_frame

    # The complete defender roster must import cleanly and integrate with
    # the runtime enemy script, not merely exist as files on disk.
    var enemy_script = load("res://scripts/enemy.gd") as Script
    for kind in ["guard", "scout", "brute", "archer", "captain"]:
        var model_path: String = "res://assets/models/enemy_%s.glb" % kind
        if not ResourceLoader.exists(model_path):
            _fail("Blender defender asset missing: " + kind)
            return
        var enemy_scene := load(model_path) as PackedScene
        if enemy_scene == null:
            _fail("Cannot import Blender defender: " + kind)
            return
        var enemy_model := enemy_scene.instantiate()
        root.add_child(enemy_model)
        await process_frame
        for part in ["Chest", "LegLeft", "LegRight", "WeaponPivot"]:
            if enemy_model.find_child(part, true, false) == null:
                _fail("%s GLB missing %s" % [kind, part])
                return
        enemy_model.queue_free()
        await process_frame

        var defender = enemy_script.new()
        defender.archetype = kind
        defender.set_physics_process(false)
        root.add_child(defender)
        await process_frame
        if defender.visual_root.find_child("EnemyRig", true, false) == null:
            _fail("%s is not using its Blender model in the game" % kind)
            return
        if defender.body_mesh == null or defender.legs.size() != 2 or defender.weapon_root == null:
            _fail("%s is missing imported animation pivots" % kind)
            return
        defender.queue_free()
        await process_frame

    var first_level = load("res://scenes/main.tscn").instantiate()
    root.add_child(first_level)
    await process_frame
    if first_level.get_node_or_null("CourtyardEnvironmentVisual") == null:
        _fail("Stage 1 did not instance the Blender courtyard")
        return
    if first_level.get_node_or_null("FortressGateVisual") == null:
        _fail("Stage 1 did not instance the Blender gate")
        return
    if first_level.player.body_mesh == null or first_level.player.legs.size() != 2:
        _fail("The villain does not use the Blender mesh/pivot hierarchy")
        return
    if first_level.player.visual_root.find_child("VillainRig", true, false) == null:
        _fail("Stage 1 is still displaying only the procedural fallback")
        return
    print("PASS: villain, castle art and five defenders import and animate in Godot")
    first_level.queue_free()
    await process_frame
    quit(0)
