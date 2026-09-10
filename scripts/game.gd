extends Node3D

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

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _setup_environment()
    _build_world_details()
    _style_interface()
    _connect_gameplay()
    _bind_touch_buttons()
    _on_hp_changed(player.hp)

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
    objective_label.text = "CÉL: TÖRD ÁT A HŐSÖK VÉDELMÉT ÉS ÉRD EL A KAPUT"
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

    controls.z_index = 10

    vignette = ColorRect.new()
    vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vignette.color = Color(0.35, 0.0, 0.0, 0.0)
    vignette.z_index = 5
    $UI.add_child(vignette)
    $UI.move_child(vignette, 0)

    _style_control_buttons()

func _style_control_buttons() -> void:
    var buttons := [
        $UI/Controls/Move/Up,
        $UI/Controls/Move/Down,
        $UI/Controls/Move/Left,
        $UI/Controls/Move/Right,
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
    var camera := $Player/CameraPivot/Camera3D as Camera3D
    if camera:
        var base := camera.position
        var tween := create_tween()
        tween.tween_property(camera, "position", base + Vector3(0, 0, 0.16), 0.05)
        tween.tween_property(camera, "position", base, 0.09)

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
    var tween := create_tween()
    tween.tween_interval(0.45)
    tween.tween_property(status_label, "modulate:a", 0.0, 0.35)
    tween.tween_callback(func():
        if not ended:
            status_label.text = ""
            status_label.modulate.a = 1.0
    )

func _on_player_died() -> void:
    _finish_game("A HŐSÖK MEGÁLLÍTOTTAK")

func _on_goal_body_entered(body: Node) -> void:
    if body == player and not ended:
        _finish_game("A KAPUT ELÉRTED")

func _finish_game(message: String) -> void:
    ended = true
    status_label.text = message
    status_label.modulate.a = 1.0
    if end_panel:
        end_panel.visible = true
    restart_button.visible = true
    restart_button.disabled = false
    restart_button.mouse_filter = Control.MOUSE_FILTER_STOP
    restart_button.move_to_front()
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
        $UI/Controls/Move/Up: "move_forward",
        $UI/Controls/Move/Down: "move_back",
        $UI/Controls/Move/Left: "move_left",
        $UI/Controls/Move/Right: "move_right",
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
    sky_mat.sky_top_color = Color(0.018, 0.022, 0.07, 1)
    sky_mat.sky_horizon_color = Color(0.31, 0.09, 0.12, 1)
    sky_mat.ground_bottom_color = Color(0.015, 0.018, 0.028, 1)
    sky_mat.ground_horizon_color = Color(0.11, 0.055, 0.07, 1)
    sky_mat.sun_angle_max = 12.0
    sky.sky_material = sky_mat
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = 0.55
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.glow_enabled = true
    env.fog_enabled = true
    env.fog_light_color = Color(0.2, 0.08, 0.1, 1)
    env.fog_light_energy = 0.55
    env.fog_density = 0.012
    env.fog_height = 0.0
    $WorldEnvironment.environment = env

func _build_world_details() -> void:
    var stone := StandardMaterial3D.new()
    stone.albedo_color = Color(0.105, 0.11, 0.14, 1)
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
