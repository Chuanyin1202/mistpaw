extends SceneTree
var failures:=0
func check(ok:bool,s:String):
 print(("PASS " if ok else "FAIL ")+s)
 if not ok:failures+=1
func arm(g,e):
 e.node.position=Vector3(0,e.home.y,0)
 e.windup=0.01
 e.aim=2
 e.aim_z=0
 e.recoil=0
 e.stagger=0
 e.recovery=0
 e.pounce_time=-1.0
 g.hero.position=Vector3(2,g.HERO_GROUND_Y,0)
 g.hp=100
 g.invulnerable=0
 g.update_enemy(e,0.01)
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 g.music.stop()
 g.sound_voices=5
 for old in g.enemies:old.node.hide()
 g.enemies.clear()
 var e:Dictionary=g.enemy_pools[1][1]
 e.node.show()
 g.enemies.append(e)
 arm(g,e)
 check(e.node.position.x==0 and g.hp==100,"takeoff neither teleports nor hits early")
 g.update_enemy(e,0.12)
 check(e.node.position.x>0.9 and e.node.position.x<1.1 and e.node.position.y>e.home.y+0.5,"pounce travels through airborne midpoint")
 check(g.hp==100 and e.marker.visible,"flight keeps warning without early damage")
 if DisplayServer.get_name()!="headless":
  await process_frame
  RenderingServer.force_draw(false)
  root.get_texture().get_image().save_png("res://docs/weasel-pounce-midpoint.png")
 g.update_enemy(e,0.12)
 check(g.hp==91 and e.recovery>0 and is_equal_approx(e.node.position.y,e.home.y),"landing hits once and opens recovery")
 g.update_enemy(e,0.1)
 check(g.hp==91,"recovery does not hit again")
 arm(g,e)
 var locked:Vector3=e.pounce_target
 g.hero.position.z=1.0
 g.update_enemy(e,0.24)
 check(e.pounce_target==locked and g.hp==100,"sidestep avoids locked landing")
 arm(g,e)
 g.damage_enemy(e,1,2.6)
 g.update_enemy(e,0.01)
 check(e.pounce_time<0 and g.hp==100,"heavy stagger cancels pending pounce damage")
 arm(g,e)
 var pos:Vector3=e.node.position
 g.paused=true
 g._physics_process(0.12)
 check(e.node.position==pos,"pause freezes pounce")
 g.paused=false
 g.enemies.clear()
 var toad:Dictionary=g.enemy_pools[1][2]
 g.enemies.append(toad)
 toad.node.position=Vector3(2,toad.home.y,0)
 toad.retreat_left=1.2
 g.hero.position=Vector3(0,g.HERO_GROUND_Y,0)
 for i in range(240):
  toad.clock=-100
  g.update_enemy(toad,1.0/60)
 check(toad.node.position.x<3.25 and toad.retreat_left==0,"isolated toad stops retreating after budget")
 # A pending pounce landing near a new bite's contact postpones the bite.
 g.enemies.clear()
 var rat:Dictionary=g.enemy_pools[0][0]
 g.enemies.append(rat)
 g.enemies.append(e)
 rat.node.position=Vector3(1,rat.home.y,0)
 rat.clock=10
 rat.windup=-1
 rat.recovery=0
 rat.stagger=0
 e.node.position=Vector3(4,e.home.y,0)
 e.windup=0.21
 e.pounce_time=-1.0
 g.last_enemy_telegraph=-10
 g.update_enemy(rat,0.001)
 check(rat.windup<0,"bite waits when pounce contact would coincide")
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 quit(1 if failures else 0)
