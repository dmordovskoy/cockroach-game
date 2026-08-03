extends CanvasLayer

@onready var label: Label = $Label


func _ready() -> void:
	label.text = str(ProjectSettings.get_setting("application/config/version", "dev"))
	get_viewport().size_changed.connect(_update_stamp_scale)
	_update_stamp_scale()


func apply_render_scale(render_size: Vector2, logical_size: Vector2) -> void:
	if render_size.x <= 0.0 or render_size.y <= 0.0:
		return
	if logical_size.x <= 0.0 or logical_size.y <= 0.0:
		return
	var render_scale := minf(render_size.x / logical_size.x, render_size.y / logical_size.y)
	label.pivot_offset = label.size
	label.scale = Vector2.ONE / maxf(render_scale, 1.0)


func _update_stamp_scale() -> void:
	apply_render_scale(
		Vector2(get_viewport().get_texture().get_size()), get_viewport().get_visible_rect().size
	)
