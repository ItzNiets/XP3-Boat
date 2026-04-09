extends Node3D

@export var bullet_config: PackedScene 
@onready var spawn_point = $Canhao/SpawnPointB  

# --- VARIÁVEIS DE ESTADO ---
var esta_operando = false
var player_referencia = null

# --- CONFIGURAÇÕES DE GIRO HORIZONTAL (Y) ---
var velocidade_giro = 2.0
var angulo_h = 90.0   # Ângulo inicial (ajuste conforme seu editor)
var limite_esq = 30.0    
var limite_dir = 150.0   

# --- CONFIGURAÇÕES DE INCLINAÇÃO VERTICAL (X) ---
var angulo_v = 0.0     # Começa reto (0 graus)
var velocidade_inclinacao = 1.5
var limite_cima = 25.0  # Máximo para o céu
var limite_baixo = -10.0 # Máximo para o mar

func _process(_delta):
	# SÓ ENTRA AQUI SE O PLAYER ESTIVER NO CONTROLE
	if esta_operando:

		# --- CONTROLE HORIZONTAL (Esquerda/Direita) ---
		var dir_h = 0
		if Input.is_key_pressed(KEY_LEFT): dir_h += 1 
		if Input.is_key_pressed(KEY_RIGHT): dir_h -= 1
		
		angulo_h += dir_h * velocidade_giro
		angulo_h = clamp(angulo_h, limite_esq, limite_dir)
		rotation_degrees.y = angulo_h
		
		# --- CONTROLE VERTICAL (Cima/Baixo) ---
		var dir_v = 0
		if Input.is_key_pressed(KEY_UP): dir_v += 1   # Sobe
		if Input.is_key_pressed(KEY_DOWN): dir_v -= 1 # Desce
		
		angulo_v += dir_v * velocidade_inclinacao
		angulo_v = clamp(angulo_v, limite_baixo, limite_cima)
		rotation_degrees.x = angulo_v
		
		# --- LÓGICA DE TIRO ---
		if Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER):
			if Input.is_action_just_pressed("ui_accept"): 
				atirar()

func atirar():
	if bullet_config and player_referencia:
		if player_referencia.tem_municao():
			var nova_bala = bullet_config.instantiate()
			
			# Adiciona na raiz para a física da bala ser independente do canhão
			get_tree().root.add_child(nova_bala)
			
			# O SpawnPointB já carrega a rotação X e Y do canhão
			nova_bala.global_transform = spawn_point.global_transform
			
			player_referencia.gastar_municao()
		else:
			print("Canhão: Sem munição!")


func assumir_controle(player):
	esta_operando = true
	player_referencia = player
	print("Canhão B: Player assumiu o controle.")

func soltar_controle():
	esta_operando = false
	player_referencia = null
	print("Canhão B: Player soltou o controle.")
