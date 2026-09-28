extends SceneTree

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var stage_one := load("res://scenes/main.tscn").instantiate()
    root.add_child(stage_one)
    await process_frame
    stage_one._on_goal_body_entered(stage_one.player)
    if not stage_one.ended or not stage_one.next_button.visible or not stage_one._is_second_stage_unlocked():
        push_error("Level one did not unlock the next stage")
        quit(1)
        return
    stage_one.queue_free()
    await process_frame

    var stage_two := load("res://scenes/stage2.tscn").instantiate()
    root.add_child(stage_two)
    await process_frame
    if stage_two.stage_number != 2 or stage_two.get_node_or_null("MovingBridge9") == null or stage_two.get_node_or_null("Checkpoint") == null:
        push_error("Level two obstacles did not load")
        quit(1)
        return
    stage_two.player.global_position = Vector3(0, -8, 15)
    stage_two._physics_process(0.016)
    if stage_two.player.hp != 75 or stage_two.player.global_position.y < 0:
        push_error("Pit respawn did not apply health penalty")
        quit(1)
        return
    stage_two._on_goal_body_entered(stage_two.player)
    if not stage_two.ended:
        push_error("Level two goal did not complete")
        quit(1)
        return
    quit(0)
