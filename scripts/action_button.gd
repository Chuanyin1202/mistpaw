extends Button
## Shared presentation for keyboard prompts and future touch-sized layouts.
var rejected_left:=0.0
var art:TextureRect
var dimmed:=false
var remaining:=0.0
var duration:=1.0
var pulse:=0.0
var was_cooling:=false
var active:=false
func _ready():
 focus_mode=Control.FOCUS_NONE
 mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 for state in ["normal","hover","pressed","disabled","focus"]:
  add_theme_stylebox_override(state,StyleBoxEmpty.new())
func _has_point(point:Vector2)->bool:
 return point.distance_to(size*0.5)<=size.x*0.5
func update_cooldown(value:float,total:float,dt:float):
 if was_cooling and value<=0:pulse=0.22
 was_cooling=value>0
 remaining=value
 duration=total
 pulse=maxf(0,pulse-dt)
 rejected_left=maxf(0,rejected_left-dt)
 queue_redraw()
func _draw():
 var c:=size*0.5
 var radius:=size.x*0.5
 if art!=null:
  var brightness:=0.38 if dimmed else (1.22 if is_pressed() or active else (1.1 if is_hovered() else 1.0))
  art.modulate=Color(brightness,brightness,brightness,1)
 # Rings sit outside the painted bronze rim; only cooling actions show progress.
 draw_circle(c+Vector2(0,3),radius+2,Color(0.015,0.025,0.03,0.55),true,-1,true)
 if remaining>0:
  draw_arc(c,radius+2,-PI/2,-PI/2+TAU*(1-clampf(remaining/duration,0,1)),80,Color("e5c587"),2,true)
 if is_pressed() or active:
  draw_arc(c,radius+1,0,TAU,80,Color("ffe2a3"),2,true)
 if rejected_left>0:draw_arc(c,radius+2,0,TAU,80,Color(1,0.35,0.18,rejected_left/0.18),3,true)
 if pulse>0:draw_arc(c,radius+3,0,TAU,80,Color(1,0.9,0.65,pulse/0.22),3,true)

func reject():
 rejected_left=0.18
 queue_redraw()
