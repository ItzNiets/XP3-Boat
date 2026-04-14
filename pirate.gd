extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var usando_canhao = false
var navio_referencia = null 

var municao_player = 3
var max_municao = 3

func _physics_process(delta: float) -> void:
	if usando_canhao:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# --- 4 DIREÇÕES ---
	var input_dir = Vector2.ZERO
	
	if Input.is_action_pressed("ui_up"):
		input_dir = Vector2(0, -2)
	elif Input.is_action_pressed("ui_down"):
		input_dir = Vector2(0, 1)
	elif Input.is_action_pressed("ui_left"):
		input_dir = Vector2(-1, 0)
	elif Input.is_action_pressed("ui_right"):
		input_dir = Vector2(1, 0)

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _input(event):
	if event.is_action_pressed("interagirCanhao"):
		if usando_canhao:
			sair_do_canhao()
		else:
			interagir_com_objetos()

	if event.is_action_pressed("recarregar"):
		if not usando_canhao:
			tentar_recarregar_estoque()

	# --- CONTROLE DO NAVIO (CORRIGIDO) ---
	if usando_canhao and navio_referencia:
		
		if event.is_action_pressed("ui_up"):
			navio_referencia.comando_acelerar()
			
		if event.is_action_pressed("ui_down"):
			navio_referencia.comando_parar()
		
		# VIRAR FIXO (90 GRAUS)
		if event.is_action_pressed("ui_left"): 
			navio_referencia.comando_virar_fixo(1)
			 # Gira +90 graus
			
		if event.is_action_pressed("ui_right"):
			navio_referencia.comando_virar_fixo(-1)
			
func interagir_com_objetos():
	var sensor = $AreaInteracao
	var areas = sensor.get_overlapping_areas()
	
	for area in areas:
		var alvo = encontrar_script_por_metodo(area, "assumir_controle")
		if alvo:
			if alvo.has_method("get_navio"):
				navio_referencia = alvo.get_navio()
			
			alvo.assumir_controle(self)
			usando_canhao = true
			return

func sair_do_canhao():
	usando_canhao = false
	navio_referencia = null
	
	var sensor = $AreaInteracao
	for area in sensor.get_overlapping_areas():
		var alvo = encontrar_script_por_metodo(area, "soltar_controle")
		if alvo:
			alvo.soltar_controle()
			break

func tentar_recarregar_estoque():
	var sensor = $AreaInteracao
	var areas = sensor.get_overlapping_areas()
	
	for area in areas:
		var alvos = [area, area.get_parent()]
		for no in alvos:
			if no and no.has_meta("valor_recarga"):
				var qtd = no.get_meta("valor_recarga")
				if municao_player < max_municao:
					municao_player = min(municao_player + int(qtd), max_municao)
					Manager.mudar_a_sprite.emit(municao_player)
					return

func encontrar_script_por_metodo(no_inicial, metodo):
	var atual = no_inicial
	while atual != null:
		if atual.has_method(metodo): 
			return atual
		atual = atual.get_parent()
	return null

func tem_municao() -> bool:
	return municao_player > 0

func gastar_municao():
	if municao_player > 0:
		municao_player -= 1
		Manager.mudar_a_sprite.emit(municao_player)
