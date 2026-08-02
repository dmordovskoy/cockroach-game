extends Camera3D

@export var target: Node3D
@export var follow_speed := 5.0

var _offset := Vector3.ZERO


func _ready() -> void:
	if target:
		_offset = global_position - target.global_position


func _physics_process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	if target:
		var goal := target.global_position + _offset
		global_position = global_position.lerp(goal, minf(follow_speed * delta, 1.0))
