extends CharacterBody3D

@export var speed = 10.0 # Valor baixo para sair lentamente

func _physics_process(_delta):
	# Move a bala para frente (eixo Z negativo no Godot)
	var direction = -global_transform.basis.z
	velocity = direction * speed
	move_and_slide()
