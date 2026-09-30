extends Node3D

var side_view := false
var target: CharacterBody3D
var look_ahead := 3.6
const SIDE_HEIGHT := 12.0
const SIDE_FLOOR_CENTER := 3.0
@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
    target = get_parent() as CharacterBody3D
    top_level = true
    global_rotation = Vector3.ZERO
    global_position = target.global_position
    _place_camera()

func toggle_view() -> void:
    set_view(not side_view)

func set_view(enabled: bool) -> void:
    side_view = enabled
    target.get_parent().call("set_side_view", enabled)
    look_ahead = 3.6
    global_position = _focus()
    _place_camera()

func _process(delta: float) -> void:
    if side_view and absf(target.velocity.z) > 0.2:
        look_ahead = lerpf(look_ahead, signf(target.velocity.z) * 3.6, 1.0 - exp(-3.0 * delta))
    global_position = global_position.lerp(_focus(), 1.0 - exp(-8.0 * delta))
    camera.look_at(global_position if side_view else global_position + Vector3(0, 0.65, 0))

func _focus() -> Vector3:
    if side_view:
        # Keep ordinary jumps inside a stable frame; follow only tall platforms.
        var ground: float = target.get_parent().side_ground_height(target.global_position.z)
        return Vector3(0, ground + SIDE_FLOOR_CENTER + maxf(0.0, target.global_position.y - ground - 4.8), target.global_position.z + look_ahead)
    return target.global_position

func _place_camera() -> void:
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL if side_view else Camera3D.PROJECTION_PERSPECTIVE
    camera.keep_aspect = Camera3D.KEEP_HEIGHT
    camera.size = SIDE_HEIGHT
    camera.cull_mask = 5 if side_view else 3
    camera.position = Vector3(-30, 0, 0) if side_view else Vector3(-0.6, 2.45, -5.55)
    camera.fov = 58.0 if side_view else 60.0
    camera.look_at(global_position if side_view else global_position + Vector3(0, 0.65, 0))

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_C:
        toggle_view()
