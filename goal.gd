extends Area2D

var level_completed = false
var warning_showing = false

func _ready():
	var warning_label = get_tree().current_scene.get_node_or_null("CanvasLayer/BossWarningLabel")

	if warning_label:
		warning_label.text = "Derrotá al boss primero"
		warning_label.position = Vector2(450, 250)
		warning_label.hide()

func _on_body_entered(body):
	if level_completed:
		return

	if not body.is_in_group("player"):
		return

	if is_boss_alive():
		show_boss_warning()
		print("Todavía tenés que derrotar al boss")
		return

	level_completed = true

	SoundManager.stop_all_loop_sounds()
	SoundManager.stop_music()
	SoundManager.play_sound("level_complete", -3)

	var win_label = get_tree().current_scene.get_node("CanvasLayer/WinLabel")
	win_label.text = "¡Ganaste!"
	win_label.position = Vector2(550, 300)
	win_label.show()

	await get_tree().create_timer(0.2).timeout

	get_tree().paused = true

func is_boss_alive():
	var boss = get_tree().get_first_node_in_group("boss")

	if boss:
		return true

	return false

func show_boss_warning():
	if warning_showing:
		return

	warning_showing = true

	var warning_label = get_tree().current_scene.get_node_or_null("CanvasLayer/BossWarningLabel")

	if warning_label:
		warning_label.text = "Derrotá al boss primero"
		warning_label.position = Vector2(450, 250)
		warning_label.show()

	await get_tree().create_timer(2.0).timeout

	if warning_label:
		warning_label.hide()

	warning_showing = false
