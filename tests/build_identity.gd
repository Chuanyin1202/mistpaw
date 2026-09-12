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
 g.sound_voices=5
 for e in g.enemies:e.node.hide()
 var actors=g.enemies.slice(0,3)
 g.enemies.clear()
 for e in actors:g.enemies.append(e)
 for build in range(3):
  g.effects.clear()
  g.build_effects.clear()
  g.build=build
  g.hp=50
  g.hero.position=Vector3(0,1.87,0)
  g.facing=1
  for i in range(3):
   var e=actors[i]
   e.hp=1000
   e.node.show()
   e.node.position=Vector3(2+i*1.5,e.home.y,0 if i==0 else -1.3)
  g.resolve_attack(false)
  var active=g.build_effects.pool.filter(func(f):return f.node.visible)
  check(not active.is_empty() and active.all(func(f):return f.kind==build or (build==2 and f.kind==3)),"distinct active effect for build "+str(build))
  if build==0:check(actors[0].hp==983,"shockwave preserves base hit damage")
  if build==1:
   check(active.size()==2 and actors[1].hp==991 and actors[2].hp==991,"lightning jumps twice into off-lane neighbours")
   check(active[0].from.distance_to(actors[0].node.position+Vector3(0,-0.25,0.7))<0.01,"lightning originates on struck enemy")
   check(active[1].from==active[0].to,"second lightning begins where first ends")
  if build==2:
   check(is_equal_approx(g.hp,50+15.3*0.06),"lifesteal restores six percent of actual sword damage once")
   g.build_effects.advance(0.12,g.hero.position)
   var wisp=active.filter(func(f):return f.kind==2)[0]
   var before:Vector3=wisp.node.position
   g.hero.position.x=-0.5
   g.build_effects.advance(0.05,g.hero.position)
   check(wisp.node.position.distance_to(g.hero.position)<before.distance_to(g.hero.position),"wisp follows moving hero")
  g.update_hud()
  await capture(view,"build-"+str(build))
  var age:float=active[0].age
  g.paused=true
  g._physics_process(0.5)
  check(active[0].age==age,"pause freezes build effect "+str(build))
  g.paused=false
  g.build_effects.advance(1,g.hero.position)
  check(g.build_effects.pool.all(func(f):return not f.node.visible),"build effects expire "+str(build))
 g.hp=50
 actors[0].hp=1
 g.hero.position=Vector3(0,1.87,0)
 g.resolve_attack(false)
 check(is_equal_approx(g.hp,50.06),"overkill on a one-health enemy heals only actual damage")
 g.hp=50
 for e in actors.slice(1):
  e.node.position=Vector3(2,e.home.y,0)
  e.hp=1000
 g.resolve_attack(true)
 check(is_equal_approx(g.hp,50+39.6*2*0.06),"heavy hits heal proportionally across real targets")
 g.build_effects.clear()
 g.hp=100
 g.resolve_attack(false)
 check(g.build_effects.pool.all(func(f):return not f.node.visible or f.kind==3),"full health has slash but no false healing wisp")
 g.build_effects.emit(0,g.hero.position,Vector3.ZERO,1)
 g.finish(false)
 check(g.build_effects.pool.all(func(f):return not f.node.visible),"death clears build effects")
 for c in g.get_children():
  if c is AudioStreamPlayer:c.stop()
 await create_timer(0.3).timeout
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 print("BUILD FAILURES=",failures)
 quit(1 if failures else 0)
func capture(view:SubViewport,name:String):
 if DisplayServer.get_name()=="headless":return
 await process_frame
 await process_frame
 RenderingServer.force_draw(false)
 view.get_texture().get_image().save_png("res://docs/"+name+".png")
