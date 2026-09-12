extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 var original:int=g.visual_profile
 g.toggle_pause()
 g.ui.quality_button.pressed.emit()
 var selected:int=g.visual_profile
 var hp:float=g.hp
 g._physics_process(1)
 var paused_ok:bool=g.hp==hp and g.paused
 for c in g.get_children():
  if c is AudioStreamPlayer:c.stop()
 g.queue_free()
 await process_frame
 var next=load("res://scenes/main.tscn").instantiate()
 root.add_child(next)
 await process_frame
 if not next.ready_for_play:await next.boot_finished
 next.set_physics_process(false)
 var restored:bool=next.visual_profile==selected and next.ui.quality_button.text.contains(["精緻","均衡","清晰"][selected])
 var rendering:bool=next.forest.environment.ssr_enabled==(selected==0)
 next.set_visual_profile(original)
 print(("PASS " if paused_ok else "FAIL ")+"quality button changes profile while game stays paused")
 print(("PASS " if restored else "FAIL ")+"restarting restores selected profile and menu caption")
 print(("PASS " if rendering else "FAIL ")+"restored profile applies to renderer")
 for c in next.get_children():
  if c is AudioStreamPlayer:c.stop()
 next.queue_free()
 await process_frame
 await create_timer(0.3).timeout
 quit(0 if paused_ok and restored and rendering else 1)
