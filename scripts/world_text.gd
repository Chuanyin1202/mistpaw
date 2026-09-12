extends Label3D
## Retain world placement and existing Label3D callers; rasterize text after DOF.
var screen:Label
var camera:Camera3D
var game:Node3D
var motion:Tween
func setup(host:Control,view:Camera3D,owner_game:Node3D):
 layers=0
 camera=view
 game=owner_game
 screen=Label.new()
 screen.mouse_filter=Control.MOUSE_FILTER_IGNORE
 screen.add_theme_color_override("font_outline_color",Color(0.025,0.035,0.035,0.9))
 screen.add_theme_constant_override("outline_size",3)
 host.add_child(screen)
func _process(_dt:float):
 if screen==null:return
 if motion!=null and motion.is_valid():
  if game.paused:motion.pause()
  elif not motion.is_running():motion.play()
 screen.visible=is_visible_in_tree() and not text.is_empty() and modulate.a>0.02 and not camera.is_position_behind(global_position)
 if not screen.visible:return
 var at:=camera.unproject_position(global_position)
 var above:=camera.unproject_position(global_position+camera.global_basis.y)
 var pixels_per_unit:=at.distance_to(above)
 screen.text=text
 screen.modulate=modulate
 screen.add_theme_font_size_override("font_size",maxi(14,roundi(font_size*pixel_size*pixels_per_unit*global_basis.get_scale().y)))
 screen.reset_size()
 screen.position=game.ui.place_combat_text(screen,at)
func _exit_tree():
 if is_instance_valid(screen):screen.queue_free()
