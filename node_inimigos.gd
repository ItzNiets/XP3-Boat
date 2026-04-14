extends CharacterBody3D

@export var speed: float = 4.0
@export var vida: int = 2
@export var dano_no_barco: int = 10

var player = null

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	# Lógica de Perseguição
	var target_pos = player.global_position
	var direction = (target_pos - global_position).normalized()
	direction.y = 0 
	look_at(global_position + direction, Vector3.UP)
	velocity = direction * speed
	
	move_and_slide()
	
	# Verificação de Colisão com o Navio
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var body = col.get_collider()
		
		if body.is_in_group("player"): 
			if body.has_method("receber_dano_navio"):
				body.receber_dano_navio(dano_no_barco)
				# Opcional: Adicionar um pequeno atraso ou recuo aqui para evitar dano por segundo muito alto

# Função chamada por outros scripts (ex: Bala ou Arma)
func levar_dano(quantidade: int):
	# A verificação de is_queued_for_deletion() é uma excelente prática
	if is_queued_for_deletion():
		return
		
	vida -= quantidade
	print("Inimigo: Atingido! Vida restante: ", vida)
	
	if vida <= 0:
		morrer()

func morrer():
	print("Inimigo: Morri!")
	# Adicione aqui efeitos de partículas ou som antes do queue_free()
	queue_free()
