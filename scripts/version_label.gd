extends CanvasLayer

const BASE_FONT_SIZE := 24.0
const BASE_VIEWPORT_HEIGHT := 1080.0
const MIN_FONT_SIZE := 12
const MAX_FONT_SIZE := 48

@onready var label: Label = $Label


func _ready() -> void:
	label.text = str(ProjectSettings.get_setting("application/config/version", "dev"))
	get_viewport().size_changed.connect(_refresh_font_size)
	_refresh_font_size()


func apply_viewport_height(viewport_height: float) -> void:
	var scaled := roundi(BASE_FONT_SIZE * viewport_height / BASE_VIEWPORT_HEIGHT)
	label.add_theme_font_size_override("font_size", clampi(scaled, MIN_FONT_SIZE, MAX_FONT_SIZE))


func _refresh_font_size() -> void:
	apply_viewport_height(get_viewport().get_visible_rect().size.y)
