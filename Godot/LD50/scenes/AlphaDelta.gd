extends Node2D

var alpha_online = false
var delta_online = false

# Called when the node enters the scene tree for the first time.
func _ready():
	Events.connect("alpha_online", self, "_on_alpha_online")
	Events.connect("alpha_offline", self, "_on_alpha_offline")
	Events.connect("delta_online", self, "_on_delta_online")
	Events.connect("delta_offline", self, "_on_delta_offline")


var alpha_timer = 0
var delta_timer = 0

var alpha_speed = .5
var delta_speed = .5

func _physics_process(delta):
	if alpha_online:
		alpha_timer += delta
		if alpha_timer > alpha_speed:
			alpha_timer = 0
			Events.emit_signal("keypress_a")
	if delta_online:
		delta_timer += delta
		if delta_timer > delta_speed:
			delta_timer = 0
			Events.emit_signal("keypress_d")


func _on_alpha_online():
	$Alpha.play()
	$DynaStatus.bbcode_text = "[color=green]dyna"
	alpha_online = true

func _on_alpha_offline():
	$Alpha.stop()
	$DynaStatus.bbcode_text = "[color=red]dyna"
	alpha_online = false

func _on_delta_online():
	$Delta.play()
	$MoStatus.bbcode_text = "[color=green]mo"
	delta_online = true

func _on_delta_offline():
	$Delta.stop()
	$MoStatus.bbcode_text = "[color=red]mo"
	delta_online = false
