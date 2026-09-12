extends MeshInstance3D
func _init():
 var quad := QuadMesh.new()
 quad.size=Vector2(20,12)
 mesh=quad
 rotation.x=-PI/2
 cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var mat:=ShaderMaterial.new()
 mat.shader=preload("res://shaders/enemy_telegraph.gdshader")
 material_override=mat
 hide()
func update_for(e:Dictionary):
 var boss=get_parent().boss if e.kind==4 else null
 var pattern:int=boss.pattern if boss!=null else 0
 visible=e.windup>=0 or e.get("pounce_time",-1.0)>=0
 if pattern==2 and boss.active>=0:visible=true
 if not visible:return
 var origin:Vector3=e.node.position
 if pattern==1:origin=boss.origin
 if pattern==2:origin=boss.destination
 if e.kind==1:
  origin=e.pounce_target if e.get("pounce_time",-1.0)>=0 else get_parent().constrain_ground(origin.move_toward(Vector3(e.aim,origin.y,e.aim_z),3))
 position=Vector3(origin.x,0.17,origin.z)
 material_override.set_shader_parameter("aim",Vector2(e.aim-position.x,e.aim_z-position.z))
 material_override.set_shader_parameter("reach",3.0 if e.kind>=3 else 1.45)
 material_override.set_shader_parameter("depth_width",1.1 if e.kind>=3 else 0.7)
 material_override.set_shader_parameter("facing",-1.0 if e.node.flip_h else 1.0)
 material_override.set_shader_parameter("ranged",e.kind==2)
 material_override.set_shader_parameter("pattern",pattern)
 if pattern>0:
  material_override.set_shader_parameter("progress",1.0-clampf(e.windup/boss.windup_length,0,1))
  return
 material_override.set_shader_parameter("progress",1.0-clampf(e.windup/(0.9 if e.kind==4 else e.windup_length),0,1))
