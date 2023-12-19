extends Node

var player_health : int = 100
var m1911_ammo_in_gun : int = 7
var m1911_ammo_in_reserve : int = 35

func _process(_delta):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
