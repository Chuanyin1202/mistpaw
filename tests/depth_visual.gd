extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var view := SubViewport.new()
 view.size = Vector2i(1280,720)
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
 g.camera.position.x=3.5
 g.forest.follow_camera(3.5)
 for z in [-4.0,-0.8,1.1]:
  g.hero.position=Vector3(1,1.87,z)
  g.hero.texture=load("res://assets/art/cat-walk.png")
  g.hero.vframes=2
  g.hero.frame=1
  g.update_hud()
  await capture(view,"depth-%.1f" % z)
 # One real diagonal movement and attack sequence at 60Hz, no recording.
 g.hero.position=Vector3(1,1.87,-2.5)
 var key := InputEventKey.new()
 key.physical_keycode=KEY_D
 key.pressed=true
 Input.parse_input_event(key)
 Input.flush_buffered_events()
 for tick in range(100):
  g._physics_process(1.0/60)
  await process_frame
  if tick in [35,65,95]:await capture(view,"depth-combat-%d" % tick)
 key=InputEventKey.new()
 key.physical_keycode=KEY_D
 key.pressed=false
 Input.parse_input_event(key)
 Input.flush_buffered_events()
 print("DEPTH_VISUAL hp=",g.hp," x=",g.hero.position.x," z=",g.hero.position.z)
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 quit()
func capture(view:SubViewport,name:String):
 await process_frame
 await process_frame
 RenderingServer.force_draw(false)
 view.get_texture().get_image().save_png("res://docs/"+name+".png")
