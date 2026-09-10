extends Node3D

@onready var player = $Player
@onready var hp_label: Label = $UI/TopBar/HP
@onready var status_label: Label = $UI/Status
@onready var goal: Area3D = $Goal
@onready var restart_button: Button = $UI/Restart

func _ready() -> void:
    player.hp_changed.connect(_on_hp_changed)
    player.died.connect(_on_player_died)
    goal.body_entered.connect(_on_goal_body_entered)
    restart_button.pressed.connect(_restart)
    _on_hp_changed(player.hp)
    _bind_touch_buttons()

func _on_hp_changed(value: int) -> void:
    hp_label.text = "HP: %d" % value

func _on_player_died() -> void:
    status_label.text = "LEGYOZTEK"
    restart_button.visible = true
    player.set_physics_process(false)

func _on_goal_body_entered(body: Node) -> void:
    if body == player:
        status_label.text = "CEL ELERVE"
        restart_button.visible = true
        player.set_physics_process(false)

func _restart() -> void:
    get_tree().reload_current_scene()

func _bind_touch_buttons() -> void:
    var bindings := {
        $UI/Controls/Move/Up: "move_forward",
        $UI/Controls/Move/Down: "move_back",
        $UI/Controls/Move/Left: "move_left",
        $UI/Controls/Move/Right: "move_right",
        $UI/Controls/Actions/Jump: "jump",
        $UI/Controls/Actions/Attack: "attack",
        $UI/Controls/Actions/Block: "block"
    }
    for button in bindings:
        var action: StringName = bindings[button]
        button.button_down.connect(func(): player.set_touch_action(action, true))
        button.button_up.connect(func(): player.set_touch_action(action, false))
