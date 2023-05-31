extends CanvasLayer

onready var fader = $fader

var next_scene = ""

func _ready():
	fade_in()


func fade_out(scene):
	next_scene = scene
	$fader.play("fade")


func fade_in():
	$fader.play_backwards("fade")


func _on_startmenu_pressed():
	$mouse_select.play()
	yield($mouse_select,"finished")
	fade_out("res://scenes/main_menu/startmenu.tscn")


func _on_controls_pressed():
	$mouse_select.play()
	yield($mouse_select,"finished")
	fade_out("res://scenes/main_menu/controls.tscn")



func _on_fader_animation_finished(_anim_name):
	if next_scene == "exit":
		get_tree().quit()
		return
	if not next_scene == "":
		if get_tree().change_scene(next_scene) != OK:
			print("An error occured when trying to switch scenes")


func _on_controls_mouse_entered():
	$mouse_over.play()


func _on_startmenu_mouse_entered():
	$mouse_over.play()
