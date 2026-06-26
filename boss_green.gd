extends CharacterBody2D

const SPEED = 80.0
const GRAVITY = 1000.0
const HEALTH_MAX = 30
const DAMAGE_COOLDOWN = 1.0
const ACTIVATION_DISTANCE = 700.0

# Distancias ajustadas para que ataque cerca, pero sin meterse encima
const STOP_DISTANCE = 95.0
const ATTACK_DISTANCE = 110.0
const ATTACK_COOLDOWN = 1.3

# Poder a distancia del boss
const POWER_ATTACK_DISTANCE = 360.0
const POWER_ATTACK_COOLDOWN = 2.2
const POWER_MUZZLE_OFFSET = Vector2(28, -8)

# Salto del boss
const JUMP_FORCE = -850.0
const JUMP_COOLDOWN = 1.2
const PLAYER_ABOVE_DISTANCE = 100.0
const WALL_JUMP_DELAY = 0.2

# Puntos que da el boss al morir
const BOSS_SCORE_VALUE = 1000

# Ajuste visual del sprite
const SPRITE_OFFSET = Vector2(0, 8)

var boss_power_scene = preload("res://boss_power.tscn")

var health = HEALTH_MAX
var direction = -1
var damage_timer = 0.0
var attack_timer = 0.0
var power_attack_timer = 0.0
var jump_timer = 0.0
var wall_stuck_timer = 0.0

var is_dead = false
var is_attacking = false
var is_power_attacking = false
var is_hurt = false
var player = null
var boss_activated = false
var boss_music_started = false

var walk_timer = 0.0
var walk_frame_index = 0

var attack_visual_timer = 0.0
var power_attack_visual_timer = 0.0

@onready var boss_health_bar = get_node_or_null("../CanvasLayer/BossHealthBar")

# Frames del boss
const BOSS_FRAME_W = 34
const BOSS_FRAME_H = 38

var idle_frame = Rect2(1, 1, BOSS_FRAME_W, BOSS_FRAME_H)

var walk_frames = [
	Rect2(1, 1, BOSS_FRAME_W, BOSS_FRAME_H),
	Rect2(37, 1, BOSS_FRAME_W, BOSS_FRAME_H)
]

# Usamos frame limpio para ataque porque el frame real traía partes raras
var attack_frame = Rect2(1, 1, BOSS_FRAME_W, BOSS_FRAME_H)

# Para tirar poder usamos el mismo frame limpio por ahora
var power_attack_frame = Rect2(1, 1, BOSS_FRAME_W, BOSS_FRAME_H)

# El daño se muestra con modulate rojo
var death_frame = Rect2(73, 281, BOSS_FRAME_W, BOSS_FRAME_H)

func _ready():
	add_to_group("boss")
	player = get_tree().get_first_node_in_group("player")

	$Sprite2D.region_enabled = true
	$Sprite2D.region_rect = idle_frame
	$Sprite2D.position = SPRITE_OFFSET
	$Sprite2D.scale = Vector2.ONE

	# Ayuda a que el CharacterBody2D se mantenga pegado al piso
	floor_snap_length = 20.0

	setup_boss_health_bar()

	print("BossGreen apareció en: ", global_position)

func _physics_process(delta):
	if is_dead:
		SoundManager.stop_loop_sound("boss_walk")
		return

	if damage_timer > 0:
		damage_timer -= delta

	if attack_timer > 0:
		attack_timer -= delta

	if power_attack_timer > 0:
		power_attack_timer -= delta

	if jump_timer > 0:
		jump_timer -= delta

	if attack_visual_timer > 0:
		attack_visual_timer -= delta

	if power_attack_visual_timer > 0:
		power_attack_visual_timer -= delta

	# Gravedad
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

	player = get_tree().get_first_node_in_group("player")

	if player == null:
		velocity.x = 0
		update_boss_walk_sound()
		update_animation(delta)
		move_and_slide()
		return

	var distance_x = player.global_position.x - global_position.x
	var distance_to_player = abs(distance_x)
	var vertical_distance = abs(player.global_position.y - global_position.y)

	# Si el player está lejos, el boss queda quieto
	if distance_to_player > ACTIVATION_DISTANCE:
		velocity.x = 0
		update_boss_walk_sound()
		update_animation(delta)
		move_and_slide()
		return

	# Activar boss, barra y música cuando el player se acerca
	if not boss_activated:
		boss_activated = true
		show_boss_health_bar()
		start_boss_music()

	# Mirar hacia el player
	if distance_x < 0:
		direction = -1
	else:
		direction = 1

	$Sprite2D.flip_h = direction > 0

	# Si está en rango de ataque cuerpo a cuerpo, se queda quieto y ataca
	if distance_to_player <= ATTACK_DISTANCE and vertical_distance <= 120:
		velocity.x = 0

		if attack_timer <= 0 and not is_attacking and not is_power_attacking:
			attack()
			attack_timer = ATTACK_COOLDOWN

	# Si está a distancia media, tira poder
	elif distance_to_player <= POWER_ATTACK_DISTANCE and vertical_distance <= 140:
		velocity.x = 0

		if power_attack_timer <= 0 and not is_attacking and not is_power_attacking and not is_hurt:
			power_attack()
			power_attack_timer = POWER_ATTACK_COOLDOWN

	# Si está cerca, se frena para no subirse encima
	elif distance_to_player <= STOP_DISTANCE:
		velocity.x = 0

	else:
		if not is_attacking and not is_power_attacking and not is_hurt:
			velocity.x = direction * SPEED

			# Si se choca contra pared/plataforma, salta
			if is_on_wall() and is_on_floor():
				wall_stuck_timer += delta

				if wall_stuck_timer >= WALL_JUMP_DELAY and jump_timer <= 0:
					boss_jump()
					wall_stuck_timer = 0.0
			else:
				wall_stuck_timer = 0.0

			# Si el player está más arriba, intenta saltar
			if player.global_position.y < global_position.y - PLAYER_ABOVE_DISTANCE and is_on_floor() and jump_timer <= 0:
				boss_jump()
		else:
			velocity.x = 0

	update_boss_walk_sound()
	update_animation(delta)
	move_and_slide()

func update_animation(delta):
	var visual_offset_x = 0.0

	if is_dead:
		$Sprite2D.position = SPRITE_OFFSET
		$Sprite2D.scale = Vector2.ONE
		$Sprite2D.region_rect = death_frame
		return

	# Cuando recibe daño, no cambiamos de frame.
	# Solo se pone rojo desde take_boss_damage().
	if is_hurt:
		$Sprite2D.position = SPRITE_OFFSET
		$Sprite2D.scale = Vector2.ONE

		if abs(velocity.x) > 0:
			$Sprite2D.region_rect = walk_frames[walk_frame_index]
		else:
			$Sprite2D.region_rect = idle_frame

		return

	if is_power_attacking:
		$Sprite2D.region_rect = power_attack_frame

		if power_attack_visual_timer > 0.20:
			visual_offset_x = -5 * direction
		elif power_attack_visual_timer > 0.10:
			visual_offset_x = 18 * direction
		else:
			visual_offset_x = 0

		$Sprite2D.position = SPRITE_OFFSET + Vector2(visual_offset_x, 0)
		$Sprite2D.scale = Vector2.ONE
		return

	if is_attacking:
		$Sprite2D.region_rect = attack_frame

		# Movimiento de ataque SOLO hacia adelante/atrás
		if attack_visual_timer > 0.24:
			visual_offset_x = -8 * direction
		elif attack_visual_timer > 0.12:
			visual_offset_x = 35 * direction
		else:
			visual_offset_x = 10 * direction

		$Sprite2D.position = SPRITE_OFFSET + Vector2(visual_offset_x, 0)
		$Sprite2D.scale = Vector2.ONE
		return

	$Sprite2D.position = SPRITE_OFFSET
	$Sprite2D.scale = Vector2.ONE

	if abs(velocity.x) > 0:
		walk_timer += delta

		if walk_timer >= 0.18:
			walk_timer = 0
			walk_frame_index += 1

			if walk_frame_index >= walk_frames.size():
				walk_frame_index = 0

		$Sprite2D.region_rect = walk_frames[walk_frame_index]
		return

	$Sprite2D.region_rect = idle_frame

func update_boss_walk_sound():
	if is_dead or is_attacking or is_power_attacking or is_hurt:
		SoundManager.stop_loop_sound("boss_walk")
		return

	if abs(velocity.x) > 0 and is_on_floor():
		SoundManager.play_loop_sound("boss_walk", -13)
	else:
		SoundManager.stop_loop_sound("boss_walk")

func start_boss_music():
	if boss_music_started:
		return

	boss_music_started = true

	SoundManager.stop_music()
	SoundManager.play_music("final_boss_music", -16, true)

	print("Música del boss iniciada")

func attack():
	if is_dead:
		return

	is_attacking = true
	velocity.x = 0
	attack_visual_timer = 0.36

	SoundManager.stop_loop_sound("boss_walk")

	print("BossGreen atacó")

	# Espera breve antes de aplicar daño
	await get_tree().create_timer(0.22).timeout

	if is_dead:
		return

	player = get_tree().get_first_node_in_group("player")

	if player:
		var distance_to_player = abs(player.global_position.x - global_position.x)
		var vertical_distance = abs(player.global_position.y - global_position.y)

		if distance_to_player <= ATTACK_DISTANCE + 25 and vertical_distance <= 120:
			if player.has_method("take_damage"):
				player.take_damage()

	await get_tree().create_timer(0.14).timeout

	is_attacking = false
	$Sprite2D.position = SPRITE_OFFSET
	$Sprite2D.scale = Vector2.ONE

func power_attack():
	if is_dead:
		return

	is_power_attacking = true
	velocity.x = 0
	power_attack_visual_timer = 0.35

	SoundManager.stop_loop_sound("boss_walk")
	SoundManager.play_sound("boss_scream", -8)

	print("BossGreen tiró poder")

	await get_tree().create_timer(0.18).timeout

	if is_dead:
		return

	var power = boss_power_scene.instantiate()
	power.direction = direction

	var power_position = global_position
	power_position.x += POWER_MUZZLE_OFFSET.x * direction
	power_position.y += POWER_MUZZLE_OFFSET.y

	power.global_position = power_position

	get_parent().add_child(power)

	await get_tree().create_timer(0.17).timeout

	is_power_attacking = false
	$Sprite2D.position = SPRITE_OFFSET
	$Sprite2D.scale = Vector2.ONE

func boss_jump():
	if is_dead or is_attacking or is_power_attacking or is_hurt:
		return

	if is_on_floor():
		velocity.y = JUMP_FORCE
		jump_timer = JUMP_COOLDOWN
		SoundManager.stop_loop_sound("boss_walk")
		print("BossGreen saltó alto")

func take_boss_damage(amount = 1):
	if is_dead:
		return

	health -= amount

	if health < 0:
		health = 0

	SoundManager.stop_loop_sound("boss_walk")
	SoundManager.play_sound("boss_scream", -4)

	print("Vida Boss Verde: ", health)

	update_boss_health_bar()
	show_boss_health_bar()

	# En vez de cambiar a un frame roto, solo parpadea en rojo
	is_hurt = true
	modulate = Color(1, 0.35, 0.35)

	await get_tree().create_timer(0.12).timeout

	modulate = Color(1, 1, 1)
	is_hurt = false

	if health <= 0:
		die()

func die():
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO

	SoundManager.stop_loop_sound("boss_walk")
	SoundManager.stop_music()
	SoundManager.play_sound("boss_die", -3)

	# Volver a la música normal del nivel después de matar al boss
	SoundManager.play_music("game_music", -18, true)

	# Sumar score al derrotar al boss
	add_score_to_ui()

	$Sprite2D.position = SPRITE_OFFSET
	$Sprite2D.scale = Vector2.ONE
	$Sprite2D.region_rect = death_frame

	hide_boss_health_bar()

	print("Boss Verde derrotado")

	await get_tree().create_timer(0.7).timeout
	queue_free()

func add_score_to_ui():
	var canvas_layer = get_tree().current_scene.get_node_or_null("CanvasLayer")

	if canvas_layer and canvas_layer.has_method("add_score"):
		canvas_layer.add_score(BOSS_SCORE_VALUE)
	else:
		print("No se encontró CanvasLayer con método add_score para sumar score del boss")

func setup_boss_health_bar():
	if boss_health_bar:
		boss_health_bar.min_value = 0
		boss_health_bar.max_value = HEALTH_MAX
		boss_health_bar.value = health
		boss_health_bar.visible = false

func update_boss_health_bar():
	if boss_health_bar:
		boss_health_bar.value = health

func show_boss_health_bar():
	if boss_health_bar:
		boss_health_bar.visible = true
		boss_health_bar.value = health

func hide_boss_health_bar():
	if boss_health_bar:
		boss_health_bar.visible = false

func _on_hit_area_body_entered(body):
	if body.has_method("take_damage") and damage_timer <= 0 and not is_dead:
		body.take_damage()
		damage_timer = DAMAGE_COOLDOWN
