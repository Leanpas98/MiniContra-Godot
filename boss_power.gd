extends Area2D

const SPEED = 260.0
const MAX_DISTANCE = 900.0
const DAMAGE = 25

var direction = 1
var start_position = Vector2.ZERO

func _ready():
	start_position = global_position

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _process(delta):
	global_position.x += direction * SPEED * delta

	if abs(global_position.x - start_position.x) > MAX_DISTANCE:
		queue_free()

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)
		queue_free()
		return

	queue_free()
