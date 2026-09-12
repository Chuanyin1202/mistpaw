extends Node3D
## One encounter's distinct verbs. Claw still uses the shared enemy contact path.
const CHARGE=preload("res://assets/art/boss-charge.png")
const LEAP=preload("res://assets/art/boss-leap.png")
var game:Node3D
var posture:=0.0
var stunned:=0.0
var break_lock:=0.0
var posture_quiet:=0.0
var pattern:=0
var previous_pattern:=-1
var phase:=1
var follow_up:=false
var next_attack:=-1
var fracture:MeshInstance3D
var active:=-1.0
var roar:=-1.0
var windup_length:=0.9
var origin:=Vector3.ZERO
var destination:=Vector3.ZERO
var charge_hit:=false
var ring:MeshInstance3D
var light:OmniLight3D
var debris:Array[Sprite3D]=[]
var land_age:=-1.0
var land_point:=Vector3.ZERO
var land_damaging:=false
var ring_hit:=false

func _ready():
 game=get_parent()
 ring=MeshInstance3D.new()
 ring.mesh=QuadMesh.new()
 ring.mesh.size=Vector2(10,10)
 ring.rotation.x=-PI/2
 ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 ring.material_override=ShaderMaterial.new()
 ring.material_override.shader=preload("res://shaders/boss_ground_wave.gdshader")
 add_child(ring)
 ring.hide()
 fracture=MeshInstance3D.new()
 fracture.mesh=QuadMesh.new()
 fracture.mesh.size=Vector2(10,10)
 fracture.rotation.x=-PI/2
 fracture.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 fracture.material_override=ShaderMaterial.new()
 fracture.material_override.shader=preload("res://shaders/boss_fracture.gdshader")
 add_child(fracture)
 fracture.hide()
 light=OmniLight3D.new()
 light.light_color=Color("ffbb68")
 light.omni_range=5
 light.light_energy=0
 light.light_volumetric_fog_energy=0
 add_child(light)
 for i in range(16):
  var stone:=Sprite3D.new()
  stone.texture=preload("res://assets/art/stone-flight.png")
  stone.hframes=2
  stone.vframes=2
  stone.pixel_size=0.005+float(i%3)*0.0015
  stone.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
  stone.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  add_child(stone)
  stone.hide()
  debris.append(stone)

func begin(e:Dictionary,chosen:int=-1,chained:bool=false):
 follow_up=chained
 next_attack=-1
 var distance:float=game.ground_distance(e.node.position,game.hero.position)
 pattern=chosen
 if pattern<0:
  pattern=2 if previous_pattern==0 else (1 if previous_pattern==2 else 0)
  if distance>4.5:pattern=2 if previous_pattern==1 else 1
 previous_pattern=pattern
 origin=e.node.position
 var target:Vector3=game.hero.position
 target.y=origin.y
 var direction:=origin.direction_to(target)
 if direction.length()<0.01:direction=Vector3.LEFT
 destination=game.constrain_ground(origin+direction*minf(distance+2.0,7.0)) if pattern==1 else game.constrain_ground(target)
 e.aim=destination.x
 e.aim_z=destination.z
 e.node.flip_h=destination.x<origin.x
 windup_length=0.72 if pattern==1 else (0.85 if pattern==2 else 0.9)
 e.windup=windup_length
 e.clock=0.0
 active=-1.0
 charge_hit=false

func advance(e:Dictionary,dt:float)->bool:
 var n:Sprite3D=e.node
 break_lock=maxf(0,break_lock-dt)
 posture_quiet+=dt
 if posture_quiet>3.0:posture=maxf(0,posture-dt*8)
 if stunned<=0 and posture>=100 and active<0 and roar<0 and not wave_pending():break_guard(e)
 if stunned>0:
  stunned=maxf(0,stunned-dt)
  e.clock=0
  e.windup=-1.0
  e.recovery=0.0
  n.texture=game.ENEMY_FALL_TEXTURES[4]
  n.frame=0
  n.offset=Vector2(sin(stunned*20)*1.5,-4)
  e.label.text="破防 · 暈厥"
  e.label.modulate=Color("ffe1a0")
  e.marker.hide()
  if stunned==0:
   e.recovery=0.35
   break_lock=5.0
  return true
 if next_attack>=0 and e.recovery<=0 and e.windup<0 and active<0:
  var chosen:=0 if game.ground_distance(n.position,game.hero.position)<3.6 else 2
  begin(e,chosen,true)
  e.marker.update_for(e)
  n.texture=LEAP if chosen==2 else game.ENEMY_ATTACK_TEXTURES[4]
  n.frame=0
  return true
 if phase==1 and e.hp<=e.max_hp*0.5 and e.windup<0 and e.recovery<=0 and active<0:
  phase=2
  roar=0.0
  game.toast("妖王狂怒 · 躍擊後有震波，跳躍避開",3.0)
  game.sound("boss-rage.wav",-3)
 if roar>=0:
  roar+=dt
  n.texture=LEAP
  n.frame=1 if roar<0.65 else 3
  e.label.text="狂怒 · 留意震波"
  e.label.modulate=Color("ffb474")
  e.marker.hide()
  light.position=n.position
  light.light_energy=sin(clampf(roar/0.9,0,1)*PI)*0.85
  if roar>=0.9:
   roar=-1
   begin(e,2)
  return true
 if pattern==0:return false
 n.texture=CHARGE if pattern==1 else LEAP
 n.flip_h=destination.x<origin.x
 e.label.text="衝撞 · 側移繞背" if pattern==1 else "躍擊 · 離開落點"
 e.label.modulate=Color("ffb474")
 if e.windup>=0:
  e.windup-=dt
  n.frame=0
  e.marker.update_for(e)
  if e.windup<=0:
   e.windup=-1
   active=0
   game.sound("boss-charge.wav" if pattern==1 else "wave-air.wav",-4,1.0 if pattern==1 else 0.9)
 elif active>=0:
  var before:Vector3=n.position
  active+=dt
  var t:=minf(active/(0.38 if pattern==1 else 0.46),1)
  n.position=origin.lerp(destination,t)
  if pattern==1:
   n.frame=1+int(active*18)%2
   var a:=Vector2(before.x,before.z)
   var b:=Vector2(n.position.x,n.position.z)
   var hero_at:=Vector2(game.hero.position.x,game.hero.position.z)
   var closest:=Geometry2D.get_closest_point_to_segment(hero_at,a,b)
   if not charge_hit and hero_at.distance_to(closest)<=0.85 and game.jump_height<1.6:
    game.take_damage(22)
    charge_hit=true
    if game.ended:return true
  else:
   n.frame=1
   n.position.y+=sin(t*PI)*2.8
  if t>=1:
   active=-1
   n.frame=2 if pattern==2 else 3
   e.recovery=(1.85 if phase==2 else 1.0) if pattern==2 else (0.6 if phase==2 else 0.85)
   e.clock=0
   if pattern==2:
    if game.ground_distance(game.hero.position,destination)<=2.2 and game.jump_height<1.9:
     game.take_damage(26)
     if game.ended:return true
    land(destination,phase==2)
   else:
    game.sound("stone-contact.wav",-9,0.75)
    if phase==2 and not follow_up:next_attack=0
  e.marker.update_for(e)
 elif e.recovery>0:
  n.frame=2 if pattern==2 and e.recovery>0.5 else 3
  e.label.text=recovery_hint()
  e.label.modulate=Color("ffb474") if wave_pending() or next_attack>=0 else Color("d7e4b9")
  e.marker.hide()
 else:
  pattern=0
  e.label.text=""
  return false
 n.get_child(0).position.y=-n.position.y+0.14
 n.get_child(0).scale=Vector3.ONE*(1.0-minf((n.position.y-e.home.y)*0.1,0.3))
 return true

func land(at:Vector3,damaging:bool):
 game.forest.atmosphere.disturb(at,2.0)
 land_point=Vector3(at.x,0.19,at.z)
 land_age=0
 land_damaging=damaging
 ring_hit=false
 game.camera.v_offset=0.035
 game.sound("boss-fracture.wav",-2)

func advance_effects(dt:float):
 game.camera.v_offset=move_toward(game.camera.v_offset,0,dt*0.3)
 if roar<0:light.light_energy=move_toward(light.light_energy,0,dt*4)
 if land_age<0:return
 var before:=land_age
 land_age+=dt
 fracture.visible=land_age<2.4
 fracture.position=land_point+Vector3(0,0.012,0)
 fracture.material_override.set_shader_parameter("age",land_age)
 fracture.material_override.set_shader_parameter("ground_back",game.Forest.road_back(land_point.x))
 var delayed:=land_damaging and land_age>=0.65
 var warning:=land_damaging and land_age>0.2 and not delayed
 var radius:=clampf((land_age-0.65)/0.65,0,1)*4.2 if delayed else (4.2 if warning else minf(land_age*10,2.2))
 ring.visible=land_age<1.3 if land_damaging else land_age<0.3
 ring.position=land_point
 ring.material_override.set_shader_parameter("ground_back",game.Forest.road_back(land_point.x))
 ring.material_override.set_shader_parameter("radius",radius)
 ring.material_override.set_shader_parameter("strength",1.0 if delayed else (0.22 if warning else maxf(0,1-land_age/0.3)))
 ring.material_override.set_shader_parameter("danger",delayed or warning)
 if delayed and before<0.65:game.sound("wave-air.wav",-8,0.6)
 if delayed and not ring_hit:
  var old_radius:=clampf((before-0.65)/0.65,0,1)*4.2
  var d:float=game.ground_distance(game.hero.position,land_point)
  if d>=old_radius-0.3 and d<=radius+0.3 and game.jump_height<0.7:
   game.take_damage(14)
   ring_hit=true
   if game.ended:return
 for i in range(debris.size()):
  var stone:=debris[i]
  stone.visible=land_age<0.85
  if stone.visible:
   var a:=float(i)*2.399963
   stone.position=land_point+Vector3(cos(a)*land_age*(2.0+i%4),maxf(0,sin(land_age/0.85*PI))*(0.65+(i%3)*0.25),sin(a)*land_age*2.5)
   stone.modulate.a=1.0-smoothstep(0.55,0.85,land_age)
   stone.frame=int(land_age*18+i)%4
 if land_age<0.18:
  light.position=land_point+Vector3(0,1.2,0)
  light.light_energy=(1-land_age/0.18)*0.65
 if land_age>2.5:land_age=-1

func clear():
 posture=0
 stunned=0
 break_lock=0
 posture_quiet=0
 next_attack=-1
 follow_up=false
 game.camera.v_offset=0
 fracture.hide()
 land_age=-1
 active=-1
 roar=-1
 ring.hide()
 light.light_energy=0
 for stone in debris:stone.hide()

func wave_pending()->bool:
 return land_damaging and land_age>=0 and land_age<1.3
func recovery_hint()->String:
 if wave_pending():return "震波將至 · Space 跳躍" if land_age<0.65 else "震波擴散 · 保持騰空"
 return "追擊蓄勢 · 留意下一招" if next_attack>=0 else "收勢 · K 重劈反擊"

func guarding(e:Dictionary)->bool:
 # Recovery and a committed attack leave the back open; there is no damage immunity.
 if stunned>0 or e.recovery>0 or roar>=0:return false
 var front:float=-1.0 if e.node.flip_h else 1.0
 return (game.hero.position.x-e.node.position.x)*front>=-0.35

func hit_posture(e:Dictionary,impact:float):
 if stunned>0 or break_lock>0:return
 posture_quiet=0
 var pressure:float=28 if impact>=2.5 else (12 if impact>=1.6 else 6)
 posture=minf(100,posture+pressure*(0.5 if guarding(e) else 1.0))

func break_guard(e:Dictionary):
 posture=0
 stunned=1.6
 next_attack=-1
 follow_up=false
 pattern=0
 active=-1
 e.windup=-1.0
 e.recovery=0.0
 e.recoil=0.0
 e.clock=0
 e.marker.hide()
 game.feedback.guard_age=1
 game.effects.impact(e.node.position+Vector3(0,0,0.8),3.5)
 game.sound("boss-fracture.wav",-4,1.3)
 game.toast("妖王破防 · 趁暈厥全力反擊",1.6)

func posture_hint()->String:
 if stunned>0:return "破防暈厥 · 全力反擊"
 if break_lock>0:return "架勢重整"
 return "即將破防 · K 重劈" if posture>=70 else ("架勢鬆動" if posture>=35 else "架勢穩固")
