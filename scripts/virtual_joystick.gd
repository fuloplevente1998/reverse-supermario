extends Control

signal changed(axis: Vector2)

var pointer := -1
var mouse_active := false
var thumb := Vector2.ZERO

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    queue_redraw()

func _draw() -> void:
    var center := size * 0.5
    var radius := minf(size.x, size.y) * 0.42
    draw_circle(center, radius, Color(0.08, 0.13, 0.2, 0.46))
    draw_arc(center, radius, 0, TAU, 48, Color(0.84, 0.75, 0.58, 0.82), 5.0)
    draw_circle(center + thumb * radius, radius * 0.38, Color(0.8, 0.2, 0.13, 0.88))

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and pointer == -1:
            pointer = event.index
            _update_axis(event.position)
            accept_event()
        elif not event.pressed and pointer == event.index:
            pointer = -1
            _release()
            accept_event()
    elif event is InputEventScreenDrag and pointer == event.index:
        _update_axis(event.position)
        accept_event()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and pointer == -1:
        mouse_active = event.pressed
        if mouse_active:
            _update_axis(event.position)
        else:
            _release()
        accept_event()
    elif event is InputEventMouseMotion and mouse_active and pointer == -1:
        _update_axis(event.position)
        accept_event()

func _update_axis(local_point: Vector2) -> void:
    var radius := minf(size.x, size.y) * 0.42
    thumb = ((local_point - size * 0.5) / radius).limit_length(1.0)
    var axis := Vector2(thumb.x, -thumb.y)
    if axis.length() < 0.12:
        axis = Vector2.ZERO
    changed.emit(axis)
    queue_redraw()

func _release() -> void:
    thumb = Vector2.ZERO
    changed.emit(Vector2.ZERO)
    queue_redraw()
