extends VehicleBody

#borrowed logic from SRCoder at: https://www.youtube.com/watch?v=zXLpitpFC6E
#explosion shader from LittleStryker at: https://www.youtube.com/watch?v=E-i3sZSXNMU

export (float, 100, 3000, 100) var max_rpm = 1000.0
export (float, 100, 1000, 10) var max_torque = 500.0
export (float, 100, 3000, 100) var max_rev_rpm = 500.0
export (float, 100, 1000, 10) var max_rev_torque = 250.0
export (float, 1, 20, 1) var accel_speed = 10.0
export (float, 1, 100, 1) var brake_power = 7.5
export (float, 1, 100, 1) var steer_power = 50.0

var acceleration = 0
var reversing = false
var reverse_time = 0
var game_over = false

onready var objective = get_owner().get_node("objective")
onready var debug = get_owner().get_node("HUD/Control/debug")
onready var hud = get_owner().get_node("HUD")
onready var shop_island_roads = get_owner().get_node("shop_island/shop_roads").get_children()
onready var dest_island_roads = get_owner().get_node("dest_island/dest_roads").get_children()
onready var explosion_xform = $part_system.global_rotation

var in_objective = false
signal objective_reached
signal use_fuel

var closest_road
var closest_road_pos
var last_rotation
var towing = false

#var fade_mats = []

func _ready():
	$part_system/AnimationPlayer.seek(0, true)


#https://www.reddit.com/r/godot/comments/ooln68/i_need_to_get_the_global_position_of_edges_of_3d/
func get_aabb_global_endpoints(mesh: MeshInstance) -> Array:
	var aabb: AABB = mesh.get_aabb()
	var global_endpoints := []
	for i in range(8):
		var local_endpoint: Vector3 = aabb.get_endpoint(i)
		var global_endpoint: Vector3 = mesh.to_global(local_endpoint)
		global_endpoints.push_back(global_endpoint)
	return global_endpoints


func hide_visuals():
	$taxi.hide()
	$arrow.hide()
	$stop.hide()
	$brake_lights.hide()
	$reverse_lights.hide()
	$headlights.hide()


func show_visuals():
	$taxi.show()
	$headlights.show()

func stop_car():
	#kill engine forces
	$rear_left_wheel.engine_force = 0
	$rear_right_wheel.engine_force = 0
	#reset movement and rotation velocities
	linear_velocity = Vector3(0, 0, 0)
	angular_velocity = Vector3(0, 0, 0)
	acceleration = 0


func stop_sounds():
	$engine_noise.stop()
	$brake_noise.stop()
	$turn_noise.stop()
	$explosion_noise.stop()


var squeal_delay = 0
var unstuck_timer = 0
var airborne = false
var airborne_last = false

func _physics_process(delta):
	if hud.game_over:
		stop_car()
		stop_sounds()
		return
	if towing or hud.get_node("tow_fade").current_animation != "":
		return
	if squeal_delay > 0:
		squeal_delay -= delta
	if unstuck_timer > 0:
		unstuck_timer -= delta
	#get linear velocity, convert to km/h
	#https://godotforums.org/d/20499-truck-town-how-to-calculate-speed
	var speed = round(linear_velocity.length() * 3.6)
	
	#were we airborne?
	airborne_last = airborne
	
	#Find last road we touched
	var roads = shop_island_roads + dest_island_roads
	if $ground_ray.is_colliding():
		airborne = false
		var col = $ground_ray.get_collider()
		#if it's a road
		if roads.has(col.get_owner()):
			#get the mesh
			var mesh = col.get_parent()
			var endpoints = get_aabb_global_endpoints(mesh)
			#find GLOBAL center of road
			var center = endpoints[0] + ((endpoints[7] - endpoints[0]) / 2)
			#update where to go when we crash
			closest_road_pos = center + Vector3(0, .25, 0)
			last_rotation = global_rotation
	else:
		airborne = true
	
	#do we squeal?
	if airborne == false and airborne_last == true:
		if not $turn_noise.playing:
			$turn_noise.pitch_scale = rand_range(.75, 2.25)
			$turn_noise.play()
	
	#handle steering
	steering = lerp(steering, Input.get_axis("turn_right", "turn_left") * 0.15, steer_power * delta)
	$taxi/taxi/wheel_frontLeft.rotation_degrees.y = 180 + (steering * 300)
	$taxi/taxi/wheel_frontRight.rotation_degrees.y = steering * 300
	
	if speed > 10:
		if (abs($front_left_wheel.get_skidinfo()) < 0.5 or abs($front_left_wheel.get_skidinfo()) < 0.5) and not $turn_noise.playing:
			if squeal_delay <= 0:
				$turn_noise.pitch_scale = rand_range(.75, 2.25)
				$turn_noise.play()
				squeal_delay = rand_range(.3, .8)
			
		var speed_mod = speed / 100.0
		$taxi.rotation.z = lerp($taxi.rotation.z, -steering * speed_mod, .05)
		$brake_lights.rotation.z = lerp($brake_lights.rotation.z, steering * speed_mod, .05)
		$reverse_lights.rotation.z = $brake_lights.rotation.z
		$headlights.rotation.z = $brake_lights.rotation.z
	else:
		$taxi.rotation.z = lerp($taxi.rotation.z, 0, .05)
		$brake_lights.rotation.z = lerp($brake_lights.rotation.z, 0, .05)
		$reverse_lights.rotation.z = lerp($reverse_lights.rotation.z, 0, .05)
		$headlights.rotation.z = lerp($headlights.rotation.z, 0, .05)
	
	#handle acceleration
	if Input.is_action_pressed("accelerate"):
		acceleration = clamp(acceleration + delta * 20, 0, accel_speed)
		reversing = false
		reverse_time = 0
		$engine_noise.pitch_scale = lerp($engine_noise.pitch_scale, 2, 0.2)
		$engine_noise.volume_db = lerp($engine_noise.volume_db, -25, 0.2)
		#if not $engine_noise.playing:
		$engine_noise.play()
		#else:
		#	if $engine_noise.get_playback_position() > 3.6:
		#		$engine_noise.play(1.6)
	else:
		acceleration = clamp(acceleration - delta * 20, 0, accel_speed)
		$engine_noise.pitch_scale = lerp($engine_noise.pitch_scale, 1, 0.2)
		$engine_noise.volume_db = lerp($engine_noise.volume_db, -35, 0.2)
	
	#just pressed reverse and not currently moving, back up
	if Input.is_action_just_pressed("brake") and speed == 0:
		reversing = true
		reverse_time = 0
	
	#handle braking
	if Input.is_action_pressed("brake"):
		if acceleration > 0:
			acceleration = 0
		$rear_left_wheel.brake = brake_power
		$rear_right_wheel.brake = brake_power
		$brake_lights.show()
		if ($rear_left_wheel.is_in_contact() or $rear_right_wheel.is_in_contact()) and not $brake_noise.playing and not reversing:
			$brake_noise.pitch_scale = rand_range(0.75, 1.25)
			$brake_noise.play()
		if reversing:
			acceleration = -accel_speed
		elif reverse_time < 1 and speed == 0:
			reverse_time += delta
			if reverse_time >= .5:
				reversing = true
	else:
		$rear_left_wheel.brake = 1
		$rear_right_wheel.brake = 1
		$brake_lights.hide()
	
	#polish
	if reversing:
		$brake_lights.hide()
		$reverse_lights.show()
		$engine_noise.pitch_scale = lerp($engine_noise.pitch_scale, 1.5, 0.2)
	else:
		$reverse_lights.hide()
	
	#prevent accelerating forever
	if acceleration > 0:
		$rear_left_wheel.engine_force = acceleration * max_torque * (1 - abs($rear_left_wheel.get_rpm() / max_rpm))
		$rear_right_wheel.engine_force = acceleration * max_torque * (1 - abs($rear_right_wheel.get_rpm() / max_rpm))
	else:
		$rear_left_wheel.engine_force = acceleration * max_rev_torque * (1 - abs($rear_left_wheel.get_rpm() / max_rev_rpm))
		$rear_right_wheel.engine_force = acceleration * max_rev_torque * (1 - abs($rear_right_wheel.get_rpm() / max_rev_rpm))
	
	#point arrow at target
	if objective.visible:
		$arrow.look_at(objective.global_transform.origin, Vector3.UP)
		$arrow.rotation_degrees.y += 90
		$arrow.rotation_degrees.x = 0
		$arrow.rotation_degrees.z = 0
		if !$arrow.visible and !$stop.visible:
			$arrow.show()
	else:
		$arrow.hide()
	
	var unstuck_pressed = false
	if Input.is_action_just_pressed("unstuck"):
		if unstuck_timer <= 0:
			unstuck_pressed = true
			unstuck_timer = 30
		else:
			hud.get_node("label_unstuck").text = str(" Unstuck not available for ", str(int(ceil(unstuck_timer))).pad_zeros(2), " more seconds!")
			var player = hud.get_node("flash_unstuck")
			if not player.is_playing():
				player.play("flash_unstuck")
	
	#if we drove off the map then reset to closest road
	if translation.y <= -4.7 or (get_colliding_bodies() and get_colliding_bodies()[0].get_parent().name == "lava") or unstuck_pressed:
		#linear_velocity = Vector3(0, 0, 0) #stop moving, play explosion, wait a few secs, respawn car elsewhere
		stop_sounds()
		stop_car()
		PhysicsServer.set_active(false)
		#hide the visuals for the car
		hide_visuals()
		towing = true
		
		#play explosion
		$part_system.global_rotation = explosion_xform
		$explosion_noise.pitch_scale = rand_range(.8, 1)
		$explosion_noise.play()
		$part_system.get_node("AnimationPlayer").play("explode")
		#wait for explosion
		yield($part_system.get_node("AnimationPlayer"),"animation_finished")
		#fade to black with message
		hud.fade_in()
		yield(hud.get_node("tow_fade"),"animation_finished")
		
		#subtract money
		hud.tow_fee(-20)
		yield(hud.get_node("fader"),"animation_finished")
		hud.cash -= 20
		#put car back on the road
		global_transform.origin = closest_road_pos
		#set the car to the rotation it had when last on the ground
		global_rotation = last_rotation
		PhysicsServer.set_active(true)
		stop_car()
		#show the visuals for the car
		show_visuals()
		
		$taxi.rotation.z = 0
		$brake_lights.rotation.z = 0
		$reverse_lights.rotation.z = 0
		$headlights.rotation.z = 0
		
		towing = false
		#fix the camera!
		$cam_base.reset()
		hud.fade_out()
		yield(hud.get_node("tow_fade"),"animation_finished")
		
		yield(get_tree().create_timer(.25),"timeout")
		
		return
	
	#if in objective and stopped, then pickup / deliver / whatever
	if in_objective and speed == 0:
		#objective.global_transform.origin = Vector3(rand_range(-250, 250), -3.24, rand_range(100, 200))
		emit_signal("objective_reached")
	
	#use gas
	if acceleration != 0:
		emit_signal("use_fuel")


func do_game_over():
	linear_velocity = Vector3(0, 0, 0)
	game_over = true

func _on_objective_body_entered(body):
	if body.name == "player":
		in_objective = true
		$arrow.hide()
		$stop.show()

func _on_objective_body_exited(body):
	if body.name == "player":
		in_objective = false
		$stop.hide()
		$arrow.show()
