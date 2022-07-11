extends StaticBody2D

var is_gathering = false
var mineral_count = 50
var growth_stage = 0

func _ready():
	Events.connect("drone_harvesting", self, "_on_drone_harvesting")
	Events.connect("drone_finished", self, "_on_drone_finished")
	Events.connect("drone_gather_from", self, "_on_drone_gather_from")

var grow_time = 0
var drone_harvesting = false

func _on_drone_gather_from(msg, drone):
	if msg != name: return
	mineral_count = clamp(mineral_count-5, 0, 1500)
	Events.emit_signal("crystal_send_minerals", mineral_count, name, drone)


func _on_drone_harvesting(msg):
	if msg != name: return
	drone_harvesting = true
	$Sprite.animation = "gather"

func _on_drone_finished(msg):
	if msg != name: return
	drone_harvesting = false
	$Sprite.animation = "default"

func _physics_process(delta):
	grow_time += delta
	if grow_time > 1 and !drone_harvesting:
		mineral_count = min(mineral_count + 5, 1500)
		grow_time = 0
	
	#set the frame
	$Sprite.frame = growth_stage
	#update the growth stage if needed
	if mineral_count > 1125:
		growth_stage = 4
		return
	if mineral_count > 750:
		growth_stage = 3
		return
	if mineral_count > 375:
		growth_stage = 2
		return
	if mineral_count > 0:
		growth_stage = 1
		return
	growth_stage = 0
