extends Node3D

@export_range(1, 10) var stage_number := 1
const StageTwo = preload("res://scripts/stage_two.gd")
const StageGenerator = preload("res://scripts/stage_generator.gd")
const DifficultyProfiles = preload("res://scripts/generation/difficulty_profiles.gd")
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
var side_view := false

func set_side_view(enabled: bool) -> void:
    if side_view == enabled:
        return
    side_view = enabled
    if stage_number == 1:
        if not enabled: StageGenerator.ensure_free_view_scenery(self)
        for scenery in get_tree().get_nodes_in_group("free_view_scenery"):
            if is_ancestor_of(scenery): scenery.visible = not enabled
        var env: Environment = $WorldEnvironment.environment
        # Reference pass: stronger warm key and restrained cool fill restore
        # shape to armor/stone instead of flattening the foreground.
        env.ambient_light_energy = 0.46 if enabled else 0.25
        $Sun.light_energy = 1.12 if enabled else 0.60
        if get_node_or_null("CharacterFill"):
            $CharacterFill.light_energy = 0.36 if enabled else 0.18
        player._update_side_presentation()
    var actors: Array = [player]
    for group in ["enemies", "hazards", "projectiles", "moving_platforms"]:
        actors.append_array(get_tree().get_nodes_in_group(group))
    for actor: Node3D in actors:
        if not is_instance_valid(actor) or not is_ancestor_of(actor):
            continue
        if enabled:
            actor.set_meta("free_view_x", actor.position.x)
            actor.position.x = 0.0
            if actor is CharacterBody3D:
                actor.velocity.x = 0.0
                _raise_to_safe_center(actor)
        elif actor.has_meta("free_view_x"):
            actor.position.x = float(actor.get_meta("free_view_x"))
            actor.remove_meta("free_view_x")
            if actor is CharacterBody3D:
                actor.velocity.x = 0.0
                _raise_to_safe_center(actor)

func _raise_to_safe_center(actor: CharacterBody3D) -> void:
    var query := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * 8.0, actor.global_position - Vector3.UP * 2.0)
    var excluded: Array[RID] = [player.get_rid()]
    for enemy: CharacterBody3D in get_tree().get_nodes_in_group("enemies"):
        excluded.append(enemy.get_rid())
    query.exclude = excluded
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        actor.global_position.y = maxf(actor.global_position.y, float(hit.position.y) + 0.92)
        actor.velocity.y = maxf(actor.velocity.y, 0.0)

func _ready() -> void:
    var build_started := Time.get_ticks_msec()
    $UI.process_mode = Node.PROCESS_MODE_ALWAYS
    _load_difficulty()
    _setup_environment()
    StageGenerator.build(self, stage_number)
    _build_boundaries()
    _apply_difficulty()
    _style_interface()
    _connect_gameplay()
    _bind_touch_buttons()
    _on_hp_changed(player.hp)
    if stage_number == 1:
        $Player/CameraPivot.set_view(true)
    set_meta("stage_build_ms", Time.get_ticks_msec() - build_started)
    if get_tree().get_meta("warm_enter", false):
        get_tree().remove_meta("warm_enter")
        call_deferred("_warm_start")

func _warm_start() -> void:
    # Render the actual opening before accepting play input. The UI stays live.
    var previous_mode := process_mode
    process_mode = Node.PROCESS_MODE_DISABLED
    var cover := ColorRect.new()
    cover.name = "StartupCover"
    cover.color = Color("#142639")
    cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    $UI.add_child(cover)
    var label := Label.new()
    label.text = "PÁLYA BETÖLTÉSE…"
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    cover.add_child(label)
    for frame in range(8): await get_tree().process_frame
    await get_tree().create_timer(0.35, true).timeout
    process_mode = previous_mode
    cover.queue_free()
    set_meta("startup_ready", true)

func _physics_process(_delta: float) -> void:
    if not ended and player.global_position.y < -6.0:
        player.global_position = checkpoint_position
        player.velocity = Vector3.ZERO
        player.take_damage(_hazard_damage(25))
        if not ended:
            _pulse_status("VISSZA AZ ELLENŐRZŐPONTRA -25")

func _on_trap_entered(body: Node3D) -> void:
    if body == player and not ended:
        player.take_damage(_hazard_damage(20))

func _recover_water() -> void:
    if ended:
        return
    player.global_position = checkpoint_position
    player.velocity = Vector3.ZERO
    player.take_damage(_hazard_damage(25))
    if not ended:
        _pulse_status("VIZES ÁROK — VISSZA AZ ELLENŐRZŐPONTRA")

func _on_checkpoint_entered(body: Node3D, spawn: Vector3 = Vector3(0, 1.1, 16.0)) -> void:
    if body == player and not ended and spawn.z > checkpoint_position.z:
        checkpoint_position = spawn
        if bool(get_meta("generator_rebuild", false)):
            var profile: Dictionary = DifficultyProfiles.get_profile(difficulty_index)
            player.heal(roundi(20.0 * float(profile["healing_multiplier"])))
        _pulse_status("ELLENŐRZŐPONT AKTÍV")

func side_ground_height(z: float) -> float:
    return StageGenerator.ground_height(stage_number, z, difficulty_index)

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

    $UI/TopBar.visible = false
    var health_panel := Panel.new()
    health_panel.name = "HealthPanel"
    health_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var health_style := StyleBoxFlat.new()
    health_style.bg_color = Color("#211a20")
    health_style.border_color = Color("#d5ac60")
    health_style.set_border_width_all(2)
    health_style.set_corner_radius_all(9)
    health_panel.add_theme_stylebox_override("panel", health_style)
    $UI.add_child(health_panel)
    hp_bar = ProgressBar.new()
    hp_bar.min_value = 0
    hp_bar.max_value = player.max_hp
    hp_bar.value = player.hp
    hp_bar.show_percentage = false
    hp_bar.custom_minimum_size = Vector2(264, 20)
    hp_bar.position = Vector2(12,31)
    hp_bar.size = Vector2(264,24)
    health_panel.add_child(hp_bar)
    var health_bg := StyleBoxFlat.new()
    health_bg.bg_color = Color("#120e16")
    health_bg.border_color = Color("#c39a50")
    health_bg.set_border_width_all(2)
    health_bg.set_corner_radius_all(5)
    hp_bar.add_theme_stylebox_override("background", health_bg)
    var health_fill := StyleBoxFlat.new()
    health_fill.bg_color = Color("#d73937")
    health_fill.set_corner_radius_all(4)
    hp_bar.add_theme_stylebox_override("fill", health_fill)

    var hp_text := Label.new()
    hp_text.name = "HPText"
    hp_text.text = "ÉLETERŐ"
    hp_text.position = Vector2(12,5)
    hp_text.add_theme_font_size_override("font_size", 17)
    $UI/HealthPanel.add_child(hp_text)

    objective_label = Label.new()
    objective_label.text = "%d. PÁLYA: %s — %s" % [stage_number, StageGenerator.title(stage_number), StageGenerator.goal(stage_number)]
    objective_label.position = Vector2(24, 78)
    objective_label.add_theme_font_size_override("font_size", 16)
    $UI.add_child(objective_label)

    kill_label = Label.new()
    kill_label.position = Vector2(24, 108)
    kill_label.add_theme_font_size_override("font_size", 16)
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
    view_button.name = "ViewMenu"
    view_button.text = "NÉZETVÁLTÁS  •  C"
    view_button.position = Vector2(1072, 20)
    view_button.size = Vector2(186, 43)
    _style_overlay_button(view_button)
    view_button.focus_mode = Control.FOCUS_NONE
    controls.add_child(view_button)
    view_button.pressed.connect($Player/CameraPivot.toggle_view)
    stage_button = Button.new()
    stage_button.position = Vector2(1072, 72)
    stage_button.size = Vector2(186, 43)
    _style_overlay_button(stage_button)
    stage_button.text = "PÁLYÁK"
    stage_button.focus_mode = Control.FOCUS_NONE
    controls.add_child(stage_button)
    stage_button.pressed.connect(_open_stage_panel)
    var home_button := Button.new()
    home_button.name = "HomeMenu"
    home_button.text = "FŐMENÜ"
    home_button.position = Vector2(1072, 124)
    home_button.size = Vector2(186, 43)
    _style_overlay_button(home_button)
    home_button.focus_mode = Control.FOCUS_NONE
    controls.add_child(home_button)
    home_button.pressed.connect(_go_home)
    $UI/Controls/Joystick.changed.connect(player.set_touch_axis)
    _build_stage_panel()
    _style_control_buttons()
    _layout_mobile_interface()
    get_viewport().size_changed.connect(_layout_mobile_interface)

func _style_overlay_button(button: Button) -> void:
    # Still a real, full-size touch target; only remove the huge opaque HUD.
    button.add_theme_font_size_override("font_size", 15)
    button.add_theme_color_override("font_color", Color("#f6eadd"))
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color(0.10, 0.13, 0.18, 0.64)
    normal.border_color = Color(0.73, 0.58, 0.38, 0.72)
    normal.set_border_width_all(1)
    normal.set_corner_radius_all(11)
    button.add_theme_stylebox_override("normal", normal)
    var pressed := normal.duplicate() as StyleBoxFlat
    pressed.bg_color = Color(0.18, 0.22, 0.28, 0.89)
    button.add_theme_stylebox_override("hover", pressed)
    button.add_theme_stylebox_override("pressed", pressed)


func _style_control_buttons() -> void:
    var labels := {"Jump":"UGRÁS", "Block":"VÉDÉS", "Attack":"TÁMADÁS"}
    for button: Button in [$UI/Controls/Actions/Jump,$UI/Controls/Actions/Attack,$UI/Controls/Actions/Block]:
        button.set_script(preload("res://scripts/round_touch_button.gd"))
        button.call("_ready")
        button.text = ""
        button.icon = load("res://assets/ui/%s.svg" % str(button.name).to_lower())
        button.add_theme_constant_override("icon_max_width",42)
        button.focus_mode = Control.FOCUS_NONE
        var backdrop := StyleBoxFlat.new()
        backdrop.bg_color = Color(0.13,0.09,0.13,0.90)
        backdrop.border_color = Color("#dab66d")
        backdrop.set_border_width_all(3)
        backdrop.set_corner_radius_all(52)
        backdrop.content_margin_bottom = 22.0
        button.add_theme_stylebox_override("normal",backdrop)
        var down := backdrop.duplicate() as StyleBoxFlat
        down.bg_color = Color("#723542")
        down.border_color = Color("#ffe4a3")
        button.add_theme_stylebox_override("pressed",down)
        button.add_theme_stylebox_override("hover",backdrop)
        var caption := Label.new()
        caption.text = labels[str(button.name)]
        caption.position = Vector2(0,75)
        caption.size = Vector2(104,20)
        caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        caption.add_theme_font_size_override("font_size",12)
        caption.add_theme_color_override("font_color",Color("#f8e5bc"))
        caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
        button.add_child(caption)

func mobile_safe_rect() -> Rect2:
    var viewport_size := get_viewport().get_visible_rect().size
    var area := Rect2(Vector2.ZERO,viewport_size)
    if OS.has_feature("android"):
        var safe := DisplayServer.get_display_safe_area()
        var window_size := Vector2(DisplayServer.window_get_size())
        if safe.size.x > 0 and safe.size.y > 0 and window_size.x > 0 and window_size.y > 0:
            var factor := viewport_size / window_size
            area = area.intersection(Rect2(Vector2(safe.position)*factor,Vector2(safe.size)*factor))
    return area

func _layout_mobile_interface(safe_override: Rect2 = Rect2()) -> void:
    if hp_bar == null:
        return
    var safe := mobile_safe_rect() if safe_override.size == Vector2.ZERO else safe_override
    $UI/HealthPanel.position = safe.position + Vector2(20,18)
    $UI/HealthPanel.size = Vector2(288,65)
    objective_label.position = safe.position + Vector2(22,91)
    kill_label.position = safe.position + Vector2(22,117)
    var menu_buttons := [controls.get_node("ViewMenu"),stage_button,controls.get_node("HomeMenu")]
    for index in range(menu_buttons.size()):
        menu_buttons[index].position = Vector2(safe.end.x-194,safe.position.y+20+52*index)
    var actions: Control = $UI/Controls/Actions
    actions.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    actions.position = Vector2(safe.end.x-354,safe.end.y-166)
    actions.size = Vector2(334,146)
    for item in [[$UI/Controls/Actions/Block,Vector2(0,36)],[$UI/Controls/Actions/Jump,Vector2(108,0)],[$UI/Controls/Actions/Attack,Vector2(216,36)]]:
        item[0].position = item[1]
        item[0].size = Vector2(104,104)
    var joystick: Control = $UI/Controls/Joystick
    joystick.position = Vector2(safe.position.x+28,safe.end.y-220)
    status_label.position.x = safe.get_center().x-status_label.size.x*0.5
    stage_panel.position = safe.get_center()-stage_panel.size*0.5
    restart_button.position.x = safe.get_center().x-restart_button.size.x*0.5
    next_button.position.x = safe.get_center().x-next_button.size.x*0.5

func _on_hp_changed(value: int) -> void:
    if hp_bar:
        hp_bar.value = value

func _on_enemy_defeated() -> void:
    if stage_number == 10 and goal.overlaps_body(player):
        call_deferred("_on_goal_body_entered", player)
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
    if stage_number == 10:
        var captain := get_node_or_null("Captain")
        if captain and not captain.dead:
            _pulse_status("ELŐBB GYŐZD LE A KAPITÁNYT!")
            return
    if stage_number < 10:
        _unlock_stage(stage_number + 1)
        _finish_game("%d. PÁLYA TELJESÍTVE" % stage_number)
        next_button.visible = true
        next_button.move_to_front()
    else:
        _finish_game("A KAPITÁNY LEGYŐZVE — A HERCEGNŐ VÁRA A TIÉD!")

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
    var profile: Dictionary = DifficultyProfiles.get_profile(difficulty_index)
    player.max_hp = int(profile["player_health"])
    player.hp = player.max_hp
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if is_ancestor_of(enemy):
            enemy.apply_difficulty(profile)

func _hazard_damage(amount: int) -> int:
    var profile: Dictionary = DifficultyProfiles.get_profile(difficulty_index)
    return maxi(1, roundi(amount * float(profile["hazard_damage_multiplier"])))

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
    $UI/Controls/Joystick._reset_pointer()
    player.set_touch_action("block", false)
    get_tree().paused = true

func _close_stage_panel() -> void:
    stage_panel.visible = false
    get_tree().paused = false
    controls.visible = true

func _cycle_difficulty() -> void:
    difficulty_index = (difficulty_index + 1) % 3
    var progress := ConfigFile.new()
    progress.load(SAVE_PATH)
    progress.set_value("progress", "difficulty", difficulty_index)
    if progress.save(SAVE_PATH) != OK:
        push_error("Unable to save difficulty")
    difficulty_button.text = _difficulty_text()
    get_tree().paused = false
    # Restart so player and guard statistics use the same chosen difficulty.
    get_tree().call_deferred("reload_current_scene")

func _select_stage(number: int) -> void:
    get_tree().paused = false
    if _is_stage_unlocked(number):
        get_tree().call_deferred("change_scene_to_file", _stage_path(number))

func _open_next_stage() -> void:
    if stage_number < 10:
        get_tree().call_deferred("change_scene_to_file", _stage_path(stage_number + 1))

func _go_home() -> void:
    get_tree().paused = false
    player.set_touch_axis(Vector2.ZERO)
    get_tree().call_deferred("change_scene_to_file", "res://scenes/title.tscn")

func _finish_game(message: String) -> void:
    ended = true
    if status_tween:
        status_tween.kill()
    for group in ["enemies", "hazards", "projectiles"]:
        for actor in get_tree().get_nodes_in_group(group):
            actor.set_physics_process(false)
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
    # Render 3D at 75% resolution; touch UI retains the native viewport size.
    get_viewport().scaling_3d_scale = 0.75
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
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    # Cool indirect fill keeps graphite armor legible from behind.
    env.ambient_light_color = Color(0.85, 0.88, 0.93)
    env.ambient_light_energy = 0.25
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.glow_enabled = false # Mobile: use emissive materials without post-process bloom.
    env.fog_enabled = true
    env.fog_light_color = Color(0.46, 0.40, 0.34, 1)
    env.fog_light_energy = 0.42
    env.fog_density = 0.0010
    env.fog_height = 0.0
    $WorldEnvironment.environment = env
    $Sun.light_color = Color(1.0, 0.88, 0.73)
    $Sun.light_energy = 0.60
    if stage_number == 1:
        # Cheap shadow-free camera-side fill: the dark playable silhouette
        # is not allowed to disappear against high-value courtyard stones.
        var front_fill := DirectionalLight3D.new()
        front_fill.name = "CharacterFill"
        front_fill.rotation_degrees = Vector3(-18,-90,0)
        front_fill.light_color = Color(0.81, 0.88, 1.0)
        front_fill.light_energy = 0.18
        front_fill.shadow_enabled = false
        add_child(front_fill)

func _build_boundaries() -> void:
    var half_width := StageGenerator.width(stage_number) * 0.5 - 0.3
    var stone := StandardMaterial3D.new()
    stone.albedo_color = Color(0.49, 0.57, 0.6)
    stone.roughness = 0.92
    var end_z := StageGenerator.end_z(stage_number, difficulty_index)
    var center_z := (end_z - 15.0) * 0.5
    _boundary("BoundaryWest", Vector3(-half_width, 5, center_z), Vector3(0.5, 12, end_z + 15), stone)
    _boundary("BoundaryEast", Vector3(half_width, 5, center_z), Vector3(0.5, 12, end_z + 15), stone)
    _boundary("BoundaryRear", Vector3(0, 5, -14.7), Vector3(half_width * 2, 12, 0.5), stone)
    _boundary("BoundaryFront", Vector3(0, 5, end_z - 0.3), Vector3(half_width * 2, 12, 0.5), stone)

func _boundary(node_name: String, center: Vector3, dimensions: Vector3, stone: Material) -> void:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = center
    add_child(body)
    var collision := CollisionShape3D.new()
    collision.name = "Collision"
    var shape := BoxShape3D.new()
    shape.size = dimensions
    collision.shape = shape
    body.add_child(collision)
    # Invisible collision keeps the scenery outside the traversable corridor.
