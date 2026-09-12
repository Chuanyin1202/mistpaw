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
 for e in g.enemies:e.node.position.x=55
 g.take_damage(9)
 g._physics_process(0.02)
 check(g.hp==91 and g.hero.texture.resource_path.ends_with("cat-hurt.png"),"damage shows dedicated reaction")
 var x:float=g.hero.position.x
 var key:=InputEventKey.new()
 key.physical_keycode=KEY_D
 key.pressed=true
 Input.parse_input_event(key)
 Input.flush_buffered_events()
 g._physics_process(0.02)
 check(g.hero.position.x>x,"hurt reaction does not lock movement")
 key=key.duplicate()
 key.pressed=false
 Input.parse_input_event(key)
 Input.flush_buffered_events()
 await capture(view,"hero-hurt")
 g.hp=20
 g._physics_process(0.02)
 check(g.hud.text.contains("危險") and g.damage_edge.material.get_shader_parameter("strength")>0,"low health has clear danger cue")
 await capture(view,"hero-danger")
 g.try_dash()
 g._physics_process(0.02)
 check(g.hero.texture.resource_path.ends_with("cat-rush.png"),"dash immediately overrides reaction")
 g.dash_time=0
 g.invulnerable=0
 g.hero.position.y+=1.5
 g.take_damage(100)
 check(g.ended and g.result_overlay.visible and g.retry_button.has_focus(),"death offers retry immediately")
 g._physics_process(0.15)
 check(g.hero.texture.resource_path.ends_with("cat-fall.png") and g.hero.frame==1,"death begins kneeling sequence")
 g._physics_process(0.3)
 print("DEATH_GROUND frame=",g.hero.frame," y=",g.hero.position.y," target=",g.HERO_GROUND_Y," delta=",g.hero.position.y-g.HERO_GROUND_Y)
 check(g.hero.frame==3 and is_equal_approx(g.hero.position.y,g.HERO_GROUND_Y),"death reaches grounded resting pose")
 check(is_equal_approx(g.hero.position.y+g.hero.get_child(0).position.y,0.14),"airborne death leaves shadow on ground")
 await capture(view,"hero-fallen")
 var at:Vector3=g.hero.position
 g._physics_process(1)
 check(g.hero.position==at and g.hero.frame==3,"finished death stays still")
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
