extends SceneTree
## Fixed framing and seed for native lighting comparisons; outputs stay in build/.
func _initialize():call_deferred("run")
func run():
 var label:="current"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--label="):label=arg.trim_prefix("--label=")
 DirAccess.make_dir_recursive_absolute("res://build/verification/lighting")
 var view:=SubViewport.new()
 view.size=Vector2i(1280,720)
 view.own_world_3d=true
 view.msaa_3d=Viewport.MSAA_4X if RenderingServer.get_current_rendering_method()=="forward_plus" else Viewport.MSAA_DISABLED
 view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(view)
 var display:=TextureRect.new()
 display.texture=view.get_texture()
 display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.add_child(display)
 var game=load("res://scenes/main.tscn").instantiate()
 view.add_child(game)
 await process_frame
 if not game.ready_for_play:await game.boot_finished
 game.set_physics_process(false)
 game.music.stop()
 game.set_visual_profile(0,false)
 if "--floor-probe" in OS.get_cmdline_user_args():
  var mat:ShaderMaterial=game.forest.get_node("WideFarBank").material_override
  var probe:=Shader.new()
  probe.code=mat.shader.code.replace("shader_type spatial;","shader_type spatial;\nrender_mode cull_disabled;").replace('#include "surface_relief.gdshaderinc"','#include "res://shaders/surface_relief.gdshaderinc"')
  mat.shader=probe
  print("LIGHTING floor probe disables culling only")
 for position in [2.0,15.0,32.0,44.0]:
  game.hero.position=Vector3(position,game.HERO_GROUND_Y,0)
  game.camera.position.x=clampf(position+2.5,3,47)
  game.forest.follow_camera(game.camera.position.x)
  for e in game.enemies:e.node.hide()
  game.update_hud()
  for i in range(40):await process_frame
  view.get_texture().get_image().save_png("res://build/verification/lighting/%s-%d.png" % [label,position])
  print("LIGHTING capture ",label," x=",position)
 game.queue_free()
 await process_frame
 view.queue_free()
 display.queue_free()
 await process_frame
 quit()
