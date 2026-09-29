extends CharacterBody3D

signal hp_changed(value: int)
signal died
signal attack_performed
signal damage_taken(amount: int, blocked: bool)

@export var move_speed: float = 7.2
@export var acceleration: float = 24.0
@export var jump_velocity: float = 8.0
@export var max_hp: int = 100
@export var attack_damage: int = 30
@export var attack_range: float = 2.8
@export var attack_cooldown: float = 0.38

var surface_acceleration := 1.0
var hp: int = 100
var blocking: bool = false
var attack_ready: bool = true
var dead: bool = false

var touch_forward: bool = false
var touch_back: bool = false
var touch_left: bool = false
var touch_right: bool = false
var touch_jump: bool = false
var touch_attack: bool = false
var touch_block: bool = false
var touch_axis := Vector2.ZERO

var visual_root: Node3D
var body_mesh: MeshInstance3D
var weapon_root: Node3D
var camera_pivot: Node3D
var camera_yaw: float = 0.0
var legs: Array[Node3D] = []
var model_animator: AnimationPlayer
var model_idle := ""
var model_run := ""
const Art = preload("res://scripts/art.gd")

func _ready() -> void:
    hp = max_hp
    add_to_group("player")
    camera_pivot = get_node_or_null("CameraPivot") as Node3D
    _build_character_visual()

func _physics_process(delta: float) -> void:
    if dead:
        return

    if not is_on_floor():
        velocity += get_gravity() * delta

    var wants_jump: bool = Input.is_action_just_pressed("jump") or touch_jump
    if wants_jump and is_on_floor():
        velocity.y = jump_velocity
        _jump_squash()
    touch_jump = false

    var keyboard_vec := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
    var touch_vec := Vector2(
        float(int(touch_right) - int(touch_left)),
        float(int(touch_forward) - int(touch_back))
    )
    var input_vec := touch_axis if touch_axis.length_squared() > 0.01 else (touch_vec if touch_vec.length_squared() > 0.01 else keyboard_vec)
    if input_vec.length() > 1.0:
        input_vec = input_vec.normalized()

    blocking = Input.is_action_pressed("block") or touch_block

    if input_vec.length_squared() > 0.01:
        var basis_y := Basis(Vector3.UP, camera_yaw)
        var direction := (basis_y * Vector3(-input_vec.x, 0.0, input_vec.y)).normalized()
        if camera_pivot.get("side_view"):
            direction = Vector3(-input_vec.y, 0.0, input_vec.x).normalized()
        var speed := move_speed
        speed *= input_vec.length()
        if blocking:
            speed *= 0.48
        velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * surface_acceleration * delta)
        velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * surface_acceleration * delta)
        rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), minf(1.0, delta * 14.0))
        if visual_root:
            visual_root.position.y = sin(Time.get_ticks_msec() * 0.021) * 0.045
    else:
        velocity.x = move_toward(velocity.x, 0.0, acceleration * surface_acceleration * delta)
        velocity.z = move_toward(velocity.z, 0.0, acceleration * surface_acceleration * delta)
        if visual_root:
            visual_root.position.y = move_toward(visual_root.position.y, 0.0, delta * 0.5)

    _update_block_pose(delta)

    if Input.is_action_just_pressed("attack") or touch_attack:
        touch_attack = false
        attack()

    move_and_slide()
    var moving := Vector2(velocity.x, velocity.z).length() > 0.2 and is_on_floor()
    if model_animator and model_idle != "" and model_run != "":
        var desired := model_run if moving else model_idle
        if model_animator.current_animation != desired:
            model_animator.play(desired, 0.13)
    else:
        # The original procedural model still supports the legacy leg motion.
        for i in range(legs.size()):
            var stride := sin(Time.get_ticks_msec() * 0.016 + i * PI) * 0.45
            legs[i].rotation.x = lerpf(legs[i].rotation.x, stride if moving else 0.0, minf(1.0, delta * 14.0))

func attack() -> void:
    if not attack_ready or dead or blocking:
        return
    attack_ready = false
    attack_performed.emit()
    _attack_animation()

    var forward := global_transform.basis.z.normalized()
    var best_enemy: Node3D = null
    var best_score: float = -2.0
    for enemy_node in get_tree().get_nodes_in_group("enemies"):
        var enemy := enemy_node as Node3D
        if enemy == null or not is_instance_valid(enemy):
            continue
        var offset := enemy.global_position - global_position
        var flat := Vector3(offset.x, 0.0, offset.z)
        if flat.length() <= attack_range and flat.length() > 0.01:
            var score := forward.dot(flat.normalized())
            if score > -0.15 and score > best_score:
                best_score = score
                best_enemy = enemy

    if best_enemy and best_enemy.has_method("take_damage"):
        best_enemy.call("take_damage", attack_damage, global_position)
        var target_dir := best_enemy.global_position - global_position
        target_dir.y = 0.0
        if target_dir.length() > 0.01:
            rotation.y = atan2(target_dir.x, target_dir.z)

    await get_tree().create_timer(attack_cooldown).timeout
    attack_ready = true

func take_damage(amount: int) -> void:
    if dead:
        return
    var actual := amount
    var was_blocked := blocking
    if blocking:
        actual = maxi(1, int(ceil(float(amount) * 0.28)))
    hp = maxi(0, hp - actual)
    hp_changed.emit(hp)
    damage_taken.emit(actual, was_blocked)
    _damage_flash(was_blocked)
    if hp <= 0:
        dead = true
        velocity = Vector3.ZERO
        died.emit()

func set_touch_action(action: StringName, pressed: bool) -> void:
    match action:
        &"move_forward":
            touch_forward = pressed
        &"move_back":
            touch_back = pressed
        &"move_left":
            touch_left = pressed
        &"move_right":
            touch_right = pressed
        &"jump":
            if pressed:
                touch_jump = true
        &"attack":
            if pressed:
                touch_attack = true
        &"block":
            touch_block = pressed
        _:
            if pressed:
                Input.action_press(action)
            else:
                Input.action_release(action)

func set_touch_axis(axis: Vector2) -> void:
    touch_axis = axis

func _build_character_visual() -> void:
    var old_mesh := get_node_or_null("Mesh") as MeshInstance3D
    if old_mesh:
        old_mesh.visible = false

    visual_root = Node3D.new()
    visual_root.name = "VillainVisual"
    add_child(visual_root)
    if _install_blender_visual():
        return

    var dark := StandardMaterial3D.new()
    dark.albedo_color = Color(0.055, 0.025, 0.07, 1)
    dark.metallic = 0.32
    dark.roughness = 0.36

    var crimson := StandardMaterial3D.new()
    crimson.albedo_color = Color(0.55, 0.025, 0.055, 1)
    crimson.metallic = 0.18
    crimson.roughness = 0.30

    var steel := StandardMaterial3D.new()
    steel.albedo_color = Color(0.27, 0.30, 0.38, 1)
    steel.metallic = 0.82
    steel.roughness = 0.18

    body_mesh = MeshInstance3D.new()
    var torso := CapsuleMesh.new()
    torso.radius = 0.47
    torso.height = 0.95
    body_mesh.mesh = torso
    body_mesh.material_override = dark
    body_mesh.position.y = 0.2
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

        var horn := MeshInstance3D.new()
        var horn_mesh := CylinderMesh.new()
        horn_mesh.top_radius = 0.0
        horn_mesh.bottom_radius = 0.07
        horn_mesh.height = 0.42
        horn.mesh = horn_mesh
        horn.material_override = steel
        horn.position = Vector3(0.22 * side, 1.28, 0)
        horn.rotation_degrees.z = -22.0 * side
        visual_root.add_child(horn)

    legs = Art.armor(visual_root, true)
    Art.cape(visual_root)

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


func _install_blender_visual() -> bool:
    # CI generates this GLB using Blender before Godot imports the project.
    # A local checkout without Blender retains the existing procedural avatar.
    const MODEL_PATH := "res://assets/models/villain_knight.glb"
    if not ResourceLoader.exists(MODEL_PATH):
        return false
    var scene := load(MODEL_PATH) as PackedScene
    if scene == null:
        return false
    var model := scene.instantiate() as Node3D
    if model == null:
        return false
    visual_root.add_child(model)
    var chest := model.find_child("Chest", true, false) as MeshInstance3D
    var sword := model.find_child("WeaponPivot", true, false) as Node3D
    var left_leg := model.find_child("LegLeft", true, false) as Node3D
    var right_leg := model.find_child("LegRight", true, false) as Node3D
    if chest == null or sword == null or left_leg == null or right_leg == null:
        push_warning("Incomplete Blender character; using procedural fallback")
        visual_root.remove_child(model)
        model.queue_free()
        return false
    body_mesh = chest
    var chest_material := chest.get_active_material(0)
    if chest_material is StandardMaterial3D:
        # Per-character copy: the damage flash must not tint every instance.
        body_mesh.material_override = chest_material.duplicate() as StandardMaterial3D
    weapon_root = sword
    legs = [left_leg, right_leg]
    # Use skeletal animation when the new rig is present. Preserve the prior
    # procedural attack and block controls, independent of locomotion.
    var animation_nodes := model.find_children("*", "AnimationPlayer", true, false)
    if not animation_nodes.is_empty():
        model_animator = animation_nodes[0] as AnimationPlayer
        for clip in model_animator.get_animation_list():
            var label := String(clip).to_lower()
            if label.contains("idle"):
                model_idle = String(clip)
            elif label.contains("run"):
                model_run = String(clip)
        if model_idle != "":
            model_animator.play(model_idle)
    else:
        # The 0.0.9 non-skeletal GLB uses the original waving cape shader.
        Art.cape(visual_root)
    return true

func _attack_animation() -> void:
    if weapon_root == null:
        return
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(weapon_root, "rotation_degrees:x", -115.0, 0.09)
    tween.tween_property(weapon_root, "rotation_degrees:x", 22.0, 0.17)
    tween.tween_property(weapon_root, "rotation_degrees:x", 0.0, 0.10)

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
    weapon_root.rotation_degrees.z = lerp(weapon_root.rotation_degrees.z, target, minf(1.0, delta * 12.0))

func _damage_flash(was_blocked: bool) -> void:
    if body_mesh == null:
        return
    var mat := body_mesh.material_override as StandardMaterial3D
    if mat == null:
        return
    var original := mat.albedo_color
    if was_blocked:
        mat.albedo_color = Color(0.2, 0.55, 1.0, 1)
    else:
        mat.albedo_color = Color(1.0, 0.12, 0.1, 1)
    await get_tree().create_timer(0.11).timeout
    if is_instance_valid(mat):
        mat.albedo_color = original
