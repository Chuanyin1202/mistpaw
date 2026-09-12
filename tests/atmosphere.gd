extends SceneTree
var failures:=0
func check(ok:bool,s:String):
 print(("PASS " if ok else "FAIL ")+s)
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
 var a=g.forest.atmosphere
 a.clear()
 a.disturb(Vector3(15,0,0),1)
 check(a.particles.filter(func(p):return p.node.visible).all(func(p):return not p.leaf),"stone bridge produces dust without forest leaves")
 a.clear()
 a.disturb(Vector3(4,0,0),1)
 check(a.particles.any(func(p):return p.node.visible and p.leaf),"forest impact lifts leaves")
 a.clear()
 a.reactions_enabled=false
 a.disturb(Vector3.ZERO,2)
 check(a.particles.all(func(p):return not p.node.visible),"reaction effects can be independently disabled")
 a.reactions_enabled=true
 a.ambient_enabled=false
 a.disturb(Vector3.ZERO,2)
 for i in range(90):a.advance(1.0/60,g.hero.position,false)
 check(a.particles.all(func(p):return not p.node.visible),"impact particles fully expire")
 for i in range(30):a.disturb(Vector3.ZERO,2)
 check(a.particles.size()==72 and a.get_child_count()==74,"repeated effects cannot grow allocation budget")
 var age:float=a.particles[0].age
 g.paused=true
 g._physics_process(0.2)
 check(a.particles[0].age==age,"pause freezes environment reactions")
 g.paused=false
 g.update_hud()
 g.help.get_parent().hide()
 g.message.hide()
 a.clear()
 a.ambient_enabled=true
 g.hero.position.x=15
 g.camera.position.x=17.5
 g.forest.follow_camera(17.5)
 for e in g.enemies:e.node.hide()
 g.ui.world_text.hide()
 for i in range(360):
  a.advance(1.0/60,g.hero.position,false)
  if DisplayServer.get_name()!="headless":await process_frame
 check(a.particles.any(func(p):return p.ambient and p.node.visible),"ambient particles spawn with bounded cadence")
 if DisplayServer.get_name()!="headless":
  RenderingServer.force_draw(false)
  view.get_texture().get_image().save_png("res://docs/atmosphere-lake.png")
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 quit(1 if failures else 0)
