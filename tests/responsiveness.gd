extends SceneTree
var failures:=0
func check(ok:bool,title:String):
 print(("PASS " if ok else "FAIL ")+title)
 if not ok: failures+=1
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 g.music.stop()
 g.sound_voices=5
 for e in g.enemies:e.node.position.x=55
 for power in [false,true]:
  g.start_attack(power)
  var elapsed:=0.0
  var contact:=-1.0
  while g.attack_time>=0:
   g._physics_process(1.0/120)
   elapsed+=1.0/120
   if g.contact_done and contact<0:contact=elapsed
  print("TIMING heavy=",power," contact=",contact," recovery=",elapsed)
  check(contact<=(0.20 if power else 0.12),"contact response within target")
  check(elapsed<=(0.50 if power else 0.32),"recovery within target")
 g.skill_cd=0
 g.start_attack(false)
 g.try_heavy()
 check(not g.attack_power and g.heavy_buffer>0,"early heavy press queues without erasing basic contact")
 for i in range(16):g._physics_process(1.0/120)
 check(g.attack_power and g.skill_cd>2.6 and g.heavy_buffer==0,"queued heavy consumes after the basic contact")
 g.attack_time=-1
 g.skill_cd=0.12
 g.try_heavy()
 for i in range(18):g._physics_process(1.0/120)
 check(g.attack_power and g.skill_cd>2.6,"skill input near cooldown end is retained")
 g.heavy_buffer=0.1
 g.paused=true
 g._physics_process(0.3)
 check(is_equal_approx(g.heavy_buffer,0.1),"pause preserves buffered input")
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 print("FAILURES: ",failures)
 quit(1 if failures else 0)
