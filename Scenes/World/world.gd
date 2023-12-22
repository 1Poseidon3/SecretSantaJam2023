extends Node3D

#region Constants
const DEFAULT_PLAYER_HEALTH : int = 100
const DEFAULT_MAX_PLAYER_HEALTH : int = 100
const DEFAULT_MAX_SPRINT_SPEED : float = 5.0
const DEFAULT_POINTS : int = 0
const DEFAULT_SCORE : int = 0
const DEFAULT_M1911_AMMO_IN_GUN : int = 7
const DEFAULT_M1911_AMMO_IN_RESERVE : int = 56
const DEFAULT_RIFLE_AMMO_IN_GUN : int = 20
const DEFAULT_RIFLE_AMMO_IN_RESERVE : int = 100
const DEFAULT_SHOTGUN_AMMO_IN_GUN : int = 6
const DEFAULT_SHOTGUN_AMMO_IN_RESERVE : int = 48
#endregion

#region On Ready Variables
@onready var hit_feedback : ColorRect = $HitHealFeedback/HitFeedback
@onready var heal_feedback : ColorRect = $HitHealFeedback/HealFeedback
@onready var spawns : Node3D = $EnemySpawnPoints
@onready var nav_region : NavigationRegion3D = $NavigationRegion3D
@onready var player : CharacterBody3D = $Player
@onready var player_camera : Camera3D = $Player.get_child(2).get_child(0)
@onready var player_hud : Control = $Player.get_child(3)
@onready var rifle_pickup : Node3D = $Guns/Rifle
@onready var shotgun_pickup : Node3D = $Guns/Shotgun
@onready var rifle_pickup_sound : AudioStreamPlayer3D = $"Guns/Rifle/Rifle Pickup Sound Player"
@onready var shotgun_pickup_sound : AudioStreamPlayer3D = $"Guns/Shotgun/Shotgun Pickup Sound Player"
@onready var powerup1 : StaticBody3D = $"Powerups/Power Up 1 Cabin 1"
@onready var powerup2 : StaticBody3D = $"Powerups/Power Up 2 Cabin 1"
@onready var powerup3 : StaticBody3D = $"Powerups/Power Up 3 Cabin 1"
@onready var powerup4 : StaticBody3D = $"Powerups/Power Up 1 Cabin 2"
@onready var powerup5 : StaticBody3D = $"Powerups/Power Up 2 Cabin 2"
@onready var powerup6 : StaticBody3D = $"Powerups/Power Up 3 Cabin 2"
@onready var powerup7 : StaticBody3D = $"Powerups/Power Up 1 Cabin 3"
@onready var powerup8 : StaticBody3D = $"Powerups/Power Up 2 Cabin 3"
@onready var powerup9 : StaticBody3D = $"Powerups/Power Up 3 Cabin 3"
@onready var powerup10 : StaticBody3D = $"Powerups/Power Up 4 Cabin 1"
@onready var powerup11 : StaticBody3D = $"Powerups/Power Up 5 Cabin 1"
@onready var powerup12 : StaticBody3D = $"Powerups/Power Up 6 Cabin 1"
#endregion

#region Variables
var zombie = load("res://Scenes/Enemies/enemy_1.tscn")
var z_instance
var tween : Tween
#endregion

func _ready():
	randomize()
	Globals.player_health = DEFAULT_PLAYER_HEALTH
	Globals.max_player_health = DEFAULT_MAX_PLAYER_HEALTH
	Globals.max_sprint_speed = DEFAULT_MAX_SPRINT_SPEED
	Globals.points = DEFAULT_POINTS
	Globals.score = DEFAULT_SCORE
	Globals.m1911_ammo_in_gun = DEFAULT_M1911_AMMO_IN_GUN
	Globals.m1911_ammo_in_reserve = DEFAULT_M1911_AMMO_IN_RESERVE
	Globals.rifle_ammo_in_gun = DEFAULT_RIFLE_AMMO_IN_GUN
	Globals.rifle_ammo_in_reserve - DEFAULT_RIFLE_AMMO_IN_RESERVE
	Globals.shotgun_ammo_in_gun = DEFAULT_SHOTGUN_AMMO_IN_GUN
	Globals.shotgun_ammo_in_reserve = DEFAULT_SHOTGUN_AMMO_IN_RESERVE
	player_camera.rotation = Vector3(0.0, 0.0, 0.0)
	player.position.y = 2.0
	player.sensitivity = 0.001
	player_hud.get_child(0).visible = true
	player_hud.get_child(1).visible = true
	player_hud.get_child(2).visible = true
	player_hud.get_child(3).visible = false
	player_hud.get_child(4).visible = true
	player_hud.get_child(5).visible = true
	player_hud.get_child(6).color = Color(0, 0, 0, 0)
	tween = get_tree().create_tween().set_parallel(true)
	# Hacky solution. I tried everything to get the tweens to loop indefinitely
	# Spinning 10,000 times ought to do the trick (I hope)
	tween.tween_property(rifle_pickup, "rotation_degrees:y", 3600000, 70000)
	tween.tween_property(shotgun_pickup, "rotation_degrees:y", 3600000, 70000)
	tween.tween_property(powerup1, "rotation_degrees:y", 3600000, 70000)
	tween.tween_property(powerup2, "rotation_degrees:y", 3600000, 70000)
	tween.tween_property(powerup3, "rotation_degrees:y", 3600000, 70000)
	tween.tween_property(powerup4, "rotation_degrees:y", 3600000, 70000)
	tween.tween_property(powerup5, "rotation_degrees:y", 3600000, 70000)
	tween.tween_property(powerup6, "rotation_degrees:y", 3600000, 70000)
	tween.tween_property(powerup7, "rotation_degrees:y", 3600000, 70000)
	tween.tween_property(powerup8, "rotation_degrees:y", 3600000, 70000)
	tween.tween_property(powerup9, "rotation_degrees:y", 3600000, 70000)
	tween.tween_property(powerup10, "rotation_degrees:y", 3600000, 70000)
	tween.tween_property(powerup11, "rotation_degrees:y", 3600000, 70000)
	tween.tween_property(powerup12, "rotation_degrees:y", 3600000, 70000)

func _on_player_player_hit():
	hit_feedback.visible = true
	await get_tree().create_timer(0.2).timeout
	hit_feedback.visible = false

func _on_player_player_healed():
	heal_feedback.visible = true
	await get_tree().create_timer(0.2).timeout
	heal_feedback.visible = false

func _get_random_child(parent_node):
	var random_id = randi() % parent_node.get_child_count()
	return parent_node.get_child(random_id)

func _on_zombie_spawn_timer_timeout():
	var spawn_point = _get_random_child(spawns).global_position
	z_instance = zombie.instantiate()
	z_instance.position = spawn_point
	nav_region.add_child(z_instance)

func _on_player_restart_game():
	get_tree().reload_current_scene()

func _on_rifle_pickup_trigger_body_entered(body):
	body.rifle_unlocked = true
	rifle_pickup.visible = false
	rifle_pickup_sound.play()

func _on_shotgun_pickup_trigger_body_entered(body):
	body.shotgun_unlocked = true
	shotgun_pickup.visible = false
	shotgun_pickup_sound.play()

func _on_rifle_pickup_sound_player_finished():
	rifle_pickup.queue_free()

func _on_shotgun_pickup_sound_player_finished():
	shotgun_pickup.queue_free()
