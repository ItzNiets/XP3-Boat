extends Node3D
@export var bullet_config: PackedScene 
@onready var spawn_point = $Canhao/SpawnPointB  

# --- VARIÁVEIS DE ESTADO ---
var esta_operando = false
var player_referencia = null

# --- CONFIGURAÇÕES DE GIRO ---
var velocidade_giro = 2.0
var angulo_atual = 90.0   # Começa no ângulo que ele está no editor
var limite_esq = 30.0     # 90 - 60
var limite_dir = 150.0    # 90 + 60

func _process(_delta):
	# SÓ ENTRA AQUI SE O PLAYER ESTIVER NO CONTROLE
	if esta_operando:

		var direcao = 0
		if Input.is_key_pressed(KEY_LEFT): direcao += 1 
		if Input.is_key_pressed(KEY_RIGHT): direcao -= 1
		
		angulo_atual += direcao * velocidade_giro
		# Agora o limite respeita a posição original de 90 graus
		angulo_atual = clamp(angulo_atual, limite_esq, limite_dir)
		rotation_degrees.y = angulo_atual
		
		# SÓ ATIRA SE O PLAYER ESTIVER OPERANDO E APERTAR A TECLA
		# Use "ui_accept" para a tecla Enter
		if Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER):
			if Input.is_action_just_pressed("ui_accept"): 
				atirar()

func atirar():
	# Verifica se temos a cena da bala e munição no player
	if bullet_config and player_referencia:
		if player_referencia.tem_municao():
			var nova_bala = bullet_config.instantiate()
			
			# Adiciona a bala na raiz da cena para ela não girar junto com o canhão depois de sair
			get_tree().root.add_child(nova_bala)
			
			nova_bala.global_transform = spawn_point.global_transform
			
			player_referencia.gastar_municao()
		else:
			print("Canhão: Sem munição!")

# --- FUNÇÕES DE CONTROLE (Chamadas pelo Pirata) ---

func assumir_controle(player):
	esta_operando = true
	player_referencia = player
	print("Canhão: Player assumiu o controle.")

func soltar_controle():
	esta_operando = false
	player_referencia = null
	print("Canhão: Player soltou o controle.")
