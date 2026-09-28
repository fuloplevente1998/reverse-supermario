extends RefCounted

# Original procedural artwork. Shared meshes/materials keep Android costs modest.
static func material(color: Color, metal: float = 0.0) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = color
    result.metallic = metal
    result.roughness = 0.55
    return result

static func box(parent: Node3D, size: Vector3, position: Vector3, mat: Material) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    return piece(parent, mesh, position, mat)

static func piece(parent: Node3D, mesh: Mesh, position: Vector3, mat: Material) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = position
    node.material_override = mat
    parent.add_child(node)
    return node

static func cylinder(parent: Node3D, radius: float, height: float, position: Vector3, mat: Material, cone: bool = false) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.bottom_radius = radius
    mesh.top_radius = 0.0 if cone else radius
    mesh.height = height
    mesh.radial_segments = 8
    return piece(parent, mesh, position, mat)

static func armor(root: Node3D, villain: bool) -> Array[Node3D]:
    var steel := material(Color("#394657") if villain else Color("#9aafb8"), 0.65)
    var gold := material(Color("#d8a654"), 0.65)
    var cloth := material(Color("#641e3c") if villain else Color("#244978"))
    var dark := material(Color("#161a27"))
    var legs: Array[Node3D] = []
    for side in [-1.0, 1.0]:
        var leg := Node3D.new()
        root.add_child(leg)
        leg.position = Vector3(side * 0.24, -0.35, 0)
        box(leg, Vector3(0.3, 0.38, 0.32), Vector3(0, -0.12, 0), cloth)
        box(leg, Vector3(0.34, 0.25, 0.4), Vector3(0, -0.37, 0.06), steel)
        box(leg, Vector3(0.35, 0.13, 0.5), Vector3(0, -0.49, 0.1), dark)
        legs.append(leg)
        box(root, Vector3(0.25, 0.45, 0.28), Vector3(side * 0.58, 0.1, 0.02), steel)
        cylinder(root, 0.29, 0.15, Vector3(side * 0.5, 0.48, 0), gold)
        if villain:
            cylinder(root, 0.085, 0.24, Vector3(side * 0.56, 0.67, 0), gold, true)
    box(root, Vector3(0.83, 0.14, 0.58), Vector3(0, -0.23, 0), dark)
    box(root, Vector3(0.2, 0.19, 0.08), Vector3(0, -0.22, 0.33), gold)
    box(root, Vector3(0.48, 0.42, 0.13), Vector3(0, 0.22, 0.39), steel)
    box(root, Vector3(0.07, 0.28, 0.025), Vector3(0, 0.22, 0.47), gold)
    box(root, Vector3(0.27, 0.07, 0.025), Vector3(0, 0.24, 0.47), gold)
    box(root, Vector3(0.56, 0.12, 0.08), Vector3(0, 0.98, 0.34), dark)
    for side in [-1.0, 1.0]:
        var eye := material(Color("#ffb05c") if villain else Color("#8edee0"))
        eye.emission_enabled = true
        eye.emission = eye.albedo_color
        box(root, Vector3(0.14, 0.045, 0.025), Vector3(side * 0.15, 0.99, 0.395), eye)
    if not villain:
        box(root, Vector3(0.12, 0.26, 0.56), Vector3(0, 1.29, 0), cloth)
        box(root, Vector3(0.62, 0.83, 0.16), Vector3(-0.69, 0.06, 0.3), gold)
        box(root, Vector3(0.5, 0.69, 0.18), Vector3(-0.69, 0.06, 0.32), cloth)
        box(root, Vector3(0.08, 0.48, 0.025), Vector3(-0.69, 0.06, 0.42), gold)
    return legs

static func cape(root: Node3D) -> void:
    var mesh := PlaneMesh.new()
    mesh.size = Vector2(0.95, 1.22)
    mesh.subdivide_width = 6
    mesh.subdivide_depth = 10
    mesh.orientation = PlaneMesh.FACE_Z
    var shader := Shader.new()
    shader.code = """
shader_type spatial;
render_mode cull_disabled;
void vertex() {
    float hem = UV.y;
    VERTEX.z -= hem * hem * 0.18 + sin(TIME * 3.8 + UV.y * 6.0 + UV.x * 4.0) * 0.07 * hem;
}
void fragment() {
    float trim = step(0.93, UV.y) + step(UV.x, 0.055) + step(0.945, UV.x);
    ALBEDO = mix(vec3(0.24, 0.016, 0.05), vec3(0.63, 0.37, 0.09), clamp(trim, 0.0, 1.0));
    ROUGHNESS = 0.9;
}
"""
    var mat := ShaderMaterial.new()
    mat.shader = shader
    piece(root, mesh, Vector3(0, -0.02, -0.43), mat)

static func courtyard(root: Node3D) -> void:
    var stone := material(Color("#536375"))
    var dark := material(Color("#293747"))
    var trim := material(Color("#b49c72"))
    var bark := material(Color("#343338"))
    var leaves := material(Color("#234c50"))
    var paver := BoxMesh.new()
    paver.size = Vector3(1.72, 0.08, 1.86)
    var paving := MultiMesh.new()
    paving.transform_format = MultiMesh.TRANSFORM_3D
    paving.use_colors = true
    paving.mesh = paver
    paving.instance_count = 5 * 28
    var rng := RandomNumberGenerator.new()
    rng.seed = 713
    var n := 0
    for row in range(28):
        for col in range(5):
            var pos := Vector3((col - 2) * 1.85, 0.045, -12 + row * 2.0)
            paving.set_instance_transform(n, Transform3D(Basis.IDENTITY, pos))
            var shade := rng.randf_range(0.7, 1.0)
            paving.set_instance_color(n, Color(shade, shade, shade))
            n += 1
    var road := MultiMeshInstance3D.new()
    road.multimesh = paving
    var road_mat := material(Color("#71808c"))
    road_mat.vertex_color_use_as_albedo = true
    road.material_override = road_mat
    root.add_child(road)
    # Keep the central route and existing jump platforms unobstructed.
    for side in [-1.0, 1.0]:
        box(root, Vector3(1, 0.4, 59), Vector3(side * 16.5, 0.2, 15), stone)
        for z in range(-10, 46, 7):
            cylinder(root, 0.22, 3.8, Vector3(side * 14, 1.9, z), bark)
            cylinder(root, 1.5, 3.2, Vector3(side * 14, 3.8, z), leaves, true)
            cylinder(root, 1.15, 2.8, Vector3(side * 14, 5.3, z), leaves, true)
        # Castle towers flank the destination, beyond the playable route.
        cylinder(root, 2.8, 9, Vector3(side * 7.8, 4.5, 43), stone)
        cylinder(root, 3.1, 0.45, Vector3(side * 7.8, 9, 43), trim)
        cylinder(root, 3.4, 4, Vector3(side * 7.8, 11.1, 43), dark, true)
        for level in [3.0, 6.0]:
            box(root, Vector3(0.55, 1.25, 0.12), Vector3(side * 7.8, level, 40.19), dark)
        box(root, Vector3(1.3, 6.5, 1.6), Vector3(side * 2.6, 3.25, 39.7), stone)
        box(root, Vector3(1.7, 0.28, 1.9), Vector3(side * 2.6, 6.5, 39.7), trim)
    box(root, Vector3(6.4, 1.0, 1.6), Vector3(0, 6.1, 39.7), stone)
    var portal := material(Color(0.1, 0.65, 0.72, 0.3))
    portal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    portal.emission_enabled = true
    portal.emission = Color(0.08, 0.5, 0.55)
    box(root, Vector3(4, 5.6, 0.08), Vector3(0, 2.8, 39.9), portal)
