extends Control
## Screen-space health avoids depth-of-field blur; no numeric HP label.
var ratio := 1.0
var trail := 1.0
var hold := 0.0
var elite := false
func _init():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 2
	size = Vector2(58, 7)
func set_health(value: float, dt: float):
	value = clampf(value, 0, 1)
	if value < ratio: hold = 0.16
	ratio = value
	hold = maxf(0, hold - dt)
	if hold <= 0: trail = move_toward(trail, ratio, dt * 1.8)
	queue_redraw()
func _draw():
	draw_rect(Rect2(Vector2(-1,-1), size + Vector2(2,2)), Color("a18b59") if elite else Color("403d30"))
	draw_rect(Rect2(Vector2.ZERO, size), Color("151b1b"))
	var inside := size - Vector2(2,2)
	draw_rect(Rect2(Vector2.ONE, Vector2(inside.x * trail, inside.y)), Color("d0a168"))
	draw_rect(Rect2(Vector2.ONE, Vector2(inside.x * ratio, inside.y)), Color("c77745") if elite else Color("ae5145"))
