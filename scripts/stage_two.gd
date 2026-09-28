extends RefCounted

const Art = preload("res://scripts/art.gd")
const MovingPlatform = preload("res://scripts/moving_platform.gd")

static func build(game: Node3D) -> void:
    # Remove the continuous floor before the first physics tick. Each gap is 4 m.
    game.get_node("Ground").queue_free()
    var stone := Art.material(Color("#394451"))
    var edge := Art.material(Color("#a87c50"), 0.5)
    var danger := Art.material(Color("#d14b36"))
    danger.emission_enabled = true
    danger.emission = Color("#9e271b")
    for segment in [[-15.0, 7.0], [11.0, 21.0], [25.0, 45.0]]:
        var start: float = segment[0]
        var finish: float = segment[1]
        _solid_box(game, Vector3(17, 1, finish - start), Vector3(0, -0.5, (start + finish) * 0.5), stone)
        for z in [start, finish]:
            Art.box(game, Vector3(17, 0.18, 0.3), Vector3(0, 0.08, z), edge)
    for z in [9.0, 23.0]:
        var platform := MovingPlatform.new()
        platform.name = "MovingBridge%d" % int(z)
        platform.position = Vector3(0, -0.05, z)
        platform.travel = 2.6
        platform.period = 3.1 if z < 20.0 else 4.2
        game.add_child(platform)
        var mesh := Art.box(platform, Vector3(3.8, 0.38, 2.4), Vector3.ZERO, edge)
        mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = Vector3(3.8, 0.38, 2.4)
        collision.shape = shape
        platform.add_child(collision)
    for z in [2.0, 16.0, 29.0]:
        var trap := Area3D.new()
        trap.name = "SpikeTrap%d" % int(z)
        trap.position = Vector3(0, 0.16, z)
        game.add_child(trap)
        var shape := BoxShape3D.new()
        shape.size = Vector3(5.0, 0.42, 1.5)
        var collision := CollisionShape3D.new()
        collision.shape = shape
        trap.add_child(collision)
        for x in [-2.0, -1.0, 0.0, 1.0, 2.0]:
            Art.cylinder(trap, 0.27, 0.45, Vector3(x, 0.08, 0), danger, true)
        trap.body_entered.connect(Callable(game, "_on_trap_entered"))
    var checkpoint := Area3D.new()
    checkpoint.name = "Checkpoint"
    checkpoint.position = Vector3(0, 1.0, 18.0)
    game.add_child(checkpoint)
    var marker := Art.material(Color("#3cbed2"))
    marker.emission_enabled = true
    marker.emission = Color("#167f9a")
    Art.cylinder(checkpoint, 0.22, 2.4, Vector3(0, 0.2, 0), marker)
    var checkpoint_shape := CylinderShape3D.new()
    checkpoint_shape.radius = 2.0
    checkpoint_shape.height = 2.5
    var checkpoint_collision := CollisionShape3D.new()
    checkpoint_collision.shape = checkpoint_shape
    checkpoint.add_child(checkpoint_collision)
    checkpoint.body_entered.connect(Callable(game, "_on_checkpoint_entered"))

static func _solid_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    parent.add_child(body)
    Art.box(body, size, Vector3.ZERO, mat)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
