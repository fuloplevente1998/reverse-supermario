extends Node3D

@export_range(1, 10) var stage_number := 1
const StageTwo = preload("res://scripts/stage_two.gd")
const StageGenerator = preload("res://scripts/stage_generator.gd")
const SAVE_PATH := "user://reverse_platformer_progress.cfg"

@onready var player = $Player
@onready var hp_label: Label = $UI/TopBar/HP
@onready var status_label: Label = $UI/Status
@onready var goal: Area3D = $Goal
@onready var restart_button: Button = $UI/Restart
@onready var controls: Control = $UI/Controls

var hp_bar: ProgressBar
var objective_label: Label
var kill_label: Label
var vignette: ColorRect
var end_panel: ColorRect
var enemies_total := 0
var enemies_defeated := 0
var ended := false
var status_tween: Tween
var next_button: Button
var stage_button: Button
var stage_panel: Control
var difficulty_button: Button
var difficulty_index := 1
var checkpoint_position := Vector3(0, 1.1, -10)

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _load_difficulty()
    _setup_environment()
    _build_world_details()
    if stage_number == 1:
        preload("res://scripts/art.gd").courtyard(self)
    elif stage_number == 2:
        StageTwo.build(self)
    else:
        StageGenerator.build(self, stage_number)
    _build_boundaries()
    _apply_difficulty()
    _style_interface()
    _connect_gameplay()
    _bind_touch_buttons()
    _on_hp_changed(player.hp)

func _physics_process(_delta: float) -> void:
    if stage_number >= 2 and not ended and player.global_position.y < -6.0:
        player.global_position = checkpoint_position
        player.velocity = Vector3.ZERO
        player.take_damage(_hazard_damage(25))
        if not ended:
            _pulse_status("VISSZA AZ ELLENŐRZŐPONTRA -25")

func _on_trap_entered(body: Node3D) -> void:
    if body == player and not ended:
        player.take_damage(_hazard_damage(20))

func _on_checkpoint_entered(body: Node3D) -> void:
    if body == player and not ended:
        checkpoint_position = Vector3(0, 1.1, 18.0 if stage_number == 2 else 16.0)
        _pulse_status("ELLENŐRZŐPONT AKTÍV")

func _connect_gameplay() -> void:
    player.hp_changed.connect(_on_hp_changed)
    player.died.connect(_on_player_died)
    player.attack_performed.connect(_on_player_attack)
    player.damage_taken.connect(_on_player_damage)
    goal.body_entered.connect(_on_goal_body_entered)
    restart_button.pressed.connect(_restart)
    restart_button.gui_input.connect(_on_restart_gui_input)

    var enemies := get_tree().get_nodes_in_group("enemies")
    enemies_total = enemies.size()
    for enemy in enemies:
        if enemy.has_signal("defeated"):
            enemy.defeated.connect(_on_enemy_defeated)
    _update_kills()

func _style_interface() -> void:
    hp_label.text = ""

    hp_bar = ProgressBar.new()
    hp_bar.min_value = 0
    hp_bar.max_value = player.max_hp
    hp_bar.value = player.hp
    hp_bar.show_percentage = false
    hp_bar.custom_minimum_size = Vector2(300, 26)
    $UI/TopBar.add_child(hp_bar)

    var hp_text := Label.new()
    hp_text.name = "HPText"
    hp_text.text = "ÉLETERŐ"
    hp_text.position = Vector2(0, -28)
    hp_text.add_theme_font_size_override("font_size", 17)
    $UI/TopBar.add_child(hp_text)

    objective_label = Label.new()
    objective_label.text = "%d. PÁLYA: %s — ÉRD EL A KAPUT" % [stage_number, StageGenerator.title(stage_number)]
    objective_label.position = Vector2(24, 78)
    objective_label.add_theme_font_size_override("font_size", 18)
    $UI.add_child(objective_label)

    kill_label = Label.new()
    kill_label.position = Vector2(24, 108)
    kill_label.add_theme_font_size_override("font_size", 18)
    $UI.add_child(kill_label)

    status_label.add_theme_font_size_override("font_size", 42)
    status_label.modulate = Color(1.0, 0.86, 0.62, 1)
    status_label.z_index = 101

    end_panel = ColorRect.new()
    end_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    end_panel.color = Color(0.015, 0.012, 0.025, 0.76)
    end_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    end_panel.visible = false
    end_panel.z_index = 90
    $UI.add_child(end_panel)

    restart_button.text = "ÚJRAINDÍTÁS"
    restart_button.visible = false
    restart_button.z_index = 120
    restart_button.mouse_filter = Control.MOUSE_FILTER_STOP
    restart_button.focus_mode = Control.FOCUS_NONE
    restart_button.add_theme_font_size_override("font_size", 25)
    restart_button.custom_minimum_size = Vector2(300, 92)

    next_button = Button.new()
    next_button.text = "KÖVETKEZŐ PÁLYA"
    next_button.position = Vector2(480, 235)
    next_button.size = Vector2(320, 78)
    next_button.add_theme_font_size_override("font_size", 24)
    next_button.focus_mode = Control.FOCUS_NONE
    next_button.z_index = 120
    next_button.visible = false
    $UI.add_child(next_button)
    next_button.pressed.connect(_open_next_stage)

    controls.z_index = 10

    vignette = ColorRect.new()
    vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vignette.color = Color(0.35, 0.0, 0.0, 0.0)
    vignette.z_index = 5
    $UI.add_child(vignette)
    $UI.move_child(vignette, 0)

    var view_button := Button.new()
    view_button.text = "NÉZETVÁLTÁS  •  C"
    view_button.position = Vector2(1000, 24)
    view_button.size = Vector2(250, 64)
    view_button.focus_mode = Control.FOCUS_NONE
    controls.add_child(view_button)
    view_button.pressed.connect($Player/CameraPivot.toggle_view)
    stage_button = Button.new()
    stage_button.position = Vector2(1000, 98)
    stage_button.size = Vector2(250, 57)
    stage_button.text = "PÁLYÁK"
    stage_button.focus_mode = Control.FOCUS_NONE
    controls.add_child(stage_button)
    stage_button.pressed.connect(_open_stage_panel)
    var home_button := Button.new()
    home_button.text = "FŐMENÜ"
    home_button.position = Vector2(1000, 165)
    home_button.size = Vector2(250, 55)
    home_button.focus_mode = Control.FOCUS_NONE
    controls.add_child(home_button)
    home_button.pressed.connect(_go_home)
    $UI/Controls/Joystick.changed.connect(player.set_touch_axis)
    _build_stage_panel()
    _style_control_buttons()

func _style_control_buttons() -> void:
    var buttons := [
        $UI/Controls/Actions/Jump,
        $UI/Controls/Actions/Attack,
        $UI/Controls/Actions/Block
    ]
    for button: Button in buttons:
        button.add_theme_font_size_override("font_size", 21)
        button.modulate = Color(1, 1, 1, 0.82)
        button.focus_mode = Control.FOCUS_NONE

    $UI/Controls/Actions/Jump.text = "UGRÁS"
    $UI/Controls/Actions/Attack.text = "TÁMADÁS"
    $UI/Controls/Actions/Block.text = "VÉDÉS"

func _on_hp_changed(value: int) -> void:
    if hp_bar:
        hp_bar.value = value

func _on_enemy_defeated() -> void:
    enemies_defeated += 1
    _update_kills()
    _pulse_status("ELLENFÉL LEGYŐZVE")

func _update_kills() -> void:
    if kill_label:
        kill_label.text = "ŐRÖK: %d / %d" % [enemies_defeated, enemies_total]

func _on_player_attack() -> void:
    pass

func _on_player_damage(amount: int, blocked: bool) -> void:
    if vignette:
        vignette.color = Color(0.1, 0.35, 0.8, 0.22) if blocked else Color(0.6, 0.0, 0.0, 0.28)
        var tween := create_tween()
        tween.tween_property(vignette, "color:a", 0.0, 0.3)
    _pulse_status("VÉDVE -%d" % amount if blocked else "TALÁLAT -%d" % amount)

func _pulse_status(text_value: String) -> void:
    if ended:
        return
    status_label.text = text_value
    status_label.modulate.a = 1.0
    if status_tween:
        status_tween.kill()
    status_tween = create_tween()
    status_tween.tween_interval(0.45)
    status_tween.tween_property(status_label, "modulate:a", 0.0, 0.35)
    status_tween.tween_callback(func():
        if not ended:
            status_label.text = ""
            status_label.modulate.a = 1.0
    )

func _on_player_died() -> void:
    _finish_game("A HŐSÖK MEGÁLLÍTOTTAK")

func _on_goal_body_entered(body: Node) -> void:
    if body != player or ended:
        return
    if stage_number < 10:
        _unlock_stage(stage_number + 1)
        _finish_game("%d. PÁLYA TELJESÍTVE" % stage_number)
        next_button.visible = true
        next_button.move_to_front()
    else:
        _finish_game("A KÜLDETÉS TELJESÍTVE")

func _stage_path(number: int) -> String:
    return "res://scenes/main.tscn" if number == 1 else "res://scenes/stage%d.tscn" % number

func _unlocked_stage() -> int:
    var progress := ConfigFile.new()
    if progress.load(SAVE_PATH) != OK:
        return 1
    return clampi(int(progress.get_value("progress", "unlocked_stage", 1)), 1, 10)

func _is_stage_unlocked(number: int) -> bool:
    return number <= _unlocked_stage()

func _unlock_stage(number: int) -> void:
    var progress := ConfigFile.new()
    progress.load(SAVE_PATH)
    progress.set_value("progress", "unlocked_stage", maxi(_unlocked_stage(), number))
    if progress.save(SAVE_PATH) != OK:
        push_error("Unable to save unlocked stage")

func _load_difficulty() -> void:
    var progress := ConfigFile.new()
    progress.load(SAVE_PATH)
    difficulty_index = clampi(int(progress.get_value("progress", "difficulty", 1)), 0, 2)

func _apply_difficulty() -> void:
    var player_health := [120, 100, 80]
    var enemy_health := [0.75, 1.0, 1.3]
    var enemy_damage := [0.7, 1.0, 1.4]
    player.max_hp = player_health[difficulty_index]
    player.hp = player.max_hp
    for enemy in get_tree().get_nodes_in_group("enemies"):
        enemy.max_hp = maxi(1, roundi(enemy.max_hp * enemy_health[difficulty_index]))
        enemy.hp = enemy.max_hp
        enemy.damage = maxi(1, roundi(enemy.damage * enemy_damage[difficulty_index]))
        enemy.move_speed *= [0.85, 1.0, 1.12][difficulty_index]

func _hazard_damage(amount: int) -> int:
    return maxi(1, roundi(amount * [0.75, 1.0, 1.3][difficulty_index]))

func _build_stage_panel() -> void:
    stage_panel = Control.new()
    stage_panel.position = Vector2(190, 80)
    stage_panel.size = Vector2(900, 540)
    stage_panel.z_index = 150
    stage_panel.visible = false
    $UI.add_child(stage_panel)
    var backdrop := ColorRect.new()
    backdrop.color = Color(0.045, 0.065, 0.1, 0.96)
    backdrop.size = stage_panel.size
    stage_panel.add_child(backdrop)
    var title := Label.new()
    title.text = "VÁLASSZ PÁLYÁT"
    title.position = Vector2(40, 26)
    title.add_theme_font_size_override("font_size", 30)
    stage_panel.add_child(title)
    for number in range(1, 11):
        var button := Button.new()
        button.text = "%d. %s" % [number, StageGenerator.title(number)]
        button.position = Vector2(40 + ((number - 1) % 5) * 168, 96 + int((number - 1) / 5) * 112)
        button.size = Vector2(155, 88)
        button.disabled = not _is_stage_unlocked(number)
        button.add_theme_font_size_override("font_size", 15)
        stage_panel.add_child(button)
        button.pressed.connect(_select_stage.bind(number))
    difficulty_button = Button.new()
    difficulty_button.position = Vector2(50, 360)
    difficulty_button.size = Vector2(370, 76)
    difficulty_button.text = _difficulty_text()
    stage_panel.add_child(difficulty_button)
    difficulty_button.pressed.connect(_cycle_difficulty)
    var close := Button.new()
    close.text = "VISSZA A JÁTÉKHOZ"
    close.position = Vector2(475, 360)
    close.size = Vector2(365, 76)
    stage_panel.add_child(close)
    close.pressed.connect(_close_stage_panel)
    var home := Button.new()
    home.text = "FŐMENÜ"
    home.position = Vector2(475, 449)
    home.size = Vector2(365, 60)
    stage_panel.add_child(home)
    home.pressed.connect(_go_home)

func _difficulty_text() -> String:
    var names := ["KÖNNYŰ", "NORMÁL", "NEHÉZ"]
    return "NEHÉZSÉG: %s" % names[difficulty_index]

func _open_stage_panel() -> void:
    stage_panel.visible = true
    controls.visible = false
    player.set_touch_axis(Vector2.ZERO)

func _close_stage_panel() -> void:
    stage_panel.visible = false
    controls.visible = true

func _cycle_difficulty() -> void:
    difficulty_index = (difficulty_index + 1) % 3
    var progress := ConfigFile.new()
    progress.load(SAVE_PATH)
    progress.set_value("progress", "difficulty", difficulty_index)
    if progress.save(SAVE_PATH) != OK:
        push_error("Unable to save difficulty")
    difficulty_button.text = _difficulty_text()
    # Restart so player and guard statistics use the same chosen difficulty.
    get_tree().call_deferred("reload_current_scene")

func _select_stage(number: int) -> void:
    if _is_stage_unlocked(number):
        get_tree().call_deferred("change_scene_to_file", _stage_path(number))

func _open_next_stage() -> void:
    if stage_number < 10:
        get_tree().call_deferred("change_scene_to_file", _stage_path(stage_number + 1))

func _go_home() -> void:
    player.set_touch_axis(Vector2.ZERO)
    get_tree().call_deferred("change_scene_to_file", "res://scenes/title.tscn")

func _finish_game(message: String) -> void:
    ended = true
    if status_tween:
        status_tween.kill()
    for enemy in get_tree().get_nodes_in_group("enemies"):
        enemy.set_physics_process(false)
    status_label.text = message
    status_label.modulate.a = 1.0
    if end_panel:
        end_panel.visible = true
    restart_button.visible = true
    restart_button.disabled = false
    restart_button.mouse_filter = Control.MOUSE_FILTER_STOP
    restart_button.move_to_front()
    var home := Button.new()
    home.text = "FŐMENÜ"
    home.position = Vector2(490, 335)
    home.size = Vector2(300, 66)
    home.z_index = 120
    home.focus_mode = Control.FOCUS_NONE
    $UI.add_child(home)
    home.pressed.connect(_go_home)
    status_label.move_to_front()
    player.set_physics_process(false)
    controls.visible = false
    for action in ["move_forward", "move_back", "move_left", "move_right", "jump", "attack", "block"]:
        Input.action_release(action)

func _on_restart_gui_input(event: InputEvent) -> void:
    if not ended:
        return
    if event is InputEventScreenTouch and event.pressed:
        _restart()
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _restart()

func _restart() -> void:
    if not ended:
        return
    restart_button.disabled = true
    ended = false
    get_tree().paused = false
    get_tree().reload_current_scene()

func _bind_touch_buttons() -> void:
    var bindings := {
        $UI/Controls/Actions/Jump: "jump",
        $UI/Controls/Actions/Attack: "attack",
        $UI/Controls/Actions/Block: "block"
    }
    for button in bindings:
        var action: StringName = bindings[button]
        button.button_down.connect(func(): player.set_touch_action(action, true))
        button.button_up.connect(func(): player.set_touch_action(action, false))

func _setup_environment() -> void:
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.12, 0.22, 0.34, 1)
    sky_mat.sky_horizon_color = Color(0.71, 0.51, 0.4, 1)
    sky_mat.ground_bottom_color = Color(0.09, 0.13, 0.17, 1)
    sky_mat.ground_horizon_color = Color(0.27, 0.21, 0.24, 1)
    sky_mat.sun_angle_max = 12.0
    sky.sky_material = sky_mat
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = 1.15
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.glow_enabled = false # Mobile: use emissive materials without post-process bloom.
    env.fog_enabled = true
    env.fog_light_color = Color(0.36, 0.3, 0.3, 1)
    env.fog_light_energy = 0.55
    env.fog_density = 0.003
    env.fog_height = 0.0
    $WorldEnvironment.environment = env
    $Sun.light_energy = 1.3

func _build_boundaries() -> void:
    var half_width := 17.7 if stage_number == 1 else (8.2 if stage_number == 2 else 8.7)
    var stone := StandardMaterial3D.new()
    stone.albedo_color = Color(0.49, 0.57, 0.6)
    stone.roughness = 0.92
    _boundary("BoundaryWest", Vector3(-half_width, 5, 15), Vector3(0.5, 12, 60), stone)
    _boundary("BoundaryEast", Vector3(half_width, 5, 15), Vector3(0.5, 12, 60), stone)
    _boundary("BoundaryRear", Vector3(0, 5, -14.7), Vector3(half_width * 2, 12, 0.5), stone)
    _boundary("BoundaryFront", Vector3(0, 5, 44.7), Vector3(half_width * 2, 12, 0.5), stone)

func _boundary(node_name: String, center: Vector3, dimensions: Vector3, stone: Material) -> void:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = center
    add_child(body)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = dimensions
    collision.shape = shape
    body.add_child(collision)
    # Low visible masonry; the tall collision prevents jumping outside.
    var railing := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(dimensions.x, 1.0, dimensions.z)
    railing.mesh = mesh
    railing.material_override = stone
    railing.position.y = -4.75
    body.add_child(railing)

func _build_world_details() -> void:
    var stone := StandardMaterial3D.new()
    stone.albedo_color = Color(0.25, 0.3, 0.36, 1)
    stone.roughness = 0.86

    var ember := StandardMaterial3D.new()
    ember.albedo_color = Color(0.85, 0.12, 0.025, 1)
    ember.emission_enabled = true
    ember.emission = Color(0.95, 0.055, 0.012, 1)
    ember.emission_energy_multiplier = 3.5

    var metal := StandardMaterial3D.new()
    metal.albedo_color = Color(0.12, 0.13, 0.17, 1)
    metal.metallic = 0.72
    metal.roughness = 0.31

    for z in range(-6, 39, 6):
        for side in [-1.0, 1.0]:
            var pillar := MeshInstance3D.new()
            var mesh := BoxMesh.new()
            mesh.size = Vector3(1.2, 3.8 + float((z + 6) % 3) * 0.4, 1.2)
            pillar.mesh = mesh
            pillar.material_override = stone
            pillar.position = Vector3(11.5 * side, mesh.size.y * 0.5, z)
            add_child(pillar)

            var cap := MeshInstance3D.new()
            var cap_mesh := BoxMesh.new()
            cap_mesh.size = Vector3(1.7, 0.35, 1.7)
            cap.mesh = cap_mesh
            cap.material_override = metal
            cap.position = pillar.position + Vector3(0, mesh.size.y * 0.5 + 0.15, 0)
            add_child(cap)

            if z % 12 == 0:
                var crystal := MeshInstance3D.new()
                var crystal_mesh := SphereMesh.new()
                crystal_mesh.radius = 0.22
                crystal_mesh.height = 0.44
                crystal.mesh = crystal_mesh
                crystal.material_override = ember
                crystal.position = cap.position + Vector3(0, 0.65, 0)
                add_child(crystal)

                var light := OmniLight3D.new()
                light.light_color = Color(1.0, 0.16, 0.04, 1)
                light.light_energy = 2.2
                light.omni_range = 7.0
                light.position = crystal.position
                add_child(light)

    for z in [-2.0, 10.0, 23.0, 34.0]:
        var arch_left := MeshInstance3D.new()
        var arch_mesh := BoxMesh.new()
        arch_mesh.size = Vector3(1.0, 5.2, 1.0)
        arch_left.mesh = arch_mesh
        arch_left.material_override = stone
        arch_left.position = Vector3(-5.5, 2.6, z)
        add_child(arch_left)

        var arch_right := MeshInstance3D.new()
        arch_right.mesh = arch_mesh
        arch_right.material_override = stone
        arch_right.position = Vector3(5.5, 2.6, z)
        add_child(arch_right)

        var lintel := MeshInstance3D.new()
        var lintel_mesh := BoxMesh.new()
        lintel_mesh.size = Vector3(12.0, 0.8, 1.1)
        lintel.mesh = lintel_mesh
        lintel.material_override = stone
        lintel.position = Vector3(0, 5.0, z)
        add_child(lintel)
