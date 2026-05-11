extends CharacterBody3D

# Constantes baseadas nos arquivos de exemplo da Godot
@export var SPEED : float = 5.0
@export var JUMP_VELOCITY : float = 4.5

# Obtém a gravidade padrão das configurações do projeto
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
	# Adiciona gravidade (essencial para colisão com o chão)
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Gerencia o pulo (mapeado para Espaço por padrão no ui_accept)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Captura o vetor de entrada das setas (ui_left, ui_right, ui_up, ui_down)
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Calcula a direção relativa à rotação do personagem
	# Isso garante que "Cima" seja sempre para onde o personagem olha
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# Suaviza a frenagem usando move_toward
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# move_and_slide usa a variável 'velocity' interna para mover e colidir
	move_and_slide()
