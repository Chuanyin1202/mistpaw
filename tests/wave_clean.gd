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
 g.hero.position=Vector3(14,1.87,0)
 g.camera.position.x=16.5
 g.camera.look_at(Vector3(16.5,1.3,0))
 g.forest.follow_camera(16.5)
 for e in g.enemies:e.node.hide()
 g.update_hud()
 await capture(view,"wave-clean-base")
 var baseline:Image
 if DisplayServer.get_name()!="headless":baseline=view.get_texture().get_image()
 g.build_effects.emit(0,g.hero.position+Vector3(1.5,0,0),Vector3.ZERO,1)
 for light in g.build_effects.lights:light.light_energy=0
 await capture(view,"wave-clean-probe")
 var fx=g.build_effects.pool.filter(func(f):return f.node.visible)[0]
 fx.mat.set_shader_parameter("strength",0.0)
 await capture(view,"wave-zero-strength")
 if baseline:
  var result:=view.get_texture().get_image()
  var difference:=0.0
  for y in range(300,415):
   for x in range(550,635):
    var a:=baseline.get_pixel(x,y)
    var b:=result.get_pixel(x,y)
    difference+=(absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b))*255.0
  difference/=85.0*115.0*3.0
  print("ZERO_STRENGTH_PIXEL_DELTA=",difference)
  check(difference<2.0,"zero-strength additive quad leaves no fog rectangle")
 else:
  print("SKIP pixel regression requires native rendering")
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 print("WAVE FAILURES=",failures)
 quit(1 if failures else 0)
func capture(view:SubViewport,name:String):
 if DisplayServer.get_name()=="headless":return
 await process_frame
 await process_frame
 RenderingServer.force_draw(false)
 view.get_texture().get_image().save_png("res://docs/"+name+".png")
