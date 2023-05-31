extends Spatial

#borrowed heavily from SRCoder: https://www.youtube.com/watch?v=6A6tp-rKy3Y

var direction = Vector3.FORWARD
export (float, 1, 10, 0.1) var smooth_speed = 2.5
onready var reset_xform = transform
onready var reset_cam = $camera.transform
onready var last_position = global_transform.origin


func reset():
	transform = reset_xform
	$camera.transform = reset_cam


func _physics_process(delta):
	var current_velocity = get_parent().get_linear_velocity()
	current_velocity.y = 0
	
	var linear_velocity = (global_transform.origin - last_position) / delta
	linear_velocity.y = 0
	
	if current_velocity.length_squared() > 1:
		direction = lerp(direction, -current_velocity.normalized(), smooth_speed*delta)
		#smooth_speed = (current_velocity.normalized() / linear_velocity.normalized()).length()
		#direction = lerp(direction, -linear_velocity.normalized(), smooth_speed * delta)
		#rotate camera base to point in the dir vector
		global_transform.basis = get_rotation_from_direction(direction)

	# Rotate camera base to point in the direction vector
	global_transform.basis = get_rotation_from_direction(direction)
#	if current_velocity.length_squared() > 1:
#		direction = lerp(direction, -current_velocity.normalized(), smooth_speed*delta)
#		#rotate camera base to point in the dir vector
#		global_transform.basis = get_rotation_from_direction(direction)
	#else:
	#	direction = lerp(direction, get_global_transform().basis.z.normalized() , smooth_speed*delta)
	#	global_transform.basis = get_rotation_from_direction(direction)
		#rotation.y = lerp(rotation.y, 0, smooth_speed * delta)
	
	rotation_degrees.x = 25
	#if cam goes too low or we crashed
	if global_transform.origin.y < -3.7 or get_parent().towing:
		var target_pos = get_parent().global_transform.origin
		target_pos.y = 7
		global_transform.origin = lerp(global_transform.origin, target_pos, smooth_speed*delta)
		$camera.look_at(get_parent().translation, Vector3.UP)
		
		var explosion_pos = get_parent().get_node("part_system").global_transform
		explosion_pos = target_pos
		explosion_pos.y = -1.2
	
	last_position = global_transform.origin


func get_rotation_from_direction(look_direction: Vector3) -> Basis:
	look_direction = look_direction.normalized()
	var x_axis = look_direction.cross(Vector3.UP)
	return Basis(x_axis, Vector3.UP, -look_direction)
