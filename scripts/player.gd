class_name Player
extends CharacterBody3D

@export var speed := 6.0
@export var acceleration := 40.0
@export var turn_speed := 12.0
@export var jump_velocity := 4.0


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input.x, 0.0, input.y)

	velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	if not is_on_floor():
		velocity += get_gravity() * delta
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	if direction.length_squared() > 0.001:
		var yaw := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, yaw, turn_speed * delta)

	move_and_slide()
