extends Node

var sounds = {}
var music_player: AudioStreamPlayer
var active_loop_players = {}

var current_music_name = ""
var current_music_volume = -18.0
var music_loop_enabled = true

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_sounds()
	create_music_player()

func load_sounds():
	sounds = {
		"player_run": "res://sounds/run.wav",
		"enemy_run": "res://sounds/run.wav",
		"player_shoot": "res://sounds/player_shoot.ogg",
		"enemy_shoot": "res://sounds/player_shoot.ogg",
		"enemy_die": "res://sounds/enemy_die.mp3",
		"player_die": "res://sounds/player_die.wav",
		"boss_die": "res://sounds/boss_die.wav",
		"boss_scream": "res://sounds/boss_scream.wav",
		"boss_walk": "res://sounds/boss_walk.wav",
		"game_music": "res://sounds/game_music.mp3",
		"level_complete": "res://sounds/level_complete.wav",
		"final_boss_music": "res://sounds/final_boss_music.wav"
	}

func create_music_player():
	music_player = AudioStreamPlayer.new()
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player)
	music_player.volume_db = -18

	if not music_player.finished.is_connected(_on_music_finished):
		music_player.finished.connect(_on_music_finished)

func play_sound(sound_name: String, volume_db: float = -4.0):
	if not sounds.has(sound_name):
		print("No existe el sonido:", sound_name)
		return

	var path = sounds[sound_name]

	if not ResourceLoader.exists(path):
		print("No se encontró el archivo de sonido:", path)
		return

	var audio_stream = load(path)

	if audio_stream == null:
		print("No se pudo cargar el sonido:", path)
		return

	var player = AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)

	player.stream = audio_stream
	player.volume_db = volume_db
	player.play()

	player.finished.connect(func():
		player.queue_free()
	)

func play_loop_sound(sound_name: String, volume_db: float = -10.0):
	if active_loop_players.has(sound_name):
		var existing_player = active_loop_players[sound_name]

		if existing_player and existing_player.playing:
			return

	if not sounds.has(sound_name):
		print("No existe el sonido loop:", sound_name)
		return

	var path = sounds[sound_name]

	if not ResourceLoader.exists(path):
		print("No se encontró el archivo de sonido loop:", path)
		return

	var audio_stream = load(path)

	if audio_stream == null:
		print("No se pudo cargar el sonido loop:", path)
		return

	var player = AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)

	player.stream = audio_stream
	player.volume_db = volume_db
	player.play()

	active_loop_players[sound_name] = player

func stop_loop_sound(sound_name: String):
	if not active_loop_players.has(sound_name):
		return

	var player = active_loop_players[sound_name]

	if player:
		player.stop()
		player.queue_free()

	active_loop_players.erase(sound_name)

func stop_all_loop_sounds():
	for sound_name in active_loop_players.keys():
		var player = active_loop_players[sound_name]

		if player:
			player.stop()
			player.queue_free()

	active_loop_players.clear()

func play_music(music_name: String, volume_db: float = -18.0, loop_music: bool = true):
	if not sounds.has(music_name):
		print("No existe la música:", music_name)
		return

	var path = sounds[music_name]

	if not ResourceLoader.exists(path):
		print("No se encontró el archivo de música:", path)
		return

	var audio_stream = load(path)

	if audio_stream == null:
		print("No se pudo cargar la música:", path)
		return

	current_music_name = music_name
	current_music_volume = volume_db
	music_loop_enabled = loop_music

	music_player.stream = audio_stream
	music_player.volume_db = volume_db
	music_player.stream_paused = false
	music_player.play()

func stop_music():
	if music_player:
		music_loop_enabled = false
		music_player.stop()

func pause_music():
	if music_player and music_player.playing:
		music_player.stream_paused = true

func resume_music():
	if music_player and music_player.stream:
		music_player.stream_paused = false

func _on_music_finished():
	if not music_loop_enabled:
		return

	if current_music_name == "":
		return

	if not sounds.has(current_music_name):
		return

	var path = sounds[current_music_name]

	if not ResourceLoader.exists(path):
		return

	var audio_stream = load(path)

	if audio_stream == null:
		return

	music_player.stream = audio_stream
	music_player.volume_db = current_music_volume
	music_player.play()
