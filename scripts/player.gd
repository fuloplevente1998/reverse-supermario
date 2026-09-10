extends CharacterBody3D

signal hp_changed(value: int)
signal died
signal attack_performed
signal damage_taken(amount: int, blocked: bool)

@export var move_speed := 7.2
@export var acceleration := 22.0
@export var jump_velocity := 8.0
@export var max_hp := 100
@export var attack_damage := 30
@export var attack_range := 2.65
@export var attack_cooldown := 0.38

var hp := 100
var blocking := false
var attack_ready := true
var dead := false
var visual_root: Node3D
var body_mesh: MeshInstance3D
var weapon_root: Node3D

func _ready() -> void:
    hp = max_hp
    add_to_group("player")
    _build_character_visual()

func _physics_process(delta: float) -> void:
    if dead:
        return

    if not is_on_floor():
        velocity += get_gravity() * delta

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity
        _jump_squash()

    var input_vec := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
    var direction := Vector3(input_vec.x, 0.0, input_vec.y)

    if direction.length() > 0.05:
        direction = direction.normalized()
        velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
        velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration * delta)
        var target_yaw := atan2(direction.x, direction.z)
        rotation.y = lerp_angle(rotation.y, target_yaw, min(1.0, delta * 12.0))
        if visual_root:
            visual_root.position.y = sin(Time.get_ticks_msec() * 0.018) * 0.035
    else:
        velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
        velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
        if visual_root:
            visual_root.position.y = move_toward(visual_root.position.y, 0.0, delta * 0.4)

    blocking = Input.is_action_pressed("block")
    _update_block_pose(delta)

    if Input.is_action_just_pressed("attack"):
        attack()

    move_and_slide()

func attack() -> void:
    if not attack_ready or dead:
        return
    attack_ready = false
    attack_performed.emit()
    _attack_animation()

    var forward := global_transform.basis.z.normalized()
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(enemy):
            continue
        var offset: Vector3 = enemy.global_position - global_position
        var flat_offset := Vector3(offset.x, 0.0, offset.z)
        if flat_offset.length() <= attack_range and flat_offset.length() > 0.01:
            if forward.dot(flat_offset.normalized()) > 0.15:
                enemy.take_damage(attack_damage, global_position)

    await get_tree().create_timer(attack_cooldown).timeout
    attack_ready = true

func take_damage(amount: int) -> void:
    if dead:
        return
    var actual := amount
    var was_blocked := blocking
    if blocking:
        actual = maxi(1, int(ceil(amount * 0.28)))
    hp = max(0, hp - actual)
    hp_changed.emit(hp)
    damage_taken.emit(actual, was_blocked)
    _damage_flash(was_blocked)
    if hp <= 0:
        dead = true
        died.emit()

func set_touch_action(action: StringName, pressed: bool) -> void:
    if pressed:
        Input.action_press(action)
    else:
        Input.action_release(action)

func _build_character_visual() -> void:
    var old_mesh := get_node_or_null("Mesh") as MeshInstance3D
    if old_mesh:
        old_mesh.visible = false

    visual_root = Node3D.new()
    visual_root.name = "HeroVisual"
    add_child(visual_root)

    var dark := StandardMaterial3D.new()
    dark.albedo_color = Color(0.09, 0.035, 0.06, 1)
    dark.metallic = 0.25
    dark.roughness = 0.42

    var crimson := StandardMaterial3D.new()
    crimson.albedo_color = Color(0.48, 0.035, 0.07, 1)
    crimson.metallic = 0.15
    crimson.roughness = 0.35

    var steel := StandardMaterial3D.new()
    steel.albedo_color = Color(0.22, 0.25, 0.31, 1)
    steel.metallic = 0.75
    steel.roughness = 0.2

    body_mesh = MeshInstance3D.new()
    var torso := CapsuleMesh.new()
    torso.radius = 0.47
    torso.height = 1.45
    body_mesh.mesh = torso
    body_mesh.material_override = dark
    body_mesh.position.y = 0.05
    visual_root.add_child(body_mesh)

    var head := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.37
    sphere.height = 0.74
    head.mesh = sphere
    head.material_override = crimson
    head.position = Vector3(0, 0.93, 0)
    visual_root.add_child(head)

    for side in [-1.0, 1.0]:
        var shoulder := MeshInstance3D.new()
        var shoulder_mesh := SphereMesh.new()
        shoulder_mesh.radius = 0.24
        shoulder_mesh.height = 0.48
        shoulder.mesh = shoulder_mesh
        shoulder.material_override = steel
        shoulder.position = Vector3(0.48 * side, 0.43, 0)
        visual_root.add_child(shoulder)

    var cape := MeshInstance3D.new()
    var cape_mesh := BoxMesh.new()
    cape_mesh.size = Vector3(0.8, 1.15, 0.08)
    cape.mesh = cape_mesh
    cape.material_override = crimson
    cape.position = Vector3(0, 0.05, -0.38)
    cape.rotation_degrees.x = -8
    visual_root.add_child(cape)

    weapon_root = Node3D.new()
    weapon_root.position = Vector3(0.58, 0.15, 0.15)
    visual_root.add_child(weapon_root)

    var blade := MeshInstance3D.new()
    var blade_mesh := BoxMesh.new()
    blade_mesh.size = Vector3(0.12, 0.12, 1.65)
    blade.mesh = blade_mesh
    blade.material_override = steel
    blade.position = Vector3(0, 0, 0.82)
    weapon_root.add_child(blade)

    var guard := MeshInstance3D.new()
    var guard_mesh := BoxMesh.new()
    guard_mesh.size = Vector3(0.65, 0.11, 0.12)
    guard.mesh = guard_mesh
    guard.material_override = crimson
    guard.position = Vector3(0, 0, 0.12)
    weapon_root.add_child(guard)

func _attack_animation() -> void:
    if weapon_root == null:
        return
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(weapon_root, "rotation_degrees:x", -105.0, 0.10)
    tween.tween_property(weapon_root, "rotation_degrees:x", 18.0, 0.18)

func _jump_squash() -> void:
    if visual_root == null:
        return
    var tween := create_tween()
    tween.tween_property(visual_root, "scale", Vector3(0.9, 1.12, 0.9), 0.08)
    tween.tween_property(visual_root, "scale", Vector3.ONE, 0.14)

func _update_block_pose(delta: float) -> void:
    if weapon_root == null:
        return
    var target := -55.0 if blocking else 0.0
    weapon_root.rotation_degrees.z = lerp(weapon_root.rotation_degrees.z, target, min(1.0, delta * 12.0))

func _damage_flash(was_blocked: bool) -> void:
    if body_mesh == null:
        return
    var mat := body_mesh.material_override as StandardMaterial3D
    if mat == null:
        return
    var original := mat.albedo_color
    mat.albedo_color = Color(0.2, 0.55, 1.0, 1) if was_blocked else Color(1.0, 0.12, 0.1, 1)
    await get_tree().create_timer(0.11).timeout
    if is_instance_valid(mat):
        mat.albedo_color = original
