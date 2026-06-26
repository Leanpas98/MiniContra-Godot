extends Area2D

func _ready():
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	print("Entró a la soga:", body.name)

	if body.has_method("enter_rope"):
		body.enter_rope(self)

func _on_body_exited(body):
	print("Salió de la soga:", body.name)

	if body.has_method("exit_rope"):
		body.exit_rope(self)
