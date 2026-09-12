extends SceneTree
var failures:=0
func check(ok:bool,title:String):
 print(("PASS " if ok else "FAIL ")+title)
 if not ok:failures+=1
func _initialize():call_deferred("run")
func key(code:Key):
 for pressed in [true,false]:
  var e:=InputEventKey.new()
  e.keycode=code
  e.physical_keycode=code
  e.pressed=pressed
  Input.parse_input_event(e)
  Input.flush_buffered_events()
func run():
 root.size=Vector2i(1280,720)
 await process_frame
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 key(KEY_ESCAPE)
 check(g.paused and g.ui.resume_button.has_focus(),"Escape reaches pause menu through input system")
 var assist:CheckButton=g.ui.pause_overlay.find_children("*","CheckButton",true,false)[0]
 var at:Vector2=assist.get_global_rect().get_center()
 for pressed in [true,false]:
  var click:=InputEventMouseButton.new()
  click.position=at
  click.button_index=MOUSE_BUTTON_LEFT
  click.pressed=pressed
  Input.parse_input_event(click)
  Input.flush_buffered_events()
 check(g.auto_attack,"選單可用滑鼠切換自動普攻輔助")
 check(not g.attack_held,"點擊輔助選項不會留下攻擊指令")
 var p:Vector2=g.ui.mute_button.get_global_rect().get_center()
 for pressed in [true,false]:
  var e:=InputEventMouseButton.new()
  e.position=p
  e.button_index=MOUSE_BUTTON_LEFT
  e.pressed=pressed
  Input.parse_input_event(e)
  Input.flush_buffered_events()
 check(g.muted and AudioServer.is_bus_mute(0),"mouse activates sound control")
 key(KEY_ESCAPE)
 check(not g.paused and not g.ui.pause_overlay.visible,"Escape closes menu after mouse focus")
 key(KEY_L)
 check(g.dash_time>0,"L returns to dodge after closing menu")
 key(KEY_M)
 check(not AudioServer.is_bus_mute(0),"M restores sound")
 check(AudioServer.get_bus_effect_count(0)==1 and AudioServer.get_bus_effect(0,0) is AudioEffectHardLimiter,"single master peak limiter is active")
 root.size=Vector2i(1920,1080)
 await process_frame
 await process_frame
 key(KEY_ESCAPE)
 await process_frame
 if DisplayServer.get_name()!="headless":
  RenderingServer.force_draw(false)
  root.get_texture().get_image().save_png("res://docs/menu-1080p.png")
 check(g.ui.pause_overlay.get_rect().size.x>=1280,"pause overlay adapts to desktop viewport")
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 print("MENU INPUT FAILURES=",failures)
 quit(1 if failures else 0)
