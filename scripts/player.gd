extends CharacterBody3D

signal hp_changed(value: int)
signal died

@export var move_speed := 6.0
@export var jump_velocity := 7.0
@export var max_hp := 100
@export var attack_damage := 25
@export var attack_range := 2.2
@export var attack_cooldown := 0.45

var hp := 100
var blocking := false
var attack_ready := true

func _ready() -> void:
    hp = max_hp
    add_to_group("player")

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity += get_gravity() * delta

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

    var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := Vector3(input_vec.x, 0.0, input_vec.y)

    if direction.length() > 0.05:
        direction = direction.normalized()
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
        var target_yaw := atan2(direction.x, direction.z)
        rotation.y = lerp_angle(rotation.y, target_yaw, min(1.0, delta * 10.0))
    else:
        velocity.x = move_toward(velocity.x, 0.0, move_speed * 5.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, move_speed * 5.0 * delta)

    blocking = Input.is_action_pressed("block")

    if Input.is_action_just_pressed("attack"):
        attack()

    move_and_slide()

func attack() -> void:
    if not attack_ready:
        return
    attack_ready = false

    for enemy in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(enemy):
            continue
        var offset: Vector3 = enemy.global_position - global_position
        if offset.length() <= attack_range:
            var forward := global_transform.basis.z.normalized()
            var flat_offset := Vector3(offset.x, 0.0, offset.z).normalized()
            if forward.dot(flat_offset) > -0.35:
                enemy.take_damage(attack_damage)

    await get_tree().create_timer(attack_cooldown).timeout
    attack_ready = true

func take_damage(amount: int) -> void:
    var actual := amount
    if blocking:
        actual = int(ceil(amount * 0.35))
    hp = max(0, hp - actual)
    hp_changed.emit(hp)
    if hp <= 0:
        died.emit()

func set_touch_action(action: StringName, pressed: bool) -> void:
    if pressed:
        Input.action_press(action)
    else:
        Input.action_release(action)
