extends Node3D
class_name ShipBuoyancy

# --- CONFIGURAÇÕES ---
@export var velocidade_frente = 0.0
const VEL_MAX = 5.0
var angulo_alvo_y = 0.0
const VELOCIDADE_GIRO_SUAVE = 1.0 

@export var vida_navio: int = 100
var water: Water

# --- FLUTUAÇÃO ---
@export var water_node_path: NodePath
@export var probe_bow     := Vector3(0, 0, 6)
@export var probe_stern   := Vector3(0, 0, -6)
@export var probe_port    := Vector3(-2.5, 0, 0)
@export var probe_stbd    := Vector3(2.5, 0, 0)
@export_range(0.1, 5.0) var float_lerp_speed: float = 1.0
@export_range(0.1, 5.0) var rotation_lerp_speed: float = 0.8
@export var height_offset: float = 0.0
@export_range(1.0, 30.0) var max_tilt_degrees: float = 5.0

func _ready() -> void:
	angulo_alvo_y = rotation.y
	if not water_node_path.is_empty():
		water = get_node(water_node_path) as Water
	if not water:
		var found = get_tree().current_scene.find_child("WaterPlane", true, false)
		if found is Water: water = found

func _physics_process(delta: float) -> void:
	if not water: return
	
	# Rotação e Movimento
	rotation.y = lerp_angle(rotation.y, angulo_alvo_y, delta * VELOCIDADE_GIRO_SUAVE)
	var frente_navio = global_transform.basis.z 
	global_translate(frente_navio * velocidade_frente * delta)

	# Lógica de Flutuação
	var center := global_position
	var h_bow := water.get_wave_height(center + (transform.basis.z * probe_bow.z))
	var h_stern := water.get_wave_height(center + (transform.basis.z * probe_stern.z))
	var h_port := water.get_wave_height(center + (transform.basis.x * probe_port.x))
	var h_stbd := water.get_wave_height(center + (transform.basis.x * probe_stbd.x))
	
	var target_y := ((h_bow + h_stern + h_port + h_stbd) / 4.0) + height_offset
	global_position.y = lerpf(global_position.y, target_y, delta * float_lerp_speed)
	
	# Inclinação
	var bow_stern_len := absf(probe_bow.z - probe_stern.z)
	var port_stbd_len := absf(probe_stbd.x - probe_port.x)
	var pitch := clampf(atan2(h_stern - h_bow, bow_stern_len), -deg_to_rad(max_tilt_degrees), deg_to_rad(max_tilt_degrees))
	var roll := clampf(atan2(h_port - h_stbd, port_stbd_len), -deg_to_rad(max_tilt_degrees), deg_to_rad(max_tilt_degrees))
	rotation.x = lerp_angle(rotation.x, pitch, delta * rotation_lerp_speed)
	rotation.z = lerp_angle(rotation.z, roll, delta * rotation_lerp_speed)

# Comandos
func comando_acelerar(): velocidade_frente = VEL_MAX
func comando_parar(): velocidade_frente = 0.0
func comando_virar_fixo(direcao: int): angulo_alvo_y += direcao * (PI / 2.0)

# Dano
func receber_dano_navio(valor):
	vida_navio -= valor
	print("Navio: PERDI VIDA! Vida atual: ", vida_navio)
	if vida_navio <= 0: print("Navio: Afundou!")
