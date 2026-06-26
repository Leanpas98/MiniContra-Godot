extends Area2D

const SPEED = 350.0
const MAX_DISTANCE = 900.0

var direction = 1
var start_x = 0.0

func _ready():
	start_x = global_position.x

func _process(delta):
	global_position.x += direction * SPEED * delta

	if abs(global_position.x - start_x) > MAX_DISTANCE:
		queue_free()

func _on_area_entered(area):
	# Si toca un enemigo normal, llama a die().
	# El score se suma dentro del enemy.gd.
	if area.has_method("die"):
		area.die()
		queue_free()
		return

	# Si toca el HitArea del boss, busca al padre BossGreen.
	if area.get_parent() and area.get_parent().has_method("take_boss_damage"):
		area.get_parent().take_boss_damage(1)
		queue_free()
		return

func _on_body_entered(body):
	# Si toca al player, no hace nada.
	# Esto evita que la bala del player se destruya raro si roza al jugador.
	if body.has_method("take_damage"):
		return

	# Si toca directamente al boss.
	if body.has_method("take_boss_damage"):
		body.take_boss_damage(1)
		queue_free()
		return

	# Si toca piso, pared u objeto, desaparece.
	queue_free()
