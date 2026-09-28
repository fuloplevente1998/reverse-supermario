extends Node3D

var direction := Vector3.FORWARD
var speed := 9.0
var damage := 10
var lifetime := 4.0
var owner_rid: RID

func _ready() -> void:
    add_to_group("projectiles")
    var mesh := SphereMesh.new()
    mesh.radius = 0.18
    mesh.height = 0.36
    var visual := MeshInstance3D.new()
    visual.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("#72e6ff")
    material.emission_enabled = true
    material.emission = Color("#32a7d9")
    visual.material_override = material
    add_child(visual)

func _physics_process(delta: float) -> void:
    lifetime -= delta
    if lifetime <= 0.0:
        queue_free()
        return
    var destination := global_position + direction * speed * delta
    var query := PhysicsRayQueryParameters3D.create(global_position, destination)
    query.exclude = [owner_rid]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        var target: Object = hit["collider"]
        if target is Node and target.is_in_group("player"):
            target.call("take_damage", damage)
        queue_free()
        return
    global_position = destination
