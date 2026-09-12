extends SceneTree
var failures:=0
func check(ok:bool,s:String):
 print(("PASS " if ok else "FAIL ")+s)
 if not ok:failures+=1
func reset(g,e,build:int,at:Vector3):
 g.hero.position=Vector3(0,g.HERO_GROUND_Y,0)
 g.build=build
 g.attack_time=-1
 g.attack_cd=0
 g.combo_window=0
 g.last_direction_time=-1
 g.facing=1
 e.node.position=Vector3(at.x,e.home.y+at.y,at.z)
 e.hp=1000
 e.clock=-100
 e.recoil=0
 e.windup=-1
 e.stagger=0
 e.recovery=0
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
 var e:Dictionary=g.enemies[0]
 var airborne:Dictionary=g.enemies[1]
 for old in g.enemies:old.node.hide()
 g.enemies.clear()
 g.enemies.append(e)
 e.node.show()
 for build in [-1,0,1,2]:
  var reach:float=4.3 if build==0 else 2.7
  reset(g,e,build,Vector3(reach-0.01,0,0))
  g._physics_process(0.001)
  check(g.attack_time>=0,"inside effective range starts attack "+str(build))
  for i in range(15):
   e.node.position=Vector3(reach-0.01,e.home.y,0)
   e.recoil=0
   g._physics_process(0.01)
   if DisplayServer.get_name()!="headless":await process_frame
  if build==0 and DisplayServer.get_name()!="headless":
   RenderingServer.force_draw(false)
   root.get_texture().get_image().save_png("res://docs/attack-entry-wave.png")
  check(e.hp<1000,"automatic strike actually contacts target "+str(build))
  reset(g,e,build,Vector3(reach+0.02,0,0))
  g._physics_process(0.001)
  check(g.attack_time<0,"outside range cannot trigger empty swing "+str(build))
  reset(g,e,build,Vector3(2,0,0.95))
  g._physics_process(0.001)
  check(g.attack_time>=0,"nearby depth offset starts attack "+str(build))
  reset(g,e,build,Vector3(2,0,1.02))
  g._physics_process(0.001)
  check(g.attack_time<0,"separate depth lane remains outside attack "+str(build))
 reset(g,e,0,Vector3(3.5,0,0))
 airborne.node.position=Vector3(1,airborne.home.y+4,0)
 airborne.clock=-100
 g.enemies.push_front(airborne)
 g._physics_process(0.001)
 check(g.attack_time>=0,"unreachable nearest actor does not block reachable target")
 g.enemies.erase(airborne)
 reset(g,e,0,Vector3(3.5,0,0))
 var key:=InputEventKey.new()
 key.physical_keycode=KEY_A
 key.pressed=true
 Input.parse_input_event(key)
 Input.flush_buffered_events()
 g._physics_process(0.01)
 check(g.attack_time<0,"retreating input does not auto-turn into attack")
 key=key.duplicate()
 key.pressed=false
 Input.parse_input_event(key)
 Input.flush_buffered_events()
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 quit(1 if failures else 0)
