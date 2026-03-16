import os

scene_path = r"c:\Users\Rafael Alves\Documents\xp-3---boat\Scenes\styl_ship_unity.tscn"

with open(scene_path, 'r') as f:
    content = f.read()

# Add the script ext_resource
script_ext = '[ext_resource type="Script" path="res://Script/ShipBuoyancy.gd" id="X_script"]\n'
first_ext_idx = content.find('[ext_resource')
if first_ext_idx != -1:
    content = content[:first_ext_idx] + script_ext + content[first_ext_idx:]

# Attach to root node
root_node_str = '[node name="StylShip_Unity" unique_id=587510060 instance=ExtResource("1_vmyh8")]\n'
new_root_node_str = '[node name="StylShip_Unity" unique_id=587510060 instance=ExtResource("1_vmyh8")]\nscript = ExtResource("X_script")\n'

content = content.replace(root_node_str, new_root_node_str)

with open(scene_path, 'w') as f:
    f.write(content)

print("Buoyancy script attached to styl_ship_unity.tscn")
