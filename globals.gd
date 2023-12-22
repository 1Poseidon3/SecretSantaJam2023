extends Node

#region Global Variables
var player_health : int = 100
var max_player_health : int = 100
var max_sprint_speed : float = 5.0
var points : int = 0
var score : int = 0
var m1911_ammo_in_gun : int = 7
var m1911_ammo_in_reserve : int = 56
var rifle_ammo_in_gun : int = 20
var rifle_ammo_in_reserve : int = 100
var shotgun_ammo_in_gun : int = 6
var shotgun_ammo_in_reserve : int = 48
#endregion

func _process(_delta):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
