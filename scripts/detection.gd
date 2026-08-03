class_name Detection
extends Node

const LIGHT_ZONE_GROUP := &"light_zones"

@export_range(0.0, 10.0, 0.01) var fill_rate := 0.35
@export_range(0.0, 10.0, 0.01) var drain_rate := 0.2
@export var meter: ProgressBar
@export var safe_color := Color(1.0, 0.86, 0.25)
@export var danger_color := Color(1.0, 0.18, 0.12)

var level := 0.0:
	set(value):
		level = clampf(value, 0.0, 1.0)
		_sync_meter()

var light_zone_count: int:
	get:
		return _overlapping_zones.size()

var _player: PhysicsBody3D
var _overlapping_zones: Array[Area3D] = []


func _ready() -> void:
	_player = get_parent() as PhysicsBody3D
	for node in get_tree().get_nodes_in_group(LIGHT_ZONE_GROUP):
		var zone := node as Area3D
		if zone == null:
			continue
		zone.body_entered.connect(_on_light_zone_body_entered.bind(zone))
		zone.body_exited.connect(_on_light_zone_body_exited.bind(zone))
	_sync_meter()


func _physics_process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	if is_lit():
		level += fill_rate * delta
	else:
		level -= drain_rate * delta


func is_lit() -> bool:
	return not _overlapping_zones.is_empty()


func reset() -> void:
	_overlapping_zones.clear()
	level = 0.0


func _on_light_zone_body_entered(body: Node3D, zone: Area3D) -> void:
	if body == _player and zone not in _overlapping_zones:
		_overlapping_zones.append(zone)


func _on_light_zone_body_exited(body: Node3D, zone: Area3D) -> void:
	if body == _player:
		_overlapping_zones.erase(zone)


func _sync_meter() -> void:
	if meter == null:
		return
	meter.value = level
	meter.self_modulate = safe_color.lerp(danger_color, level)
