extends Node3D

var side_view := false
var target: CharacterBody3D
@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
    target = get_parent() as CharacterBody3D
    top_level = true
    global_rotation = Vector3.ZERO
    global_position = target.global_position
    _place_camera()

func toggle_view() -> void:
    side_view = not side_view
    target.get_parent().call("set_side_view", side_view)
    global_position = target.global_position
    _place_camera()

func _process(delta: float) -> void:
    global_position = global_position.lerp(target.global_position, 1.0 - exp(-14.0 * delta))
    camera.look_at(global_position + Vector3(0, 0.65, 0))

func _place_camera() -> void:
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL if side_view else Camera3D.PROJECTION_PERSPECTIVE
    camera.size = 14.0
    camera.position = Vector3(-14, 0.65, 0) if side_view else Vector3(-0.6, 2.45, -5.55)
    camera.fov = 58.0 if side_view else 60.0
    camera.look_at(global_position + Vector3(0, 0.65, 0))

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_C:
        toggle_view()
