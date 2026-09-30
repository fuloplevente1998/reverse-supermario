extends Button
var pointer := -1

func _ready() -> void:
    toggle_mode = true
    visibility_changed.connect(_release_pointer)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if not event.pressed and event.index == pointer:
            _release_pointer()
            get_viewport().set_input_as_handled()
        elif event.pressed and pointer == -1 and is_visible_in_tree() and not disabled:
            var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
            if local.distance_to(size*0.5) <= minf(size.x,size.y)*0.5:
                pointer = event.index
                set_pressed_no_signal(true)
                button_down.emit()
                get_viewport().set_input_as_handled()

func _release_pointer() -> void:
    if pointer != -1:
        pointer = -1
        set_pressed_no_signal(false)
        button_up.emit()

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        _release_pointer()
