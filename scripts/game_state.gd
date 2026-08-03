class_name GameState
extends Node

signal state_changed(new_state: int)
signal lives_changed(lives_remaining: int, lives_maximum: int)
signal death_presented(reason: String)

enum State { READY, PLAYING, DEAD, GAME_OVER }

@export var max_lives := 5
@export var player: CharacterBody3D
@export var spawn_point: Marker3D
@export var detection: Detection
@export var camera_rig: CameraRig

var state := State.READY
var lives := 0
var death_reason := ""
var _initial_player_transform := Transform3D.IDENTITY


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	max_lives = maxi(max_lives, 1)
	if player != null:
		_initial_player_transform = player.global_transform
	_reset_run()
	_set_state(State.READY)


func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false


func _process(_delta: float) -> void:
	step_input()


func step_input() -> void:
	if state != State.PLAYING:
		return
	# DEBUG — remove with real death causes
	if Input.is_action_just_pressed("debug_game_over"):
		_debug_game_over()
	elif Input.is_action_just_pressed("debug_die"):
		kill_player("Squished by the debug key")


func start_run() -> void:
	if state != State.READY:
		return
	_set_state(State.PLAYING)


func kill_player(reason: String) -> void:
	if state != State.PLAYING:
		return
	death_reason = reason
	lives = clampi(lives - 1, 0, max_lives)
	lives_changed.emit(lives, max_lives)
	death_presented.emit(death_reason)
	if lives == 0:
		_set_state(State.GAME_OVER)
	else:
		_set_state(State.DEAD)


func dismiss_death() -> void:
	if state != State.DEAD:
		return
	_respawn_player()
	if detection != null:
		detection.reset()
	_set_state(State.PLAYING)


func dismiss_game_over() -> void:
	if state != State.GAME_OVER:
		return
	_reset_run()
	_set_state(State.READY)


func _debug_game_over() -> void:
	death_reason = "Skipped to game over by the debug key"
	lives = 0
	lives_changed.emit(lives, max_lives)
	death_presented.emit(death_reason)
	_set_state(State.GAME_OVER)


func _reset_run() -> void:
	lives = max_lives
	death_reason = ""
	_respawn_player()
	if detection != null:
		detection.reset()
	lives_changed.emit(lives, max_lives)


func _respawn_player() -> void:
	if player == null:
		return
	if spawn_point != null:
		player.global_transform = spawn_point.global_transform
	else:
		player.global_transform = _initial_player_transform
	player.force_update_transform()
	player.velocity = Vector3.ZERO
	if camera_rig != null:
		camera_rig.global_position = player.global_position


func _set_state(new_state: int) -> void:
	state = new_state
	get_tree().paused = state != State.PLAYING
	state_changed.emit(state)
