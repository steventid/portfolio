extends Node2D

#where I initially want it to go
const dome_pos = Vector2(45,16)

var dome_positions = [dome_pos]

var target = Vector2(43,13)
var actual_click_pos = null
var flow_field = null
onready var tm = null

var current_path = []
var current_target = null

var carried_minerals = 0
var gather_target = null
var gather_target_pos = null

var state = "moving"
var prior_state = null
var selected = false

func _draw():
	#draw_circle(Vector2.ZERO, 18, Color(0, 1, 0))
	#draw_rect(Rect2(Vector2(-16, -16), Vector2(32, 32)), Color(0, 1, 0), false)
	if selected:
		draw_arc(Vector2(0, 0), 18, 0, deg2rad(360), 20, Color(0, 1, 0), 1.2, true)

func _ready():
	Events.connect("crystal_send_minerals", self, "on_crystal_send_minerals")
	for dir in get_parent().dirs:
		dome_positions.append(dome_pos + dir)
	tm = get_parent().get_node("TileMap")
	set_target(target)


func _physics_process(delta):
	tm = get_parent().get_node("TileMap")
	
	if tm == null:
		return
	if flow_field == null:
		flow_field = get_parent()._calc_flow_field(target)
	
	if state == "moving":
		do_moving()
		$Sprite.playing = true
		return
	
	$Sprite.playing = false
	
	if state == "gathering":
		do_gather(delta)
	
	if state == "repairing_dome":
		do_repair_dome(delta)
	
	if state == "repairing_comms":
		do_repair_comms(delta)


func do_repair_comms(delta):
	repair_time += delta
	if repair_time > 1:
		repair_time = 0
		if get_parent().minerals < 25 or gather_target.health > 9:
			state = "idle"
			$RepairStatus.hide()
			return
		get_parent().minerals -= 25
		gather_target.health += 1
		if gather_target.health == 10:
			get_parent().comms_online += 1



var repair_time = 0
func do_repair_dome(delta):
	if get_parent().dome_health >= 100:
		state = "idle"
		$RepairStatus.hide()
		return
		
	repair_time += delta
	if repair_time > .5:
		repair_time = 0
		Events.emit_signal("drone_repair_dome")

func do_moving():
	#try to move towards the area I should be
	var my_pos = tm.world_to_map(position)
	var vel = flow_field[my_pos.x][my_pos.y]
	
	if current_path.empty() and current_target == null:
			#so now we arrived at the FINAL target, see if we need to perform an action here
			if target in dome_positions:
				if carried_minerals >= 5:
					carried_minerals -= 5
					Events.emit_signal("drone_deposit", 5)
					return
				else:
					if prior_state == "gathering":
						set_target(gather_target_pos)
						return
					else:
						if get_parent().dome_health < 100:
							$RepairStatus.show()
							state = "repairing_dome"
							return
	
	if !current_target:
		state = "idle"
		return
	
	#not at target yet
	if position.distance_to(current_target) > 2:
		$Sprite.look_at(current_target)
		position = position.move_toward(current_target, 1)
		return
	else:
		#at target, pop it
		position = current_target
		current_target = current_path.pop_front()
		get_parent().get_node("Line2D").remove_point(0)
		
		
	#state = "idle"
	
	return
	
	#move towards current target
	if vel != null and my_pos != target:
		$Sprite.playing = true
		position += vel.normalized()
		$Sprite.look_at(position + vel)
	
	#we're not at the dest, move towards it
	#if !current_path.empty() and position.distance_to(current_path[0]) < 16:
	#	$Sprite.playing = true
	##	position += position.move_toward(current_path[0], 1)
	#	print(position)
	#else:
	#	current_path.pop_front()
	
	elif target in dome_positions:
		if carried_minerals > 0:
			carried_minerals -= 5
			Events.emit_signal("drone_deposit", 5)
		else:
			if prior_state == "gathering":
				set_target(gather_target_pos)
			else:
				if get_parent().dome_health < 100:
					$RepairStatus.show()
					state = "repairing_dome"
	#elif actual_click_pos != null and position.distance_to(actual_click_pos) > 16:
	#	look_at(get_global_mouse_position())
	#	position = position.move_toward(get_global_mouse_position(), 1)
	else:
		$Sprite.playing = false
		state = "idle"


var gather_time = 0
func do_gather(delta):
	gather_time += delta
	if gather_time > 1:
		#gather_time = 0
		Events.emit_signal("drone_gather_from", gather_target, name)


func on_crystal_send_minerals(msg, crystal_name, drone):
	#msg is not for me
	if drone != name: return
	if crystal_name != str(gather_target):
		return
	
	carried_minerals += 5
	
	if msg == 0 or carried_minerals >= 250:
		$GatherStatus.hide()
		prior_state = state
		set_target(dome_pos)


func select(pos):
	var myrect = Rect2(position-Vector2(16,16), Vector2(32,32))
	if myrect.has_point(pos):
		selected = true
		update()
		#$Selected.show()
		return true
	selected = false
	update()
	#$Selected.hide()
	return false

func deselect():
	selected = false
	update()
	#$Selected.hide()


func set_target(pos):
	#if !current_path.empty():
	#	return
	#if target == pos: return
	target = pos
	flow_field = get_parent()._calc_flow_field(target)
	#now we have a field, figure out where we are and get the path to the end
	current_path = []
	var current_cell = tm.world_to_map(position)
	#add the current cell's flow field so the first cell is the first one we need to go to
	#this SHOULD avoid jitter if we spam move commands
	current_cell += flow_field[current_cell.x][current_cell.y]
	while current_cell != target:
		current_path.append(tm.map_to_world(current_cell) + Vector2(16,16))
		current_cell += flow_field[current_cell.x][current_cell.y]
	
	#add the last cell to the array so we move INTO the cell we clicked on
	current_path.append(tm.map_to_world(target) + Vector2(16, 16))
	
	
	#show the path?
	get_parent().get_node("Line2D").clear_points()
	
	get_parent().get_node("Line2D").add_point(position)
	for p in current_path:
		get_parent().get_node("Line2D").add_point(p)
	
	current_target = current_path[0]
	state = "moving"
	$GatherStatus.hide()
	$RepairStatus.hide()


func _on_Area2D_body_entered(body):
	if "Crystal" in body.name:
		Events.emit_signal("drone_harvesting", body.name)
		$GatherStatus.show()
		state = "gathering"
		gather_target = body.name
		gather_target_pos = tm.world_to_map(body.position)
		return
	if "Antenna" in body.name:
		$RepairStatus.show()
		state = "repairing_comms"
		gather_target = body



func _on_Area2D_body_exited(body):
	if "Crystal" in body.name:
		Events.emit_signal("drone_finished", body.name)
		$GatherStatus.hide()
		gather_target = null
	if "Antenna" in body.name:
		$RepairStatus.hide()
		gather_target = null
