extends SceneTree
var failures:=0
func check(ok:bool,title:String):
 print(("PASS " if ok else "FAIL ")+title)
 if not ok:failures+=1
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate()
 g.auto_attack=true
 root.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 g.music.stop()
 g.sound_voices=5
 for e in g.enemies:e.node.position.x=55
 g.start_attack(false)
 g.try_heavy()
 g.try_dash()
 for i in range(28):g._physics_process(0.01)
 print("CANCEL heavy_buffer=",g.heavy_buffer," attack=",g.attack_time," heavy=",g.attack_power)
 check(g.attack_time<0,"dash cancels previously queued heavy without delayed automatic attack")
 g.attack_time=-1
 g.dash_cd=0
 g.spin_cd=0
 g.start_attack(false)
 g.try_spin()
 g.try_dash()
 for i in range(28):g._physics_process(0.01)
 check(g.spin_time<0,"dash cancels previously queued spin")
 g.dash_cd=0
 g.skill_cd=0
 g.try_dash()
 g.try_heavy()
 for i in range(25):g._physics_process(0.01)
 check(g.attack_time>=0 and g.attack_power,"new heavy pressed during dash can buffer after it")
 g.attack_time=-1
 g.dash_time=0
 g.spin_time=-1
 g.spin_cd=0
 g.jump_height=1
 g.jump_velocity=3
 g.jumps_used=1
 g.try_jump()
 g.try_spin()
 g._physics_process(0.01)
 check(g.spin_time>=0 and g.jump_height>1 and g.jumps_used==2,"second jump flows immediately into aerial spin")
 g.attack_time=-1
 g.spin_time=-1
 g.jump_height=0
 g.jump_velocity=0
 g.landing_time=0
 g.dash_time=0
 g.dash_cd=0
 g.attack_cd=0
 g.hero.position=Vector3(0,g.HERO_GROUND_Y,0)
 g.facing=1
 g.run_direction=1
 var e:Dictionary=g.enemies[0]
 e.node.position=Vector3(2.4,e.home.y,0)
 e.hp=1000
 e.clock=0
 e.windup=-1
 var key:=InputEventKey.new()
 key.physical_keycode=KEY_D
 key.pressed=true
 Input.parse_input_event(key)
 Input.flush_buffered_events()
 g._physics_process(0.01)
 check(g.attack_time>=0 and g.hero.position.x>0.07,"running enters automatic attack without braking or changing run speed")
 var life:float=e.hp
 g.try_dash()
 for i in range(10):g._physics_process(0.01)
 check(e.hp==life,"dash before contact cancels the unspent strike without ghost damage")
 key=key.duplicate()
 key.pressed=false
 Input.parse_input_event(key)
 Input.flush_buffered_events()
 g.queue_free()
 await process_frame
 await create_timer(0.3).timeout
 print("TRANSITIONS FAILURES=",failures)
 quit(1 if failures else 0)
