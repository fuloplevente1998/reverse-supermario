extends RefCounted
const Art = preload("res://scripts/art.gd")
const WorldScenery = preload("res://scripts/world_scenery.gd")

static func build(game: Node3D) -> void:
    var root := Node3D.new()
    root.name = "SideArtSample"
    game.add_child(root)
    root.set_meta("sample_start_z", -15.0)
    root.set_meta("sample_end_z", 10.0)
    var limestone := Art.material(Color.WHITE)
    limestone.albedo_texture = preload("res://assets/terrain/sample_limestone.svg")
    limestone.roughness = 0.88
    limestone.vertex_color_use_as_albedo = true
    var blocks: Array[Transform3D] = []
    # Shallow relief below the exact walkable silhouette, on the camera-facing wall.
    # Staggered joints and inset courses read as masonry rather than earth.
    for row in range(5):
        var start: float = -15.0 - (0.75 if row % 2 else 0.0)
        while start < 10.0:
            var a: float = maxf(-15.0, start)
            var b: float = minf(10.0, start + 1.5)
            if b-a > 0.04:
                blocks.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.20,0.54,b-a-0.035)), Vector3(-2.64,-0.36-row*0.58,(a+b)*0.5)))
            start += 1.5
    _batch(root,"ReliefMasonry",blocks,limestone)
    var paving: Array[Transform3D] = []
    for row in range(4):
        for col in range(17):
            var z0: float = -15.0 + col*25.0/17.0
            paving.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.27,0.10,25.0/17.0-0.025)),Vector3(-1.95+row*1.3,-0.045,z0+12.5/17.0)))
    _batch(root,"WalkwayPaving",paving,limestone)
    var cornice: Array[Transform3D] = []
    for i in range(25):
        cornice.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.24,0.18,0.98)),Vector3(-2.65,-0.095,-14.5+i)))
    _batch(root,"PaleStoneCornice",cornice,limestone)
    # Keep ornament behind the action plane. Props have no gameplay collision.
    for item in [["stage1_barrel",-7.3],["stage1_crate",-5.9],["stage1_banner",-11.5],["stage1_banner",6.4]]:
        var model := WorldScenery.place(game,item[0],Vector3(3.5,0,item[1]),Vector3.ONE*0.85,PI*0.5)
        if model:
            model.name = "Sample_" + str(item[0]) + "_" + str(item[1])
            WorldScenery.set_render_layer(model,4)
    for z in [-12.0,-3.5,5.0]:
        var tree := WorldScenery.place(game,"pine_tree",Vector3(6.0,0,z),Vector3(0.40,0.65,0.40))
        if tree:
            tree.name = "SampleGardenTree" + str(z)
            WorldScenery.set_render_layer(tree,4)
    var leaf := Art.material(Color("#50753b"))
    var berry := Art.material(Color("#993049"))
    for z in [-9.5,4.8]:
        var bush := Node3D.new()
        bush.name = "SampleFlowerBed" + str(z)
        bush.position = Vector3(3.0,0,z)
        root.add_child(bush)
        for i in range(5):
            var sphere := SphereMesh.new()
            sphere.radius = 0.30
            sphere.height = 0.60
            sphere.radial_segments = 8
            sphere.rings = 4
            Art.piece(bush,sphere,Vector3(0,0.24+0.06*(i%2),(i-2)*0.25),leaf)
            var bloom := SphereMesh.new()
            bloom.radius = 0.07
            bloom.height = 0.14
            bloom.radial_segments = 6
            bloom.rings = 3
            Art.piece(bush,bloom,Vector3(-0.2,0.49,(i-2)*0.24),berry)
        WorldScenery.set_render_layer(bush,4)
    game.set_meta("side_art_sample",true)

static func _batch(root: Node3D, node_name: String, transforms: Array[Transform3D], material: Material) -> void:
    var cube := BoxMesh.new()
    cube.size = Vector3.ONE
    var mesh := MultiMesh.new()
    mesh.transform_format = MultiMesh.TRANSFORM_3D
    mesh.use_colors = true
    mesh.mesh = cube
    mesh.instance_count = transforms.size()
    for i in range(transforms.size()):
        mesh.set_instance_transform(i,transforms[i])
        var value: float = 0.91 + float((i*7)%9)*0.01
        mesh.set_instance_color(i,Color(value,value,value,1))
    var visual := MultiMeshInstance3D.new()
    visual.name = node_name
    visual.multimesh = mesh
    visual.material_override = material
    visual.layers = 4
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    root.add_child(visual)
