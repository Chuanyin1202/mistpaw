extends Node3D
const TEXTURES=[preload("res://assets/art/wave-blade.png"),preload("res://assets/art/chain-lightning.png"),preload("res://assets/art/vital-wisp.png"),preload("res://assets/art/blood-ribbon.png")]
var pool:Array[Dictionary]=[]
var cursor:=0
var lights:Array[OmniLight3D]=[]
func _ready():
 for color in [Color("72dfe5"),Color("b48af4"),Color("f8ae62")]:
  var light:=OmniLight3D.new()
  light.light_color=color
  light.omni_range=4.5
  light.light_energy=0
  light.light_volumetric_fog_energy=0.025
  add_child(light)
  lights.append(light)
 for i in range(16):
  var n:=MeshInstance3D.new()
  n.mesh=QuadMesh.new()
  n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  var m:=ShaderMaterial.new()
  m.shader=preload("res://shaders/build_fx.gdshader")
  n.material_override=m
  add_child(n)
  n.hide()
  pool.append({"node":n,"mat":m,"age":1.0,"duration":0.2,"kind":0,"from":Vector3.ZERO,"to":Vector3.ZERO,"facing":1.0,"size":Vector2.ONE,"power":false})
func emit(kind:int,a:Vector3,b:Vector3,facing:float,power:bool=false):
 var fx=pool[cursor]
 cursor=(cursor+1)%pool.size()
 fx.kind=kind
 fx.from=a
 fx.to=b
 fx.facing=facing
 fx.power=power
 fx.age=0.0
 fx.duration=[0.22,0.14,0.30,0.16][kind]
 fx.mat.set_shader_parameter("art",TEXTURES[kind])
 fx.mat.set_shader_parameter("billboard",kind!=1)
 fx.mat.set_shader_parameter("flip",facing<0)
 fx.mat.set_shader_parameter("kind",kind)
 fx.mat.set_shader_parameter("strength",(0.85 if power else 0.42) if kind==3 else (0.95 if kind==2 else (0.75 if power else 0.5)))
 fx.node.show()
 advance_one(fx,get_parent().hero.position)
func advance(dt:float,hero:Vector3):
 for light in lights:light.light_energy=0
 for fx in pool:
  fx.age+=dt
  fx.node.visible=fx.age<fx.duration
  if fx.node.visible:advance_one(fx,hero)
func advance_one(fx:Dictionary,hero:Vector3):
 var t:float=fx.age/fx.duration
 fx.mat.set_shader_parameter("life",t)
 var n:MeshInstance3D=fx.node
 n.basis=Basis.IDENTITY
 if fx.kind==0:
  n.position=fx.from+Vector3(fx.facing*(0.3+t*0.8),-0.4,0.65)
  n.mesh.size=Vector2(3.0,3.5)*(1.25 if fx.power else 1.0)*(1+t*0.12)
 elif fx.kind==1:
  var delta:Vector3=fx.to-fx.from
  n.position=(fx.from+fx.to)*0.5
  if delta.length()>0.01:
   var axis=delta.normalized()
   var up=(get_parent().camera.global_position-n.position).normalized().cross(axis).normalized()
   n.basis=Basis(axis,up,axis.cross(up))
  n.mesh.size=Vector2(maxf(delta.length(),0.01),1.5)
 elif fx.kind==2:
  var destination=hero+Vector3(0,-0.4,1.0)
  n.position=fx.from.lerp(destination,1-pow(1-t,2))+Vector3(0,sin(t*PI)*0.45,0)
  n.mesh.size=Vector2(2.2,1.6)*(1-t*0.45)
  fx.mat.set_shader_parameter("flip",destination.x<fx.from.x)
 else:
  n.position=fx.from+Vector3(fx.facing*1.05,-0.4,0.75)
  n.mesh.size=Vector2(4.8,3.1) if fx.power else Vector2(3.2,2.2)
 var light:OmniLight3D=lights[mini(fx.kind,2)]
 var energy:float=(0.65 if fx.power else 0.26)*(1-t)*(1-t)
 if energy>light.light_energy:
  light.position=n.position+Vector3(0,0.5,0)
  light.light_energy=energy
func clear():
 for light in lights:light.light_energy=0
 for fx in pool:
  fx.age=fx.duration
  fx.node.hide()
