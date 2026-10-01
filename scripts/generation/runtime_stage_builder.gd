extends RefCounted

# Development blockout builder for the new long-stage architecture.
# IMPORTANT: these primitive visuals are temporary validation geometry only.
# Final segment visuals must come from authored PackedScene/GLB assets.
const Art = preload("res://scripts/art.gd")
const StageCatalog = preload("res://scripts/generation/stage_catalog.gd")

const BLOCKOUT_COLORS := {
    "courtyard": Color("#cdb48d"),
    "royal_gardens": Color("#8fa66a"),
    "eagle_cliff": Color("#8c8a80"),
    "frozen_bastion": Color("#a9c8dc"),
    "forge": Color("#6f5144"),
    "windmill_valley": Color("#b39662"),
    "catacombs": Color("#685b50"),
    "shadow_canyon": Color("#626b72"),
    "black_forest": Color("#53634f"),
    "crown_citadel": Color("#d2bc92")
}

static func build_blockout(parent: Node3D, plan: Dictionary, corridor_width: float = 8.0) -> Node3D:
    var root := Node3D.new()
    root.name = "GeneratorRebuildBlockout"
    root.set_meta("stage_id", int(plan["stage_id"]))
    root.set_meta("biome", str(plan["biome"]))
    root.set_meta("seed", int(plan["seed"]))
    root.set_meta("total_length", float(plan["total_length"]))
    root.set_meta("temporary_blockout", true)
    parent.add_child(root)

    var material := Art.material(BLOCKOUT_COLORS.get(str(plan["biome"]), Color("#a99a82")))
    material.roughness = 0.95
    var accent := Art.material(Color("#d0a85a"))
    accent.roughness = 0.68
    var hazard_material := Art.material(Color("#a44538"))
    hazard_material.roughness = 0.84

    for segment: Dictionary in plan["segments"]:
        _build_segment(root, segment, corridor_width, material, accent, hazard_material)

    return root

static func _build_segment(root: Node3D, segment: Dictionary, corridor_width: float, material: Material, accent: Material, hazard_material: Material) -> void:
    var segment_root := Node3D.new()
    segment_root.name = "Segment_%03d_%s" % [int(segment["index"]), str(segment["id"])]
    segment_root.position.z = float(segment["start"])
    segment_root.set_meta("segment_id", str(segment["id"]))
    segment_root.set_meta("kind", str(segment["kind"]))
    segment_root.set_meta("length", float(segment["length"]))
    segment_root.set_meta("variant_seed", int(segment["variant_seed"]))
    root.add_child(segment_root)

    var id := str(segment["id"])
    var length := float(segment["length"])

    if id in ["gap", "broken_bridge", "rope_bridge", "chain_crossing", "bone_bridge", "siege_bridge"]:
        _gap_or_bridge(segment_root, id, length, corridor_width, material, accent)
    elif id in ["stairs"]:
        _stairs(segment_root, length, corridor_width, material)
    else:
        _floor(segment_root, length, corridor_width, material)

    if id in ["hazard", "breakable_ice", "molten_channel", "crusher_hall", "lift_platform", "collapsed_crypt", "cage_gallery"]:
        _hazard_marker(segment_root, length, corridor_width, hazard_material)

    if str(segment["kind"]) == "checkpoint":
        _checkpoint_marker(segment_root, length, accent)

    if id in ["tower", "watchtower", "snow_tower", "ruined_watchtower", "wood_watchtower"]:
        _tower_marker(segment_root, length, corridor_width, accent)

    if id in ["gate", "gate_approach", "industrial_gate", "palisade_gate", "grand_gate", "finish"]:
        _gate_marker(segment_root, length, corridor_width, accent)

    if str(segment["kind"]) == "vista":
        _vista_marker(segment_root, length, corridor_width, accent)

static func _floor(parent: Node3D, length: float, width: float, material: Material) -> StaticBody3D:
    return _solid(parent, "Floor", Vector3(width, 0.8, length), Vector3(0, -0.4, length * 0.5), material)

static func _gap_or_bridge(parent: Node3D, id: String, length: float, width: float, material: Material, accent: Material) -> void:
    if id in ["rope_bridge", "chain_crossing", "bone_bridge", "siege_bridge"]:
        # Narrow but continuous validation surface. Final scenes get real bridge meshes.
        _solid(parent, "BridgeDeck", Vector3(width * 0.55, 0.45, length), Vector3(0, -0.22, length * 0.5), accent)
        return

    var ledge_length := maxf(7.0, length * 0.34)
    var gap_length := maxf(3.0, length - ledge_length * 2.0)
    _solid(parent, "GapLedgeA", Vector3(width, 0.8, ledge_length), Vector3(0, -0.4, ledge_length * 0.5), material)
    _solid(parent, "GapLedgeB", Vector3(width, 0.8, ledge_length), Vector3(0, -0.4, length - ledge_length * 0.5), material)
    parent.set_meta("gap_length", gap_length)

static func _stairs(parent: Node3D, length: float, width: float, material: Material) -> void:
    var count := 6
    var step_length := length / float(count)
    for i in range(count):
        var rise := float(mini(i, count - 1 - i)) * 0.45
        var height := 0.8 + rise
        _solid(parent, "Step%d" % i, Vector3(width, height, step_length * 0.94), Vector3(0, -0.4 + rise * 0.5, step_length * (i + 0.5)), material)

static func _hazard_marker(parent: Node3D, length: float, width: float, material: Material) -> void:
    var marker := MeshInstance3D.new()
    marker.name = "HazardMarker"
    var mesh := BoxMesh.new()
    mesh.size = Vector3(minf(width * 0.65, 5.0), 0.12, minf(length * 0.34, 7.0))
    marker.mesh = mesh
    marker.material_override = material
    marker.position = Vector3(0, 0.08, length * 0.52)
    parent.add_child(marker)

static func _checkpoint_marker(parent: Node3D, length: float, material: Material) -> void:
    var marker := Node3D.new()
    marker.name = "CheckpointMarker"
    marker.position = Vector3(0, 0, length * 0.5)
    parent.add_child(marker)
    Art.cylinder(marker, 0.08, 3.0, Vector3(0, 1.5, 0), material)
    Art.box(marker, Vector3(0.08, 1.1, 1.4), Vector3(0, 2.15, 0.72), material)

static func _tower_marker(parent: Node3D, length: float, width: float, material: Material) -> void:
    var x := width * 0.5 + 2.0
    _visual_box(parent, "TowerMarker", Vector3(3.8, 6.5, 4.5), Vector3(x, 3.25, length * 0.55), material)

static func _gate_marker(parent: Node3D, length: float, width: float, material: Material) -> void:
    var z := length * 0.72
    for x in [-width * 0.42, width * 0.42]:
        _visual_box(parent, "GatePillar", Vector3(1.0, 5.2, 1.0), Vector3(x, 2.6, z), material)
    _visual_box(parent, "GateLintel", Vector3(width * 0.95, 0.8, 1.0), Vector3(0, 5.0, z), material)

static func _vista_marker(parent: Node3D, length: float, width: float, material: Material) -> void:
    # Outside the playable corridor, marking where a hero-composition PackedScene belongs.
    _visual_box(parent, "VistaAnchor", Vector3(2.0, 2.0, 2.0), Vector3(width * 0.5 + 4.0, 1.0, length * 0.5), material)

static func _solid(parent: Node3D, node_name: String, dimensions: Vector3, at: Vector3, material: Material) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = at
    parent.add_child(body)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = dimensions
    collision.shape = shape
    body.add_child(collision)

    Art.box(body, dimensions, Vector3.ZERO, material)
    return body

static func _visual_box(parent: Node3D, node_name: String, dimensions: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = node_name
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    mesh_instance.mesh = mesh
    mesh_instance.material_override = material
    mesh_instance.position = at
    parent.add_child(mesh_instance)
    return mesh_instance
