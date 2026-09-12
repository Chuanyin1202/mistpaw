extends Node3D
## Hand-placed river terraces. No collision: the existing bridge lane owns traversal.
var rng := RandomNumberGenerator.new()
var rock_material: ShaderMaterial
func _ready():
 rng.seed = 428
 rock_material = ShaderMaterial.new()
 rock_material.shader = preload("res://shaders/moss_rock.gdshader")
 rock_material.set_shader_parameter("rock_texture",preload("res://assets/art/forest-strata.png"))
 rock_material.set_shader_parameter("moss_texture",preload("res://assets/art/forest-floor.png"))
 # Far banks converge behind the bridge, preserving a central water channel.
 for side in [-1,1]:
  for tier in range(2 if side < 0 else 3):
   var x: float = 15+side*(11.5-tier*1.5 if side < 0 else 10.5-tier*1.1)
   rock(Vector3(x,-2.8+tier*1.15,(-12.0-tier*3.0 if side < 0 else -11.0-tier*2.4)),Vector3(9.5-tier*0.8,2.0,6.0))
  # Low, irregular waterline shelves connect the bridge abutments to the lake.
  for i in range(4):
   rock(Vector3(15+side*(7.7+i*2.2),-3.3+rng.randf_range(-0.12,0.15),3.0+rng.randf_range(-0.5,0.6)),Vector3(2.6,1.1,1.8))
 # Two dark foreground silhouettes frame the water without covering the lane.
 rock(Vector3(3,-3.2,7.8),Vector3(3.1,1.7,2.0))
 rock(Vector3(28,-3.2,8.5),Vector3(4.2,1.9,2.4))
func rock(at: Vector3, size: Vector3):
 var vertices: Array[Vector3] = []
 var count := 16
 for ring in range(2):
  for i in range(count):
   var angle := TAU*float(i)/count
   var radius := rng.randf_range(0.82,1.17)*(1.0 if ring==0 else 0.83)
   vertices.append(Vector3(cos(angle)*size.x*0.5*radius,(ring-0.5)*size.y+rng.randf_range(-0.12,0.12),sin(angle)*size.z*0.5*radius))
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(count):
  var j := (i+1)%count
  for index in [i,j,i+count,j,j+count,i+count]: surface.add_vertex(vertices[index])
  for v in [Vector3(0,size.y*0.5,0),vertices[i+count],vertices[j+count]]: surface.add_vertex(v)
 surface.generate_normals()
 var mesh := MeshInstance3D.new()
 mesh.mesh = surface.commit()
 mesh.material_override = rock_material
 mesh.position = at
 add_child(mesh)
