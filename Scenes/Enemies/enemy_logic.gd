extends CharacterBody3D

var player = null
var state_machine
var runner : bool = false;
var health : int = 100
var speed : float = 1.0
var dead : bool = false

const ATTACK_RANGE : float = 1.5
const ATTACK_ANIM_SPEED : float = 1.0
const WALK_ANIM_SPEED : float = 1.0

@onready var player_path := get_tree().get_first_node_in_group("Player")
@onready var nav_agent : NavigationAgent3D = $NavigationAgent3D
@onready var anim_tree : AnimationTree = $AnimationTree
@onready var anim_player : AnimationPlayer = $AnimationPlayer

func _ready():
	player = player_path
	state_machine = anim_tree.get("parameters/playback")
	var tween = get_tree().create_tween()
	tween.tween_property($".", "position:y", 1.0, 1.5)

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
			"Attack":
				look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
				anim_tree.advance(delta * ATTACK_ANIM_SPEED)
			
		anim_tree.set("parameters/conditions/attack", _target_in_range())
		anim_tree.set("parameters/conditions/run", !_target_in_range())
		move_and_slide()
	else:
		if !anim_player.is_playing():
			var tween2 = get_tree().create_tween()
			tween2.tween_property($".", "position:y", -3, 10)
			if !tween2.is_running():
				self.queue_free()

func _target_in_range():
	return global_position.distance_to(player.global_position) < ATTACK_RANGE
	
func _hit_finished():
	if global_position.distance_to(player.global_position) < ATTACK_RANGE + 1.0:
		var dir = global_position.direction_to(player.global_position)
		player.hit(dir)

func hit():
	health -= 35
	if health <= 0:
		speed = 0.0
		anim_tree.active = false
		if randi() % 2 == 0:
			anim_player.play("Armature|Armature_006|mixamo_com|Layer0")
		else:
			anim_player.play("Armature|Armature_007|mixamo_com|Layer0")
		dead = true
		Globals.points += 100
		Globals.score += 100
