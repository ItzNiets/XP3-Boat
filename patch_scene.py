import os
import re

project_dir = r"c:\Users\Rafael Alves\Documents\xp-3---boat"
textures_dir = os.path.join(project_dir, "Stylized_Pirate_Ship", "StylShip_MatTextures")
scene_path = os.path.join(project_dir, "Scenes", "styl_ship_unity.tscn")

materials_data = {
    "Elements": {
        "albedo": "uid://d2cv3sn37y3lf",
        "ao": "uid://bq5717jepntmi",
        "metallic": "uid://dx5d0w5qs27k5",
        "normal": "uid://bf0gny0o1i0uv",
        "tex_path": "StylShip_Elements_{}.png"
    },
    "ShipHull": {
        "albedo": "uid://bd05fockp6yhy",
        "ao": "uid://dy3swofapv6hi",
        "metallic": "uid://cefnxvqtbgpjo",
        "normal": "uid://detvi5r1la7ge",
        "tex_path": "StylShip_ShipHull_{}.png"
    },
    "Decks": {
        "albedo": "uid://y66ocyr68qo2",
        "ao": "uid://c0x403sr01hhy",
        "metallic": "uid://c4ppcaxpk5cdh",
        "normal": "uid://dpdotw4xre0k4",
        "tex_path": "StylShip_Decks_{}.png"
    },
    "Masts": {
        "albedo": "uid://dgojrylr5cr6o",
        "ao": "uid://ddhqmjr6bsglg",
        "metallic": "uid://cabylmcyjdenv",
        "normal": "uid://opnds4qkkxm",
        "tex_path": "StylShip_Masts_{}.png"
    },
    "SailsRope": {
        "albedo": "uid://skag34cbcv0r",
        "ao": "uid://daq5mkurbqoao",
        "metallic": "uid://b75n358vj0fc3",
        "normal": "uid://csoo08tgbopb0",
        "emissive": "uid://wq2531sw0352",
        "tex_path": "StylShip_SailsRope_{}.png"
    },
    "Props": {
        "albedo": "uid://0ddw8g480f0b",
        "ao": "uid://dsv8mjpvaha5t",
        "metallic": "uid://da8johrsivehv",
        "normal": "uid://dy5j453oa7yqq",
        "tex_path": "StylShip_Props_{}.png"
    }
}

# Generate .tres files
for mat_name, data in materials_data.items():
    tres_path = os.path.join(textures_dir, f"{mat_name}.tres")
    res_str = f"""[gd_resource type="StandardMaterial3D" load_steps=6 format=3 uid="uid://mat_{mat_name.lower()}"]\n\n"""
    
    ext_id = 1
    maps = {
        "albedo": "AlbedoTransparency",
        "ao": "AmbientOcclusion",
        "metallic": "MetallicSmoothness",
        "normal": "NormalOpenGL",
        "emissive": "Emissive"
    }
    
    for key in ["albedo", "ao", "metallic", "normal", "emissive"]:
        if key in data:
            uid = data[key]
            tex_file = data["tex_path"].format(maps[key])
            res_str += f"""[ext_resource type="Texture2D" uid="{uid}" path="res://Stylized_Pirate_Ship/StylShip_MatTextures/{tex_file}" id="{ext_id}_{key}"]\n"""
            ext_id += 1
            
    res_str += "\n[resource]\n"
    res_str += """albedo_texture = ExtResource("1_albedo")\n"""
    res_str += """metallic = 1.0\n"""
    res_str += """metallic_texture = ExtResource("3_metallic")\n"""
    res_str += """roughness = 1.0\n"""
    res_str += """normal_enabled = true\n"""
    res_str += """normal_texture = ExtResource("4_normal")\n"""
    res_str += """ao_enabled = true\n"""
    res_str += """ao_texture = ExtResource("2_ao")\n"""
    
    if "emissive" in data:
        res_str += """emission_enabled = true\n"""
        res_str += """emission_texture = ExtResource("5_emissive")\n"""
        
    with open(tres_path, "w") as f:
        f.write(res_str)


# Now read the scene file, remove all SubResource materials, and map nodes to our new .tres ExtResources
with open(scene_path, "r") as f:
    scene_data = f.read()

# Map the original Albedo UIDs to our new Mat name
original_albedo_to_mat = {
    "uid://d2cv3sn37y3lf": "Elements",
    "uid://bd05fockp6yhy": "ShipHull",
    "uid://y66ocyr68qo2": "Decks",
    "uid://dgojrylr5cr6o": "Masts",
    "uid://skag34cbcv0r": "SailsRope",
    "uid://0ddw8g480f0b": "Props"
}

# 1. Parse ext_resources from scene
ext_resource_pattern = re.compile(r'\[ext_resource .*?uid="(.*?)".*?id="(.*?)"\]')
ext_resources = ext_resource_pattern.findall(scene_data)
albedo_id_to_mat = {}
for uid, res_id in ext_resources:
    if uid in original_albedo_to_mat:
        albedo_id_to_mat[res_id] = original_albedo_to_mat[uid]

# 2. Add our new ExtResources to the top
new_ext_resources = []
for mat_name in materials_data.keys():
    new_ext_resources.append(f'[ext_resource type="Material" uid="uid://mat_{mat_name.lower()}" path="res://Stylized_Pirate_Ship/StylShip_MatTextures/{mat_name}.tres" id="mat_{mat_name}"]')

# Insert them after the existing ext_resources
last_ext_idx = scene_data.rfind('[ext_resource')
end_of_last_ext = scene_data.find(']', last_ext_idx) + 1
scene_data = scene_data[:end_of_last_ext] + "\n" + "\n".join(new_ext_resources) + scene_data[end_of_last_ext:]


# 3. Parse sub_resources to see which sub_resource corresponds to which albedo texture
sub_resource_pattern = re.compile(r'\[sub_resource type="StandardMaterial3D" id="(.*?)"\]\nalbedo_texture = ExtResource\("(.*?)"\)')
sub_resources = sub_resource_pattern.findall(scene_data)
sub_id_to_mat = {}
for sub_id, albedo_id in sub_resources:
    if albedo_id in albedo_id_to_mat:
        sub_id_to_mat[sub_id] = albedo_id_to_mat[albedo_id]

# Remove all sub_resources from the scene data
scene_data = re.sub(r'\[sub_resource type="StandardMaterial3D" id=".*?"\]\nalbedo_texture = ExtResource\(".*?"\)\n*', '', scene_data)

# 4. Replace material_override in nodes
for sub_id, mat_name in sub_id_to_mat.items():
    scene_data = scene_data.replace(f'material_override = SubResource("{sub_id}")', f'material_override = ExtResource("mat_{mat_name}")')

with open(scene_path, "w") as f:
    f.write(scene_data)

print("Scene patched and materials created!")
