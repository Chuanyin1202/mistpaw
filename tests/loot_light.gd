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
 for quality in range(3):
  g.spawn_drop(Vector3(12+quality*3,0,0),quality)
  var d=g.drops[-1].node
  check(d.get_child(1).materials.size()==2,"beam and ground glow for quality "+str(quality))
  check(d.get_child(0).alpha_cut==SpriteBase3D.ALPHA_CUT_DISCARD,"icon transparent pixels discarded")
 await capture(view,"loot-light-after")
 g.paused=true
 g._physics_process(0.5)
 check(g.drops[0].age==0 and g.drops[0].node.get_child(1).strength==1,"pause freezes loot presentation")
 g.paused=false
 for drop in g.drops:
  var glow=drop.node.get_child(1)
  glow.advance(0.2,true)
  check(glow.strength==0 and glow.fill.light_energy==0,"light retracts during attraction")
 await capture(view,"loot-light-retracted")
 var before:int=g.pickups
 for i in range(180):g.update_loot(1.0/60.0)
 check(g.pickups==before+3 and g.drops.is_empty(),"all three items collected exactly once")
 g.update_loot(1.0)
 check(g.pickups==before+3,"no repeated rewards")
 for c in g.get_children():
  if c is AudioStreamPlayer:c.stop()
 await create_timer(0.3).timeout
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 print("LOOT LIGHT FAILURES=",failures)
 quit(1 if failures else 0)
func capture(view:SubViewport,name:String):
 if DisplayServer.get_name()=="headless":return
 await process_frame
 await process_frame
 RenderingServer.force_draw(false)
 view.get_texture().get_image().save_png("res://docs/"+name+".png")
