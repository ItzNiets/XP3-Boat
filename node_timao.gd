extends Node3D

func assumir_controle(player):
	var ponto_controle = get_node_or_null("StaticBody3D/Marker3D")
	
	if ponto_controle and player:
		player.global_position = ponto_controle.global_position
		
	#CORREÇÃO DA ROTAÇÃO (O pirata está em -180 graus é necesario fazer esse ajuste para ele n ficar de cabeça pra baixo)
		var rotacao_marker = ponto_controle.global_rotation
		
		# Se o seu pirata fica "em pé" em 180 graus no Z, usamos PI.
		player.global_rotation = Vector3(0.0, rotacao_marker.y, PI)
		
		if player is CharacterBody3D:
			player.velocity = Vector3.ZERO
		
		print("Pirata posicionado com correção de 180 graus!")
	
	if get_parent() and get_parent().has_method("comando_acelerar"):
		player.navio_referencia = get_parent()
