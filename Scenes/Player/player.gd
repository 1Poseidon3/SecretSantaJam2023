extends CharacterBody3D


const WALK_SPEED : float = 3.0
const SPRINT_SPEED : float = 5.0
const JUMP_VELOCITY : float = 5.0
const SENSITIVITY : float = 0.001
const HIT_STAGGER : float = 8.0

var gravity : float = 9.8
var t_bob : float = 0.0
var speed : float = 5.0
var current_ammo_in_gun : int = 0
var current_ammo_in_reserve : int = 0
var empty : bool = false

signal player_hit
signal player_healed
signal player_ready

@onready var head : Node3D = $Head
@onready var camera : Camera3D = $Head/Camera3D
@onready var raycast : RayCast3D = $Head/RayCast3D
@onready var gun_anim : AnimationPlayer = $Head/Camera3D/Gun.get_child(0).get_child(1)
@onready var ammo_HUD : RichTextLabel = $HUD/Ammo
@onready var health_HUD : RichTextLabel = $HUD/Health
@onready var empty_click_timer : Timer = $Timers/EmptyClickTimer
@onready var start_health_regen_timer : Timer = $Timers/StartHealthRegenTimer
@onready var health_regen_tick_timer : Timer = $Timers/HealthRegenTickTimer

@export var look_down_limit : int = -40
@export var look_up_limit : int = 60
@export var bob_frequency : float = 2.0
@export var bob_amplitude : float = 0.08
@export var base_fov : float = 75.0
@export var fov_change : float = 1.5
@export var ray_length : float = 10.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$Body.visible = false
	current_ammo_in_gun = Globals.m1911_ammo_in_gun
	current_ammo_in_reserve = Globals.m1911_ammo_in_reserve
	gun_anim.play("Regular")
	emit_signal("player_ready", self)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		raycast.rotate_y(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(look_down_limit), deg_to_rad(look_up_limit))

func _physics_process(delta):
	if Input.is_action_pressed("shoot"):
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
	health_HUD.text = str(Globals.player_health) + "%"
	ammo_HUD.text = str(current_ammo_in_gun) + "/" + str(current_ammo_in_reserve)
	if Globals.m1911_ammo_in_gun <= 0 and empty and empty_click_timer.is_stopped() and !gun_anim.is_playing():
		#gun_anim.play("Empty")
		empty = false
		empty_click_timer.start()
	if Globals.player_health > 100:
		Globals.player_health = 100

func headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_frequency) * bob_amplitude
	pos.x = sin(time * bob_frequency / 2) * bob_amplitude
	return pos

func hit(dir):
	emit_signal("player_hit")
	velocity.x += dir.x * HIT_STAGGER
	velocity.z += dir.z * HIT_STAGGER
	Globals.player_health -= 25
	start_health_regen_timer.start()

func shoot():
	if !gun_anim.is_playing():
		if Globals.m1911_ammo_in_gun > 0:
			if Globals.m1911_ammo_in_gun - 1 == 0:
				gun_anim.play("Shoot To Empty")
			else:
				gun_anim.play("Shoot")
			Globals.m1911_ammo_in_gun -= 1
		if Globals.m1911_ammo_in_gun <= 0:
			empty = true
	current_ammo_in_gun = Globals.m1911_ammo_in_gun

func buy():
	pass

func reload():
	if !gun_anim.is_playing():
		if Globals.m1911_ammo_in_gun > 0 and Globals.m1911_ammo_in_gun < 7:
			gun_anim.play("Reload Not Empty")
		elif Globals.m1911_ammo_in_gun == 0:
			gun_anim.play("Reload")
		var ammo_to_remove_from_reserve : int = 7 - Globals.m1911_ammo_in_gun
		if Globals.m1911_ammo_in_reserve - ammo_to_remove_from_reserve < 0:
			Globals.m1911_ammo_in_gun = Globals.m1911_ammo_in_reserve
			Globals.m1911_ammo_in_reserve = 0
		else:
			Globals.m1911_ammo_in_gun = 7
			Globals.m1911_ammo_in_reserve -= ammo_to_remove_from_reserve
	current_ammo_in_gun = Globals.m1911_ammo_in_gun
	current_ammo_in_reserve = Globals.m1911_ammo_in_reserve
	empty = false


func _on_health_regen_tick_timer_timeout():
	Globals.player_health += 10
	emit_signal("player_healed")
	health_regen_tick_timer.start()


func _on_start_health_regen_timer_timeout():
	if Globals.player_health < 100:
		Globals.player_health += 10
		emit_signal("player_healed")
		health_regen_tick_timer.start()
