extends CanvasLayer

onready var fader = $fader

var next_scene = ""

func _ready():
	fade_in()


func _physics_process(delta):
	$"credits so far".bbcode_text += "\n"


func fade_out(scene):
	next_scene = scene
	$fader.play("fade")


func fade_in():
	$fader.play_backwards("fade")


func _on_fader_animation_finished(_anim_name):
	if next_scene == "exit":
		get_tree().quit()
		return
	if not next_scene == "":
		if get_tree().change_scene(next_scene) != OK:
			print("An error occured when trying to switch scenes")


func _on_tutorial_pressed():
	$mouse_select.play()
	yield($mouse_select,"finished")
	fade_out("res://scenes/main_menu/startmenu.tscn")


func _on_startgame_pressed():
	$mouse_select.play()
	yield($mouse_select,"finished")
	fade_out("exit")


func _on_tutorial_mouse_entered():
	$mouse_over.play()


func _on_startgame_mouse_entered():
	$mouse_over.play()


func _on_GodotLink_pressed():
	OS.shell_open("https://godotengine.org")


func _on_AudacityLink_pressed():
	OS.shell_open("https://www.audacityteam.org")


func _on_KenneyLink_pressed():
	OS.shell_open("https://www.kenney.nl")

func _on_NafLink_pressed():
	OS.shell_open("https://nafgames.itch.io")


func _on_YuiLink_pressed():
	OS.shell_open("https://godotshaders.com/author/arlez80")


func _on_PerfLink_pressed():
	OS.shell_open("https://www.youtube.com/@PerfectioNH_")


func _on_SrcLink_pressed():
	OS.shell_open("https://www.youtube.com/@SRCoder")


func _on_SavinoLink_pressed():
	OS.shell_open("https://opengameart.org/users/savino")


func _on_PixabayLink_pressed():
	OS.shell_open("https://pixabay.com")


func _on_AnnieLink_pressed():
	OS.shell_open("https://ldjam.com/users/annearkey")


func _on_RubixLink_pressed():
	OS.shell_open("https://ldjam.com/users/rubixnoob13")
