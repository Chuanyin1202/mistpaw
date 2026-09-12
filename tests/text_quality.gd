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
 var e=g.enemies[0]
 e.node.show()
 e.node.position=Vector3(16,e.home.y,0)
 e.label.text="投石！"
 e.label.show()
 print("TEXT_PROBE alpha_cut=",e.label.alpha_cut," font_size=",e.label.font_size," filter=",e.label.texture_filter)
 g.floating("17",Vector3(14,3.5,0),Color.WHITE)
 g.floating("44",Vector3(16,3.5,0),Color("ffd278"))
 check(e.label.layers==0 and e.label.screen!=null,"world text uses projected smooth typography")
 await capture(view,"text-final")
 await process_frame
 await process_frame
 check(e.label.screen.visible and e.label.screen.text.contains("投石"),"telegraph text projects visibly")
 var before:Vector2=e.label.screen.position
 e.node.position.x+=1
 await process_frame
 check(e.label.screen.position.x>before.x,"text follows world position")
 var numbers:Array=[]
 for i in range(8):numbers.append(g.floating(str(20+i),Vector3(15,3.5,0),Color.WHITE))
 await process_frame
 await process_frame
 var separated:=true
 for i in range(numbers.size()):
  for j in range(i+1,numbers.size()):
   var a:Rect2=numbers[i].screen.get_rect()
   var b:Rect2=numbers[j].screen.get_rect()
   if a.intersects(b):separated=false
 check(separated,"eight simultaneous damage numbers avoid each other")
 await capture(view,"text-crowd-final")
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 print("TEXT FAILURES=",failures)
 quit(1 if failures else 0)
func capture(view:SubViewport,name:String):
 if DisplayServer.get_name()=="headless":return
 await process_frame
 await process_frame
 RenderingServer.force_draw(false)
 view.get_texture().get_image().save_png("res://docs/"+name+".png")
