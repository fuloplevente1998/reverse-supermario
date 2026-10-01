extends Node

# First streaming pass: disables processing and visibility outside a moving
# window. RuntimeBuilder can later replace this with true instantiate/free
# streaming once authored PackedScene segments are available.
var stage_root: Node3D
var target: Node3D
var behind_distance := 100.0
var ahead_distance := 240.0
var refresh_distance := 12.0
var last_z := -INF
var active_count := 0

func configure(root: Node3D, player: Node3D, behind: float = 100.0, ahead: float = 240.0) -> void:
    stage_root = root
    target = player
    behind_distance = behind
    ahead_distance = ahead
    last_z = -INF
    _refresh(true)

func _process(_delta: float) -> void:
    if stage_root == null or target == null or not is_instance_valid(stage_root) or not is_instance_valid(target):
        return
    if absf(target.global_position.z - last_z) >= refresh_distance:
        _refresh(false)

func _refresh(force: bool) -> void:
    if stage_root == null or target == null:
        return
    var current_z := target.global_position.z
    if not force and absf(current_z - last_z) < refresh_distance:
        return
    last_z = current_z
    active_count = 0

    var min_z := current_z - behind_distance
    var max_z := current_z + ahead_distance
    for segment_root: Node in stage_root.get_children():
        if not segment_root is Node3D:
            continue
        var start_z := float(segment_root.position.z)
        var length := float(segment_root.get_meta("length", 0.0))
        var active := start_z + length >= min_z and start_z <= max_z
        segment_root.visible = active
        segment_root.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
        if active:
            active_count += 1

func get_active_count() -> int:
    return active_count
