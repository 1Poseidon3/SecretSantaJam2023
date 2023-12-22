extends CharacterBody3D

#region Variables
var player = null
var state_machine
var runner : bool = false;
var health : int = 100
var speed : float = 1.0
var dead : bool = false
var zombie_sounds = [preload("res://Assets/Sounds/zombienoise1.wav"), preload("res://Assets/Sounds/zombienoise2.wav"), preload("res://Assets/Sounds/zombienoise3.wav"), preload("res://Assets/Sounds/zombienoise4.wav"), preload("res://Assets/Sounds/zombienoise5.wav"), preload("res://Assets/Sounds/zombienoise6.wav"), preload("res://Assets/Sounds/zombienoise7.wav"), preload("res://Assets/Sounds/zombienoise8.wav"), preload("res://Assets/Sounds/zombienoise9.wav"), preload("res://Assets/Sounds/zombienoise10.wav"), preload("res://Assets/Sounds/zombienoise11.wav"), preload("res://Assets/Sounds/zombienoise12.wav"), preload("res://Assets/Sounds/zombienoise13.wav"), preload("res://Assets/Sounds/zombienoise14.wav"), preload("res://Assets/Sounds/zombienoise15.wav"), preload("res://Assets/Sounds/zombienoise16.wav"), preload("res://Assets/Sounds/zombienoise17.wav"), preload("res://Assets/Sounds/zombienoise18.wav"), preload("res://Assets/Sounds/zombienoise19.wav"), preload("res://Assets/Sounds/zombienoise20.wav"), preload("res://Assets/Sounds/zombienoise21.wav"), preload("res://Assets/Sounds/zombienoise22.wav"), preload("res://Assets/Sounds/zombienoise23.wav"), preload("res://Assets/Sounds/zombienoise24.wav"), preload("res://Assets/Sounds/zombienoise25.wav"), preload("res://Assets/Sounds/zombienoise26.wav"), preload("res://Assets/Sounds/zombienoise27.wav"), preload("res://Assets/Sounds/zombienoise28.wav"), preload("res://Assets/Sounds/zombienoise29.wav"), preload("res://Assets/Sounds/zombienoise30.wav")]
#endregion

#region Constants
const RUN_SPEED = 4.5
const ATTACK_RANGE : float = 1.5
const ATTACK_ANIM_SPEED : float = 1.0
const WALK_ANIM_SPEED : float = 1.0
#endregion

#region On Ready Variables
@onready var player_path := get_tree().get_first_node_in_group("Player")
@onready var nav_agent : NavigationAgent3D = $NavigationAgent3D
@onready var anim_tree : AnimationTree = $AnimationTree
@onready var anim_player : AnimationPlayer = $AnimationPlayer
@onready var zombie_noise_timer : Timer = $ZombieNoiseTimer
@onready var sound_player : AudioStreamPlayer3D = $ZombieSoundPlayer
@onready var collider : CollisionShape3D = $RootNode/CollisionShape3D
#endregion

func _ready():
	#region Decide if the zombie is a runner or not
	if randi() % 4 == 0:
		runner = true
		speed = RUN_SPEED
		anim_tree.set("parameters/conditions/startrun", true)
	else:
		anim_tree.set("parameters/conditions/startwalk", true)
	#endregion
	player = player_path
	state_machine = anim_tree.get("parameters/playback")
	#region Zombie rises up from the ground
	var tween = get_tree().create_tween()
	tween.tween_property($".", "position:y", 1.0, 1.5)
	#endregion

func _physics_process(delta):
	if !dead:
		velocity = Vector3.ZERO
		match state_machine.get_current_node():
			"Walk":
				nav_agent.set_target_position(player.global_transform.origin)
				var next_nav_point = nav_agent.get_next_path_position()
				velocity = (next_nav_point - global_transform.origin).normalized() * speed
				look_at(Vector3(global_position.x + velocity.x, global_position.y, global_position.z + velocity.z), Vector3.UP)
				anim_tree.advance(delta * 1)
			"Run":
				nav_agent.set_target_position(player.global_transform.origin)
				var next_nav_point = nav_agent.get_next_path_position()
				velocity = (next_nav_point - global_transform.origin).normalized() * speed
				look_at(Vector3(global_position.x + velocity.x, global_position.y, global_position.z + velocity.z), Vector3.UP)
				anim_tree.advance(delta * 1)
			"Attack":
				look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
				anim_tree.advance(delta * ATTACK_ANIM_SPEED)
			
		anim_tree.set("parameters/conditions/attack", _target_in_range())
		if runner:
			anim_tree.set("parameters/conditions/run", !_target_in_range())
		else:
			anim_tree.set("parameters/conditions/walk", !_target_in_range())
		move_and_slide()
	else:
		if !anim_player.is_playing():
			var tween2 = get_tree().create_tween()
			tween2.tween_property($".", "position:y", -3, 10)
			if !tween2.is_running():
				self.queue_free()

func _process(_delta):
	if Globals.player_health <= 0:
		nav_agent.navigation_layers = 0x00000000
		anim_tree.active = false
		if !anim_player.is_playing():
			anim_player.play("Armature|Armature_008|mixamo_com|Layer0")

func _target_in_range():
	return global_position.distance_to(player.global_position) < ATTACK_RANGE
	
func _hit_finished():
	if global_position.distance_to(player.global_position) < ATTACK_RANGE + 1.0:
		var dir = global_position.direction_to(player.global_position)
		player.hit(dir)

func hit(gun: int):
	if gun == 0:
		health -= 25
	elif gun == 1:
		health -= 50
	else:
		health -= 100
	sound_player.stream = preload("res://Assets/Sounds/bulletimpact.wav")
	sound_player.play()
	if health <= 0:
		collider.disabled = true
		speed = 0.0
		anim_tree.active = false
		if randi() % 2 == 0:
			anim_player.play("Armature|Armature_006|mixamo_com|Layer0")
		else:
			anim_player.play("Armature|Armature_007|mixamo_com|Layer0")
		dead = true
		Globals.points += 100
		Globals.score += 100


func _on_zombie_noise_timer_timeout():
	if !sound_player.playing:
		var i = randi() % 30
		sound_player.stream = zombie_sounds[i]
		sound_player.play()
