extends Area2D

const SPEED = 220.0
const MAX_DISTANCE = 800.0

var direction = -1
var start_x = 0.0

func _ready():
	start_x = global_position.x

func _process(delta):
	global_position.x += direction * SPEED * delta

	if abs(global_position.x - start_x) > MAX_DISTANCE:
		queue_free()

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage()

	queue_free()
