extends CharacterBody3D

@export var move_speed := 2.8
@export var max_hp := 50
@export var damage := 10
@export var attack_range := 1.6
@export var attack_cooldown := 1.0
@export var aggro_range := 18.0

var hp := 50
var attack_ready := true
var player: CharacterBody3D

func _ready() -> void:
    hp = max_hp
    add_to_group("enemies")
    player = get_tree().get_first_node_in_group("player") as CharacterBody3D

func _physics_process(delta: float) -> void:
    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as CharacterBody3D
        return

    if not is_on_floor():
        velocity += get_gravity() * delta

    var offset := player.global_position - global_position
    var flat := Vector3(offset.x, 0.0, offset.z)
    var distance := flat.length()

    if distance <= aggro_range and distance > attack_range:
        var dir := flat.normalized()
        velocity.x = dir.x * move_speed
        velocity.z = dir.z * move_speed
        rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), min(1.0, delta * 8.0))
    else:
        velocity.x = move_toward(velocity.x, 0.0, move_speed * 5.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, move_speed * 5.0 * delta)

    if distance <= attack_range:
        _try_attack()

    move_and_slide()

func _try_attack() -> void:
    if not attack_ready or player == null:
        return
    attack_ready = false
    if player.has_method("take_damage"):
        player.take_damage(damage)
    await get_tree().create_timer(attack_cooldown).timeout
    attack_ready = true

func take_damage(amount: int) -> void:
    hp = max(0, hp - amount)
    if hp <= 0:
        queue_free()
