extends CanvasLayer

var score = 0
var game_paused_by_player = false

@onready var score_label = get_node_or_null("ScoreLabel")
@onready var pause_label = get_node_or_null("PauseLabel")

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	update_score_label()
	
	if pause_label:
		pause_label.text = "PAUSA"
		pause_label.position = Vector2(550, 300)
		pause_label.hide()
	
	SoundManager.play_music("game_music", -18, true)

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_P or event.keycode == KEY_ESCAPE:
			toggle_pause()

func toggle_pause():
	game_paused_by_player = not game_paused_by_player
	get_tree().paused = game_paused_by_player

	if game_paused_by_player:
		pause_game()
	else:
		resume_game()

func pause_game():
	SoundManager.stop_all_loop_sounds()
	SoundManager.pause_music()

	if pause_label:
		pause_label.show()

func resume_game():
	SoundManager.resume_music()

	if pause_label:
		pause_label.hide()

func add_score(amount = 100):
	score += amount
	update_score_label()
	print("Score:", score)

func update_score_label():
	if score_label:
		score_label.text = "Score: " + str(score)
