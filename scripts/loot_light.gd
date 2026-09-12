extends Node3D
var materials:Array[ShaderMaterial]=[]
var fill:OmniLight3D
var strength:=1.0
func setup(color:Color,quality:int):
 var height:=2.8+quality*0.65
 for ground in [false,true]:
  var n:=MeshInstance3D.new()
  var mesh:=QuadMesh.new()
  mesh.size=Vector2(1.0+quality*0.15,height) if not ground else Vector2.ONE*(1.2+quality*0.2)
  n.mesh=mesh
  n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  var mat:=ShaderMaterial.new()
  mat.shader=preload("res://shaders/loot_light.gdshader")
  mat.set_shader_parameter("tint",color)
  mat.set_shader_parameter("ground",ground)
  n.material_override=mat
  materials.append(mat)
  n.position.y=height*0.5 if not ground else -0.06
  if ground:n.rotation.x=-PI/2
  add_child(n)
 fill=OmniLight3D.new()
 fill.light_color=color
 fill.omni_range=1.8
 fill.light_energy=0.22
 fill.light_volumetric_fog_energy=0
 fill.position.y=0.25
 add_child(fill)
func advance(dt:float,attracting:bool):
 strength=move_toward(strength,0.0 if attracting else 1.0,dt*7.0)
 for mat in materials:mat.set_shader_parameter("strength",strength)
 fill.light_energy=0.22*strength
