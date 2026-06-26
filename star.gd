extends Area2D

const POINTS = 250

var collected = false

func _ready():
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if collected:
		return

	if not body.is_in_group("player"):
		return

	collected = true

	SoundManager.play_sound("level_complete", -20)

	add_score_to_ui()

	queue_free()

func add_score_to_ui():
	var canvas_layer = get_tree().current_scene.get_node_or_null("CanvasLayer")

	if canvas_layer and canvas_layer.has_method("add_score"):
		canvas_layer.add_score(POINTS)
	else:
		print("No se encontró CanvasLayer con método add_score para sumar puntos de estrella")
