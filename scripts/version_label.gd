extends CanvasLayer

@onready var label: Label = $Label


func _ready() -> void:
	label.text = str(ProjectSettings.get_setting("application/config/version", "dev"))
