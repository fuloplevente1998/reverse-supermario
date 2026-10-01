extends RefCounted

# An isolated opening-segment albedo experiment; vendor resources stay intact.
const MATERIAL = preload("res://assets/materials/ai/courtyard_limestone_v1.tres")
static var enabled := true
static var variants: Dictionary = {}

static func applies(segment_start: float) -> bool:
    return enabled and is_equal_approx(segment_start, -15.0)

static func mesh_variant(source: Mesh) -> Mesh:
    var key := source.get_rid().get_id()
    if variants.has(key): return variants[key]
    var result := source.duplicate() as Mesh
    for surface in range(result.get_surface_count()):
        var original := source.surface_get_material(surface)
        if original and "RockTrim" in original.resource_name:
            result.surface_set_material(surface, MATERIAL)
    variants[key] = result
    return result
