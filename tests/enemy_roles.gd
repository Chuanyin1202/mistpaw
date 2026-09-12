extends SceneTree
var failures:=0
func check(ok:bool,title:String):
 print(("PASS " if ok else "FAIL ")+title)
 if not ok:failures+=1
func _initialize():call_deferred("run")
func run():
 var view:=SubViewport.new()
 view.size=Vector2i(1280,720)
 view.own_world_3d=true
 view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(view)
 var g=load("res://scenes/main.tscn").instantiate()
 view.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 g.music.stop()
 for e in g.enemies:e.node.hide()
 g.enemies.clear()
 var rat:Dictionary=g.enemy_pools[0][0]
 var weasel:Dictionary=g.enemy_pools[1][1]
 var toad:Dictionary=g.enemy_pools[1][2]
 g.hero.position=Vector3(0,g.HERO_GROUND_Y,0)
 for e in [rat,weasel,toad]:
  e.node.show()
  e.node.position=Vector3(1.5,e.home.y,0)
  e.clock=10
  g.enemies.append(e)
 g.update_enemy(rat,0.001)
 g.update_enemy(weasel,0.001)
 check(rat.windup>0 and weasel.windup<0,"ready enemies do not start warnings together")
 g.elapsed+=0.21
 g.update_enemy(weasel,0.001)
 check(weasel.windup>rat.windup,"pounce has longer anticipation than bite")
 var aim:float=weasel.aim
 g.hero.position.x=-1
 g.update_enemy(weasel,0.1)
 check(weasel.aim==aim,"pounce warning keeps its locked target")
 g.enemies.erase(rat)
 g.enemies.erase(weasel)
 toad.clock=0
 var before:float=g.ground_distance(toad.node.position,g.hero.position)
 g.update_enemy(toad,0.1)
 check(g.ground_distance(toad.node.position,g.hero.position)>before,"close player forces ranged toad to retreat")
 g.enemies.erase(rat)
 g.enemies.erase(weasel)
 toad.node.position=Vector3(5,toad.home.y,0)
 toad.clock=10
 g.elapsed+=1
 g.update_enemy(toad,0.01)
 check(toad.windup>0 and is_equal_approx(toad.windup,0.85),"toad telegraphs at firing distance")
 var shots:int=g.shots.size()
 g.update_enemy(toad,0.4)
 check(g.shots.size()==shots,"toad cannot release projectile early")
 g.update_enemy(toad,0.46)
 check(g.shots.size()==shots+1 and toad.recovery>0.5,"projectile release leaves punishable recovery")
 g.enemies.clear()
 for e in [rat,weasel,toad]:
  g.enemies.append(e)
  e.node.position=Vector3(2,e.home.y,0)
  e.windup=-1
  e.recovery=0
  e.clock=0
  e.hp=e.max_hp*0.5
  g.update_enemy(e,0)
 g.readability._process(0)
 check(rat.label.text=="" and rat.bar.ratio==0.5,"half-health enemy uses bar instead of numeric HP")
 check(rat.bar.trail>rat.bar.ratio,"damage leaves brief trailing health segment")
 check(not rat.bar.get_rect().intersects(weasel.bar.get_rect()),"overlapping enemies have separated health bars")
 var trail:float=rat.bar.trail
 g.paused=true
 g._physics_process(1)
 check(rat.bar.trail==trail,"pause freezes trailing health animation")
 check(not g.ui.world_text.visible,"pause hides combat overlays behind menu")
 g.paused=false
 g.update_hud()
 g.update_enemy(rat,0.7)
 check(is_equal_approx(rat.bar.trail,0.5),"health trail catches actual remaining health")
 await process_frame
 await process_frame
 if DisplayServer.get_name()!="headless":
  RenderingServer.force_draw(false)
  view.get_texture().get_image().save_png("res://docs/enemy-health-bars.png")
 g.damage_enemy(rat,1000)
 check(not rat.bar.visible,"lethal damage immediately hides enemy health bar")
 g.finish(false)
 g.readability._process(0)
 check(not toad.bar.visible,"end screen hides enemy health bars")
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 print("ENEMY ROLES FAILURES=",failures)
 quit(1 if failures else 0)
