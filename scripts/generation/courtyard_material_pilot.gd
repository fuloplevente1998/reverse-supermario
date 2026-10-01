extends RefCounted

# Shared Stage 1 AI limestone; vendor resources and jointed wall atlases stay intact.
const MATERIAL = preload("res://assets/materials/ai/courtyard_limestone_v1.tres")
static var enabled := true
static var variants: Dictionary = {}

static func applies(_segment_start: float) -> bool:
    return enabled

static func mesh_variant(source: Mesh) -> Mesh:
    var key := source.get_rid().get_id()
    if variants.has(key): return variants[key]
    var result: Mesh = source
    for surface in range(result.get_surface_count()):
        var original := source.surface_get_material(surface)
        if original and "RockTrim" in original.resource_name:
            if result == source: result = source.duplicate() as Mesh
            result.surface_set_material(surface, MATERIAL)
    variants[key] = result
    return result
