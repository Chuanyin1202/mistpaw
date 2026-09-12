extends SceneTree
var failures := 0
func check(ok: bool, title: String):
 print(("PASS " if ok else "FAIL ")+title)
 if not ok: failures += 1
func key(g, code: Key, down: bool, repeat_event := false):
 var held := InputEventKey.new()
 held.physical_keycode=code
 held.pressed=down
 held.echo=repeat_event
 Input.parse_input_event(held)
 Input.flush_buffered_events()
 if down:
  var event := InputEventKey.new()
  event.physical_keycode=code
  event.pressed=true
  event.echo=repeat_event
  g._unhandled_key_input(event)
func step(g, ticks: int):
 for i in range(ticks):g._physics_process(1.0/60)
func reset(g):
 for code in [KEY_A,KEY_D,KEY_W,KEY_S]:key(g,code,false)
 g.hero.position=Vector3(0,1.87,0)
 g.facing=1
 g.last_direction_time=-1
 g.run_direction=0
 g.backstep_time=0
 g.backstep_pose_time=0
 g.locomotion_depth=0
 g.backstep_cd=0
 g.dash_time=0
 g.dash_cd=0
 g.invulnerable=0
 g.jump_height=0
 g.jump_velocity=0
 g.jumps_used=0
 g.attack_time=-1
 g.spin_time=-1
func _initialize():call_deferred("run")
func run():
 var view := SubViewport.new()
 view.size=Vector2i(1280,720)
 view.own_world_3d=true
 view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(view)
 var g=load("res://scenes/main.tscn").instantiate()
 view.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 g.set_process_unhandled_key_input(false)
 g.music.stop()
 g.sound_voices=5
 for e in g.enemies:e.node.position.x=55
 reset(g)
 key(g,KEY_D,true)
 step(g,3)
 check(g.run_direction==0 and g.hero.position.x>0,"single forward press walks immediately")
 key(g,KEY_D,true,true)
 check(g.run_direction==0,"key repeat cannot activate running")
 key(g,KEY_D,false)
 step(g,2)
 key(g,KEY_D,true)
 var x: float=g.hero.position.x
 step(g,10)
 check(g.run_direction==1 and absf(g.hero.position.x-x-1.2)<0.01,"forward double press runs at 7.2 units per second")
 check(g.dash_cd==0 and g.invulnerable==0,"running has neither dash cooldown nor invulnerability")
 var gait={}
 for i in range(22):
  step(g,1)
  gait[g.hero.frame]=true
 print("RUN POSE offset=",g.hero.offset," frames=",gait.size())
 check(g.hero.vframes==2 and gait.size()==4,"running uses the restored four-frame gait")
 check(g.hero.offset==Vector2.ZERO,"grounded running does not float independently of its drawn feet")
 await capture(view,"run-trial")
 key(g,KEY_D,false)
 step(g,1)
 check(g.run_direction==0,"releasing direction ends running")
 var stopped_at:Vector3=g.hero.position
 var stopped_offset:Vector2=g.hero.offset
 step(g,6)
 check(g.hero.position.is_equal_approx(stopped_at) and g.hero.offset==stopped_offset and g.hero.offset.x==0,"release stops the visible body without residual sliding")
 reset(g)
 key(g,KEY_A,true)
 step(g,3)
 check(g.hero.position.x<0 and g.facing==-1 and g.hero.flip_h,"first reverse press moves and turns immediately")
 key(g,KEY_A,false)
 step(g,2)
 key(g,KEY_A,true)
 check(g.run_direction==-1 and g.backstep_time==0,"reverse double press runs instead of triggering a backstep")
 g.try_backstep(1)
 x=g.hero.position.x
 key(g,KEY_A,false)
 var flips := 0
 for i in range(10):
  step(g,1)
  if g.facing!=1 or g.hero.flip_h:flips+=1
 check(flips==0 and g.jump_height>0,"backstep holds original facing throughout hop")
 check(g.invulnerable==0 and g.jumps_used==0 and g.dash_cd==0,"backstep grants no invulnerability and consumes no jump or dash charge")
 await capture(view,"backstep-trial")
 var hp: float=g.hp
 g.take_damage(9)
 check(g.hp==hp-9,"backstep remains vulnerable to damage")
 step(g,10)
 check(absf(g.hero.position.x-x+2.34)<0.03 and g.jump_height==0,"backstep lands after a short 2.34 unit retreat")
 g.try_backstep(1)
 check(g.backstep_time==0,"backstep cooldown rejects immediate repeat")
 reset(g)
 key(g,KEY_A,true)
 step(g,12)
 check(g.facing==-1 and g.backstep_time==0,"holding reverse keeps movement facing")
 reset(g)
 g.facing=-1
 key(g,KEY_D,true)
 step(g,3)
 key(g,KEY_D,false)
 key(g,KEY_D,true)
 g.try_backstep(-1)
 check(g.backstep_time>0 and g.facing==-1,"unbound legacy backstep remains symmetric")
 g.try_dash()
 check(g.backstep_time==0 and g.dash_time>0 and g.invulnerable>0,"dash cancels backstep and keeps its own invulnerability")
 reset(g)
 g.try_jump()
 step(g,1)
 g.try_backstep(1)
 check(g.backstep_time==0 and g.jumps_used==1,"airborne reverse gesture cannot add a third jump")
 reset(g)
 key(g,KEY_A,true)
 step(g,2)
 key(g,KEY_ESCAPE,true)
 key(g,KEY_ESCAPE,true)
 check(g.last_direction_time<0 and g.run_direction==0,"pause clears partial gesture")
 reset(g)
 g.try_backstep(1)
 step(g,3)
 x=g.hero.position.x
 var time: float=g.backstep_time
 g.paused=true
 step(g,10)
 check(g.hero.position.x==x and g.backstep_time==time,"pause freezes the backstep")
 g.paused=false
 g.finish(false)
 check(g.backstep_time==0 and g.run_direction==0,"death clears movement gestures")
 for code in [KEY_A,KEY_D,KEY_W,KEY_S]:key(g,code,false)
 g.feedback.clear()
 for c in g.get_children():
  if c is AudioStreamPlayer:c.stop()
 await create_timer(.3).timeout
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 print("MOVEMENT TRIAL FAILURES=",failures)
 quit(1 if failures else 0)
func capture(view:SubViewport,name:String):
 if DisplayServer.get_name()=="headless":return
 await process_frame
 await process_frame
 RenderingServer.force_draw(false)
 view.get_texture().get_image().save_png("res://docs/"+name+".png")
