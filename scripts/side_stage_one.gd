extends RefCounted

const Art = preload("res://scripts/art.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Hazard = preload("res://scripts/stage_hazard.gd")
const WorldScenery = preload("res://scripts/world_scenery.gd")
const SampleArt = preload("res://scripts/side_sample_art.gd")
const END_Z := 225.0
const HALF_WIDTH := 2.6
# [start, end, start height, end height]; omitted intervals are real holes.
const TERRAIN := [
    [-15.0,10.0,0.0,0.0], [10.0,22.0,0.0,2.2],
    [22.0,34.0,2.2,2.2], [34.0,46.0,2.2,0.0],
    [49.0,62.0,0.0,-1.6], [62.0,73.0,-1.6,-1.6],
    [73.0,86.0,-1.6,0.0], [86.0,94.0,0.0,0.0],
    [100.0,113.0,0.0,0.0], [113.0,124.0,0.0,2.4],
    [124.0,137.0,2.4,2.4], [140.0,149.0,2.4,2.4],
    [149.0,163.0,2.4,-1.0], [163.0,174.0,-1.0,-1.0],
    [179.0,189.0,-1.0,0.0], [189.0,225.0,0.0,0.0]
]
const GAPS := [Vector2(46,49), Vector2(94,100), Vector2(137,140), Vector2(174,179)]

static func height_at(z: float) -> float:
    for segment in TERRAIN:
        if z >= segment[0] and z <= segment[1]:
            return lerpf(segment[2], segment[3], (z-segment[0])/(segment[1]-segment[0]))
    # Camera follows the bank height over gaps, never the bottom of a pit.
    for i in range(TERRAIN.size()-1):
        if z > TERRAIN[i][1] and z < TERRAIN[i+1][0]:
            return lerpf(TERRAIN[i][3], TERRAIN[i+1][2], (z-TERRAIN[i][1])/(TERRAIN[i+1][0]-TERRAIN[i][1]))
    return 0.0

static func build(game: Node3D) -> void:
    game.player.floor_snap_length = 0.35
    game.player.floor_constant_speed = true
    var stone := Art.material(Color("#e4d2ae"))
    stone.albedo_texture = load("res://assets/models/courtyard_environment_pavestone_0.png")
    stone.uv1_triplanar = true
    stone.uv1_scale = Vector3.ONE * 0.5
    stone.roughness = 1.0
    var cap := Art.material(Color("#e0ca9a"))
    cap.roughness = 1.0
    for i in range(TERRAIN.size()):
        _terrain(game, TERRAIN[i], i, stone, cap)
    _block(game,"CourtyardHurdle0",Vector3(5.2,0.7,1.1),Vector3(0,0.35,0),stone)
    # A short raised route complements the hills; jumps stay below 2.4 m.
    for item in [[24.0,0.65,1.6],[29.0,1.2,2.0],[65.0,0.7,1.8],[108.0,1.4,2.8]]:
        var z: float = item[0]
        var height: float = item[1]
        _block(game,"JumpBlock%d" % int(z),Vector3(4.8,height,item[2]),Vector3(0,height_at(z)+height*0.5,z),stone)
    for i in range(5):
        var height: float = [0.6,1.2,1.8,1.2,0.6][i]
        _block(game,"FinalStair%d" % i,Vector3(5.2,height,1.6),Vector3(0,height*0.5,196+i*1.6),stone)
    for z in [44.0,104.0,168.0]:
        _checkpoint(game,z)
    _water(game)
    _spikes(game,39.0)
    if game.difficulty_index == 2:
        _spikes(game,185.0)
    var encounters := [["guard",8.0],["scout",31.5],["guard",57.0],["archer",110.5],["brute",132.0],["scout",164.0],["guard",191.0],["guard",215.0]]
    for item in encounters:
        _enemy(game,item[0],item[1])
    if game.difficulty_index >= 1:
        _enemy(game,"scout",82.0)
    if game.difficulty_index == 2:
        _enemy(game,"archer",145.0)
    game.get_node("Goal").position = Vector3(0,1.5,END_Z-5.0)
    game.set_meta("side_course_length",END_Z+15.0)
    game.set_meta("side_course_gaps",GAPS)
    _background(game)
    _finish_flag(game)
    SampleArt.build(game)

static func _terrain(game: Node3D, segment: Array, index: int, stone: Material, cap: Material) -> void:
    var z0: float = segment[0]
    var z1: float = segment[1]
    var y0: float = segment[2]
    var y1: float = segment[3]
    var vertices := PackedVector3Array([
        Vector3(-HALF_WIDTH,-8,z0), Vector3(HALF_WIDTH,-8,z0),
        Vector3(-HALF_WIDTH,y0,z0), Vector3(HALF_WIDTH,y0,z0),
        Vector3(-HALF_WIDTH,-8,z1), Vector3(HALF_WIDTH,-8,z1),
        Vector3(-HALF_WIDTH,y1,z1), Vector3(HALF_WIDTH,y1,z1)
    ])
    var body := StaticBody3D.new()
    body.name = "SideTerrain%d" % index
    body.add_to_group("side_terrain")
    var shape := ConvexPolygonShape3D.new()
    shape.points = vertices
    var collision := CollisionShape3D.new()
    collision.shape = shape
    body.add_child(collision)
    var mesh := SurfaceTool.new()
    mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
    mesh.set_smooth_group(-1)
    # Godot uses clockwise fronts; keep generated normals outward, including slopes.
    for face in [[0,4,6,2],[1,3,7,5],[2,6,7,3],[0,1,5,4],[0,2,3,1],[4,5,7,6]]:
        for k in [0,2,1,0,3,2]:
            mesh.add_vertex(vertices[face[k]])
    mesh.generate_normals()
    var visual := MeshInstance3D.new()
    visual.mesh = mesh.commit()
    visual.material_override = stone
    body.add_child(visual)
    # Clear pale lip makes the real walkable silhouette stand out from background.
    var edge := Art.box(body,Vector3(0.13,0.16,Vector2(z1-z0,y1-y0).length()),Vector3(-HALF_WIDTH-0.03,(y0+y1)*0.5-0.07,(z0+z1)*0.5),cap)
    edge.rotation.x = -atan2(y1-y0,z1-z0)
    game.add_child(body)

static func _block(game: Node3D, node_name: String, dimensions: Vector3, at: Vector3, material: Material) -> void:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = at
    var shape := BoxShape3D.new()
    shape.size = dimensions
    var collision := CollisionShape3D.new()
    collision.shape = shape
    body.add_child(collision)
    var surface := material
    if node_name == "CourtyardHurdle0":
        var masonry := Art.material(Color.WHITE)
        masonry.albedo_texture = preload("res://assets/terrain/sample_limestone.svg")
        masonry.roughness = 0.9
        surface = masonry
    Art.box(body,dimensions,Vector3.ZERO,surface)
    if node_name == "CourtyardHurdle0":
        var pale := Art.material(Color("#ead9b4"))
        # Trim stays within the tested collider; it cannot create an unseen step.
        Art.box(body,Vector3(dimensions.x,0.10,dimensions.z),Vector3(0,dimensions.y*0.5-0.05,0),pale)
        for z in [-0.35,0.0,0.35]:
            Art.box(body,Vector3(0.012,dimensions.y-0.12,0.025),Vector3(-dimensions.x*0.5-0.006,-0.04,z),Art.material(Color("#957957")))
    game.add_child(body)

static func _enemy(game: Node3D, kind: String, z: float) -> void:
    var enemy := Enemy.new()
    enemy.archetype = kind
    enemy.name = "%s_%d" % [kind.capitalize(),int(z)]
    enemy.position = Vector3(0,height_at(z)+1.1,z)
    var shape := CapsuleShape3D.new()
    shape.height = 1.8
    shape.radius = 0.55
    var collision := CollisionShape3D.new()
    collision.shape = shape
    enemy.add_child(collision)
    game.add_child(enemy)

static func _checkpoint(game: Node3D, z: float) -> void:
    var area := Area3D.new()
    area.name = "Checkpoint" if z == 44.0 else "Checkpoint%d" % int(z)
    area.add_to_group("course_checkpoints")
    var spawn := Vector3(0,height_at(z)+1.1,z)
    area.position = spawn
    var shape := BoxShape3D.new()
    shape.size = Vector3(5.2,5,2)
    var collision := CollisionShape3D.new()
    collision.shape = shape
    area.add_child(collision)
    var mat := Art.material(Color("#69ddc0"))
    Art.box(area,Vector3(5.2,0.08,0.3),Vector3(0,-1.06,0),mat)
    # Thin flag behind the player, never in front of the route.
    Art.cylinder(area,0.055,2.6,Vector3(1.9,0.2,0),Art.material(Color("#d9b46c")))
    Art.box(area,Vector3(0.04,0.55,0.85),Vector3(1.9,1.1,0.4),mat)
    game.add_child(area)
    area.body_entered.connect(Callable(game,"_on_checkpoint_entered").bind(spawn))

static func _spikes(game: Node3D, z: float) -> void:
    var trap := Hazard.new()
    trap.name = "SideSpikes%d" % int(z)
    trap.kind = "spikes"
    trap.position = Vector3(0,height_at(z)+0.45,z)
    trap.dimensions = Vector3(4.0,0.7,1.5)
    trap.period = [4.5,3.6,2.8][game.difficulty_index]
    trap.damage = game._hazard_damage(20)
    game.add_child(trap)

static func _water(game: Node3D) -> void:
    var area := Area3D.new()
    area.name = "WaterDitch"
    area.position = Vector3(0,-2.8,97)
    area.collision_layer = 0
    area.collision_mask = 1
    var shape := BoxShape3D.new()
    shape.size = Vector3(5.2,1.6,6)
    var collision := CollisionShape3D.new()
    collision.shape = shape
    area.add_child(collision)
    var water := Art.material(Color("#268da3"),0.1)
    water.roughness = 0.3
    Art.box(area,Vector3(5.2,0.15,6),Vector3(0,0.8,0),water)
    var foam := Art.material(Color("#bdebe1"))
    for i in range(6):
        Art.box(area,Vector3(0.12,0.04,0.5),Vector3(-HALF_WIDTH-0.02,0.91,-2.5+i),foam)
    game.add_child(area)
    area.body_entered.connect(func(body: Node3D):
        if body == game.player and not game.ended:
            game.call_deferred("_recover_water")
    )

static func _background(game: Node3D) -> void:
    var root := Node3D.new()
    root.name = "SideBackdrop"
    game.add_child(root)
    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_texture = load("res://assets/backgrounds/courtyard_side_panorama.jpg")\n    # Keep the far painted layer subordinate to lit 3D gameplay geometry.\n    mat.albedo_color = Color(0.86, 0.87, 0.84, 1)\n    mat.cull_mode = BaseMaterial3D.CULL_DISABLED\n    for z in [-48.0,48.0,144.0,240.0]:
        var mesh := QuadMesh.new()
        mesh.size = Vector2(96,32)
        var panel := MeshInstance3D.new()
        panel.name = "BackdropPanel"
        panel.mesh = mesh
        panel.material_override = mat
        panel.position = Vector3(14,9,z)
        panel.rotation.y = -PI*0.5
        if int((z+48.0)/96.0) % 2 == 1:
            panel.scale.x = -1.0
        panel.layers = 4
        panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        root.add_child(panel)

static func _finish_flag(game: Node3D) -> void:
    var flag := Node3D.new()
    flag.name = "SideFinishFlag"
    flag.position = Vector3(1.5,0,END_Z-5.0)
    game.add_child(flag)
    Art.cylinder(flag,0.09,5,Vector3(0,2.5,0),Art.material(Color("#dfb85d")))
    Art.box(flag,Vector3(0.09,1.2,1.8),Vector3(0,4.1,0.9),Art.material(Color("#941e3f")))
    WorldScenery.set_render_layer(flag,4)
