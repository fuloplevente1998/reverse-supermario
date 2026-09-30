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
var model_animation: AnimationPlayer
var model_attack_time: float = 0.0
var jump_buffer := 0.0
var coyote_time := 0.0
const Art = preload("res://scripts/art.gd")
const KNIGHT_MODEL = preload("res://assets/models/knight_study.glb")
const KNIGHT_SWORD = preload("res://assets/models/broadsword_study.glb")
const KNIGHT_SHIELD = preload("res://assets/models/kite_shield_study.glb")

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
    var platformer: bool = get_parent().stage_number == 1 and bool(camera_pivot.get("side_view"))
    if platformer:
        coyote_time = 0.10 if is_on_floor() else maxf(0.0,coyote_time-delta)
        jump_buffer = 0.12 if wants_jump else maxf(0.0,jump_buffer-delta)
    if (platformer and jump_buffer>0.0 and coyote_time>0.0) or (not platformer and wants_jump and is_on_floor()):
        velocity.y = jump_velocity
        jump_buffer = 0.0
        coyote_time = 0.0
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
    var on_center_line: bool = bool(camera_pivot.get("side_view"))
    if on_center_line:
        # Screen left/right controls only forward/back along the stage's Z axis.
        input_vec = Vector2(input_vec.x, 0.0)
        position.x = 0.0
        velocity.x = 0.0

    blocking = Input.is_action_pressed("block") or touch_block

    if input_vec.length_squared() > 0.01:
        var basis_y := Basis(Vector3.UP, camera_yaw)
        var direction := (basis_y * Vector3(-input_vec.x, 0.0, input_vec.y)).normalized()
        if camera_pivot.get("side_view"):
            direction = Vector3(0.0, 0.0, input_vec.x).normalized()
        var speed := move_speed
        speed *= input_vec.length()
        if blocking:
            speed *= 0.48
        velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * surface_acceleration * delta)
        velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * surface_acceleration * delta)
        rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), minf(1.0, delta * 14.0))
        if visual_root:
            visual_root.position.y = move_toward(visual_root.position.y, 0.0, delta * 8.0)
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
    if on_center_line:
        position.x = 0.0
        velocity.x = 0.0
    _update_model_animation(delta)
    for i in range(legs.size()):
        var stride := sin(Time.get_ticks_msec() * 0.016 + i * PI) * 0.45
        var moving := Vector2(velocity.x, velocity.z).length() > 0.2 and is_on_floor()
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
    var model := KNIGHT_MODEL.instantiate() as Node3D
    model.name = "KnightModel"
    model.position.y = -0.9
    model.scale = Vector3.ONE * 0.9
    visual_root.add_child(model)
    model_animation = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
    body_mesh = model.find_child("KnightRuntime", true, false) as MeshInstance3D
    if body_mesh and body_mesh.mesh.get_surface_count() > 0:
        body_mesh.material_override = body_mesh.mesh.surface_get_material(0).duplicate()
    var skeleton := model.find_child("Skeleton3D", true, false) as Skeleton3D
    if skeleton:
        _attach_model_item(skeleton, "hand.R", KNIGHT_SWORD, false)
        _attach_model_item(skeleton, "hand.L", KNIGHT_SHIELD, true)
    if model_animation:
        for clip_name in ["idle", "run"]:
            if model_animation.has_animation(clip_name):
                model_animation.get_animation(clip_name).loop_mode = Animation.LOOP_LINEAR
        _play_model_animation("idle")

func _attach_model_item(skeleton: Skeleton3D, bone_name: String, item_scene: PackedScene, shield: bool) -> void:
    if skeleton.find_bone(bone_name) < 0:
        return
    var socket := BoneAttachment3D.new()
    socket.bone_name = bone_name
    skeleton.add_child(socket)
    var item := item_scene.instantiate() as Node3D
    socket.add_child(item)
    if shield:
        item.rotation.z = PI
        item.position = Vector3(0.0, 0.3, 0.12)
    else:
        # Hand bone local +Y follows the downward fingers. Flip the authored
        # blade and place its grip center, rather than its pommel, in the fist.
        item.rotation.z = PI
        item.position.y = 0.15

func _play_model_animation(clip_name: String) -> void:
    if model_animation and model_animation.has_animation(clip_name) and model_animation.current_animation != clip_name:
        model_animation.play(clip_name, 0.08)

func _update_model_animation(delta: float) -> void:
    if model_animation == null:
        return
    model_attack_time = maxf(0.0, model_attack_time - delta)
    if model_attack_time > 0.0:
        return
    if blocking:
        model_animation.speed_scale = 1.0
        _play_model_animation("block")
    elif not is_on_floor():
        model_animation.speed_scale = 1.0
        _play_model_animation("jump")
    elif Vector2(velocity.x, velocity.z).length() > 0.2:
        _play_model_animation("run")
        model_animation.speed_scale = clampf(Vector2(velocity.x, velocity.z).length() / move_speed, 0.45, 1.2)
    else:
        model_animation.speed_scale = 1.0
        _play_model_animation("idle")

func _attack_animation() -> void:
    if model_animation:
        model_animation.speed_scale = 1.0
        model_animation.play("attack", 0.035)
        model_attack_time = attack_cooldown
        return
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
