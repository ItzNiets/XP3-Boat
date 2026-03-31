extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var usando_canhao = false


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

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
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

func interagir_com_objetos():
	var sensor = $AreaInteracao
	var areas = sensor.get_overlapping_areas()
	for area in areas:
		var alvo = encontrar_script_por_metodo(area, "assumir_controle")
		if alvo:
			alvo.assumir_controle(self)
			usando_canhao = true
			return

func tentar_recarregar_estoque():
	var sensor = $AreaInteracao
	var areas = sensor.get_overlapping_areas()
	
	for area in areas:
		var alvos = [area, area.get_parent()]
		for no in alvos:
			if no and no.has_meta("valor_recarga"):
				var qtd = no.get_meta("valor_recarga")
				
				if municao_player < max_municao:
					municao_player += int(qtd)
					
					if municao_player > max_municao: 
						municao_player = max_municao
					
					# --- ESSA É A LINHA QUE ATUALIZA A TELA ---
					Manager.mudar_a_sprite.emit(municao_player)
					# ------------------------------------------
					
					print("Munição Atual: ", municao_player, "/", max_municao)
					return
				else:
					print("Munição já está cheia!")
func sair_do_canhao():
	usando_canhao = false
	var sensor = $AreaInteracao
	for area in sensor.get_overlapping_areas():
		var alvo = encontrar_script_por_metodo(area, "soltar_controle")
		if alvo:
			alvo.soltar_controle()
			return

func encontrar_script_por_metodo(no_inicial, metodo): #Serve pra acar o scrip no pai e no avo
	var atual = no_inicial
	while atual != null:
		if atual.has_method(metodo): return atual
		atual = atual.get_parent()
	return null

func tem_municao() -> bool:
	return municao_player > 0

func gastar_municao():
	if municao_player > 0:
		municao_player -= 1
		Manager.mudar_a_sprite.emit(municao_player)
		
		

		
