extends CharacterBody3D

@export var speed: float = 4.0
@export var vida: int = 1
@export var dano_no_barco: int = 1
@export var intervalo_ataque: float = 3.0  # Segundos entre ataques

var alvo: Node3D = null  # O navio
var esta_recuando: bool = false
var pode_atacar := true

func _ready():
	add_to_group("inimigos")
	call_deferred("_find_navio")
	collision_layer = 2
	collision_mask = 1 | 2

func _find_navio():
	var root = get_tree().current_scene
	alvo = _search(root)

func _search(node: Node) -> Node3D:
	if node is ShipBuoyancy:
		return node
	for c in node.get_children():
		var result = _search(c)
		if result:
			return result
	return null

func _physics_process(_delta: float) -> void:
	if not alvo or not is_instance_valid(alvo): return

	if esta_recuando:
		move_and_slide()
		return

	# Perseguir o navio
	var target_pos = alvo.global_position
	var direction = (target_pos - global_position).normalized()
	direction.y = 0

	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)
	velocity = direction * speed
	velocity.y = 0

	if move_and_slide():
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()

			var corpo_dano = collider if collider.has_method("receber_dano_navio") else collider.get_owner()

			if corpo_dano and corpo_dano.has_method("receber_dano_navio"):
				if pode_atacar and corpo_dano.vida_navio > 0:
					corpo_dano.receber_dano_navio(dano_no_barco)
					recuar()
					break

func recuar():
	if esta_recuando: return
	esta_recuando = true
	pode_atacar = false

	var col = get_last_slide_collision()
	if col:
		var direcao_recuo = col.get_normal()
		direcao_recuo.y = 0
		velocity = direcao_recuo * 10
		global_position += direcao_recuo * 2.0

	# Recuo curto e depois volta a atacar
	await get_tree().create_timer(1.0).timeout
	velocity = Vector3.ZERO
	esta_recuando = false

	# Cooldown de ataque
	await get_tree().create_timer(intervalo_ataque).timeout
	pode_atacar = true

# --- SISTEMA DE DANO DO INIMIGO ---
func levar_dano(quantidade: int):
	if is_queued_for_deletion(): return
	vida -= quantidade
	if vida <= 0: morrer()

func morrer():
	Manager.registrar_morte_inimigo()
	queue_free()
