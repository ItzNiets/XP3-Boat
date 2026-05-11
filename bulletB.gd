extends CharacterBody3D

@export var speed = 20.0 

func _physics_process(_delta):
	# Define a velocidade baseada na direção frontal (Z negativo)
	var direction = global_transform.basis.z
	velocity = direction * speed
	
	move_and_slide()
	
	# Verifica se houve colisão após o movimento
	if get_slide_collision_count() > 0:
		var col = get_slide_collision(0)
		var body = col.get_collider()
		
		# Tenta encontrar a função no próprio objeto ou no pai dele
		if body.has_method("levar_dano"):
			body.levar_dano(1)
			print("Bala: Acertei o corpo!")
		elif body.get_parent() and body.get_parent().has_method("levar_dano"):
			body.get_parent().levar_dano(1)
			print("Bala: Acertei o pai do corpo!")
		else:
			
			print("--- DEBUG DE COLISÃO ---")
			print("Bala bateu em: ", body.name)
			print("Tipo do objeto: ", body.get_class())
			print("Script anexado: ", body.get_script())
			print("Caminho do script: ", body.get_script().resource_path if body.get_script() else "NENHUM SCRIPT")
			print("------------------------")
			
		# Remove a bala após o impacto
		queue_free()
