extends Node3D
## Cosmetic particles share the combat clock and a fixed allocation budget.
var particles:Array[Dictionary]=[]
var mist_layers:Array[FogVolume]=[]
var time:=0.0
var cursor:=0
var ambient_clock:=0.0
var stride_distance:=0.0
var previous:=Vector3.ZERO
var initialized:=false
var ambient_enabled:=true
var reactions_enabled:=true
var rng:=RandomNumberGenerator.new()
func _ready():
 rng.seed=71423
 if RenderingServer.get_current_rendering_method() == "forward_plus":
  for x in [12.0,21.0]:
   var fog:=FogVolume.new()
   fog.size=Vector3(9,1.0,5)
   fog.position=Vector3(x,-2.9,-3)
   var mat:=FogMaterial.new()
   mat.density=0.018
   mat.albedo=Color("93aca9")
   fog.material=mat
   add_child(fog)
   mist_layers.append(fog)
 var quad:=QuadMesh.new()
 quad.size=Vector2.ONE
 for i in range(72):
  var n:=MeshInstance3D.new()
  n.mesh=quad
  n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  var mat:=ShaderMaterial.new()
  mat.shader=preload("res://shaders/forest_particle.gdshader")
  n.material_override=mat
  add_child(n)
  n.hide()
  particles.append({"node":n,"mat":mat,"age":0.0,"life":1.0,"velocity":Vector3.ZERO,"leaf":false,"ambient":false,"size":0.1})
func emit(at:Vector3,velocity:Vector3,leaf:bool,ambient:bool,life:float,size:float):
 var p:Dictionary=particles[cursor]
 cursor=(cursor+1)%particles.size()
 p.age=0.0
 p.life=life
 p.velocity=velocity
 p.leaf=leaf
 p.ambient=ambient
 p.size=size
 p.node.position=at
 p.node.rotation=Vector3(-0.25,0,rng.randf_range(-PI,PI) if leaf else 0)
 p.node.scale=Vector3.ONE*size
 p.mat.set_shader_parameter("leaf",leaf)
 p.mat.set_shader_parameter("tint",Color(0.62,0.48+rng.randf()*0.14,0.22,0.8) if leaf else (Color(0.94,0.85,0.64,0.65) if ambient else Color(0.55,0.52,0.42,0.35)))
 p.mat.set_shader_parameter("opacity",0.0)
 p.node.show()
func disturb(at:Vector3,strength:float):
 if not reactions_enabled:return
 var forest_floor:=at.x<8 or at.x>23
 for i in range(int(4+strength*5)):
  var leaf:=forest_floor and i%3==0
  var direction:=Vector3(rng.randf_range(-1,1),rng.randf_range(0.5,1.4),rng.randf_range(-0.5,0.5))
  emit(Vector3(at.x,0.24,at.z),direction*strength,leaf,false,0.55+rng.randf()*0.45,0.15 if leaf else 0.28+strength*0.15)
func advance(dt:float,hero:Vector3,running:bool):
 time+=dt
 for i in range(mist_layers.size()):
  mist_layers[i].position.z=-3+sin(time*0.12+i)*0.5
  mist_layers[i].visible=ambient_enabled and get_parent().environment.volumetric_fog_enabled
 if not initialized:previous=hero;initialized=true
 var travelled:=Vector2(hero.x-previous.x,hero.z-previous.z).length()
 if running and travelled<1.0:
  stride_distance+=travelled
  if stride_distance>1.0:
   disturb(hero,0.35)
   stride_distance=0.0
 else:stride_distance=0.0
 previous=hero
 ambient_clock+=dt
 if ambient_enabled and ambient_clock>0.24:
  ambient_clock=0.0
  var x:=hero.x+rng.randf_range(-8,10)
  var leaf:= (x<8 or x>23) and rng.randf()<0.45
  emit(Vector3(x,rng.randf_range(2,6),rng.randf_range(-5,0)),Vector3(0.18,-0.3 if leaf else 0.02,0.04),leaf,true,6.0,0.17 if leaf else 0.045)
 for p in particles:
  if not p.node.visible:continue
  p.age+=dt
  if p.age>=p.life:
   p.node.hide()
   continue
  if not p.ambient:p.velocity.y-=dt*2.5
  p.node.position+=p.velocity*dt
  p.node.position.y=maxf(0.20,p.node.position.y)
  if p.leaf:
   p.node.rotation.z+=dt*1.4
   p.node.position.x+=sin(p.age*4.0)*dt*0.13
  elif not p.ambient:p.node.scale=Vector3.ONE*p.size*(1+p.age*1.5)
  var fade:=sin(PI*clampf(p.age/p.life,0,1))
  p.mat.set_shader_parameter("opacity",fade)
func clear():
 for p in particles:p.node.hide()
