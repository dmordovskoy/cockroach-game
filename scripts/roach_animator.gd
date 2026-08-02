class_name RoachAnimator
extends Node3D

const MOVE_THRESHOLD := 0.2
const REFERENCE_SPEED := 6.0
const MIN_SCUTTLE_SPEED_SCALE := 0.5
const MAX_SCUTTLE_SPEED_SCALE := 1.75

@export var animation_player: AnimationPlayer


func _ready() -> void:
	if animation_player == null:
		push_error("RoachAnimator requires an AnimationPlayer")
		return

	for animation_name: StringName in [&"idle", &"scuttle"]:
		if animation_player.has_animation(animation_name):
			animation_player.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
	step(0.0)


func _physics_process(delta: float) -> void:
	step(delta)


func step(_delta: float) -> void:
	if animation_player == null:
		return

	var player := get_parent() as CharacterBody3D
	if player == null:
		return

	var horizontal_speed := Vector2(player.velocity.x, player.velocity.z).length()
	if horizontal_speed > MOVE_THRESHOLD:
		var speed_scale := clampf(
			horizontal_speed / REFERENCE_SPEED,
			MIN_SCUTTLE_SPEED_SCALE,
			MAX_SCUTTLE_SPEED_SCALE,
		)
		play_animation(&"scuttle", speed_scale)
	else:
		play_animation(&"idle", 1.0)


func play_animation(animation_name: StringName, speed_scale: float) -> void:
	if not animation_player.has_animation(animation_name):
		push_error("Roach animation missing: %s" % animation_name)
		return
	if animation_player.current_animation != animation_name:
		animation_player.play(animation_name)
	animation_player.speed_scale = speed_scale
