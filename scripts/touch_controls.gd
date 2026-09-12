extends Control
## Touch only translates contacts into the existing movement/action interface.
var game:Node3D
var enabled:=false
var was_playable:=false
var stick_finger:=-1
# Browser touch identifiers may be signed; presence is independent of the ID.
var stick_active:=false
var stick_origin:=Vector2.ZERO
var stick_offset:=Vector2.ZERO
var action_fingers:Dictionary={}
var pause_button:Button
var stick_vector:=Vector2.ZERO
var run_charge:=0.0
var run_heading:=Vector2.ZERO
var probe_enabled:=false
var probe_clock:=0.0
var probe_distance:=0.0
var probe_previous:=Vector3.ZERO
var probe_point:=Vector2.ZERO
const RUN_DELAY:=0.35
const RUN_THRESHOLD:=0.22
const RADIUS:=76.0
const DEADZONE:=0.16

func _ready():
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 pause_button=game.ui.button("暫停",func():game.toggle_pause())
 game.ui.place(pause_button,self,Vector2(36,158),Vector2(88,42))
 pause_button.mouse_filter=Control.MOUSE_FILTER_STOP
 if OS.has_feature("web"):
  probe_enabled=bool(JavaScriptBridge.eval("new URLSearchParams(location.search).has('touch_probe')"))
 probe_previous=game.hero.position
 enabled=DisplayServer.is_touchscreen_available()
 pause_button.visible=enabled

func reset_contacts():
 stick_finger=-1
 stick_active=false
 stick_offset=Vector2.ZERO
 game.touch_movement=Vector2.ZERO
 stick_vector=Vector2.ZERO
 game.touch_running=false
 run_charge=0
 run_heading=Vector2.ZERO
 if action_fingers.values().has("basic"):game.release_action("basic")
 action_fingers.clear()
 queue_redraw()

func _notification(what):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT and game!=null:reset_contacts()

func _process(dt):

 if probe_enabled:
  probe_clock+=dt
  probe_distance+=Vector2(game.hero.position.x-probe_previous.x,game.hero.position.z-probe_previous.z).length()
  probe_previous=game.hero.position
  if probe_clock>=0.25:
   var sample:={"revision":"signed-touch-fix","finger":stick_finger,"point_x":probe_point.x,"point_y":probe_point.y,"strength":stick_offset.length()/RADIUS,"charge":run_charge,"running":game.touch_running,"speed":probe_distance/probe_clock,"move_x":game.touch_movement.x,"move_y":game.touch_movement.y,"paused":game.paused,"ready":game.ready_for_play,"ended":game.ended,"attack":game.attack_time,"dash":game.dash_time}
   JavaScriptBridge.eval("window.mistpawTouchProbe && window.mistpawTouchProbe("+JSON.stringify(sample)+")")
   probe_clock=0;probe_distance=0

 var playable:bool=game.ready_for_play and not game.paused and not game.ended
 if playable!=was_playable:
  was_playable=playable
  queue_redraw()
 pause_button.visible=enabled and playable
 if playable:update_run(dt)
 if not playable:reset_contacts()
 if enabled and playable and get_viewport_rect().size.x<get_viewport_rect().size.y:
  game.toggle_pause()

func action_at(point:Vector2)->String:
 for slot in game.ui.slots:
  var tile:Control=slot.tile
  if tile.is_visible_in_tree() and tile._has_point(tile.get_global_transform_with_canvas().affine_inverse()*point):
   return slot.action
 return ""

func change_action(index:int,next:String):
 var previous:String=action_fingers.get(index,"")
 if previous==next:return
 action_fingers.erase(index)
 if previous!="" and not action_fingers.values().has(previous):game.release_action(previous)
 if next!="":
  var already:bool=action_fingers.values().has(next)
  action_fingers[index]=next
  if not already:game.press_action(next)
 apply_movement()

func apply_movement():
 game.touch_movement=stick_vector
 update_run(0)

func update_run(dt:float):
 if not stick_active or stick_offset.length()<RADIUS*RUN_THRESHOLD:
  run_charge=0
  run_heading=Vector2.ZERO
  game.touch_running=false
 else:
  var direction:=stick_offset.normalized()
  if run_heading==Vector2.ZERO or direction.dot(run_heading)<0.80:
   run_charge=0
   run_heading=direction
   game.touch_running=false
  else:run_charge=minf(RUN_DELAY,run_charge+dt)
  game.touch_running=run_charge>=RUN_DELAY
 # Once charged, thumb travel controls direction rather than throttling sprint.
 game.touch_movement=stick_vector.normalized() if game.touch_running else stick_vector
 queue_redraw()

func update_stick(point:Vector2):
 stick_offset=(point-stick_origin).limit_length(RADIUS)
 var strength:=stick_offset.length()/RADIUS
 stick_vector=Vector2.ZERO if strength<DEADZONE else stick_offset.normalized()*((strength-DEADZONE)/(1.0-DEADZONE))
 apply_movement()
 queue_redraw()

func _input(event):
 if not game.ready_for_play or game.paused or game.ended:return
 # Let regular buttons handle touch-emulated mouse in menus, but prevent a
 # second click from the same finger on combat controls.
 if enabled and event is InputEventMouseButton and event.device==-1:
  var pause_rect:=pause_button.get_global_rect()
  if not pause_rect.has_point(event.position):get_viewport().set_input_as_handled()
  return
 if not (event is InputEventScreenTouch or event is InputEventScreenDrag):return
 enabled=true
 queue_redraw()
 var point:Vector2=get_global_transform_with_canvas().affine_inverse()*event.position
 probe_point=point
 if event is InputEventScreenTouch:
  if not event.pressed or event.canceled:
   if stick_active and event.index==stick_finger:
    stick_finger=-1
    stick_active=false
    stick_offset=Vector2.ZERO
    stick_vector=Vector2.ZERO
    apply_movement()
   change_action(event.index,"")
   queue_redraw()
   return
  for i in range(game.ui.relics.size()):
   var relic:Control=game.ui.relics[i].tile
   if relic.get_global_rect().grow(8).has_point(event.position):
    if not game.select_build(i):game.toast("尚未取得這件法寶",1.2)
    get_viewport().set_input_as_handled()
    return
  if point.x<380 and point.y>size.y-380 and point.y<size.y-115 and not stick_active:
   stick_finger=event.index
   stick_active=true
   stick_origin=Vector2(clampf(point.x,90,290),clampf(point.y,size.y-310,size.y-200))
   update_stick(point)
   get_viewport().set_input_as_handled()
  else:
   var action:=action_at(event.position)
   if action!="":
    change_action(event.index,action)
    get_viewport().set_input_as_handled()
 elif stick_active and event.index==stick_finger:
  update_stick(point)
  get_viewport().set_input_as_handled()
 else:
  # Sliding attack -> dodge/jump releases attack before triggering the new action.
  var was_action:bool=action_fingers.has(event.index)
  var action:=action_at(event.position)
  if was_action or action!="":
   change_action(event.index,action)
   get_viewport().set_input_as_handled()

func _draw():
 if not enabled or not game.ready_for_play or game.paused or game.ended:return
 var center:=stick_origin if stick_active else Vector2(145,size.y-238)
 draw_circle(center,RADIUS+8,Color(0.025,0.085,0.09,0.6),true,-1,true)
 draw_arc(center,RADIUS+8,0,TAU,64,Color(0.67,0.57,0.35,0.7),2,true)
 if run_charge>0:
  var color:=Color("a5e4cf") if game.touch_running else Color("d9bc7d")
  draw_arc(center,RADIUS+8,-PI/2,-PI/2+TAU*run_charge/RUN_DELAY,64,color,3,true)
 draw_arc(center,RADIUS*DEADZONE,0,TAU,32,Color(0.55,0.75,0.7,0.3),1,true)
 draw_circle(center+stick_offset,31,Color(0.12,0.28,0.27,0.88),true,-1,true)
 draw_arc(center+stick_offset,31,0,TAU,48,Color(0.85,0.75,0.49,0.9),2,true)
