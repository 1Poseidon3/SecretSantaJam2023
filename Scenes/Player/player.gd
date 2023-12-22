extends CharacterBody3D

#region Constants
const WALK_SPEED : float = 3.0
const SPRINT_SPEED : float = 5.0
const JUMP_VELOCITY : float = 5.0
const HIT_STAGGER : float = 8.0
#endregion

#region Variables
var sensitivity : float = 0.001
var gravity : float = 9.8
var t_bob : float = 0.0
var speed : float = 5.0
var current_ammo_in_gun : int = 0
var current_ammo_in_reserve : int = 0
var stamina : int = 100
var can_sprint : bool = true
var sprinting : bool = false
var current_gun : int = 0
var rifle_unlocked : bool = false
var shotgun_unlocked : bool = false
var switch_guns : bool = false
var switch_direction : bool = false
var current_gun_made_not_visible : bool = false
var shotgun_reload : bool = false
#endregion

#region Signals
signal player_hit
signal player_healed
signal player_ready
signal restart_game
#endregion

#region On Ready Variables
@onready var head : Node3D = $Head
@onready var camera : Camera3D = $Head/Camera3D
@onready var interact_raycast : RayCast3D = $Head/Camera3D/InteractRayCast
@onready var gun_anim : AnimationPlayer = $Head/Camera3D/Gun/M1911.get_child(1)
@onready var ammo_HUD : RichTextLabel = $HUD/Ammo
@onready var health_HUD : RichTextLabel = $HUD/Health
@onready var points_HUD : RichTextLabel = $HUD/Points
@onready var stamina_HUD : TextureProgressBar = $HUD/Stamina
@onready var start_health_regen_timer : Timer = $Timers/StartHealthRegenTimer
@onready var health_regen_tick_timer : Timer = $Timers/HealthRegenTickTimer
@onready var gun_click_timer : Timer = $Timers/GunClickTimer
@onready var stamina_recharge_timer : Timer = $Timers/StaminaRechargeTimer
@onready var lower_stamina_timer : Timer = $Timers/LowerStaminaTimer
@onready var footstep_timer : Timer = $Timers/FootstepTimer
@onready var game_restart_timer : Timer = $Timers/GameRestartTimer
@onready var gun_sounds : AudioStreamPlayer3D = $Head/Camera3D/Gun/M1911.get_child(2)
@onready var crosshair: TextureRect = $HUD/Crosshair
@onready var shoot_raycast : RayCast3D = $Head/Camera3D/HitscanShootRayCast
@onready var sound_player : AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var fade_out : ColorRect = $HUD/FadeOut
#endregion

#region Export Variables
@export var look_down_limit : int = -40
@export var look_up_limit : int = 60
@export var bob_frequency : float = 2.0
@export var bob_amplitude : float = 0.08
@export var base_fov : float = 75.0
@export var fov_change : float = 1.5
@export var ray_length : float = 10.0
#endregion

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$Body.visible = false
	current_ammo_in_gun = Globals.m1911_ammo_in_gun
	current_ammo_in_reserve = Globals.m1911_ammo_in_reserve
	gun_anim.play("Regular")
	crosshair.position.x = get_viewport().size.x / 2 - 32
	crosshair.position.y = get_viewport().size.y / 2 - 32
	emit_signal("player_ready", self)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * sensitivity)
		camera.rotate_x(-event.relative.y * sensitivity)
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
		
	if Input.is_action_pressed("sprint") and can_sprint:
		footstep_timer.wait_time = 0.3
		speed = SPRINT_SPEED
		stamina_recharge_timer.stop()
		sprinting = true
		if lower_stamina_timer.is_stopped():
			stamina -= 5
			lower_stamina_timer.start()
	else:
		speed = WALK_SPEED
	
	if Input.is_action_just_released("sprint"):
		sprinting = false
		footstep_timer.wait_time = 0.8
	
	if (Input.is_action_pressed("forward") or Input.is_action_pressed("backward") or Input.is_action_pressed("left") or Input.is_action_pressed("right")) and footstep_timer.is_stopped():
		sound_player.play()
		footstep_timer.start()
	
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
	#region Showing price ray cast
	if interact_raycast.is_colliding():
		var colliding_object = interact_raycast.get_collider()
		if colliding_object.has_method("show_price"):
			colliding_object.show_price()
	#endregion
	
	#region HUD
	health_HUD.text = str(Globals.player_health) + "%"
	ammo_HUD.text = str(current_ammo_in_gun) + "/" + str(current_ammo_in_reserve)
	points_HUD.text = str(Globals.points)
	#endregion
	
	#region Reset health if over 100
	if Globals.player_health > 100:
		Globals.player_health = 100
	#endregion
	
	#region Stamina
	stamina_HUD.value = stamina
	if stamina < 100 and lower_stamina_timer.is_stopped() and !sprinting:
		stamina += 5
		lower_stamina_timer.start()
	if stamina <= 0 and stamina_recharge_timer.is_stopped():
		stamina_recharge_timer.start()
		can_sprint = false
	#endregion
	
	#region Footsteps
	if !sound_player.playing:
		if randi() % 2 == 0:
			sound_player.stream = preload("res://Assets/Sounds/footstep1.wav")
		else:
			sound_player.stream = preload("res://Assets/Sounds/footstep2.wav")
	#endregion
	
	#region Death
	if Globals.player_health <= 0:
		if game_restart_timer.is_stopped():
			game_restart_timer.start()
		sensitivity = 0.0
		var tween = get_tree().create_tween()
		tween.set_parallel(true)
		tween.tween_property(camera, "rotation", Vector3(0.25, -0.25, 0.25), 0.25)
		tween.tween_property(camera, "position:y", -1.5, 0.25)
		tween.tween_property(fade_out, "color", Color(0, 0, 0, 1), 3)
		ammo_HUD.visible = false
		health_HUD.visible = false
		points_HUD.visible = false
		stamina_HUD.visible = false
		crosshair.visible = false
		health_regen_tick_timer.stop()
		start_health_regen_timer.stop()
		footstep_timer.stop()
	#endregion
	
	#region Switch guns
	if switch_guns:
		if !gun_anim.is_playing():
			if !current_gun_made_not_visible:
				$Head/Camera3D/Gun.get_child(current_gun).visible = false
				current_gun_made_not_visible = true
			if !switch_direction:
				current_gun += 1
				if current_gun == 1 and !rifle_unlocked:
					current_gun += 1
				if current_gun == 2 and !shotgun_unlocked:
					current_gun += 1
				if current_gun > 2:
					current_gun = 0
			else:
				current_gun -= 1
				if current_gun < 0:
					current_gun = 2
				if current_gun == 2 and !shotgun_unlocked:
					current_gun -= 1
				if current_gun == 1 and !rifle_unlocked:
					current_gun -= 1
			gun_anim = $Head/Camera3D/Gun.get_child(current_gun).get_child(1)
			$Head/Camera3D/Gun.get_child(current_gun).visible = true
			gun_anim.play("Switch On")
			if current_gun == 0:
				current_ammo_in_gun = Globals.m1911_ammo_in_gun
				current_ammo_in_reserve = Globals.m1911_ammo_in_reserve
			elif current_gun == 1:
				current_ammo_in_gun = Globals.rifle_ammo_in_gun
				current_ammo_in_reserve = Globals.rifle_ammo_in_reserve
			else:
				current_ammo_in_gun = Globals.shotgun_ammo_in_gun
				current_ammo_in_reserve = Globals.shotgun_ammo_in_reserve
			switch_guns = false
		
	if Input.is_action_just_pressed("ScrollDown"):
		gun_anim = $Head/Camera3D/Gun.get_child(current_gun).get_child(1)
		gun_anim.play("Switch Off")
		switch_direction = false
		switch_guns = true
		current_gun_made_not_visible = false
		
	
	if Input.is_action_just_pressed("ScrollUp"):
		gun_anim = $Head/Camera3D/Gun.get_child(current_gun).get_child(1)
		gun_anim.play("Switch Off")
		switch_direction = true
		switch_guns = true
		current_gun_made_not_visible = false
	#endregion
	
	#region Shotgun reload loop
	if shotgun_reload and !gun_anim.is_playing():
		gun_anim.play("Reload Start")
		if Globals.shotgun_ammo_in_gun < 6 and Globals.shotgun_ammo_in_reserve > 0:
			gun_anim.play("Shell In")
			Globals.shotgun_ammo_in_gun += 1
			Globals.shotgun_ammo_in_reserve -= 1
		if (Globals.shotgun_ammo_in_gun == 6 or Globals.shotgun_ammo_in_reserve == 0):
			gun_anim.play("Reload End")
			shotgun_reload = false
		current_ammo_in_gun = Globals.shotgun_ammo_in_gun
		current_ammo_in_reserve = Globals.shotgun_ammo_in_reserve
	#endregion

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
		#region Shoot M1911
		if current_gun == 0:
			if Globals.m1911_ammo_in_gun > 0:
				if Globals.m1911_ammo_in_gun - 1 == 0:
					gun_anim.play("Shoot To Empty")
				else:
					gun_anim.play("Shoot")
				Globals.m1911_ammo_in_gun -= 1
				if shoot_raycast.is_colliding():
					if shoot_raycast.get_collider().get_parent().is_in_group("Enemy"):
						if shoot_raycast.get_collider().get_parent().has_method("hit"):
							shoot_raycast.get_collider().get_parent().hit(0)
			else:
				if !gun_sounds.is_playing() and gun_click_timer.is_stopped():
					gun_sounds.stream = preload("res://Assets/Sounds/GunEmptyClick.wav")
					gun_sounds.play()
					gun_click_timer.start()
			current_ammo_in_gun = Globals.m1911_ammo_in_gun
		#endregion
		#region Shoot rifle
		elif current_gun == 1:
			if Globals.rifle_ammo_in_gun > 0:
				if Globals.rifle_ammo_in_gun - 1 == 0:
					gun_anim.play("Shoot To Empty")
				else:
					gun_anim.play("Shoot")
				Globals.rifle_ammo_in_gun -= 1
				if shoot_raycast.is_colliding():
					if shoot_raycast.get_collider().get_parent().is_in_group("Enemy"):
						if shoot_raycast.get_collider().get_parent().has_method("hit"):
							shoot_raycast.get_collider().get_parent().hit(1)
			else:
				if !gun_sounds.is_playing() and gun_click_timer.is_stopped():
					gun_sounds.stream = preload("res://Assets/Sounds/GunEmptyClick.wav")
					gun_sounds.play()
					gun_click_timer.start()
			current_ammo_in_gun = Globals.rifle_ammo_in_gun
		#endregion
		#region Shoot shotgun
		else:
			if Globals.shotgun_ammo_in_gun > 0:
				gun_anim.play("Shoot")
				Globals.shotgun_ammo_in_gun -= 1
				if shoot_raycast.is_colliding():
					if shoot_raycast.get_collider().get_parent().is_in_group("Enemy"):
						if shoot_raycast.get_collider().get_parent().has_method("hit"):
							shoot_raycast.get_collider().get_parent().hit(2)
			else:
				if !gun_sounds.is_playing() and gun_click_timer.is_stopped():
					gun_sounds.stream = preload("res://Assets/Sounds/GunEmptyClick.wav")
					gun_sounds.play()
					gun_click_timer.start()
			current_ammo_in_gun = Globals.shotgun_ammo_in_gun
		#endregion

func buy():
	if interact_raycast.is_colliding():
		var colliding_object = interact_raycast.get_collider()
		if colliding_object.is_in_group("Door"):
			if Globals.points >= colliding_object.price:
				Globals.points -= colliding_object.price
				colliding_object.bought = true

func reload():
	if !gun_anim.is_playing():
		#region M1911 reload
		if current_gun == 0:
			if Globals.m1911_ammo_in_gun > 0 and Globals.m1911_ammo_in_gun < 7:
				gun_anim.play("Reload Not Empty")
			elif Globals.m1911_ammo_in_gun == 0:
				gun_anim.play("Reload")
			var m1911_ammo_to_remove_from_reserve : int = 7 - Globals.m1911_ammo_in_gun
			if Globals.m1911_ammo_in_reserve - m1911_ammo_to_remove_from_reserve < 0:
				Globals.m1911_ammo_in_gun = Globals.m1911_ammo_in_reserve
				Globals.m1911_ammo_in_reserve = 0
			else:
				Globals.m1911_ammo_in_gun = 7
				Globals.m1911_ammo_in_reserve -= m1911_ammo_to_remove_from_reserve
			current_ammo_in_gun = Globals.m1911_ammo_in_gun
			current_ammo_in_reserve = Globals.m1911_ammo_in_reserve
		#endregion
		#region Rifle reload
		elif current_gun == 1:
			if Globals.rifle_ammo_in_gun > 0 and Globals.rifle_ammo_in_gun < 20:
				gun_anim.play("Reload Not Empty")
			elif Globals.rifle_ammo_in_gun == 0:
				gun_anim.play("Reload")
			var rifle_ammo_to_remove_from_reserve : int = 20 - Globals.rifle_ammo_in_gun
			if Globals.rifle_ammo_in_reserve - rifle_ammo_to_remove_from_reserve < 0:
				Globals.rifle_ammo_in_gun = Globals.rifle_ammo_in_reserve
				Globals.rifle_ammo_in_reserve = 0
			else:
				Globals.rifle_ammo_in_gun = 20
				Globals.rifle_ammo_in_reserve -= rifle_ammo_to_remove_from_reserve
			current_ammo_in_gun = Globals.rifle_ammo_in_gun
			current_ammo_in_reserve = Globals.rifle_ammo_in_reserve
		#endregion
		#region Shotgun reload
		else:
			shotgun_reload = true
		#endregion

func _on_health_regen_tick_timer_timeout():
	Globals.player_health += 10
	emit_signal("player_healed")
	health_regen_tick_timer.start()
	if Globals.player_health >= 100:
		health_regen_tick_timer.stop()

func _on_start_health_regen_timer_timeout():
	if Globals.player_health < 100:
		Globals.player_health += 10
		emit_signal("player_healed")
		health_regen_tick_timer.start()

func _on_stamina_recharge_timer_timeout():
	can_sprint = true

func _on_game_restart_timer_timeout():
	emit_signal("restart_game")
