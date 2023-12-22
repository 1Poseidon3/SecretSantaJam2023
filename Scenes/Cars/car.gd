extends StaticBody3D

var num_times_played : int = 0
var price : int = 10000
var bought : bool = false

@onready var price_tag1 : Label3D = $Label3D
@onready var price_tag2 : Label3D = $Label3D2
@onready var audio_player : AudioStreamPlayer3D = $AudioStreamPlayer3D

func _process(_delta):
	if bought:
		end()
		bought = false

func show_price():
	price_tag1.visible = true
	price_tag2.visible = true
	$PriceTextDisappear.start()

func end():
	audio_player.play()
	var tween = get_tree().create_tween()
	tween.tween_property(self.get_parent().get_child(7).get_child(3).get_child(6), "color", Color(0, 0, 0, 1), 5)

func _on_price_text_disappear_timeout():
	price_tag1.visible = false
	price_tag2.visible = false

func _on_audio_stream_player_3d_finished():
	if num_times_played == 0:
		audio_player.stream = preload("res://Assets/Cars/Sound effects/Car_Door_Close.ogg")
		audio_player.play()
	elif num_times_played == 1:
		audio_player.stream = preload("res://Assets/Cars/Sound effects/Car2_Engine_Start_Up.ogg")
		audio_player.play()
	elif num_times_played == 2:
		audio_player.stream = preload("res://Assets/Cars/Sound effects/Car2_Engine_Loop.ogg")
		audio_player.play()
	else:
		get_tree().quit()
	num_times_played += 1
