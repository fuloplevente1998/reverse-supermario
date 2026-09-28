extends CharacterBody3D

signal defeated

@export var move_speed := 3.4
@export var max_hp := 60
@export var damage := 12
@export var attack_range := 1.7
@export var attack_cooldown := 0.9
@export var aggro_range := 22.0

@export var archetype := "guard"
const Projectile = preload("res://scripts/projectile.gd")
var windup := 0.35
var base_scale := Vector3.ONE
var tint := Color("#4e83b5")
var attack_marker: MeshInstance3D
const Art = preload("res://scripts/art.gd")
var dead := false
var legs: Array[Node3D] = []
var hp := 60
var attack_ready := true
var player: CharacterBody3D
var visual_root: Node3D
var body_mesh: MeshInstance3D

func _ready() -> void:
    _configure_archetype()
    hp = max_hp
    add_to_group("enemies")
    player = get_tree().get_first_node_in_group("player") as CharacterBody3D
    _build_visual()

func _physics_process(delta: float) -> void:
    if dead:
        return
    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as CharacterBody3D
        return
    if not is_on_floor():
        velocity += get_gravity() * delta
    if global_position.y < -8:
        take_damage(hp + 1)
        return
    var offset := player.global_position - global_position
    var flat := Vector3(offset.x, 0.0, offset.z)
    var distance := flat.length()
    var direction := flat.normalized()
    var desired := Vector3.ZERO
    if distance <= aggro_range:
        rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), minf(1.0, delta * 8.0))
        if archetype == "archer":
            if distance > 9.0:
                desired = direction * move_speed
            elif distance < 4.0:
                desired = -direction * move_speed
            if distance <= 12.0 and _can_see_player():
                _try_attack()
        elif distance > attack_range:
            desired = direction * move_speed
        elif absf(offset.y) < 2.0:
            _try_attack()
    if desired.length_squared() > 0.01 and is_on_floor():
        var ahead := global_position + desired.normalized() * 1.1
        var query := PhysicsRayQueryParameters3D.create(ahead + Vector3.UP * 0.3, ahead - Vector3.UP * 2.4)
        query.exclude = [get_rid()]
        var ground := get_world_3d().direct_space_state.intersect_ray(query)
        if ground.is_empty():
            desired = Vector3.ZERO
    if not attack_ready and archetype != "scout":
        desired = Vector3.ZERO
    velocity.x = desired.x
    velocity.z = desired.z
    move_and_slide()
    for i in range(legs.size()):
        var moving := Vector2(velocity.x, velocity.z).length() > 0.2
        legs[i].rotation.x = sin(Time.get_ticks_msec() * 0.013 + i * PI) * 0.35 if moving else 0.0

func _can_see_player() -> bool:
    var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.3, player.global_position + Vector3.UP * 0.3)
    query.exclude = [get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    return not hit.is_empty() and hit["collider"] == player

func _try_attack() -> void:
    if not attack_ready or player == null or bool(player.get("dead")):
        return
    attack_ready = false
    attack_marker.visible = true
    await get_tree().create_timer(windup, false).timeout
    attack_marker.visible = false
    if dead or not is_physics_processing() or not is_instance_valid(player) or bool(player.get("dead")):
        return
    _lunge()
    if archetype == "archer":
        if _can_see_player():
            var shot = Projectile.new()
            shot.owner_rid = get_rid()
            shot.damage = damage
            shot.speed = 8.0 + move_speed
            get_parent().add_child(shot)
            shot.global_position = global_position + Vector3.UP * 0.3
            shot.direction = (player.global_position + Vector3.UP * 0.3 - shot.global_position).normalized()
    elif global_position.distance_to(player.global_position) <= attack_range + 0.5 and _can_see_player():
        player.take_damage(damage)
    await get_tree().create_timer(attack_cooldown, false).timeout
    attack_ready = true

func _configure_archetype() -> void:
    aggro_range = 12.0
    match archetype:
        "scout":
            max_hp = 35
            move_speed = 5.3
            damage = 8
            attack_cooldown = 0.65
            windup = 0.2
            base_scale = Vector3.ONE * 0.85
            tint = Color("#4cba83")
        "brute":
            max_hp = 110
            move_speed = 2.0
            damage = 22
            attack_range = 2.1
            windup = 0.7
            base_scale = Vector3.ONE * 1.15
            tint = Color("#c7a05e")
        "archer":
            max_hp = 45
            move_speed = 2.6
            damage = 12
            attack_cooldown = 1.9
            windup = 0.65
            tint = Color("#7b82db")
        "captain":
            max_hp = 240
            move_speed = 2.7
            damage = 26
            attack_range = 2.6
            attack_cooldown = 1.3
            windup = 0.8
            base_scale = Vector3.ONE * 1.35
            tint = Color("#e5ce88")

func take_damage(amount: int, source_position := Vector3.ZERO) -> void:
    if dead:
        return
    if archetype == "brute" and attack_ready:
        var incoming := (source_position - global_position).normalized()
        if global_transform.basis.z.dot(incoming) > 0.5:
            amount = maxi(1, roundi(amount * 0.4))
    hp = max(0, hp - amount)
    _hit_reaction(source_position)
    if hp <= 0:
        dead = true
        remove_from_group("enemies")
        set_physics_process(false)
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
    armor.albedo_color = tint
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
    torso.height = 0.95
    body_mesh.mesh = torso
    body_mesh.material_override = armor
    body_mesh.position.y = 0.2
    visual_root.add_child(body_mesh)

    var helm := MeshInstance3D.new()
    var helm_mesh := SphereMesh.new()
    helm_mesh.radius = 0.4
    helm_mesh.height = 0.8
    helm.mesh = helm_mesh
    helm.material_override = armor
    helm.position.y = 0.92
    visual_root.add_child(helm)

    legs = Art.armor(visual_root, false)
    visual_root.scale = base_scale
    var accent := Art.material(tint)
    Art.box(visual_root, Vector3(0.54, 0.62, 0.1), Vector3(0, 0.25, 0.48), accent)
    if archetype == "archer":
        Art.cylinder(visual_root, 0.07, 1.5, Vector3(0.7, 0.2, 0.2), accent)
        Art.cylinder(visual_root, 0.24, 0.35, Vector3(0.7, 1.0, 0.2), accent, true)
    elif archetype in ["brute", "captain"]:
        Art.box(visual_root, Vector3(0.65, 0.5, 0.55), Vector3(0.75, 0.65, 0.4), accent)
        Art.cylinder(visual_root, 0.07, 1.2, Vector3(0.75, 0.0, 0.4), accent)
    if archetype == "captain":
        for x in [-0.28, 0.0, 0.28]:
            Art.cylinder(visual_root, 0.1, 0.4, Vector3(x, 1.52, 0), accent, true)
    attack_marker = Art.cylinder(self, 0.18, 0.5, Vector3(0, 2.5, 0), Art.material(Color("#ffb73d")), true)
    attack_marker.visible = false

func _hit_reaction(source_position: Vector3) -> void:
    if body_mesh:
        var mat := body_mesh.material_override as StandardMaterial3D
        if mat:
            var original := mat.albedo_color
            mat.albedo_color = Color(1.0, 0.18, 0.1, 1)
            var tween := create_tween()
            tween.tween_property(visual_root, "scale", base_scale * Vector3(1.15, 0.82, 1.15), 0.06)
            tween.tween_property(visual_root, "scale", base_scale, 0.11)
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
    tween.tween_property(visual_root, "scale", base_scale * Vector3(0.9, 0.9, 1.18), 0.08)
    tween.tween_property(visual_root, "scale", base_scale, 0.12)

