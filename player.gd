extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -610.0
const GRAVITY = 1000.0
const SHOOT_COOLDOWN = 0.25
const RESPAWN_TIME = 2.0
const CLIMB_SPEED = 120.0

const MAX_LIVES = 3
const MAX_HEALTH = 100
const DAMAGE_AMOUNT = 25

# Si el player cae por debajo de esta altura, muere.
# Si muere demasiado rápido, subí el número: 1100, 1300.
# Si tarda mucho en morir, bajalo: 700, 800.
const FALL_DEATH_Y = 900.0

var bullet_scene = preload("res://bullet.tscn")

var facing = 1
var lives = MAX_LIVES
var health = MAX_HEALTH

var shoot_timer = 0.0
var is_dead = false
var spawn_position = Vector2.ZERO

var walk_timer = 0.0
var walk_frame_index = 0
var shoot_anim_timer = 0.0
var shoot_key_was_pressed = false

var on_rope = false
var current_rope = null

@onready var life_label = get_node_or_null("../CanvasLayer/LifeLabel")
@onready var health_bar = get_node_or_null("../CanvasLayer/HealthBar")

# Frames del spritesheet
var idle_frame = Rect2(5, 5, 56, 77)
var shoot_frame = Rect2(267, 5, 57, 84)

var crouch_frame = Rect2(127, 18, 60, 64)
var crouch_shoot_frame = Rect2(192, 18, 60, 64)

var death_frame = Rect2(271, 94, 84, 43)
var jump_frame = Rect2(292, 143, 45, 117)

# Frame para agarrarse de la cuerda
var rope_frame = Rect2(293, 144, 43, 115)

var walk_frames = [
	Rect2(5, 87, 57, 84),
	Rect2(67, 89, 57, 82),
	Rect2(129, 87, 57, 84),
	Rect2(191, 89, 57, 82),
	Rect2(5, 176, 57, 84),
	Rect2(67, 178, 57, 82),
	Rect2(129, 176, 57, 84),
	Rect2(191, 178, 57, 82)
]

func _ready():
	add_to_group("player")
	spawn_position = global_position
	
	$Sprite2D.region_enabled = true
	$Sprite2D.region_rect = idle_frame
	
	update_life_ui()

func _physics_process(delta):
	if is_dead:
		SoundManager.stop_loop_sound("player_run")
		return

	# Si cae al vacío, muere
	if global_position.y > FALL_DEATH_Y:
		fall_to_death()
		return

	if shoot_timer > 0:
		shoot_timer -= delta

	if shoot_anim_timer > 0:
		shoot_anim_timer -= delta

	if on_rope:
		SoundManager.stop_loop_sound("player_run")
		handle_rope_movement()
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var is_crouching = Input.is_physical_key_pressed(KEY_DOWN)

	if Input.is_physical_key_pressed(KEY_SPACE) and is_on_floor() and not is_crouching:
		velocity.y = JUMP_VELOCITY
		SoundManager.stop_loop_sound("player_run")

	var direction = 0

	if not is_crouching:
		if Input.is_physical_key_pressed(KEY_LEFT):
			direction = -1
		elif Input.is_physical_key_pressed(KEY_RIGHT):
			direction = 1

	velocity.x = direction * SPEED

	if direction != 0:
		facing = direction
		$Sprite2D.flip_h = facing < 0

	if is_crouching:
		$Muzzle.position.x = 65 * facing
		$Muzzle.position.y = -5
	else:
		$Muzzle.position.x = 70 * facing
		$Muzzle.position.y = -20

	var shoot_key_pressed = Input.is_physical_key_pressed(KEY_X)

	if shoot_key_pressed and not shoot_key_was_pressed and shoot_timer <= 0:
		shoot()
		shoot_timer = SHOOT_COOLDOWN
		shoot_anim_timer = 0.12

	shoot_key_was_pressed = shoot_key_pressed

	update_animation(delta, direction, is_crouching)
	update_player_run_sound(direction, is_crouching)

	move_and_slide()

func handle_rope_movement():
	velocity = Vector2.ZERO
	SoundManager.stop_loop_sound("player_run")

	if Input.is_physical_key_pressed(KEY_LEFT):
		velocity.x = -SPEED
		facing = -1
		$Sprite2D.flip_h = true
	elif Input.is_physical_key_pressed(KEY_RIGHT):
		velocity.x = SPEED
		facing = 1
		$Sprite2D.flip_h = false
	else:
		velocity.x = 0

	if Input.is_physical_key_pressed(KEY_UP):
		velocity.y = -CLIMB_SPEED
	elif Input.is_physical_key_pressed(KEY_DOWN):
		velocity.y = CLIMB_SPEED
	else:
		velocity.y = 0

	$Muzzle.position.x = 70 * facing
	$Muzzle.position.y = -20

	var shoot_key_pressed = Input.is_physical_key_pressed(KEY_X)

	if shoot_key_pressed and not shoot_key_was_pressed and shoot_timer <= 0:
		shoot()
		shoot_timer = SHOOT_COOLDOWN
		shoot_anim_timer = 0.12

	shoot_key_was_pressed = shoot_key_pressed

	if Input.is_physical_key_pressed(KEY_SPACE):
		on_rope = false
		current_rope = null
		velocity.y = JUMP_VELOCITY
		velocity.x = SPEED * facing
		move_and_slide()
		return

	if shoot_anim_timer > 0:
		$Sprite2D.region_rect = shoot_frame
	else:
		$Sprite2D.region_rect = rope_frame

	move_and_slide()

func update_animation(delta, direction, is_crouching):
	if not is_on_floor():
		$Sprite2D.region_rect = jump_frame
		return

	if is_crouching and shoot_anim_timer > 0:
		$Sprite2D.region_rect = crouch_shoot_frame
		return

	if is_crouching:
		$Sprite2D.region_rect = crouch_frame
		return

	if shoot_anim_timer > 0:
		$Sprite2D.region_rect = shoot_frame
		return

	if direction != 0:
		walk_timer += delta

		if walk_timer >= 0.12:
			walk_timer = 0
			walk_frame_index += 1

			if walk_frame_index >= walk_frames.size():
				walk_frame_index = 0

		$Sprite2D.region_rect = walk_frames[walk_frame_index]
		return

	$Sprite2D.region_rect = idle_frame

func update_player_run_sound(direction, is_crouching):
	if is_dead or on_rope or is_crouching:
		SoundManager.stop_loop_sound("player_run")
		return

	if direction != 0 and is_on_floor():
		SoundManager.play_loop_sound("player_run", -14)
	else:
		SoundManager.stop_loop_sound("player_run")

func shoot():
	SoundManager.play_sound("player_shoot", -30)

	var bullet = bullet_scene.instantiate()
	bullet.global_position = $Muzzle.global_position
	bullet.direction = facing
	get_parent().add_child(bullet)

func take_damage(amount = DAMAGE_AMOUNT):
	if is_dead:
		return

	health -= amount

	if health < 0:
		health = 0

	update_life_ui()

	print("Salud:", health, " Vidas:", lives)

	if health <= 0:
		lose_life()

func lose_life():
	lives -= 1
	update_life_ui()

	if lives <= 0:
		die_and_game_over()
	else:
		die_and_respawn()

func fall_to_death():
	if is_dead:
		return

	print("Player cayó al vacío")

	health = 0
	update_life_ui()
	lose_life()

func die_and_respawn():
	is_dead = true
	on_rope = false
	current_rope = null
	velocity = Vector2.ZERO
	
	SoundManager.stop_loop_sound("player_run")
	SoundManager.play_sound("player_die", -3)
	
	$Sprite2D.region_rect = death_frame
	$CollisionShape2D.set_deferred("disabled", true)

	await get_tree().create_timer(RESPAWN_TIME).timeout

	global_position = spawn_position
	velocity = Vector2.ZERO
	
	health = MAX_HEALTH
	is_dead = false
	
	$CollisionShape2D.set_deferred("disabled", false)
	$Sprite2D.region_rect = idle_frame
	
	update_life_ui()

func die_and_game_over():
	is_dead = true
	on_rope = false
	current_rope = null
	velocity = Vector2.ZERO
	
	SoundManager.stop_loop_sound("player_run")
	SoundManager.play_sound("player_die", -30)
	
	$Sprite2D.region_rect = death_frame
	$CollisionShape2D.set_deferred("disabled", true)

	await get_tree().create_timer(RESPAWN_TIME).timeout
	
	SoundManager.stop_all_loop_sounds()
	get_tree().reload_current_scene()

func enter_rope(rope):
	if is_dead:
		return

	on_rope = true
	current_rope = rope
	velocity = Vector2.ZERO
	SoundManager.stop_loop_sound("player_run")
	print("Player agarró la soga")

func exit_rope(rope):
	if current_rope == rope:
		on_rope = false
		current_rope = null
		SoundManager.stop_loop_sound("player_run")
		print("Player soltó la soga")

func update_life_ui():
	if life_label:
		life_label.text = "Vidas: " + str(lives)

	if health_bar:
		health_bar.min_value = 0
		health_bar.max_value = MAX_HEALTH
		health_bar.value = health
