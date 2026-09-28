extends RefCounted

const Art = preload("res://scripts/art.gd")
const MovingPlatform = preload("res://scripts/moving_platform.gd")
const StageTwo = preload("res://scripts/stage_two.gd")
const EnemyScript = preload("res://scripts/enemy.gd")

# Eight authored recipes. The deterministic seed varies decoration, while
# the jump gaps and checkpoint remain deliberately placed and traversable.
const STAGES := [
    {"name": "TÜSKEKERT", "gaps": [8, 27], "traps": [2, 20, 36], "color": Color("#537369"), "travel": 1.6},
    {"name": "JÉGGERINC", "gaps": [10, 25], "traps": [3, 20, 32], "color": Color("#91b5bd"), "travel": 2.8},
    {"name": "PARÁZSKOHÓ", "gaps": [8, 21, 34], "traps": [2, 28, 37], "color": Color("#81574b"), "travel": 2.0},
    {"name": "KÖDKAPU", "gaps": [7, 26], "traps": [1, 20, 34], "color": Color("#646c89"), "travel": 3.0},
    {"name": "ŐRTORONY", "gaps": [11, 28], "traps": [3, 19, 35], "color": Color("#a08c69"), "travel": 2.2},
    {"name": "HÍDLÁNC", "gaps": [8, 22, 33], "traps": [2, 28, 37], "color": Color("#5d7992"), "travel": 3.0},
    {"name": "ALKONYÚT", "gaps": [10, 25, 34], "traps": [3, 19, 30], "color": Color("#835d77"), "travel": 2.4},
    {"name": "TRÓN ELŐTT", "gaps": [9, 23, 32], "traps": [2, 27, 36], "color": Color("#866f5e"), "travel": 2.9},
]

static func title(stage_number: int) -> String:
    if stage_number == 1:
        return "VÁRUDVAR"
    if stage_number == 2:
        return "TÖRÖTT HÍD"
    return str(STAGES[stage_number - 3]["name"])

static func build(game: Node3D, stage_number: int) -> void:
    var recipe: Dictionary = STAGES[stage_number - 3]
    var gaps: Array = recipe["gaps"]
    var rng := RandomNumberGenerator.new()
    rng.seed = 8147 + stage_number * 101
    var stone := Art.material(recipe["color"])
    var trim := Art.material(Color("#c8ad79"), 0.55)
    var hazard := Art.material(Color("#e57944"))
    hazard.emission_enabled = true
    hazard.emission = Color("#b33e1e")
    game.get_node("Ground").queue_free()

    var left := -15.0
    var index := 0
    for gap in gaps:
        var center := float(gap)
        _floor(game, left, center - 2.0, stone, index)
        _bridge(game, center, float(recipe["travel"]), trim)
        left = center + 2.0
        index += 1
    _floor(game, left, 45.0, stone, index)

    for trap_z in recipe["traps"]:
        _spikes(game, float(trap_z), hazard)

    var checkpoint := Area3D.new()
    checkpoint.name = "Checkpoint"
    checkpoint.position = Vector3(0, 1.0, 16)
    game.add_child(checkpoint)
    var shape := CylinderShape3D.new()
    shape.radius = 1.5
    shape.height = 2.2
    var collision := CollisionShape3D.new()
    collision.shape = shape
    checkpoint.add_child(collision)
    var light := Art.material(Color("#55cce2"))
    light.emission_enabled = true
    light.emission = Color("#1e9db5")
    Art.cylinder(checkpoint, 0.18, 2.5, Vector3(0, 0.15, 0), light)
    checkpoint.body_entered.connect(Callable(game, "_on_checkpoint_entered"))

    # Repeatable accent layout; no random gap width or required jump distance.
    for side in [-1.0, 1.0]:
        for z in range(-9, 40, 7):
            var height := rng.randf_range(1.5, 3.5)
            Art.cylinder(game, 0.55, height, Vector3(11.0 * side, height * 0.5, z), stone)
            Art.cylinder(game, 0.15, 0.42, Vector3(11.0 * side, height + 0.22, z), hazard, true)

    var safe_z := [1.0, 15.0, 37.0, 4.0, 19.0, 30.0]
    for i in range(3):
        var enemy = game.get_node("Enemy%d" % (i + 1))
        enemy.position = Vector3(-3.0 if i % 2 == 0 else 3.0, 1.1, safe_z[i])
    var extras := mini(3, 1 + int((stage_number - 3) / 3))
    for i in range(extras):
        var z: float = safe_z[i + 3]
        var safe := true
        for gap in gaps:
            if absf(z - float(gap)) < 3.0:
                safe = false
        if not safe:
            continue
        var guard := CharacterBody3D.new()
        guard.name = "ExtraGuard%d" % i
        guard.set_script(EnemyScript)
        guard.position = Vector3(3.0, 1.1, z)
        var guard_shape := BoxShape3D.new()
        guard_shape.size = Vector3(1.1, 1.8, 1.1)
        var guard_collision := CollisionShape3D.new()
        guard_collision.shape = guard_shape
        guard.add_child(guard_collision)
        game.add_child(guard)

static func _floor(game: Node3D, start: float, finish: float, stone: Material, index: int) -> void:
    var body := StaticBody3D.new()
    body.name = "GeneratedFloor%d" % index
    body.position = Vector3(0, -0.5, (start + finish) * 0.5)
    game.add_child(body)
    var size := Vector3(18, 1, finish - start)
    Art.box(body, size, Vector3.ZERO, stone)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)

static func _bridge(game: Node3D, z: float, travel: float, trim: Material) -> void:
    var bridge := MovingPlatform.new()
    bridge.name = "MovingBridge%d" % int(z)
    bridge.position = Vector3(0, -0.07, z)
    bridge.travel = travel
    bridge.period = 2.8 + z * 0.045
    game.add_child(bridge)
    Art.box(bridge, Vector3(3.7, 0.32, 2.35), Vector3.ZERO, trim)
    var shape := BoxShape3D.new()
    shape.size = Vector3(3.7, 0.32, 2.35)
    var collision := CollisionShape3D.new()
    collision.shape = shape
    bridge.add_child(collision)

static func _spikes(game: Node3D, z: float, hazard: Material) -> void:
    var trap := Area3D.new()
    trap.name = "SpikeTrap%d" % int(z)
    trap.position = Vector3(0, 0.16, z)
    game.add_child(trap)
    var shape := BoxShape3D.new()
    shape.size = Vector3(5.2, 0.42, 1.4)
    var collision := CollisionShape3D.new()
    collision.shape = shape
    trap.add_child(collision)
    for x in [-2.0, -1.0, 0.0, 1.0, 2.0]:
        Art.cylinder(trap, 0.24, 0.43, Vector3(x, 0.08, 0), hazard, true)
    trap.body_entered.connect(Callable(game, "_on_trap_entered"))
