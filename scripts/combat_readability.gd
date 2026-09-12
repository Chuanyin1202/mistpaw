extends Node3D
var silhouette:Sprite3D
var key_light:OmniLight3D
func _ready():
 var g=get_parent()
 g.hero.layers=5
 key_light=OmniLight3D.new()
 key_light.light_cull_mask=4
 key_light.light_color=Color("c4dce3")
 key_light.light_energy=0.32
 key_light.omni_range=5
 key_light.light_volumetric_fog_energy=0
 add_child(key_light)
 silhouette=Sprite3D.new()
 silhouette.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 silhouette.pixel_size=g.hero.pixel_size
 silhouette.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
 silhouette.shaded=false
 silhouette.no_depth_test=true
 silhouette.modulate=Color(0.65,0.87,0.91,0.40)
 silhouette.render_priority=10
 add_child(silhouette)
 silhouette.hide()
func advance():
 var g=get_parent()
 key_light.position=g.hero.position+Vector3(-1,1,2)
 var blockers=g.enemies.filter(func(e):return e.node.position.z>=g.hero.position.z-0.12 and e.node.position.y<g.hero.position.y+2.0 and absf(e.node.position.x-g.hero.position.x)<(2.6 if e.kind==4 else (1.9 if e.kind>=3 else 1.15)))
 silhouette.visible=not g.ended and not blockers.is_empty()
 if not silhouette.visible:return
 silhouette.modulate=Color(1.0,0.95,0.83,0.65) if blockers.any(func(e):return e.kind==4) else Color(0.65,0.87,0.91,0.40)
 silhouette.position=g.hero.position
 silhouette.pixel_size=g.hero.pixel_size
 silhouette.texture=g.hero.texture
 silhouette.hframes=g.hero.hframes
 silhouette.vframes=g.hero.vframes
 silhouette.frame=g.hero.frame
 silhouette.offset=g.hero.offset
 silhouette.flip_h=g.hero.flip_h

func _process(_dt: float):
 var g=get_parent()
 if not g.ready_for_play:return
 var occupied:Array[Rect2]=[]
 for pool in g.enemy_pools:
  for e in pool:
   var bar:Control=e.bar
   var anchor:Vector3=e.node.position+Vector3(0,1.15,0.8)
   bar.visible=not g.ended and e in g.enemies and e.kind<4 and e.node.visible and not g.camera.is_position_behind(anchor) and (e.hp<e.max_hp or e.windup>=0 or g.ground_distance(e.node.position,g.hero.position)<5)
   if not bar.visible:continue
   var point:Vector2=g.camera.unproject_position(anchor)
   bar.size=Vector2(72 if e.kind==3 else 58,7)
   var rect:=Rect2((point-bar.size*0.5).round(),bar.size)
   # Separate close health bars without changing actor or hitbox placement.
   for attempt in range(8):
    if not occupied.any(func(other):return other.grow(2).intersects(rect)):break
    rect.position.y-=10
   bar.position=rect.position
   occupied.append(rect)

 g.ui.text_obstacles=occupied
