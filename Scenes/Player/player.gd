extends CharacterBody3D


const WALK_SPEED = 3.0
const SPRINT_SPEED = 5.0
const JUMP_VELOCITY = 5.0
const SENSITIVITY = 0.001
const HIT_STAGGER = 8.0

var gravity = 9.8
var t_bob = 0.0
var speed = 5.0
var ammo_reserve = 35
var ammo_in_gun = 7

signal player_hit
signal player_ready

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var raycast = $Head/RayCast3D
@onready var gun_anim = $Head/Camera3D/Gun.get_child(0).get_child(1)

@export var look_down_limit = -40
@export var look_up_limit = 60
@export var bob_frequency = 2.0
@export var bob_amplitude = 0.08
@export var base_fov = 75.0
@export var fov_change = 1.5
@export var ray_length = 10.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$Body.visible = false
	emit_signal("player_ready", self)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		raycast.rotate_y(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(look_down_limit), deg_to_rad(look_up_limit))

func _physics_process(delta):
	if Input.is_action_just_pressed("shoot"):
		shoot()
	
	if Input.is_action_just_pressed("action"):
		buy()
	
	if Input.is_action_just_pressed("reload"):
		reload()
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
		
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = headbob(t_bob)
	
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = base_fov + fov_change * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()

func _process(_delta):
	if raycast.is_colliding():
		var colliding_object = raycast.get_collider()
		if colliding_object.has_method("show_price"):
			colliding_object.show_price()

func headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_frequency) * bob_amplitude
	pos.x = sin(time * bob_frequency / 2) * bob_amplitude
	return pos

func hit(dir):
	emit_signal("player_hit")
	velocity.x += dir.x * HIT_STAGGER
	velocity.z += dir.z * HIT_STAGGER

func shoot():
	if ammo_in_gun > 0:
		if !gun_anim.is_playing():
			gun_anim.play("Shoot")

func buy():
	pass

func reload():
	if !gun_anim.is_playing():
		if ammo_in_gun > 0:
			gun_anim.play("Reload Not Empty")
		else:
			gun_anim.play("Reload")
