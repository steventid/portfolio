extends CanvasLayer

var notice_time = rand_range(3, 10)
var objective_timer = 1
var phone_state = "idle" #"buzzing", "checking"
var player_state = "available"
var order
var current_order_pay = 0
var cash = 50

var delivery_time = 0
var accept_time = 0

var refuel_cost = 0

var game_over = false

onready var order_text = $Control/Phone/show_app
onready var objective = get_owner().get_node("objective")

var orders = [
	["borger", 5.0, "Get 2 chicken sandwiches and 2 cheeseborgers."],
	["borger", 10.0, "Get a #9, Large, with a diet soda."],
	["borger", 20.0, "Get 2 large fries, 2 large nuggets, 4 fried pies"],
	["pizza", 10.0, "Get 1 Medium cheese pizza, with bones."],
	["pizza", 20.0, "Get 1 Large supreme pizza, boneless."],
	["pizza", 40.0, "Get 1 Large supreme, 1 Large cheese, and wings. All bones."],
	["italian", 20.0, "Get a personal lasagna."],
	["italian", 20.0, "Get a spaghetti plate with breadsticks."],
	["italian", 40.0, "Get the family sized lasagna pan with breadsticks"],
	["icecream", 20.0, "Get a 2 scoop chocolate cone."],
	["icecream", 40.0, "Get a frozen coffee drink."],
	["icecream", 40.0, "Get a pint of rocky road."],
	]

var dests = [
	Vector2(292, 221),
	Vector2(511, 407),
	Vector2(437, 35),
	Vector2(955, -38),
	Vector2(492, -185),
	Vector2(829, -293)
]


func _ready():
	$fader.play_backwards("fade")
	randomize()
	reset_phone()


func fade_in():
	$tow_fade.play("fade")


func fade_out():
	$tow_fade.play_backwards("fade")


func tow_fee(amount):
	if not $cash.playing:
		$cash.play()
	if amount < 0:
		$show_tow.set("custom_colors/default_color", Color(.84, .11, .11))
		$show_tow.text = str(" ", amount)
	else:
		$show_tow.set("custom_colors/default_color", Color(.29, .93, .18))
		$show_tow.text = str(" +", amount)
	$fader.play("tow_fee")


func handle_refuel():
	if refuel_cost == 0:
		return
	
	if cash <= 0:
		if not $decline.playing:
			$decline.play()
		$flash_money.play("flash_money")
		return
	
	$flash_fuel.stop()
	$Control/label_fuel.modulate = Color(1, 1, 1, 1)
	
	#partial refuel
	if cash < refuel_cost:
		var partial = cash / .75
		$Control/show_fuel.value += partial
		var gas = $Control/show_fuel.value
		refuel_cost = int((100 - gas) * .75)
		$Control/show_refuel.text = str(" ", refuel_cost)
		cash = 0
		$Control/show_money.text = str(" ",cash)
		tow_fee(-refuel_cost)
		return
	
	#full refuel
	cash -= refuel_cost
	tow_fee(-refuel_cost)
	$Control/show_fuel.value = 100
	$Control/show_refuel.text = str(" 0")
	$Control/show_money.text = " " + str(cash)
	refuel_cost = 0


func stop_sounds():
	$vibration.stop()
	$decline.stop()
	$accept.stop()
	$success.stop()
	$cash.stop()
	$low_time.stop()

func _physics_process(delta):
	if game_over:
		stop_sounds()
		return
	if cash < 0:
		$Control/show_money.set("custom_colors/default_color", Color(.84, .11, .11))
	else:
		$Control/show_money.set("custom_colors/default_color", Color(.98, .98, .98))
	var towing = get_owner().get_node("player").towing
	$Control/show_money.text = " " + str(cash)
	
	if Input.is_action_just_pressed("refuel") and not towing:
		handle_refuel()
	
	if objective_timer > 0:
		objective_timer -= delta
	
	if player_state != "available":
		if delivery_time > 0:
			delivery_time -= delta
			var mins = int(delivery_time / 60)
			var secs = str(int(delivery_time) % 60).pad_zeros(2)
			if (mins == 0 and int(secs) < 5):
				if not $low_time.playing:
					$low_time.play()
					$flash_timer.play("flash_delivery_time")
			$Control/show_timer.text = str(" ", mins, ":", secs)
		else:
			#fail delivery
			$decline.play()
			$Control/show_timer.hide()
			$Control/label_timer.hide()
			current_order_pay = 0
			
			$Control/label_pay.hide()
			$Control/label_money3.hide()
			$Control/show_pay.hide()
			$flash_timer.stop()
			$Control/show_timer.modulate = Color(1, 1, 1, 1)
			
			#fix status
			$Control/show_status_available.show()
			$Control/show_status_dispatched.hide()
			phone_state = "idle"
			player_state = "available"
			
			#move objective again
			objective.hide()
			position_objective(-1000, 300)
	
	
	match phone_state:
		"idle":
			notice_time -= delta
			if notice_time <= 0:
				start_notification()
		"buzzing":
			if Input.is_action_just_pressed("check_notification") and !towing:
				phone_state = "changing_states"
				if $low_time.playing:
					$low_time.stop()
					$flash_timer.stop()
					$Control/show_accept.modulate = Color(1, 1, 1, 1)
				check_notification()
			if accept_time > 0:
				accept_time -= delta
				var secs = int(accept_time) % 60
				if secs < 5 and not $low_time.playing and not phone_state == "changing_states":
					$low_time.play()
					$flash_timer.play("flash_accept")
				$Control/show_accept.text = str(" ",secs).pad_zeros(2)
			else:
				$Control/label_accept.hide()
				$Control/show_accept.hide()
				$Control/Phone/slide_phone.stop()
				$vibration.stop()
				$decline.play()
				reset_phone()
				phone_state = "idle"
				notice_time = rand_range(3, 10)
				$flash_timer.stop()
		"checking":
			if Input.is_action_just_pressed("accept_order") and !towing:
				$Control/label_accept.hide()
				$Control/show_accept.hide()
				$accept.play()
				if $low_time.playing:
					$low_time.stop()
					$flash_timer.stop()
					$Control/show_accept.modulate = Color(1, 1, 1, 1)
				phone_state = "changing_states"
				accept_order()
			if Input.is_action_just_pressed("decline_order") and !towing:
				#if not $fader.is_playing():
				if not $decline.playing:
					$decline.play()
				$low_time.stop()
				order_text.text = "Declined!"
				$Control/label_accept.hide()
				$Control/show_accept.hide()
				$flash_timer.stop()
				$flash_timer.seek(0, true)
				#$Control/show_accept.modulate = Color(1, 1, 1, 1)
				phone_state = "changing_states"
				close_notification()
			if accept_time > 0:
				accept_time -= delta
				var secs = int(accept_time) % 60
				if secs < 5 and not $low_time.playing and not phone_state == "changing_states":
					$low_time.play()
					$flash_timer.play("flash_accept")
				$Control/show_accept.text = str(" ",secs).pad_zeros(2)
			else:
				if not $fader.is_playing():
					if not $decline.playing:
						$decline.play()
					order_text.text = "Time Out!"
					$Control/label_accept.hide()
					$Control/show_accept.hide()
					phone_state = "changing_states"
					$flash_timer.stop()
					$Control/show_accept.modulate = Color(1, 1, 1, 1)
					close_notification()
		"accepted", "changing_states":
			pass


func accept_order():
	order_text.text = "Accepted!"
	close_notification()
	player_state = "pickup"
	$Control/show_status_available.hide()
	$Control/show_status_dispatched.show()
	
	$Control/label_timer.show()
	$Control/show_timer.show()
	
	$Control/label_pay.show()
	$Control/label_money3.show()
	$Control/show_pay.text = str(" ",current_order_pay)
	$Control/show_pay.show()
	
	
	#position target where it goes
	match order[0]:
		"borger":
			position_objective(-293, 360)
			delivery_time = 90
		"pizza":
			position_objective(-596, 150)
			delivery_time = 90
		"italian":
			position_objective(-400, -154)
			delivery_time = 90
		"icecream":
			position_objective(-593, -342)
			delivery_time = 120
	objective.show()
	yield($Control/Phone/slide_phone, "animation_finished")
	phone_state = "accepted"


func position_objective(x, z):
	objective.global_transform.origin = Vector3(x, -3.24, z)


func get_random_order():
	var order_idx = randi() % orders.size()
	order = orders[order_idx]
	order_text.text = order[2]
	var fee = order[1]
	var tip = randi() % int(fee * 0.30)
	current_order_pay = fee + tip
	order_text.text += "\nFee: $ " + str(fee)
	order_text.text += "\nTip: $ " + str(tip)

func get_random_dest():
	var dest_idx = randi() % dests.size()
	var dest = dests[dest_idx]
	position_objective(dest.x, dest.y)


func reset_phone():
	$Control/Phone.position = Vector2(938, 675)
	$Control/Phone.rotation_degrees = 0


func start_notification():
	get_random_order()
	phone_state = "buzzing"
	$vibration.play()
	accept_time = 15
	$Control/label_accept.rect_position.y = 510
	$Control/show_accept.rect_position.y = 510
	$Control/label_accept.show()
	$Control/show_accept.show()
	$Control/Phone/slide_phone.current_animation = "order_notification"


func check_notification():
	$vibration.stop()
	$Control/label_accept.hide()
	$Control/show_accept.hide()
	reset_phone()
	$Control/Phone/slide_phone.current_animation = "slide_phone_up"
	yield($Control/Phone/slide_phone, "animation_finished")
	phone_state = "checking"
	$Control/label_accept.rect_position.y = 310
	$Control/show_accept.rect_position.y = 310
	$Control/label_accept.show()
	$Control/show_accept.show()
	accept_time = 15


func close_notification():
	$Control/Phone/slide_phone.current_animation = "slide_phone_down"
	yield($Control/Phone/slide_phone, "animation_finished")
	phone_state = "idle"
	notice_time = rand_range(3, 10)


func _on_player_objective_reached():
	if not $success.playing:
		$success.play()
	if objective_timer > 0:
		return
	
	objective_timer = 0.1
	
	#picked up item, set destination
	if player_state == "pickup":
		get_random_dest()
		$label_unstuck.bbcode_text = str("[center]Order picked up, head to the drop off![/center]")
		if not $flash_unstuck.is_playing():
			$flash_unstuck.play("flash_unstuck")
		player_state = "delivery"
		return
	
	#otherwise we delivered
	player_state = "available"
	
	#move objective off the map
	objective.hide()
	position_objective(-1000, 300)
	
	#stop rogue sounds
	$low_time.stop()
	
	#get paid
	tow_fee(current_order_pay)
	cash += current_order_pay
	$Control/show_money.text = " " + str(cash)
	
	#win condition
	if cash >= 500:
		get_owner().get_node("player").do_game_over()
		$game_over/you_win.show()
		$game_over.show()
		game_over = true
	
	#fix status
	$Control/show_status_available.show()
	$Control/show_status_dispatched.hide()
	phone_state = "idle"
	
	#hide timer
	$Control/show_timer.hide()
	$Control/label_timer.hide()
	$flash_timer.stop()
	$Control/show_timer.modulate = Color(1, 1, 1, 1)
	
	#hide pay
	$Control/label_pay.hide()
	$Control/show_pay.hide()
	$Control/label_money3.hide()


func _on_player_use_fuel():
	var gas = $Control/show_fuel.value
	gas -= 0.003
	if gas < 10 and not $flash_fuel.is_playing():
		$flash_fuel.play("flash_fuel")
	if gas <= 0:
		get_owner().get_node("player").do_game_over()
		$game_over/no_fuel.show()
		$game_over.show()
		$too_bad.play()
		game_over = true
		
	$Control/show_fuel.value = gas
	refuel_cost = int((100 - gas) * .75)
	$Control/show_refuel.text = str(" ", refuel_cost)

func _on_restart_game_pressed():
	$mouse_select.play()


func _on_restart_game_mouse_entered():
	$mouse_over.play()


func _on_mouse_select_finished():
	if not get_tree().reload_current_scene() == OK:
		print("An error occurred when reloading the scene!")
