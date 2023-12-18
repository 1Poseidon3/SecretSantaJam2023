extends Node3D

@onready var hit_feedback = $Control/HitFeedback
@onready var spawns = $EnemySpawnPoints
@onready var nav_region = $NavigationRegion3D

var zombie = load("res://Scenes/Enemies/enemy_1.tscn")
var z_instance

func _ready():
	randomize()

func _process(_delta):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()


func _on_player_player_hit():
	hit_feedback.visible = true
	await get_tree().create_timer(0.2).timeout
	hit_feedback.visible = false

func _get_random_child(parent_node):
	var random_id = randi() % parent_node.get_child_count()
	return parent_node.get_child(random_id)


func _on_zombie_spawn_timer_timeout():
	var spawn_point = _get_random_child(spawns).global_position
	z_instance = zombie.instantiate()
	z_instance.position = spawn_point
	nav_region.add_child(z_instance)
