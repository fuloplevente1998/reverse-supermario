extends RefCounted

const Art = preload("res://scripts/art.gd")
const MovingPlatform = preload("res://scripts/moving_platform.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const Hazard = preload("res://scripts/stage_hazard.gd")

# Authored layouts: geometry and encounter placement differ, not only the palette.
const STAGES := [
    {"name":"VÁRUDVAR", "width":20.0, "gaps":[], "color":Color("#789482"), "sky":Color("#6a9bbe"), "enemies":[["guard",-4,6],["scout",4,24],["guard",0,35]]},
    {"name":"TÖRÖTT HÍD", "width":14.0, "gaps":[8,27], "color":Color("#7894a5"), "sky":Color("#7cacca"), "enemies":[["guard",-4,1],["archer",3,20],["scout",-3,35]]},
    {"name":"TÜSKEKERT", "width":18.0, "gaps":[], "color":Color("#649970"), "sky":Color("#8db8a6"), "enemies":[["scout",-5,0],["scout",5,20],["brute",0,36]]},
    {"name":"JÉGGERINC", "width":16.0, "gaps":[10,28], "color":Color("#b1d3dc"), "sky":Color("#b7d7ef"), "enemies":[["archer",-5,4],["guard",4,21],["scout",-4,35]]},
    {"name":"PARÁZSKOHÓ", "width":18.0, "gaps":[27], "color":Color("#b1886e"), "sky":Color("#c99781"), "enemies":[["brute",-4,0],["archer",5,21],["brute",-4,36]]},
    {"name":"FŰRÉSZMALOM", "width":18.0, "gaps":[9,29], "color":Color("#b6a47e"), "sky":Color("#8caca6"), "enemies":[["scout",5,0],["guard",-4,20],["archer",4,36]]},
    {"name":"ŐRTORONY", "width":16.0, "gaps":[], "color":Color("#aa9a86"), "sky":Color("#a1b4cd"), "enemies":[["archer",-5,0],["brute",4,19],["archer",-4,37]]},
    {"name":"HÍDLÁNC", "width":14.0, "gaps":[2,9,25,32], "color":Color("#7395b6"), "sky":Color("#91c4dd"), "enemies":[["archer",-4,-3],["scout",4,19],["guard",0,37]]},
    {"name":"ALKONYÚT", "width":18.0, "gaps":[9,27], "color":Color("#aa8bac"), "sky":Color("#b298c7"), "enemies":[["scout",-4,0],["brute",4,20],["archer",-4,36],["guard",4,36]]},
    {"name":"TRÓNŐRSÉG", "width":22.0, "gaps":[], "color":Color("#b7a988"), "sky":Color("#9db0c4"), "enemies":[["guard",-5,2],["archer",5,20],["brute",-5,26],["captain",0,34]]},
]

static func title(number: int) -> String:
    return str(STAGES[number - 1]["name"])

static func width(number: int) -> float:
    return float(STAGES[number - 1]["width"])

static func build(game: Node3D, number: int) -> void:
    var recipe: Dictionary = STAGES[number - 1]
    var difficulty: int = game.difficulty_index
    # Delete the placeholder geometry and actors before counting the new encounters.
    for node_name in ["Ground", "Platform1", "Platform2", "Enemy1", "Enemy2", "Enemy3"]:
        var old := game.get_node_or_null(node_name)
        if old:
            game.remove_child(old)
            old.queue_free()
    var stone := Art.material(recipe["color"])
    stone.roughness = 0.95
    var trim := Art.material(Color("#dbbd7f"), 0.3)
    var gaps: Array = recipe["gaps"]
    var start := -15.0
    var index := 0
    for gap in gaps:
        _solid(game, "GeneratedFloor%d" % index, Vector3(width(number), 1, float(gap) - 2 - start), Vector3(0, -0.5, (start + float(gap) - 2) * 0.5), stone)
        _bridge(game, float(gap), difficulty, number == 8, trim)
        start = float(gap) + 2.0
        index += 1
    _solid(game, "GeneratedFloor%d" % index, Vector3(width(number), 1, 45.0 - start), Vector3(0, -0.5, (start + 45.0) * 0.5), stone)
    _layout(game, number, stone, trim)
    _checkpoint(game)
    _scenery(game, number, recipe, stone, trim)
    for entry in recipe["enemies"]:
        _enemy(game, str(entry[0]), Vector3(float(entry[1]), 1.1, float(entry[2])))
    # Harder modes change encounters and trap timing as well as health and damage.
    if difficulty >= 1:
        _enemy(game, "scout" if number < 5 else "archer", Vector3(5, 1.1, -2))
    if difficulty == 2:
        _enemy(game, "brute" if number >= 3 else "guard", Vector3(-5, 1.1, 39))
        _hazard(game, "spikes", -4.5, 22.0, 0.8)
    game.set_meta("layout_id", number)
    game.set_meta("difficulty", difficulty)

static func _layout(game: Node3D, number: int, stone: Material, trim: Material) -> void:
    match number:
        1:
            # A jump lesson, a staggered wall, and a guarded final approach.
            for i in range(3):
                _solid(game, "CourtyardHurdle%d" % i, Vector3(10, 0.65 + i * 0.25, 1.0), Vector3(-2 if i % 2 == 0 else 2, (0.65 + i * 0.25) * 0.5, 0 + i * 12), trim)
            _hazard(game, "spikes", 0, 32, 0)
        2:
            _solid(game, "BridgeBarricade", Vector3(8, 1.1, 1.2), Vector3(-2, 0.55, 2), trim)
            _hazard(game, "spikes", -2, 21, 0)
            _hazard(game, "saw", 0, 35, 0)
        3:
            # Alternating hedge walls produce an actual winding route.
            var hedge := Art.material(Color("#376b48"))
            for i in range(4):
                var z: float = [-1, 7, 23, 31][i]
                _solid(game, "Hedge%d" % i, Vector3(12, 2.7, 1.0), Vector3(-2.5 if i % 2 == 0 else 2.5, 1.35, z), hedge)
                _hazard(game, "spikes", 5.0 if i % 2 == 0 else -5.0, z + 2.5, i * 0.7)
        4:
            for z in [-1.0, 20.0, 34.0]:
                _ice(game, z)
            for x in [-4.0, 0.0, 4.0]:
                _solid(game, "IcePillar", Vector3(1.2, 2.2, 1.3), Vector3(x, 1.1, 5 if x != 0 else 23), stone)
            _hazard(game, "saw", 0, 35, 1)
        5:
            for i in range(4):
                _hazard(game, "fire", -3.5 if i % 2 == 0 else 3.5, [-1.0, 7.0, 21.0, 34.0][i], i * 0.7)
            _solid(game, "FurnaceCover1", Vector3(2.2, 2.4, 2.2), Vector3(0, 1.2, 4), stone)
            _solid(game, "FurnaceCover2", Vector3(2.2, 2.4, 2.2), Vector3(-1, 1.2, 23), stone)
        6:
            for i in range(3):
                _hazard(game, "saw", 0, [-1.0, 21.0, 35.0][i], i * 1.2)
            _solid(game, "MillHurdle", Vector3(11, 0.8, 1), Vector3(2, 0.4, 4), trim)
        7:
            # Two broad stair ridges: six short, traversable rises, then descents.
            for ridge in [0, 1]:
                for i in range(6):
                    var height: float = [0.65, 1.3, 1.95, 1.95, 1.3, 0.65][i]
                    _solid(game, "TowerStep%d_%d" % [ridge, i], Vector3(14, height, 1.65), Vector3(0, height * 0.5, 2 + ridge * 21 + i * 1.65), stone)
            _hazard(game, "spikes", -4, 20, 0)
            _hazard(game, "spikes", 4, 35, 1.4)
        8:
            _hazard(game, "saw", 0, 20, 0)
            _solid(game, "ChainApproach", Vector3(7, 0.8, 1), Vector3(-2, 0.4, -3), trim)
        9:
            _hazard(game, "fire", -3, 2, 0)
            _hazard(game, "saw", 0, 21, 0.7)
            _hazard(game, "spikes", 3, 34, 1.2)
            _solid(game, "TwilightWall1", Vector3(10, 2.5, 1), Vector3(-3, 1.25, 5), stone)
            _solid(game, "TwilightWall2", Vector3(10, 2.5, 1), Vector3(3, 1.25, 31), stone)
        10:
            for x in [-6.5, 6.5]:
                for z in [6.0, 23.0, 34.0]:
                    _solid(game, "ArenaCover", Vector3(1.5, 2.5, 1.5), Vector3(x, 1.25, z), stone)
            _hazard(game, "fire", -3.5, 9, 0)
            _hazard(game, "fire", 3.5, 9, 1.6)
            _hazard(game, "saw", 0, 25, 0)
            _hazard(game, "spikes", 4.5, 32, 1)

static func _solid(game: Node3D, node_name: String, dimensions: Vector3, at: Vector3, material: Material) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = at
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = dimensions
    collision.shape = shape
    body.add_child(collision)
    Art.box(body, dimensions, Vector3.ZERO, material)
    game.add_child(body)
    return body

static func _bridge(game: Node3D, z: float, difficulty: int, chain: bool, trim: Material) -> void:
    var bridge := MovingPlatform.new()
    bridge.name = "MovingBridge%d" % int(z)
    bridge.position = Vector3(0, -0.07, z)
    bridge.travel = [1.0, 2.1, 3.0][difficulty] + (0.2 if chain else 0.0)
    bridge.period = [5.0, 4.2, 3.4][difficulty]
    var dimensions := Vector3([5.0, 4.4, 3.8][difficulty], 0.32, 2.5)
    Art.box(bridge, dimensions, Vector3.ZERO, trim)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = dimensions
    collision.shape = shape
    bridge.add_child(collision)
    game.add_child(bridge)

static func _hazard(game: Node3D, kind: String, x: float, z: float, phase: float) -> void:
    var hazard = Hazard.new()
    hazard.name = "%s_%d_%d" % [kind, int(x), int(z)]
    hazard.kind = kind
    hazard.position = Vector3(x, 0.55 if kind != "fire" else 0.9, z)
    hazard.phase = phase
    hazard.period = [4.5, 3.6, 2.8][game.difficulty_index]
    hazard.damage = game._hazard_damage(20)
    if kind == "saw":
        hazard.dimensions = Vector3(1.6, 1.0, 1.6)
        hazard.travel = width(game.stage_number) * 0.34
    elif kind == "fire":
        hazard.dimensions = Vector3(4.0, 1.8, 1.5)
    game.add_child(hazard)

static func _enemy(game: Node3D, kind: String, at: Vector3) -> void:
    var enemy = EnemyScript.new()
    enemy.archetype = kind
    enemy.position = at
    enemy.name = "Captain" if kind == "captain" else kind.capitalize()
    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.55
    shape.height = 1.8
    collision.shape = shape
    enemy.add_child(collision)
    game.add_child(enemy)

static func _checkpoint(game: Node3D) -> void:
    var area := Area3D.new()
    area.name = "Checkpoint"
    area.position = Vector3(0, 1.0, 16)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    # Entire safe landing is a checkpoint, even when the player stays at one side.
    shape.size = Vector3(width(game.stage_number) - 1, 3, 2)
    collision.shape = shape
    area.add_child(collision)
    var material := Art.material(Color("#65ddcb"))
    material.emission_enabled = true
    material.emission = Color("#299b87")
    Art.box(area, Vector3(width(game.stage_number) - 1, 0.05, 0.35), Vector3(0, -0.95, 0), material)
    game.add_child(area)
    area.body_entered.connect(Callable(game, "_on_checkpoint_entered"))

static func _ice(game: Node3D, z: float) -> void:
    var area := Area3D.new()
    area.name = "IcePatch%d" % int(z)
    area.position = Vector3(0, 0.25, z)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(13, 0.7, 4)
    collision.shape = shape
    area.add_child(collision)
    var material := Art.material(Color("#d0f0f3"), 0.3)
    material.roughness = 0.12
    Art.box(area, Vector3(13, 0.04, 4), Vector3(0, -0.22, 0), material)
    game.add_child(area)
    area.body_entered.connect(func(body: Node3D):
        if body.is_in_group("player"):
            body.set("surface_acceleration", 0.22)
    )
    area.body_exited.connect(func(body: Node3D):
        if body.is_in_group("player"):
            body.set("surface_acceleration", 1.0)
    )

static func _scenery(game: Node3D, number: int, recipe: Dictionary, stone: Material, trim: Material) -> void:
    var env: Environment = game.get_node("WorldEnvironment").environment
    var sky: ProceduralSkyMaterial = env.sky.sky_material
    sky.sky_top_color = recipe["sky"]
    sky.sky_horizon_color = Color(recipe["sky"]).lightened(0.2)
    env.fog_light_color = recipe["sky"]
    var outer := width(number) * 0.5 + 2.5
    for side in [-1.0, 1.0]:
        for z in range(-9, 40, 8):
            var at := Vector3(side * outer, 0, z)
            if number in [1, 3]:
                Art.cylinder(game, 0.22, 3, at + Vector3.UP * 1.5, trim)
                Art.cylinder(game, 1.6, 3, at + Vector3.UP * 3.5, Art.material(Color("#376c52")), true)
            elif number == 4:
                Art.cylinder(game, 1.0, 4.5, at + Vector3.UP * 2, Art.material(Color("#b0e0f0")), true)
            elif number == 5:
                Art.cylinder(game, 1.0, 5.5, at + Vector3.UP * 2.7, stone)
                Art.cylinder(game, 1.1, 0.4, at + Vector3.UP * 5.5, Art.material(Color("#eb8b3c")))
            elif number == 6:
                Art.box(game, Vector3(2.6, 2.5, 2.6), at + Vector3.UP * 1.25, trim)
            else:
                Art.cylinder(game, 0.7, 3.5 + number * 0.15, at + Vector3.UP * 1.75, stone)
                Art.box(game, Vector3(1.7, 0.25, 1.7), at + Vector3.UP * 3.6, trim)
    # One destination gate; repetitive foreground arches no longer hide the route.
    for x in [-2.3, 2.3]:
        Art.box(game, Vector3(1, 5.5, 1.1), Vector3(x, 2.75, 40), stone)
    Art.box(game, Vector3(5.8, 0.65, 1.1), Vector3(0, 5.2, 40), trim)
    if number == 10:
        Art.box(game, Vector3(3, 4, 1), Vector3(0, 2, 43), trim)
