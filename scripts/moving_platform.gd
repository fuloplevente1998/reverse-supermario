extends AnimatableBody3D

@export var travel: float = 3.0
@export var period: float = 3.2
var origin: Vector3
var elapsed := 0.0

func _ready() -> void:
    origin = position
    sync_to_physics = true

func _physics_process(delta: float) -> void:
    elapsed += delta
    position = origin + Vector3(sin(elapsed * TAU / period) * travel, 0, 0)
