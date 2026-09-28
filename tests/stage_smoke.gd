extends SceneTree

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var progress := ConfigFile.new()
    progress.set_value("progress", "unlocked_stage", 1)
    progress.set_value("progress", "difficulty", 1)
    progress.save("user://reverse_platformer_progress.cfg")

    var stage_one = load("res://scenes/main.tscn").instantiate()
    root.add_child(stage_one)
    await process_frame
    if stage_one.get_node_or_null("UI/Controls/Joystick") == null:
        push_error("Joystick missing from stage one")
        quit(1)
        return
    stage_one._on_goal_body_entered(stage_one.player)
    if not stage_one.ended or not stage_one.next_button.visible or not stage_one._is_stage_unlocked(2):
        push_error("Level one did not unlock the next stage")
        quit(1)
        return
    stage_one.queue_free()
    await process_frame

    for difficulty in range(3):
        progress.set_value("progress", "difficulty", difficulty)
        progress.save("user://reverse_platformer_progress.cfg")
        for number in range(2, 11):
            var stage = load("res://scenes/stage%d.tscn" % number).instantiate()
            root.add_child(stage)
            await process_frame
            if stage.stage_number != number or stage.get_node_or_null("Checkpoint") == null:
                push_error("Stage %d failed to load" % number)
                quit(1)
                return
            if stage.get_node_or_null("UI/Controls/Joystick") == null:
                push_error("Joystick missing from stage %d" % number)
                quit(1)
                return
            if number >= 3 and stage.get_node_or_null("GeneratedFloor0") == null:
                push_error("Generated obstacles missing from stage %d" % number)
                quit(1)
                return
            if stage.player.hp != [120, 100, 80][difficulty]:
                push_error("Wrong health for difficulty %d" % difficulty)
                quit(1)
                return
            if number == 2 and difficulty == 1:
                stage.player.global_position = Vector3(0, -8, 15)
                stage._physics_process(0.016)
                if stage.player.hp != 75 or stage.player.global_position.y < 0:
                    push_error("Pit checkpoint or health penalty failed")
                    quit(1)
                    return
            stage._on_goal_body_entered(stage.player)
            if not stage.ended or (number < 10 and not stage._is_stage_unlocked(number + 1)):
                push_error("Progression failed at stage %d" % number)
                quit(1)
                return
            stage.queue_free()
            await process_frame
    quit(0)
