class_name RunUI
extends CanvasLayer

const LIVE_HEART_COLOR := Color(1.0, 0.12, 0.16, 1.0)
const LOST_HEART_COLOR := Color(0.25, 0.08, 0.08, 0.45)

@export var game_state: GameState

@onready var start_overlay: ColorRect = $StartOverlay
@onready var death_overlay: ColorRect = $DeathOverlay
@onready var game_over_overlay: ColorRect = $GameOverOverlay
@onready var hearts: HBoxContainer = $Hearts
@onready var start_button: Button = $StartOverlay/Center/VBox/StartButton
@onready var continue_button: Button = $DeathOverlay/Center/VBox/ContinueButton
@onready var game_over_button: Button = $GameOverOverlay/Center/VBox/ReturnButton
@onready var cause_label: Label = $DeathOverlay/Center/VBox/Cause


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if game_state == null:
		return
	game_state.state_changed.connect(_on_state_changed)
	game_state.lives_changed.connect(_on_lives_changed)
	game_state.death_presented.connect(_on_death_presented)
	start_button.pressed.connect(game_state.start_run)
	continue_button.pressed.connect(game_state.dismiss_death)
	game_over_button.pressed.connect(game_state.dismiss_game_over)
	_on_lives_changed(game_state.lives, game_state.max_lives)
	_on_death_presented(game_state.death_reason)
	_on_state_changed(game_state.state)


func _process(_delta: float) -> void:
	step_input()


func _unhandled_input(event: InputEvent) -> void:
	if game_state == null:
		return
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if game_state.state == GameState.State.DEAD:
		game_state.dismiss_death()
		get_viewport().set_input_as_handled()
	elif game_state.state == GameState.State.GAME_OVER:
		game_state.dismiss_game_over()
		get_viewport().set_input_as_handled()


func step_input() -> void:
	if game_state == null:
		return
	if game_state.state == GameState.State.READY and Input.is_action_just_pressed("confirm"):
		game_state.start_run()


func _on_state_changed(new_state: int) -> void:
	start_overlay.visible = new_state == GameState.State.READY
	death_overlay.visible = new_state == GameState.State.DEAD
	game_over_overlay.visible = new_state == GameState.State.GAME_OVER
	hearts.visible = new_state != GameState.State.READY
	match new_state:
		GameState.State.READY:
			start_button.call_deferred("grab_focus")
		GameState.State.DEAD:
			continue_button.call_deferred("grab_focus")
		GameState.State.GAME_OVER:
			game_over_button.call_deferred("grab_focus")


func _on_lives_changed(lives_remaining: int, lives_maximum: int) -> void:
	if hearts.get_child_count() != lives_maximum:
		for child in hearts.get_children():
			child.free()
		for index in range(lives_maximum):
			var heart := Label.new()
			heart.name = "Heart%d" % (index + 1)
			heart.text = "♥"
			heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
			heart.add_theme_font_size_override("font_size", 28)
			hearts.add_child(heart)
	for index in range(hearts.get_child_count()):
		var heart := hearts.get_child(index) as Label
		heart.modulate = LIVE_HEART_COLOR if index < lives_remaining else LOST_HEART_COLOR


func _on_death_presented(reason: String) -> void:
	cause_label.text = "Cause: %s" % reason
