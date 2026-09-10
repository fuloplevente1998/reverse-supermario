extends CharacterBody3D

signal defeated

@export var move_speed := 3.4
@export var max_hp := 60
@export var damage := 12
@export var attack_range := 1.7
@export var attack_cooldown := 0.9
@export var aggro_range := 22.0

var hp := 60
var attack_ready := true
var player: CharacterBody3D
var visual_root: Node3D
var body_mesh: MeshInstance3D

func _ready() -> void:
    hp = max_hp
    add_to_group("enemies")
    player = get_tree().get_first_node_in_group("player") as CharacterBody3D
    _build_visual()

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
        velocity.x = move_toward(velocity.x, 0.0, move_speed * 6.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, move_speed * 6.0 * delta)

    if distance <= attack_range:
        _try_attack()

    move_and_slide()

func _try_attack() -> void:
    if not attack_ready or player == null:
        return
    attack_ready = false
    _lunge()
    if player.has_method("take_damage"):
        player.take_damage(damage)
    await get_tree().create_timer(attack_cooldown).timeout
    attack_ready = true

func take_damage(amount: int, source_position := Vector3.ZERO) -> void:
    hp = max(0, hp - amount)
    _hit_reaction(source_position)
    if hp <= 0:
        defeated.emit()
        await get_tree().create_timer(0.16).timeout
        queue_free()

func _build_visual() -> void:
    var old_mesh := get_node_or_null("Mesh") as MeshInstance3D
    if old_mesh:
        old_mesh.visible = false

    visual_root = Node3D.new()
    add_child(visual_root)

    var armor := StandardMaterial3D.new()
    armor.albedo_color = Color(0.08, 0.18, 0.32, 1)
    armor.metallic = 0.55
    armor.roughness = 0.28

    var glow := StandardMaterial3D.new()
    glow.albedo_color = Color(0.12, 0.72, 1.0, 1)
    glow.emission_enabled = true
    glow.emission = Color(0.03, 0.38, 0.9, 1)
    glow.emission_energy_multiplier = 2.4

    body_mesh = MeshInstance3D.new()
    var torso := CapsuleMesh.new()
    torso.radius = 0.5
    torso.height = 1.55
    body_mesh.mesh = torso
    body_mesh.material_override = armor
    body_mesh.position.y = 0.04
    visual_root.add_child(body_mesh)

    var helm := MeshInstance3D.new()
    var helm_mesh := SphereMesh.new()
    helm_mesh.radius = 0.4
    helm_mesh.height = 0.8
    helm.mesh = helm_mesh
    helm.material_override = armor
    helm.position.y = 0.92
    visual_root.add_child(helm)

    for side in [-1.0, 1.0]:
        var eye := MeshInstance3D.new()
        var eye_mesh := SphereMesh.new()
        eye_mesh.radius = 0.065
        eye_mesh.height = 0.13
        eye.mesh = eye_mesh
        eye.material_override = glow
        eye.position = Vector3(0.14 * side, 0.97, 0.34)
        visual_root.add_child(eye)

        var horn := MeshInstance3D.new()
        var horn_mesh := CylinderMesh.new()
        horn_mesh.top_radius = 0.0
        horn_mesh.bottom_radius = 0.085
        horn_mesh.height = 0.55
        horn.mesh = horn_mesh
        horn.material_override = armor
        horn.position = Vector3(0.28 * side, 1.27, 0)
        horn.rotation_degrees.z = -24.0 * side
        visual_root.add_child(horn)

func _hit_reaction(source_position: Vector3) -> void:
    if body_mesh:
        var mat := body_mesh.material_override as StandardMaterial3D
        if mat:
            var original := mat.albedo_color
            mat.albedo_color = Color(1.0, 0.18, 0.1, 1)
            var tween := create_tween()
            tween.tween_property(visual_root, "scale", Vector3(1.15, 0.82, 1.15), 0.06)
            tween.tween_property(visual_root, "scale", Vector3.ONE, 0.11)
            await get_tree().create_timer(0.09).timeout
            if is_instance_valid(mat):
                mat.albedo_color = original
    var knock := global_position - source_position
    knock.y = 0
    if knock.length() > 0.01:
        velocity += knock.normalized() * 4.0

func _lunge() -> void:
    if visual_root == null:
        return
    var tween := create_tween()
    tween.tween_property(visual_root, "scale", Vector3(0.9, 0.9, 1.18), 0.08)
    tween.tween_property(visual_root, "scale", Vector3.ONE, 0.12)
