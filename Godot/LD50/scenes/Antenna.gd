extends StaticBody2D

var health = 0

var emit_time = 0
func _process(delta):
	if health < 10: return
	
	$Sprite.frame = 1
	
	#it's fixed, emit a signal
	emit_time += delta
	if emit_time > 1:
		Events.emit_signal("send_comms")
		emit_time = 0
