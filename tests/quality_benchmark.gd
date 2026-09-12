extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1280,720)
 root.always_on_top=true
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 g.music.stop()
 g.sound_voices=5
 for e in g.enemies:e.node.hide()
 g.enemies.clear()
 g.room=2
 g.spawn_room()
 g.hero.position=Vector3(14,g.HERO_GROUND_Y,0)
 g.camera.position.x=16.5
 g.camera.look_at(Vector3(16.5,1.3,0))
 g.forest.follow_camera(16.5)
 for i in range(g.enemies.size()):
  var e:Dictionary=g.enemies[i]
  e.node.position=Vector3(15+i%3,e.home.y,-2+(i/3)*1.1)
  e.hp=100000
 g.build=0
 var report:Array=[]
 for mode in range(3):
  g.set_visual_profile(mode,false)
  var samples:Array[float]=[]
  var before:=Time.get_ticks_usec()
  for tick in range(240):
   if tick%30==0:g.resolve_attack(true)
   g.effects.advance(1.0/60,g.hero.position)
   g.build_effects.advance(1.0/60,g.hero.position)
   g.forest.atmosphere.advance(1.0/60,g.hero.position,false)
   g.readability.advance()
   g.update_hud()
   await process_frame
   var now:=Time.get_ticks_usec()
   if tick>=60:samples.append((now-before)/1000.0)
   before=now
  samples.sort()
  var row={"profile":mode,"median_ms":samples[samples.size()/2],"p95_ms":samples[int(samples.size()*0.95)],"max_ms":samples[-1]}
  report.append(row)
  print("QUALITY ",JSON.stringify(row))
  RenderingServer.force_draw(false)
  root.get_texture().get_image().save_png("res://docs/quality-crowd-"+str(mode)+".png")
 var file=FileAccess.open("res://build/verification/quality-benchmark.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"  "))
 for c in g.get_children():
  if c is AudioStreamPlayer:c.stop()
 g.queue_free()
 await process_frame
 await create_timer(0.3).timeout
 quit()
