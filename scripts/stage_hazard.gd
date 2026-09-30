extends Area3D

const Art = preload("res://scripts/art.gd")
var kind := "spikes"
var damage := 18
var period := 3.5
var phase := 0.0
var travel := 0.0
var dimensions := Vector3(4.5, 0.7, 1.5)
var elapsed := 0.0
var hit_delay := 0.0
var origin := Vector3.ZERO
var active := false
var material: StandardMaterial3D
var visual: Node3D

func _ready() -> void:
    add_to_group("hazards")
    origin = position
    collision_layer = 0
    collision_mask = 1
    var shape := BoxShape3D.new()
    shape.size = dimensions
    var collision := CollisionShape3D.new()
    collision.shape = shape
    add_child(collision)
    material = Art.material(Color("#efbd64"))
    material.emission_enabled = true
    visual = Node3D.new()
    add_child(visual)
    if kind == "saw":
        Art.cylinder(visual, 0.65, 0.25, Vector3.ZERO, material)
        for i in range(8):
            var angle := i * TAU / 8.0
            Art.box(visual, Vector3(0.28, 0.2, 0.28), Vector3(cos(angle) * 0.65, 0, sin(angle) * 0.65), material)
    elif kind == "fire":
        for x in [-1.5, 0.0, 1.5]:
            Art.cylinder(visual, 0.5, 1.6, Vector3(x, 0, 0), material, true)
    else:
        for i in range(5):
            Art.cylinder(visual, 0.25, 0.65, Vector3((i - 2) * dimensions.x / 5.0, 0, 0), material, true)
    # A permanent pad shows the footprint even during the inactive phase.
    Art.box(self, Vector3(dimensions.x, 0.09, dimensions.z), Vector3(0, -dimensions.y * 0.5, 0), Art.material(Color("#76593d")))
    _update_phase()

func _physics_process(delta: float) -> void:
    elapsed += delta
    hit_delay = maxf(0.0, hit_delay - delta)
    _update_phase()
    if kind == "saw":
        position.x = origin.x + sin(elapsed * TAU / period + phase) * travel
        visual.rotation.y += delta * 7.0
    if get_parent().get("side_view") == true:
        position.x = 0.0
    if active and hit_delay <= 0.0:
        for body in get_overlapping_bodies():
            if body.is_in_group("player") and not bool(body.get("dead")):
                body.call("take_damage", damage)
                hit_delay = 0.9
                break

func _update_phase() -> void:
    var cycle := fposmod(elapsed + phase, period) / period
    active = kind == "saw" or (cycle >= 0.5 and cycle < 0.87)
    var warning := cycle >= 0.34 and cycle < 0.5
    material.albedo_color = Color("#ff632e") if active else (Color("#ffc95e") if warning else Color("#637581"))
    material.emission = material.albedo_color * (0.65 if active else 0.12)
    visual.scale.y = 1.0 if active else (0.5 if warning else 0.12)
