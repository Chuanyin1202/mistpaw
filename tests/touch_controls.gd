extends SceneTree
var failures:=0
var g:Node
func _initialize():call_deferred("run")
func check(ok:bool,title:String):
 print(("PASS " if ok else "FAIL ")+title)
 if not ok:failures+=1
func touch(index:int,point:Vector2,pressed:bool,canceled:=false):
 var e:=InputEventScreenTouch.new()
 e.index=index;e.position=point;e.pressed=pressed;e.canceled=canceled
 Input.parse_input_event(e);Input.flush_buffered_events()
func drag(index:int,point:Vector2):
 var e:=InputEventScreenDrag.new()
 e.index=index;e.position=point
 Input.parse_input_event(e);Input.flush_buffered_events()
func center(action:String)->Vector2:
 for slot in g.ui.slots:
  if slot.action==action:return slot.tile.get_global_rect().get_center()
 return Vector2.ZERO
func run():
 root.size=Vector2i(1280,720)
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 await process_frame
 touch(0,Vector2(145,480),true)
 drag(0,Vector2(220,480))
 check(g.movement_input().x>0.9,"left finger moves right")
 touch(1,center("basic"),true)
 check(g.attack_held and g.movement_input().x>0.9,"move and hold attack with two fingers")
 drag(1,center("dash"))
 check(not g.attack_held and g.dash_time>0,"slide attack to dash releases old action")
 touch(1,center("dash"),false)
 check(g.movement_input().x>0.9,"right release preserves left stick")
 touch(2,center("jump"),true)
 check(g.jumps_used==1,"touch jump")
 touch(2,center("jump"),false)
 touch(2,center("jump"),true)
 check(g.jumps_used==2,"second touch double jump")
 touch(2,center("jump"),false)
 touch(0,Vector2(220,480),false,true)
 check(g.movement_input()==Vector2.ZERO,"canceled touch releases direction")
 touch(3,center("basic"),true)
 drag(3,Vector2(650,150))
 check(not g.attack_held,"sliding outside releases attack")
 touch(3,Vector2(650,150),false)
 touch(4,center("basic"),true)
 touch(5,center("basic"),true)
 touch(4,center("basic"),false)
 check(g.attack_held,"one of two attack fingers remains held")
 touch(5,center("basic"),false)
 check(not g.attack_held,"last attack finger releases")
 touch(0,Vector2(145,480),true);drag(0,Vector2(90,445))
 check(g.movement_input().x<0 and g.movement_input().y<0,"diagonal depth movement")
 g.toggle_pause()
 await process_frame
 check(g.touch_movement==Vector2.ZERO and not g.attack_held,"pause releases touch contacts")
 g.toggle_pause()
 g.unlocked.assign([0,1,2])
 for choice in range(3):
  var p:Vector2=g.ui.relics[choice].tile.get_global_rect().get_center()
  touch(8,p,true);touch(8,p,false)
  check(g.build==choice,"touch relic selection "+str(choice+1))
 g.unlocked.assign([0]);g.build=0
 var locked:Vector2=g.ui.relics[2].tile.get_global_rect().get_center()
 touch(8,locked,true);touch(8,locked,false)
 check(g.build==0,"locked relic cannot be equipped")
 var controls:Control
 for child in g.ui.canvas.get_children():
  if child.get_script()==load("res://scripts/touch_controls.gd"):controls=child
 controls.set_process(false)
 g.dash_time=0;g.backstep_time=0;g.run_direction=0
 touch(0,Vector2(145,480),true);drag(0,Vector2(221,480))
 controls.update_run(0.34)
 check(not g.touch_running,"hold before threshold remains walking")
 controls.update_run(0.02)
 check(g.touch_running and g.is_running(),"steady hold accelerates without double push")
 drag(0,Vector2(218,473))
 check(g.touch_running,"small steering adjustment keeps running")
 touch(1,center("basic"),true)
 check(g.touch_running and g.attack_held,"hold run plus attack")
 touch(1,center("basic"),false)
 drag(0,Vector2(69,480))
 check(not g.touch_running,"reversing direction immediately resets acceleration")
 controls.update_run(0.36)
 check(g.touch_running,"new direction can accelerate after hold")
 drag(0,Vector2(158,480));controls.update_run(1.0)
 check(not g.touch_running,"near-neutral thumb jitter does not accelerate")
 drag(0,Vector2(145,404));controls.update_run(0.36)
 check(g.touch_running and g.movement_input().y<0,"depth movement also accelerates")
 touch(0,Vector2(145,404),false)
 check(not g.touch_running and g.touch_movement==Vector2.ZERO,"release clears acceleration and movement")
 touch(0,Vector2(145,480),true);drag(0,Vector2(221,480));controls.update_run(0.36)
 touch(0,Vector2(221,480),false,true)
 check(not g.touch_running,"canceled contact clears acceleration")
 touch(0,Vector2(145,480),true);drag(0,Vector2(221,480));controls.update_run(0.36)
 g.toggle_pause();controls._process(0)
 check(not g.touch_running and g.touch_movement==Vector2.ZERO,"pause clears autorun")
 g.toggle_pause()
 touch(0,Vector2(145,480),true);drag(0,Vector2(190.6,480));controls.update_run(0.36)
 check(g.touch_running and is_equal_approx(g.touch_movement.length(),1.0),"60 percent hold reaches full run speed")
 g.hero.position=Vector3(2,g.HERO_GROUND_Y,0)
 g.dash_time=0;g.backstep_time=0
 for e in g.enemies:e.node.position.x=60
 var start_x:float=g.hero.position.x
 for i in range(6):g._physics_process(1.0/60)
 var speed:float=(g.hero.position.x-start_x)/0.1
 print("AUTORUN measured_speed=",speed)
 check(absf(speed-7.2)<0.01,"charged partial push physically moves at 7.2 units per second")
 touch(0,Vector2(190.6,480),false)
 check(not g.touch_running and g.touch_movement==Vector2.ZERO,"release after measured sprint stops")
 for identifier in [-61353281,-1,1461891158]:
  touch(identifier,Vector2(145,480),true);drag(identifier,Vector2(221,480))
  controls.update_run(0.36)
  print("TOUCH signed-id id=",identifier," charge=",controls.run_charge," running=",g.touch_running)
  check(g.touch_running,"signed touch identifier accelerates "+str(identifier))
  touch(7,Vector2(150,485),true)
  check(controls.stick_finger==identifier,"second finger cannot steal signed stick "+str(identifier))
  touch(7,Vector2(150,485),false)
  touch(identifier,Vector2(221,480),false,true)
  check(not g.touch_running and g.touch_movement==Vector2.ZERO,"signed touch cancel releases "+str(identifier))
 print("TOUCH failures=",failures)
 g.queue_free();await process_frame;quit(failures)
