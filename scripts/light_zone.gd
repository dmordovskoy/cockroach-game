class_name LightZone
extends Area3D

const GROUP := &"light_zones"
const PLAYER_COLLISION_LAYER := 2
const LIGHT_ZONE_COLLISION_LAYER := 4


func _init() -> void:
	collision_layer = LIGHT_ZONE_COLLISION_LAYER
	collision_mask = PLAYER_COLLISION_LAYER
	monitoring = true
	monitorable = false


func _enter_tree() -> void:
	add_to_group(GROUP)
