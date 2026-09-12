extends Control
var kind:=0
var ink:=Color("ebd6ab")
func _draw():
 var c:=size*0.5
 if kind==0:
  draw_polyline(PackedVector2Array([c+Vector2(-12,13),c+Vector2(9,-13),c+Vector2(15,-16),c+Vector2(15,-9),c+Vector2(-8,16)]),ink,2,true)
  draw_line(c+Vector2(-15,5),c+Vector2(-2,16),ink,3,true)
 elif kind==1:
  draw_arc(c,15,0.3,5.5,32,ink,2,true)
  draw_arc(c,9,2.0,6.0,20,ink*Color(1,1,1,0.5),2,true)
  draw_polyline(PackedVector2Array([c+Vector2(4,-16),c+Vector2(12,-12),c+Vector2(8,-4)]),ink,2,true)
 elif kind==2:
  for x in [-9,3]:draw_polyline(PackedVector2Array([c+Vector2(x-4,-12),c+Vector2(x+7,0),c+Vector2(x-4,12)]),ink,3,true)
  draw_line(c+Vector2(-17,0),c+Vector2(-9,0),ink,2,true)
 else:
  for y in [-7,6]:draw_polyline(PackedVector2Array([c+Vector2(-10,y+5),c+Vector2(0,y-5),c+Vector2(10,y+5)]),ink,2,true)
