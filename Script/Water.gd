extends Node3D
class_name Water

## Overall wave height multiplier
@export var overall_height: float = 0.6

## The node that the ocean follows (infinite ocean illusion)
@export var follow_target: NodePath

## ─── LOD Ring Configuration ──────────────────────────────
## Number of concentric rings
@export_range(2, 8) var ring_count: int = 5
## Grid resolution per ring (vertices per side)
@export_range(16, 128) var ring_resolution: int = 64
## Cell size of the innermost ring (metres)
@export_range(0.25, 4.0) var base_cell_size: float = 1.0

var time_passed: float = 0.0
var _material: ShaderMaterial
var _follow_node: Node3D
var _rings: Array[MeshInstance3D] = []

# CPU Gerstner waves — must match shader's FIRST 5 waves for buoyancy
# [dir_x, dir_z, steepness, wavelength]
var _waves: Array[Vector4] = [
	Vector4(1.0,  0.2,   0.06, 12.0),  # Fast primary chop
	Vector4(-0.4, 1.0,   0.05, 9.0),   # Fast cross chop
	Vector4(0.7, -0.6,   0.04, 15.0),  # Medium
	Vector4(-0.6, 0.7,   0.035, 20.0), # Medium swell
	Vector4(0.8,  0.8,   0.04, 7.0),   # Fast ripple
]


func _ready() -> void:
	if not follow_target.is_empty():
		_follow_node = get_node(follow_target) as Node3D

	var shader = load("res://Scenes/water_shader.gdshader") as Shader
	if not shader:
		push_error("[Water] Could not load water_shader.gdshader")
		return

	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("overall_height", overall_height)
	_material.set_shader_parameter("wave_time", 0.0)
	_material.set_shader_parameter("color_deep", Color(0.01, 0.12, 0.35))
	_material.set_shader_parameter("color_mid", Color(0.04, 0.32, 0.58))
	_material.set_shader_parameter("color_shallow", Color(0.1, 0.55, 0.78))
	_material.set_shader_parameter("color_foam", Color(0.9, 0.97, 1.0))
	_material.set_shader_parameter("color_horizon", Color(0.45, 0.7, 0.88))
	_material.set_shader_parameter("metallic", 0.05)
	_material.set_shader_parameter("roughness", 0.12)
	_material.set_shader_parameter("contact_foam_range", 8.0)
	_material.set_shader_parameter("contact_foam_power", 2.5)
	_material.set_shader_parameter("fade_near", 120.0)
	_material.set_shader_parameter("fade_far", 400.0)

	_create_rings()


func _process(delta: float) -> void:
	time_passed += delta

	# Update wave_time on ALL ring materials (they are duplicates, not references)
	for ring in _rings:
		var mat := ring.material_override as ShaderMaterial
		if mat:
			mat.set_shader_parameter("wave_time", time_passed)

	# Follow target — snap each ring to its own grid
	if _follow_node:
		var target_x := _follow_node.global_position.x
		var target_z := _follow_node.global_position.z

		for i in range(_rings.size()):
			var cell := base_cell_size * pow(2.0, i)
			var snap := cell
			var sx := snappedf(target_x, snap)
			var sz := snappedf(target_z, snap)
			_rings[i].global_position = Vector3(sx, 0.0, sz)


## ─── Ring Mesh Generation ────────────────────────────────

func _create_rings() -> void:
	for r in _rings:
		r.queue_free()
	_rings.clear()

	for i in range(ring_count):
		var cell := base_cell_size * pow(2.0, i)
		var half_extent := cell * ring_resolution * 0.5

		var inner_half := 0.0
		if i > 0:
			var prev_cell := base_cell_size * pow(2.0, i - 1)
			inner_half = prev_cell * ring_resolution * 0.5

		var mesh := _generate_ring_mesh(ring_resolution, cell, half_extent, inner_half)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		var mat := _material.duplicate() as ShaderMaterial
		mat.set_shader_parameter("cell_size", cell)
		mi.material_override = mat

		mi.name = "WaterRing_%d" % i
		add_child(mi)
		_rings.append(mi)


func _generate_ring_mesh(res: int, cell: float, half_ext: float, inner_half: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()

	var vert_count := (res + 1) * (res + 1)
	vertices.resize(vert_count)
	normals.resize(vert_count)

	for iz in range(res + 1):
		for ix in range(res + 1):
			var idx := iz * (res + 1) + ix
			var x := -half_ext + ix * cell
			var z := -half_ext + iz * cell
			vertices[idx] = Vector3(x, 0.0, z)
			normals[idx] = Vector3(0, 1, 0)

	for iz in range(res):
		for ix in range(res):
			var quad_min_x := -half_ext + ix * cell
			var quad_max_x := quad_min_x + cell
			var quad_min_z := -half_ext + iz * cell
			var quad_max_z := quad_min_z + cell

			if inner_half > 0.0:
				if quad_min_x >= -inner_half and quad_max_x <= inner_half \
				   and quad_min_z >= -inner_half and quad_max_z <= inner_half:
					continue

			var tl := iz * (res + 1) + ix
			var top_right := tl + 1
			var bl := (iz + 1) * (res + 1) + ix
			var br := bl + 1

			indices.append(tl)
			indices.append(bl)
			indices.append(top_right)

			indices.append(top_right)
			indices.append(bl)
			indices.append(br)

	var arr_mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	return arr_mesh


# ===============================================
# CPU Gerstner — mirrors shader vertex math
# ===============================================
func _gerstner_height(dir: Vector2, steepness: float, wavelength: float, pos: Vector2, t: float) -> float:
	var d := dir.normalized()
	var k := TAU / wavelength
	var c := sqrt(9.8 / k)
	var f := k * (d.dot(pos) - c * t)
	var a := steepness / k
	return a * sin(f)

func get_wave_height(world_pos: Vector3) -> float:
	var pos := Vector2(world_pos.x, world_pos.z)
	var h := 0.0
	for w in _waves:
		h += _gerstner_height(Vector2(w.x, w.y), w.z, w.w, pos, time_passed)
	h *= overall_height
	return h + global_position.y
