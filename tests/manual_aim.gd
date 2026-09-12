extends SceneTree
## Keyboard-facing contract replaces the superseded mouse-aim contract.
var failures:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 print(("PASS " if ok else "FAIL ")+label)
 if not ok:failures+=1
func key(code:int,down:bool):
 var e:=InputEventKey.new()
 e.physical_keycode=code
 e.pressed=down
 Input.parse_input_event(e)
 Input.flush_buffered_events()
func step(g,n:int):
 for i in range(n):g._physics_process(1.0/60)
func run():
 root.size=Vector2i(1280,720)
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 for e in g.enemies:e.node.hide()
 g.enemies.clear()
 var mouse:=InputEventMouseButton.new()
 mouse.position=Vector2(50,250)
 mouse.button_index=MOUSE_BUTTON_LEFT
 mouse.pressed=true
 Input.parse_input_event(mouse)
 Input.flush_buffered_events()
 step(g,1)
 check(g.attack_time<0 and g.facing==1,"world mouse clicks neither attack nor aim")
 key(KEY_A,true)
 step(g,1)
 check(g.facing==-1,"reverse movement turns immediately")
 key(KEY_J,true)
 key(KEY_J,false)
 step(g,1)
 check(g.attack_time>=0 and g.facing==-1,"quick J click attacks facing direction without enemy")
 key(KEY_A,false)
 step(g,40)
 check(g.attack_time<0,"single click does not repeat")
 key(KEY_K,true)
 key(KEY_K,false)
 step(g,1)
 check(g.attack_power and g.facing==-1,"K heavy preserves facing")
 key(KEY_L,true)
 key(KEY_L,false)
 step(g,1)
 check(g.dash_time>0 and g.attack_time<0,"L dash cancels heavy")
 key(KEY_J,true)
 key(KEY_J,false)
 step(g,12)
 check(g.attack_time>=0 and not g.attack_power,"tap during dash is retained")
 step(g,40)
 key(KEY_SPACE,true)
 key(KEY_SPACE,false)
 step(g,1)
 key(KEY_SPACE,true)
 key(KEY_SPACE,false)
 step(g,1)
 check(g.jumps_used==2 and g.jump_height>0,"Space supplies both jumps")
 key(KEY_I,true)
 key(KEY_I,false)
 step(g,1)
 check(g.spin_time>=0,"I spin can start in air")
 step(g,70)
 key(KEY_D,true)
 key(KEY_D,false)
 step(g,3)
 key(KEY_D,true)
 step(g,1)
 check(g.run_direction==1 and g.backstep_time==0,"double tap runs without backstep")
 key(KEY_D,false)
 for i in range(g.ui.slots.size()):
  var tile=g.ui.slots[i].tile
  check(tile is Button and tile.size.x==tile.size.y,"round action button "+str(i))
  check(tile._has_point(tile.size/2) and not tile._has_point(Vector2.ZERO),"circular hit region "+str(i))
 # Queued actions must use the current held direction when the dash ends.
 for action in ["basic","heavy"]:
  step(g,70)
  g.facing=1
  g.dash_cd=0
  g.skill_cd=0
  g.try_dash()
  g.press_action(action)
  g.release_action(action)
  key(KEY_A,true)
  step(g,14)
  check(g.attack_time>=0 and g.facing==-1,action+" queued during dash takes current direction")
  key(KEY_A,false)
  key(KEY_D,true)
  step(g,1)
  check(g.facing==-1,action+" facing stays locked after attack begins")
  key(KEY_D,false)
 step(g,60)
 g.dash_cd=0
 g.ui.slots[3].tile.button_down.emit()
 check(g.dash_time>0,"UI uses same dash entry as keyboard")
 g.toggle_pause()
 var jumps:int=g.jumps_used
 g.press_action("jump")
 check(g.jumps_used==jumps,"shared action entry respects pause")
 for c in g.get_children():
  if c is AudioStreamPlayer:c.stop()
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 quit(1 if failures else 0)
