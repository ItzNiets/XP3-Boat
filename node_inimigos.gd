extends CharacterBody3D

@export var speed: float = 4.0
@export var vida: int = 1
@export var dano_no_barco: int = 1

var player = null
var esta_recuando: bool = false

func _ready():
	player = get_tree().get_first_node_in_group("player")
	
	collision_layer = 2
	collision_mask = 1 | 2 

func _physics_process(_delta: float) -> void:
	if not player: return

	if esta_recuando:
		move_and_slide()
		return

	# Lógica de Perseguição
	var target_pos = player.global_position
	var direction = (target_pos - global_position).normalized()
	
	
	direction.y = 0 
	
	look_at(global_position + direction, Vector3.UP)
	velocity = direction * speed
	
	
	velocity.y = 0 
	
	if move_and_slide():
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			var alvo = collider if collider.has_method("receber_dano_navio") else collider.get_owner()
			
			if alvo and alvo.has_method("receber_dano_navio"):
				if alvo.vida_navio > 0:
					alvo.receber_dano_navio(dano_no_barco)
					recuar()
					break

func recuar():
	if esta_recuando: return
	esta_recuando = true
	
	# Pega a colisão mais recente
	var col = get_last_slide_collision()
	if col:
		# A "normal" da colisão é a direção perpendicular à superfície onde ele bateu.
		# Ao usar essa normal, ele será jogado exatamente para longe do objeto.
		var direcao_recuo = col.get_normal()
		
		
		direcao_recuo.y = 0 
		
		# Aplica a força de recuo na direção oposta à normal da colisão
		velocity = direcao_recuo *  10
		
		#Teleporte leve para garantir que ele saia do navio
		global_position += direcao_recuo * 2.0
	
	# Tempo de duração do impulso
	await get_tree().create_timer(2.0).timeout
	
	velocity = Vector3.ZERO
	esta_recuando = false

# --- SISTEMA DE DANO DO INIMIGO ---
func levar_dano(quantidade: int):
	if is_queued_for_deletion(): return
	vida -= quantidade
	if vida <= 0: morrer()

func morrer():
	queue_free()
