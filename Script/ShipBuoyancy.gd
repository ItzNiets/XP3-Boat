extends Node3D
class_name ShipBuoyancy

## Assign the Water node in the inspector
@export var water_node_path: NodePath

## Probe offsets from the ship's center (local space)
## These should match the ship model's waterline extents
@export var probe_bow    := Vector3(0, 0, 6)    # Proa (frente)
@export var probe_stern  := Vector3(0, 0, -6)   # Popa (trás)
@export var probe_port   := Vector3(-2.5, 0, 0) # Bombordo (esquerda)
@export var probe_stbd   := Vector3(2.5, 0, 0)  # Estibordo (direita)

## How fast the ship interpolates to target height (lower = smoother/slower)
@export_range(0.1, 5.0) var float_lerp_speed: float = 1.0
## How fast the ship interpolates rotations (lower = smoother/slower)
@export_range(0.1, 5.0) var rotation_lerp_speed: float = 0.8
## Extra height offset (positive = higher above water)
@export var height_offset: float = 0.0
## Maximum tilt angle in degrees (keep low for gentle rocking)
@export_range(1.0, 30.0) var max_tilt_degrees: float = 5.0

var water: Water

func _ready() -> void:
	if not water_node_path.is_empty():
		water = get_node(water_node_path) as Water
	if not water:
		var found = get_tree().current_scene.find_child("WaterPlane", true, false)
		if found is Water:
			water = found
	if not water:
		push_warning("[ShipBuoyancy] Could not find Water node. Buoyancy disabled.")

func _physics_process(delta: float) -> void:
	if not water:
		return
	
	# Sample wave height at each probe using the ship's CURRENT world position  
	# (not the rotated basis, to avoid feedback loops that amplify motion)
	var center := global_position
	var bow_pos   := center + Vector3(probe_bow.x, 0, probe_bow.z)
	var stern_pos := center + Vector3(probe_stern.x, 0, probe_stern.z)
	var port_pos  := center + Vector3(probe_port.x, 0, probe_port.z)
	var stbd_pos  := center + Vector3(probe_stbd.x, 0, probe_stbd.z)
	
	var h_bow   := water.get_wave_height(bow_pos)
	var h_stern := water.get_wave_height(stern_pos)
	var h_port  := water.get_wave_height(port_pos)
	var h_stbd  := water.get_wave_height(stbd_pos)
	
	# ---- HEIGHT ----
	var avg_h := (h_bow + h_stern + h_port + h_stbd) / 4.0
	var target_y := avg_h + height_offset
	global_position.y = lerpf(global_position.y, target_y, delta * float_lerp_speed)
	
	# ---- TILT ----
	var bow_stern_len := absf(probe_bow.z - probe_stern.z)
	var port_stbd_len := absf(probe_stbd.x - probe_port.x)
	
	# Pitch from bow/stern height difference
	var pitch := atan2(h_stern - h_bow, bow_stern_len)
	# Roll from port/starboard height difference
	var roll := atan2(h_port - h_stbd, port_stbd_len)
	
	var max_rad := deg_to_rad(max_tilt_degrees)
	pitch = clampf(pitch, -max_rad, max_rad)
	roll = clampf(roll, -max_rad, max_rad)
	
	# Smoothly interpolate (uses low speed for gentle rocking)
	var r := rotation
	r.x = lerp_angle(r.x, pitch, delta * rotation_lerp_speed)
	r.z = lerp_angle(r.z, roll, delta * rotation_lerp_speed)
	rotation = r
