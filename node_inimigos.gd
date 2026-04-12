extends CharacterBody3D

@export var speed = 4.0
@export var vida: int = 2
@export var dano_no_barco: int = 10

var player = null


func _ready():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	# Perseguição
	var target_pos = player.global_position
	var direction = (target_pos - global_position).normalized()
	direction.y = 0 
	look_at(global_position + direction, Vector3.UP)
	velocity = direction * speed
	
	# Movimento e Detecção de Colisão Física
	move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var body = col.get_collider()
		print("Bati em: ", body.name)
		# Verifica se bateu no navio (group "player")
		if body.is_in_group("player"): 
			if body.has_method("receber_dano_navio"):
				body.receber_dano_navio(dano_no_barco)
				print("Inimigo: Bati no navio!")
				# Recua levemente para não dar dano infinito em 1 frame
				velocity = -direction * speed 

func levar_dano(quantidade):
	# Verifica se já está marcado para destruir (evita erros duplos)
	if is_queued_for_deletion():
		return
		
	vida -= quantidade
	print("Inimigo: Atingido! Vida: ", vida)
	
	if vida <= 0:
		print("Inimigo: Morri!")
		# O queue_free() libera o objeto no final do frame atual com segurança
		queue_free()
