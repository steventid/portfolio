extends Node2D

const target = Vector2(45,16)
var flow_field = null
var tm = null

func _physics_process(delta):
	tm = get_parent().get_node("TileMap")
	
	if tm == null:
		return
	if flow_field == null:
		flow_field = get_parent()._calc_flow_field(target)
	
	var my_pos = tm.world_to_map(position)
	var vel = flow_field[my_pos.x][my_pos.y]
	
	if vel != null and my_pos != target:
		position += vel.normalized() * 0.5
		$Sprite.rotation = vel.angle()
	elif my_pos == target:
		get_parent().dome_health -= 1
		queue_free()
