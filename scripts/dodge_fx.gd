extends Node3D
## 固定池殘影與氣流；只讀身法狀態，不改碰撞或無敵時間。
var ghosts:Array[Dictionary]=[]
var cursor:=0
var clock:=0.0
var travelling:=false
var wake:MeshInstance3D
var wake_material:ShaderMaterial
func _ready():
 for i in range(5):
  var n:=Sprite3D.new()
  n.billboard=BaseMaterial3D.BILLBOARD_ENABLED
  n.shaded=false
  n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  n.no_depth_test=false
  add_child(n)
  n.hide()
  ghosts.append({"node":n,"age":1.0})
 wake=MeshInstance3D.new()
 wake.mesh=QuadMesh.new()
 wake.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 wake_material=ShaderMaterial.new()
 wake_material.shader=preload("res://shaders/dodge_wake.gdshader")
 wake.material_override=wake_material
 add_child(wake)
 wake.hide()
func advance(dt:float,g):
 for ghost in ghosts:
  ghost.age+=dt
  ghost.node.visible=ghost.age<0.16
  if ghost.node.visible:ghost.node.modulate=Color(0.48,0.88,0.91,0.36*pow(1-ghost.age/0.16,2))
 var active:bool=g.dash_time>0
 if travelling and not active and g.jump_height<0.25:
  g.forest.atmosphere.disturb(g.hero.position,0.65)
 travelling=active
 wake.visible=active
 if not active:
  clock=0
  return
 clock-=dt
 if clock<=0:
  clock=0.035
  var ghost=ghosts[cursor]
  cursor=(cursor+1)%ghosts.size()
  var n:Sprite3D=ghost.node
  ghost.age=0
  n.texture=g.hero.texture
  n.hframes=g.hero.hframes
  n.vframes=g.hero.vframes
  n.frame=g.hero.frame
  n.pixel_size=g.hero.pixel_size
  n.flip_h=g.hero.flip_h
  n.offset=g.hero.offset
  n.position=g.hero.position
  n.modulate=Color(0.48,0.88,0.91,0.36)
  n.show()
 var axis:=Vector3(g.dash_direction.x,0,g.dash_direction.y)
 wake.position=g.hero.position-axis*0.85+Vector3(0,-0.35,0)
 var up:Vector3=(g.camera.global_position-wake.position).normalized().cross(axis).normalized()
 wake.basis=Basis(axis,up,axis.cross(up))
 wake.mesh.size=Vector2(3.4,1.8)
 wake_material.set_shader_parameter("phase",1-g.dash_time/g.DASH_DURATION)
func clear():
 travelling=false
 clock=0
 wake.hide()
 for ghost in ghosts:
  ghost.age=1
  ghost.node.hide()
