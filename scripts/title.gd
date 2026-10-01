extends Control

const SAVE_PATH := "user://reverse_platformer_progress.cfg"
const StageGenerator = preload("res://scripts/stage_generator.gd")

var difficulty_index := 1
var unlocked_stage := 1
var stage_panel: Control
var difficulty_button: Button
var loading := false

func _ready() -> void:
    var progress := ConfigFile.new()
    progress.load(SAVE_PATH)
    difficulty_index = clampi(int(progress.get_value("progress", "difficulty", 1)), 0, 2)
    unlocked_stage = clampi(int(progress.get_value("progress", "unlocked_stage", 1)), 1, 10)
    _build_menu()

func _draw() -> void:
    var bounds := get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, bounds), Color("#152f46"))
    draw_polygon(PackedVector2Array([Vector2(0, bounds.y * 0.6), Vector2(bounds.x * 0.35, bounds.y * 0.33), Vector2(bounds.x * 0.7, bounds.y * 0.63), Vector2(bounds.x, bounds.y * 0.36), Vector2(bounds.x, bounds.y), Vector2(0, bounds.y)]), PackedColorArray([Color("#294862"), Color("#294862"), Color("#294862"), Color("#294862"), Color("#294862"), Color("#294862")]))
    draw_rect(Rect2(0, bounds.y * 0.78, bounds.x, bounds.y * 0.22), Color("#112336"))
    # Distant castle and warm gate give the title its own scene without borrowed art.
    var base := Vector2(bounds.x * 0.75, bounds.y * 0.38)
    draw_rect(Rect2(base.x - 125, base.y + 76, 250, 196), Color("#0b1c2c"))
    for tower_x in [-135.0, 135.0]:
        draw_rect(Rect2(base.x + tower_x - 31, base.y, 62, 272), Color("#0b1c2c"))
        draw_polygon(PackedVector2Array([Vector2(base.x + tower_x - 44, base.y), Vector2(base.x + tower_x, base.y - 68), Vector2(base.x + tower_x + 44, base.y)]), PackedColorArray([Color("#0b1c2c"), Color("#0b1c2c"), Color("#0b1c2c")]))
    draw_rect(Rect2(base.x - 30, base.y + 172, 60, 100), Color("#e8a35d"))

func _build_menu() -> void:
    _label("FULTECH STUDIOS  /  KORONA ÁRNYÉKA", Vector2(70, 47), 22, Color("#f1c28d"))
    _label("A VÁR KAPUJÁIG", Vector2(70, 119), 49, Color("#f8f1df"))
    _label("Indulj a gonosz oldaláról. Győzd le az őröket,\nés juss el a hercegnő váráig!", Vector2(74, 195), 23, Color("#c8d9df"))
    _label("10 PÁLYA     •     3 NEHÉZSÉG     •     2 KAMERANÉZET", Vector2(74, 292), 17, Color("#f1c28d"))
    var play_text := "FOLYTATÁS — %d. PÁLYA" % unlocked_stage if unlocked_stage > 1 else "JÁTÉK INDÍTÁSA"
    _button(play_text, Vector2(72, 358), Vector2(390, 72), _start)
    _button("PÁLYAVÁLASZTÁS", Vector2(72, 445), Vector2(390, 67), _open_stages)
    difficulty_button = _button(_difficulty_text(), Vector2(72, 528), Vector2(390, 67), _cycle_difficulty)
    _label("MOZGÁS: JOYSTICK / WASD    •    UGRÁS: SZÓKÖZ    •    NÉZET: C", Vector2(72, 637), 15, Color("#a9c1ce"))
    _build_stage_panel()

func _label(value: String, at: Vector2, font_size: int, tint: Color) -> Label:
    var label := Label.new()
    label.text = value
    label.position = at
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", tint)
    add_child(label)
    return label

func _button(value: String, at: Vector2, dimensions: Vector2, callback: Callable) -> Button:
    var button := Button.new()
    button.text = value
    button.position = at
    button.size = dimensions
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 22)
    add_child(button)
    button.pressed.connect(callback)
    return button

func _build_stage_panel() -> void:
    stage_panel = Control.new()
    stage_panel.position = Vector2(170, 70)
    stage_panel.size = Vector2(940, 570)
    stage_panel.visible = false
    add_child(stage_panel)
    var backdrop := ColorRect.new()
    backdrop.color = Color("#132b40")
    backdrop.size = stage_panel.size
    stage_panel.add_child(backdrop)
    var title := Label.new()
    title.text = "PÁLYAVÁLASZTÁS"
    title.position = Vector2(42, 26)
    title.add_theme_font_size_override("font_size", 31)
    stage_panel.add_child(title)
    for number in range(1, 11):
        var button := Button.new()
        button.name = "Stage%d" % number
        button.text = "%d. %s" % [number, StageGenerator.title(number)] if number <= unlocked_stage else "%d. ZÁROLVA" % number
        button.position = Vector2(42 + ((number - 1) % 5) * 177, 100 + int((number - 1) / 5) * 124)
        button.size = Vector2(163, 91)
        button.disabled = number > unlocked_stage
        button.add_theme_font_size_override("font_size", 15)
        button.focus_mode = Control.FOCUS_NONE
        stage_panel.add_child(button)
        button.pressed.connect(_open_stage.bind(number))
    var back := Button.new()
    back.text = "VISSZA"
    back.position = Vector2(42, 394)
    back.size = Vector2(230, 72)
    stage_panel.add_child(back)
    back.pressed.connect(func(): stage_panel.visible = false)

func _difficulty_text() -> String:
    return "NEHÉZSÉG: %s" % ["KÖNNYŰ", "NORMÁL", "NEHÉZ"][difficulty_index]

func _cycle_difficulty() -> void:
    difficulty_index = (difficulty_index + 1) % 3
    var progress := ConfigFile.new()
    progress.load(SAVE_PATH)
    progress.set_value("progress", "difficulty", difficulty_index)
    progress.save(SAVE_PATH)
    difficulty_button.text = _difficulty_text()

func _open_stages() -> void:
    stage_panel.visible = true

func _start() -> void:
    _open_stage(unlocked_stage)

func _open_stage(number: int) -> void:
    if loading or number < 1 or number > unlocked_stage:
        return
    loading = true
    var cover := ColorRect.new()
    cover.color = Color("#142639")
    cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(cover)
    var label := Label.new()
    label.text = "PÁLYA BETÖLTÉSE…"
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    cover.add_child(label)
    await get_tree().process_frame
    if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
    var path := "res://scenes/main.tscn" if number == 1 else "res://scenes/stage%d.tscn" % number
    var error := ResourceLoader.load_threaded_request(path)
    if error != OK:
        cover.queue_free()
        loading = false
        return
    while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
        await get_tree().process_frame
    if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_LOADED:
        cover.queue_free()
        loading = false
        return
    var packed := ResourceLoader.load_threaded_get(path) as PackedScene
    get_tree().set_meta("warm_enter", DisplayServer.get_name() != "headless")
    get_tree().call_deferred("change_scene_to_packed", packed)
