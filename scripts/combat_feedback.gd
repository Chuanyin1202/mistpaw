extends Node3D
## Bounded audiovisual feedback; never advances or freezes combat simulation.
var voices:Dictionary={}
var guard:MeshInstance3D
var halo:MeshInstance3D
var guard_age:=1.0
var heal_age:=1.0
var heavy_age:=1.0
var reject_lock:=0.0
var guard_lock:=0.0
var heavy_direction:=1.0
var guard_target:Node3D
func _ready():
 for name in ["heavy","swing","chain","crackle","guard","reject"]:
  var voice:=AudioStreamPlayer.new()
  voice.bus="SFX"
  add_child(voice)
  voices[name]=voice
 for healing in [false,true]:
  var node:=MeshInstance3D.new()
  node.mesh=QuadMesh.new()
  node.mesh.size=Vector2(1.5,1.6) if healing else Vector2(2.2,2.8)
  node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  var mat:=ShaderMaterial.new()
  mat.shader=preload("res://shaders/feedback_ring.gdshader")
  mat.set_shader_parameter("healing",healing)
  node.material_override=mat
  add_child(node)
  node.hide()
  if healing:halo=node
  else:guard=node
func play(name:String,stream:AudioStream,volume:float,pitch:float=1.0):
 var voice:AudioStreamPlayer=voices[name]
 voice.stream=stream
 voice.volume_db=volume
 voice.pitch_scale=pitch
 voice.play()
func reject_heavy():
 if reject_lock>0:return
 reject_lock=0.18
 play("reject",preload("res://assets/audio/cooldown-tick.wav"),-4)
 get_parent().ui.slots[1].tile.reject()
func swing():
 play("swing",preload("res://assets/audio/wave-air.wav"),-5,0.82)
func heavy_hit(facing:float):
 heavy_age=0
 heavy_direction=facing
 play("heavy",preload("res://assets/audio/blade-weight.wav"),2,0.83)
func chain(power:bool):
 play("chain",preload("res://assets/audio/chain-snap.wav"),0 if power else -1)
 play("crackle",preload("res://assets/audio/lightning-crack.wav"),-1 if power else -3,0.9 if power else 1.1)
func blocked(target:Node3D):
 guard_target=target
 guard_age=0
 if guard_lock>0:return
 guard_lock=0.30
 play("guard",preload("res://assets/audio/guard-clink.wav"),-2)
 get_parent().floating("架勢抵擋",target.position+Vector3(0,1.5,0),Color("a8dcff"))
func heal():
 heal_age=0
func advance(dt:float):
 var g=get_parent()
 reject_lock=maxf(0,reject_lock-dt)
 guard_lock=maxf(0,guard_lock-dt)
 heavy_age+=dt
 heal_age+=dt
 guard_age+=dt
 # Short directional camera impulse, independent of boss vertical shake.
 g.camera.h_offset=heavy_direction*0.14*sin(heavy_age/0.16*TAU)*pow(1-clampf(heavy_age/0.16,0,1),2) if heavy_age<0.16 else 0
 halo.visible=heal_age<0.42
 if halo.visible:
  halo.position=g.hero.position+Vector3(0,1.15,0.4)
  halo.material_override.set_shader_parameter("age",heal_age/0.42)
 guard.visible=guard_age<0.22 and is_instance_valid(guard_target) and guard_target.visible
 if guard.visible:
  var front:float=-1 if guard_target.flip_h else 1
  guard.position=guard_target.position+Vector3(front*0.85,0,0.8)
  guard.material_override.set_shader_parameter("facing",front)
  guard.material_override.set_shader_parameter("age",guard_age/0.22)
func clear():
 heavy_age=1
 heal_age=1
 guard_age=1
 get_parent().camera.h_offset=0
 guard.hide()
 halo.hide()
 for voice in voices.values():voice.stop()
