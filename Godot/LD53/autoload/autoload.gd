extends Node

var track_index = 0
var track_list = [
	"res://music/Punk_Sitcom_Intro_1.mp3",
	"res://music/Separate_the_Ones.mp3",
	"res://music/eyesplit.mp3",
	"res://music/Academic_Exodus.mp3"
	]

var tracks = []

var pretty_names = [
	"          Music: Punk Sitcom Intro 1 by TeknoAXE - http://teknoaxe.com/Home.php",
	"          Music: Separate the Ones by TeknoAXE - http://teknoaxe.com/Home.php",
	"          Music: Eyesplit by Shane Ivers - https://www.silvermansound.com",
	"          Music: Academic Exodus by TeknoAXE - http://teknoaxe.com/Home.php"
	]

onready var music_player
onready var music_info
var counter = 0
var display_pos = 0
var display_count = 30

func play_track(i):
	track_index = i % track_list.size()
	music_player.stream = tracks[track_index]
	music_player.play()


func _physics_process(delta):
	if not music_info:
		return
	
	#handle scrolling the text
	counter += delta
	if counter > .2:
		counter = 0
		var track_name = pretty_names[track_index]
		display_pos = (display_pos + 1) % track_name.length()
		music_info.text = track_name.substr(display_pos, display_count)
		if music_info.text.length() < display_count:
			music_info.text += track_name.substr(0, display_count-music_info.text.length())


func _ready():
	#load all the tracks
	for i in range(track_list.size()):
		tracks.append(load(track_list[i]))
	
	#create music player
	if not music_player:
		music_player = AudioStreamPlayer.new()
	music_player.volume_db = -30
	
	#connect the signal - OMG MAKE SURE TO NOT LOOP MP3/OGG or it will NOT work
	music_player.connect("finished", self, "_audio_finished")
	add_child(music_player)
	
	#play the first track
	play_track(0)
	
	#make scrolly music title visualizer
	var canvas = CanvasLayer.new()
	canvas.layer = 999
	music_info = RichTextLabel.new()
	music_info.rect_size = Vector2(450, 28)
	music_info.scroll_active = false
	#music_info.rect_clip_content = true
	music_info.rect_position = Vector2(20, 550)
	
	var font = DynamicFont.new()
	font.font_data = load("res://scenes/main_menu/DroidSans-Bold.ttf")
	font.size = 20
	font.outline_size = 1
	font.outline_color = Color(1,1,1, .5)
	
	music_info.set("custom_fonts/normal_font", font)
	music_info.set("custom_colors/default_color", Color(0, 0, 0, .5))
	
	canvas.add_child(music_info)
	add_child(canvas)


func _audio_finished():
	#play next track
	play_track(track_index+1)
