extends Node2D

onready var tm = $TileMap
onready var status = $UIPanel/Label

onready var power = $UIPanel/MainStatus/Power

onready var oxygen = $UIPanel/MainStatus/Oxygen
onready var oxygen_label = $UIPanel/MainStatus/OxygenLabel

onready var dome = $Base/Dome
onready var dome_bar = $UIPanel/MainStatus/Dome

onready var comms = $UIPanel/MainStatus/Comms
onready var comms_label = $UIPanel/MainStatus/CommsLabel
var comms_online = 0

onready var rescue = $UIPanel/MainStatus/Rescue
onready var rescue_label = $UIPanel/MainStatus/RescueLabel
var rescue_running = false

onready var drone_progress = $UIPanel/MainStatus/Drones
onready var drone_label = $UIPanel/MainStatus/DroneLabel
var drones = []
var drone_scene = load("res://scenes/Drone.tscn")
var enemy_scene = load("res://scenes/Enemy.tscn")

onready var minerals_label = $UIPanel/MainStatus/MineralsLabel
var minerals = 50

onready var game_over_text = $CanvasLayer/GameOverText
onready var restart_button = $CanvasLayer/Restart


var story_messages = [
	"You have been performing research on the mars facility.\n\ntoday you woke up to multiple alarms throughout the facility.",
	"The power is currently [color=red]offline[color=green]\n\nThe dome is [color=red]damaged [color=green] and your [color=red]oxygen [color=green] levels are [color=red]dropping",
	"The dome has been damaged by [color=red]radiation [color=green]as well as [color=red]hostile aliens[color=green]",
	"To top it off, your antenna have also been [color=red]damaged\n\n[color=green]and it is only a matter of time before the facility is overrun and the dome [color=red]fails",
	"Mission Objectives:\n\n1. Activate [color=red]Manual Generator[color=green]\n\n2. 3D Print a [color=red]drone[color=green]\n\n3. Use drones to gather [color=red]minerals[color=green] and [color=red]repair[color=green]\n\n4. Repair all [color=red]Antennas[color=green] to send distress signal\n\n5. Build [color=red]turrets[color=green] to defend the dome",
	"most importantly:\n\n[color=red]survive until the rescue team arrives"
]
var story_page = 0

var alpha_status = false
var delta_status = false

var power_level = 0
var oxygen_level = 80.0
var dome_health = 75.0


var system_index = 0
var system_status = [
	"Power [color=red]offline\n\n[color=green]Press 'y' to begin manual override sequence",
	"Manual Generator Instructions:\nPress the [color=red]A KEY[color=green] to bring the [color=red]alpha [color=green] drone, identifed as 'dyna', online",
	"Manual Generator Instructions:\nPress the [color=red]D KEY[color=green] to bring the [color=red]delta [color=green] drone, identifed as 'mo', online",
	"Manual Generator Instructions:\nGreat work! [color=red]Dyna[color=green] is now online and will press the [color=red]A KEY[color=green]automatically!\n\nContinue to Press the [color=red]D KEY[color=green] to bring [color=red]mo [color=green] online",
	"Manual Generator Instructions:\nAmazing! Now both [color=red]Dyna[color=green] and [color=red]mo [color=green] are online and will run the [color=red]generator [color=green]for you!\n\nYou may have to [color=red]reset [color=green] them from time to time, however"
]

var dome_pos = Vector2(45,16)
var dome_field = []
var width = 50
var height = 33
var level_rect = Rect2(0,0,width,height)

const N = Vector2(0, -1)
const E = Vector2(1, 0)
const S = Vector2(0, 1)
const W = Vector2(-1, 0)
const NE = N+E
const SE = S+E
const SW = S+W
const NW = N+W
var dirs = [N, NE, E, SE, S, SW, W, NW]
var dists = [10, 14, 10, 14, 10, 14, 10, 14]

var spawn_locations = []
var baddies = []

var state = "menu"

var heat = []

func _ready():
	if OS.is_debug_build():
		OS.set_current_screen(2)
	for x in range(width):
		heat.append([])
		for _y in range(height):
			heat[x].append(-1)
	
	for i in range(width):
		for j in range(height):
			var foo = $Grid.duplicate()
			foo.position = Vector2(i*32, j*32)
			add_child(foo)
			foo.set_meta("heat", INF)
			heat[i][j] = foo
	$Grid.hide()
	if OS.get_name() == "HTML5":
		OS.set_window_size(Vector2(1600,900))
	status.visible_characters = 46
	dome_field = _calc_flow_field(dome_pos)
	spawn_locations = tm.get_used_cells_by_id(4)
	Events.connect("keypress_a", self, "_on_keypress_a")
	Events.connect("keypress_d", self, "_on_keypress_d")
	Events.connect("drone_deposit", self, "on_drone_deposit")
	Events.connect("drone_repair_dome", self, "on_drone_repair_dome")
	Events.connect("send_comms", self, "on_send_comms")
	
	for i in range(5):
		var foo = $Mob.duplicate()
		foo.position = spawn_locations[randi()%spawn_locations.size()] * Vector2(32,32) + Vector2(16,16)
		add_child(foo)
		baddies.append(foo)
	
	$Mob.hide()
	
#	#Speed testing for get_cell vs get_cellv
#	var num_trials = 100000
#	var x = randi()%width
#	var y = randi()%height
#	var start_time = OS.get_ticks_msec()
#	for i in range(num_trials):
#		var foo = tm.get_cell(x, y)
#	prints("get_cell:", OS.get_ticks_msec() - start_time)
#
#	start_time = OS.get_ticks_msec()
#	for i in range(num_trials):
#		var foo = tm.get_cellv(Vector2(x, y))
#	prints("get_cellv(Vector2()):", OS.get_ticks_msec() - start_time)
#
#
#	var bar = Vector2(x, y)
#	start_time = OS.get_ticks_msec()
#	for i in range(num_trials):
#		var foo = tm.get_cellv(bar)
#	prints("get_cellv(pos):", OS.get_ticks_msec() - start_time)
#
#	start_time = OS.get_ticks_msec()
#	for i in range(num_trials):
#		var foo = tm.get_cell(bar.x, bar.y)
#	prints("get_cell(pos.x, pos.y)", OS.get_ticks_msec() - start_time)
#
#	var rocks = tm.get_used_cells_by_id(5)
#	var rock_count = 0
#	var space_count = 0
#
#	print("using tm.get_cell method")
#	start_time = OS.get_ticks_msec()
#	for i in range(num_trials):
#		if tm.get_cell(randi()%width, randi()%height) == 5:
#			rock_count += 1
#		else:
#			space_count += 1
#	print("Rocks: ", rock_count, "\nSpaces: ", space_count, "\n", OS.get_ticks_msec() - start_time)
#	print("\nusing if var in array method")
#
#	rock_count = 0
#	space_count = 0
#	start_time = OS.get_ticks_msec()
#	for i in range(num_trials):
#		if Vector2(randi()%width, randi()%height) in rocks:
#			rock_count += 1
#		else:
#			space_count += 1
#	print("Rocks: ", rock_count, "\nSpaces: ", space_count, "\n", OS.get_ticks_msec() - start_time)


func _physics_process(delta):
	if state == "game_over": return
	
	if state == "menu": return
	
	#status where we show the story
	if state == "story":
		do_story_state()
		return
	
	#status where you spam A and D for Alpha and Delta
	if state == "system_offline":
		do_system_offline_state()
		return
	
	if state == "system_starting":
		do_system_starting(delta)
		return
	
	if state == "running":
		do_game_running(delta)
		return
	
	#var pos = tm.world_to_map(get_global_mouse_position())
	
	#status.text = str("FPS: ", Engine.get_frames_per_second())
	#status.text += str("\nBaddies: ", baddies.size())
	#if level_rect.has_point(pos):
	#	status.text += str("\n\n\n", pos, " - ", dome_field[pos.x][pos.y])
	
	#if Input.is_action_just_pressed("click"):
	#	dome_field = _calc_flow_field(pos)
	
	
	
#	if Engine.get_frames_per_second() > 55:
#		#add a baddie
#		var foo = $Mob.duplicate()
#		foo.position = spawn_locations[randi()%spawn_locations.size()] * Vector2(32,32) + Vector2(16,16)
#		add_child(foo)
#		baddies.append(foo)
#		foo.show()
#
#	#try to move baddies towards dome
#	for i in range(baddies.size()):
#		var bad_pos = tm.world_to_map(baddies[i].position + Vector2(0,-12))# + Vector2(16,16))
#		if bad_pos.x >= width or bad_pos.y >= height:
#			continue
#		var vel = dome_field[bad_pos.x][bad_pos.y]
#		if vel != null:
#			baddies[i].position += vel# * Vector2(randf(), randf()) + Vector2(randf(), randf())
#			baddies[i].rotation = vel.angle()
#
#	for i in range(baddies.size()-1, -1, -1):
#		if baddies[i].position.distance_to($Dome.position) < 64:
#			baddies[i].queue_free()
#			baddies.remove(i)

var oxygen_drain = 0.5

var hovering_button = false
var drone_building = false
var selected_drone = -1

var rescue_timer = 0
var enemy_timer = 0
func do_game_running(delta):
	if get_tree().get_nodes_in_group("enemies").size() < 2000:
		for i in range(10):
			spawn_enemy()
	var heet = tm.world_to_map(get_global_mouse_position())
	if level_rect.has_point(heet):
		display_message(str(heat[heet.x][heet.y].get_meta("heat"), " ", dome_field[heet.x][heet.y]))
	update_drones(delta)
	update_dome()
	calc_oxygen(delta)
	update_minerals()
	comms_label.bbcode_text = str("[color=green][right]Comms [", comms_online, " /3]")
	
	if comms.value > 0:
		enemy_timer += delta
		if enemy_timer > 5:
			enemy_timer = 0
			spawn_enemy()
	
	if rescue_running:
		rescue_timer += delta
		if rescue_timer > 1:
			rescue_timer = 0
			rescue.value += 1
	
	if dome_health <= 0:
		show_game_over("GAME OVER, THE DOME WAS DESTROYED")
	
	if oxygen_level <= 0:
		show_game_over("GAME OVER, YOU RAN OUT OF OXYGEN")
	
	if rescue.value >= 300:
		show_game_over("YOU WERE RESCUED!")
	
	display_message(str(Engine.get_frames_per_second(), "\n", get_tree().get_nodes_in_group("enemies").size()))


func show_game_over(msg):
	game_over_text.text = msg
	game_over_text.show()
	restart_button.show()
	$Fader.modulate.a = 1
	state = "game_over"
	get_tree().call_group("enemies", "queue_free")
	get_tree().call_group("antenna", "queue_free")
	for i in range(drones.size()):
		drones[i].queue_free()
	comms.value = 0



func update_drones(delta):
	drone_label.bbcode_text = str("[color=green]Drones: [", drones.size(), "/5]")
	
	if Input.is_action_just_pressed("click"):
		selected_drone = -1
		var click_pos = get_global_mouse_position()
		for i in range(drones.size()):
			if drones[i].select(click_pos):
				selected_drone = i
				break
		if selected_drone == -1:
			display_message("")
		else:
			if selected_drone < drones.size():
				for i in range(selected_drone+1, drones.size()):
					drones[i].deselect()
	
	if Input.is_action_just_pressed("right_click"):
		var actual_click = get_global_mouse_position()
		var click_pos = tm.world_to_map(actual_click)
		if selected_drone != -1 and level_rect.has_point(click_pos) and tm.get_cellv(click_pos) != 5:
			drones[selected_drone].set_target(click_pos)
			drones[selected_drone].actual_click_pos = actual_click
			drones[selected_drone].prior_state = null
	
	if drones.size() == 0 and hovering_button == false and !drone_building:
		display_message("You should build a drone!")
	if selected_drone >= 0:
		display_message(str("Drone is currently: ", drones[selected_drone].state, "\nMinerals: ", drones[selected_drone].carried_minerals, " / 250"))


	if drone_building:
		drone_progress.value += delta * 100.0
		if drone_progress.value >= 100:
			spawn_drone()


func on_drone_deposit(msg):
	minerals += msg

func on_drone_repair_dome():
	if minerals >= 25:
		minerals -= 25
		dome_health += 1

func on_send_comms():
	comms.value += 1
	if comms.value >= 300:
		comms_label.hide()
		comms.hide()
		rescue.show()
		rescue_label.show()
		rescue_running = true
	spawn_enemy()


func spawn_drone():
	#need to instance a drone at the 3D printer and set its destination to pos(43,13) in the navmap
	var foo = drone_scene.instance()
	foo.position = Vector2(1520, 528)
	add_child(foo)
	drones.append(foo)
	drone_progress.value = 0
	drone_building = false


func spawn_enemy():
	var foo = enemy_scene.instance()
	#foo.position = spawn_locations[randi()%spawn_locations.size()] * Vector2(32,32) + Vector2(16,16)
	var pos = Vector2(randi()%32, randi()%33)
	while tm.get_cellv(pos) == 5:
		pos = Vector2(randi()%50, randi()%33)
	foo.position = pos * Vector2(32, 32) + Vector2(randi()%32, randi()%32)
	foo.flow_field = dome_field
	add_child(foo)


func update_dome():
	if dome_health >= 100:
		dome_health = 100
		dome.frame = 0
		dome_bar.value = dome_health
		return
	if dome_health > 75:
		dome.frame = 1
		dome_bar.value = dome_health
		return
	if dome_health > 50:
		dome.frame = 2
		dome_bar.value = dome_health
		return
	if dome_health > 0:
		dome.frame = 3
		dome_bar.value = dome_health
		return
	if dome_health <= 0:
		dome_health = 0
		dome.frame = 4
		dome_bar.value = dome_health
		return

func update_minerals():
	minerals_label.bbcode_text = str("[color=green]Minerals: ", minerals)


func display_message(msg):
	status.bbcode_text = "[color=green]" + msg


func calc_oxygen(delta):
	#set drain to be a percent of dome health
	oxygen_drain = dome_health / 100.0
	
	
	if dome_health < 100:
		oxygen_level -= delta * oxygen_drain * 0.1
		oxygen_label.bbcode_text = "[color=red][right]oxygen: "
	else:
		oxygen_level += delta
		oxygen_label.bbcode_text = "[color=green][right]oxygen: "
	
	oxygen_level = clamp(oxygen_level, 0, 100)
	
	oxygen.value = oxygen_level


func do_story_state():
	if story_page < story_messages.size()-1:
		$CanvasLayer/Story_Next.show()
	else:
		$CanvasLayer/Story_Next.hide()
	if story_page > 0:
		$CanvasLayer/Story_Back.show()
	else:
		$CanvasLayer/Story_Back.hide()
	#set the text
	var msg = story_messages[story_page]
	typing_status_update(msg, len(msg))



func do_system_offline_state():
	typing_status_update(system_status[system_index], len(system_status[system_index]))
	
	if Input.is_action_just_pressed("press_y") and system_index == 0:
		status.visible_characters = 0
		system_index += 1
		state = "system_starting"
		$TypingChirp.play()


var alpha_timer = 0
var delta_timer = 0

func do_system_starting(delta):
	status.visible_characters = 100
	
	#update power level
	power.value = power_level
	
	if !alpha_status:
		typing_status_update(system_status[system_index], len(system_status[system_index]))
	else:
		status.bbcode_text = "[color=green]" + system_status[3]
		status.visible_characters = len(status.text)
	if delta_status:
		status.bbcode_text = "[color=green]" + system_status[4]
		status.visible_characters = len(status.text)
	
	if !alpha_status and Input.is_action_just_pressed("press_a"):
		_on_keypress_a()
		return
	
	if !delta_status and Input.is_action_just_pressed("press_d"):
		_on_keypress_d()
		return
	
	
	if power_level == 100:
		state = "running"
		status.bbcode_text = "[color=green]System initializing..."
		status.visible_characters = -1
		$Fader.modulate.a = 0
		get_node("Base/3DPrinter").playing = true

func _on_keypress_a():
	if system_index != 1: return
	if state == "system_starting":
		$TypingChirp.play()
		system_index = 2
		power_level += 5
		if power_level == 25:
			Events.emit_signal("alpha_online")
			alpha_status = true
		$Fader.modulate.a -= 0.05

func _on_keypress_d():
	if system_index != 2: return
	if state == "system_starting":
		$TypingChirp.play()
		system_index = 1
		power_level += 5
		if power_level == 50:
			Events.emit_signal("delta_online")
			delta_status = true
		$Fader.modulate.a -= 0.05


func typing_status_update(msg, length):
	status.bbcode_text = "[color=green]" + msg
	
	if status.visible_characters < length:
		status.visible_characters += 1
	
	if !$TypingChirp.playing:
		if status.visible_characters < len(status.text):
			$TypingChirp.play()


func _calc_flow_field(pos):
	var start_time = OS.get_ticks_msec()
	var target_pos = pos
	var flow_field = []
	var heatmap = []
	for x in range(width):
		flow_field.append([])
		heatmap.append([])
		for _y in range(height):
			flow_field[x].append(null)
			heatmap[x].append(-1)
	
	#calculate the heatmap
	heatmap[pos.x][pos.y] = 0
	var stack = []
	stack.append(pos)
	
	while !stack.empty():
		pos = stack.pop_front()
		if tm.get_cellv(pos) == 5:
			continue
		for i in range(dirs.size()):
			#position of neighbor
			var posn = pos + dirs[i]
			if posn.x < 0 or posn.x >= width or posn.y < 0 or posn.y >= height:
				continue
			#not yet visited
			var current_heat = heatmap[posn.x][posn.y]
			if current_heat == -1:
				heatmap[posn.x][posn.y] = heatmap[pos.x][pos.y] + dists[i]
				if tm.get_cellv(posn) == 5:
					heatmap[posn.x][posn.y] = 99999
				#if diagnoal and pos + X or pos + Y == ROCK then heat also = 99999?
#				if i % 2 == 1:
#					if tm.get_cellv(Vector2(pos.x, pos.y + dirs[i].y)) == 5:
#						heatmap[posn.x][posn.y] = 99999
#					if tm.get_cellv(Vector2(pos.x + dirs[i].x, pos.y)) == 5:
#						heatmap[posn.x][posn.y] = 99999
				stack.append(posn)
			else:
				var new_heat = heatmap[pos.x][pos.y] + dists[i]
				if tm.get_cellv(posn) == 5:
					continue
				#if diagnoal and pos + X or pos + Y == ROCK then heat also = 99999?
#				if i % 2 == 1:
#					if tm.get_cellv(Vector2(pos.x, pos.y + dirs[i].y)) == 5:
#						continue
#					if tm.get_cellv(Vector2(pos.x + dirs[i].x, pos.y)) == 5:
#						continue
				if current_heat > new_heat:
					heatmap[posn.x][posn.y] = new_heat
		if target_pos == dome_pos:
			heat[pos.x][pos.y].set_meta("heat", heatmap[pos.x][pos.y])
	
	
	for x in range(width):
		for y in range(height):
			#for each cell in the heatmap, calc the corresponding flow field
			#by pointing towards the LOWEST heat
			pos = Vector2(x, y)
			var min_idx = 0
			var min_heat = INF
			for i in range(dirs.size()):
				var new_pos = pos + dirs[i]
				#if it's outside the map
				if !level_rect.has_point(new_pos):
					continue
				#if the tilemap has a rock
				if tm.get_cellv(new_pos) == 5:
					continue
#				if i % 2 == 1:
#					if tm.get_cellv(Vector2(pos.x, pos.y + dirs[i].y)) == 5:
#						continue
#					if tm.get_cellv(Vector2(pos.x + dirs[i].x, pos.y)) == 5:
#						continue
				#if it has the lowest heat, keep up with the lowest one
				if heatmap[new_pos.x][new_pos.y] < min_heat:
					min_heat = heatmap[new_pos.x][new_pos.y]
					min_idx = i
			flow_field[pos.x][pos.y] = dirs[min_idx]
	print("Time: ", OS.get_ticks_msec() - start_time)
	return flow_field


func _on_Exit_pressed():
	get_tree().quit()


func _on_NewGame_pressed():
	$CanvasLayer/MainMenu.hide()
	$CanvasLayer/Title.hide()
	$CanvasLayer/Title2.hide()
	$UIPanel/MainStatus.show()
	state = "system_offline"
	status.visible_characters = 0
	oxygen_level = 80
	oxygen.value = oxygen_level
	dome_health = 70
	dome_bar.value = dome_health


func _on_Story_pressed():
	$CanvasLayer/MainMenu.hide()
	$CanvasLayer/Title.hide()
	$CanvasLayer/Title2.hide()
	$CanvasLayer/Story_Menu.show()
	state = "story"
	story_page = 0
	status.visible_characters = 0


func _on_Story_Menu_pressed():
	$CanvasLayer/MainMenu.show()
	$CanvasLayer/Title.show()
	$CanvasLayer/Title2.show()
	$CanvasLayer/Story_Menu.hide()
	$CanvasLayer/Story_Back.hide()
	$CanvasLayer/Story_Next.hide()
	status.bbcode_text = "[color=green]System Status: [color=red]Offline"
	state = "menu"


func _on_Story_Next_pressed():
	story_page += 1
	if story_page >= story_messages.size():
		story_page = story_messages.size()-1
	status.visible_characters = 0
	$TypingChirp.stop()


func _on_Story_Back_pressed():
	story_page -= 1
	if story_page <= 0:
		story_page = 0
	status.visible_characters = 0
	$TypingChirp.stop()


func _on_Restart_pressed():
	get_tree().reload_current_scene()


func _on_BuildDrone_pressed():
	if state != "running": return
	if minerals < 50:
		display_message("Not enough [color=red]minerals[color=green]!")
		$UINope.play()
		return
	if drones.size() == 5:
		$UINope.play()
		display_message("Already at max drone capacity!")
		return
	if drone_progress.value > 0:
		$UINope.play()
		display_message("Already building a drone, please wait!")
		return
	#enough minerals and space for drone, queue a drone to build
	minerals -= 50
	drone_progress.value = 0
	drone_building = true


func _on_BuildDrone_mouse_entered():
	if state != "running": return
	hovering_button = true
	if drones.size() < 5:
		display_message("Build Drone\n\nCost: [color=red]50[color=green] minerals")
	else:
		display_message("Already at max drone capacity!")


func _on_BuildDrone_mouse_exited():
	if state != "running": return
	hovering_button = false
