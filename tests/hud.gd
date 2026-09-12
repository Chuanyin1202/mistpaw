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
 g.hp=72
 g.unlocked.assign([0,1,2])
 g.build=1
 g.skill_cd=1.6
 g.spin_cd=0.8
 g.update_hud()
 await capture(view,"hud-combat")
 view.size=Vector2i(1920,1080)
 await capture(view,"hud-combat-1080")
 view.size=Vector2i(1280,720)
 g.ui.advance(0.01)
 check(g.ui.hp_lag.value>g.health.value,"damage lag shows lost health")
 g.ui.advance(1.0)
 check(g.ui.hp_lag.value==g.hp,"damage lag catches up")
 g.toggle_pause()
 check(g.paused and g.ui.pause_overlay.visible and g.ui.resume_button.has_focus(),"pause menu opens with keyboard focus")
 var elapsed:float=g.elapsed
 g._physics_process(0.5)
 check(g.elapsed==elapsed,"pause menu freezes combat")
 await capture(view,"hud-pause")
 g.ui.resume_button.pressed.emit()
 check(not g.paused and not g.ui.pause_overlay.visible,"resume returns to play")
 g.toggle_mute()
 check(g.muted and AudioServer.is_bus_mute(0),"mute toggle changes audio bus")
 g.toggle_mute()
 g.hp=20
 g.update_hud()
 check(g.hud.text.contains("危險"),"danger communicates beyond color")
 await capture(view,"hud-danger")
 g.invulnerable=0
 g.take_damage(100)
 g._physics_process(0.6)
 await capture(view,"hud-death")
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 print("HUD FAILURES=",failures)
 quit(1 if failures else 0)
func capture(view:SubViewport,name:String):
 if DisplayServer.get_name()=="headless":return
 await process_frame
 await process_frame
 RenderingServer.force_draw(false)
 view.get_texture().get_image().save_png("res://docs/"+name+".png")
