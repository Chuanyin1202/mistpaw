extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(ok:bool,title:String):
 print(("PASS " if ok else "FAIL ")+title)
 if not ok:failures+=1
func key(code:int,down:bool):
 var e:=InputEventKey.new()
 e.physical_keycode=code
 e.pressed=down
 Input.parse_input_event(e)
 Input.flush_buffered_events()
func snap(g,tag:String):
 print("REVIEW/pose ",tag," art=",g.hero.texture.resource_path," frame=",g.hero.frame," pixel=",g.hero.pixel_size," offset=",g.hero.offset," height=",g.jump_height)
 if DisplayServer.get_name()=="headless":return
 g.update_hud()
 await process_frame
 await process_frame
 RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png("res://build/verification/review-"+tag+".png")
func run():
 root.size=Vector2i(1280,720)
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 for e in g.enemies:e.node.hide()
 g.enemies.clear()
 g._physics_process(.01)
 await snap(g,"idle")
 key(KEY_D,true)
 for i in range(10):g._physics_process(.01)
 await snap(g,"walk")
 key(KEY_D,false)
 g._physics_process(.01)
 key(KEY_D,true)
 for i in range(10):g._physics_process(.01)
 await snap(g,"run")
 key(KEY_D,false)
 g._physics_process(.01)
 await snap(g,"stop")
 for power in [false,true]:
  g.start_attack(power)
  for i in range(5):
   for j in range(7):g._physics_process(.01)
   await snap(g,("heavy" if power else "basic")+str(i))
  for i in range(80):g._physics_process(.01)
 g.try_jump()
 for i in range(15):g._physics_process(.01)
 await snap(g,"jump-rise")
 g.try_jump()
 g.try_spin()
 for i in range(12):g._physics_process(.01)
 await snap(g,"air-spin")
 for i in range(100):g._physics_process(.01)
 await snap(g,"land")
 g.invulnerable=0
 g.take_damage(12)
 g._physics_process(.04)
 await snap(g,"hurt")
 for i in range(50):g._physics_process(.01)
 await snap(g,"recover")
 g.room=3
 g.spawn_room()
 for e in g.enemies.duplicate():g.damage_enemy(e,10000)
 print("BUGFIX/final-guide toast=",g.message.text," objective=",g.encounter_flow.objective())
 check(g.message.text.contains("最後戰利品") and not g.message.text.contains("向右"),"boss defeat toast directs player to final loot")
 check(g.encounter_flow.objective().contains("完成試煉"),"defeated boss no longer gives combat instructions")
 g.update_hud()
 check(g.ui.hint.text.contains("最後戰利品"),"HUD agrees with final reward objective")
 await snap(g,"victory-loot")
 g.finish(false)
 g._physics_process(.15)
 await snap(g,"death")
 g.feedback.clear()
 for c in g.get_children():
  if c is AudioStreamPlayer:c.stop()
 await create_timer(.3).timeout
 g.queue_free()
 await process_frame
 quit(1 if failures else 0)
