extends Area2D

const MIN_SPEED = 55.0
const MAX_SPEED = 100.0

const MIN_PATROL_DISTANCE = 220.0
const MAX_PATROL_DISTANCE = 420.0

const MIN_SHOOT_INTERVAL = 0.8
const MAX_SHOOT_INTERVAL = 1.8

const SHOOT_ANIM_TIME = 0.25
const TURN_PUSHBACK = 10.0
const TURN_COOLDOWN = 0.25

const FLOOR_CHECK_DISTANCE_X = 35.0
const FLOOR_CHECK_DISTANCE_Y = 65.0

const SCORE_VALUE = 100

var speed = 60.0
var patrol_distance = 250.0
var shoot_interval = 1.0

var direction = -1
var start_x = 0.0
var shoot_timer = 0.0
var shoot_anim_timer = 0.0
var turn_timer = 0.0
var is_dead = false

var enemy_bullet_scene = preload("res://enemy_bullet.tscn")

var normal_frame = Rect2(6, 5, 57, 84)
var shoot_frame = Rect2(68, 5, 57, 84)

@onready var floor_detector = get_node_or_null("FloorDetector")

func _ready():
	randomize()

	start_x = position.x

	speed = randf_range(MIN_SPEED, MAX_SPEED)
	patrol_distance = randf_range(MIN_PATROL_DISTANCE, MAX_PATROL_DISTANCE)
	shoot_interval = randf_range(MIN_SHOOT_INTERVAL, MAX_SHOOT_INTERVAL)

	if randi() % 2 == 0:
		direction = -1
	else:
		direction = 1

	shoot_timer = randf_range(0.3, shoot_interval)

	$Sprite2D.region_enabled = true
	$Sprite2D.region_rect = normal_frame

	if floor_detector:
		floor_detector.enabled = true

	update_muzzle_position()
	update_floor_detector_position()

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _process(delta):
	if is_dead:
		return

	if turn_timer > 0:
		turn_timer -= delta

	update_floor_detector_position()

	# Si adelante no hay piso, se da vuelta antes de caerse
	if floor_detector and turn_timer <= 0 and not floor_detector.is_colliding():
		turn_around()

	position.x += direction * speed * delta

	if position.x > start_x + patrol_distance:
		turn_around()
	elif position.x < start_x - patrol_distance:
		turn_around()

	$Sprite2D.flip_h = direction > 0

	update_muzzle_position()
	update_floor_detector_position()

	if shoot_anim_timer > 0:
		shoot_anim_timer -= delta
		$Sprite2D.region_rect = shoot_frame
	else:
		$Sprite2D.region_rect = normal_frame

	shoot_timer -= delta

	if shoot_timer <= 0:
		shoot()
		shoot_timer = shoot_interval + randf_range(0.0, 0.4)

func update_floor_detector_position():
	if not floor_detector:
		return

	floor_detector.position.x = FLOOR_CHECK_DISTANCE_X * direction
	floor_detector.position.y = 20
	floor_detector.target_position = Vector2(0, FLOOR_CHECK_DISTANCE_Y)

func turn_around():
	if turn_timer > 0:
		return

	direction *= -1
	position.x += direction * TURN_PUSHBACK
	turn_timer = TURN_COOLDOWN

func update_muzzle_position():
	if direction == -1:
		$EnemyMuzzle.position.x = -35
	else:
		$EnemyMuzzle.position.x = 35

	$EnemyMuzzle.position.y = -2

func shoot():
	if is_dead:
		return

	var enemy_bullet = enemy_bullet_scene.instantiate()

	enemy_bullet.global_position = $EnemyMuzzle.global_position
	enemy_bullet.direction = direction

	get_parent().add_child(enemy_bullet)

	shoot_anim_timer = SHOOT_ANIM_TIME

func die():
	if is_dead:
		return

	is_dead = true

	SoundManager.play_sound("enemy_die", -30)

	add_score_to_ui()

	queue_free()

func add_score_to_ui():
	var canvas_layer = get_tree().current_scene.get_node_or_null("CanvasLayer")

	if canvas_layer and canvas_layer.has_method("add_score"):
		canvas_layer.add_score(SCORE_VALUE)
	else:
		print("No se encontró CanvasLayer con método add_score")

func _on_body_entered(body):
	if is_dead:
		return

	if body.has_method("take_damage"):
		body.take_damage()
		return

	turn_around()
