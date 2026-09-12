extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var view := SubViewport.new()
 view.size = Vector2i(1280,720)
 view.own_world_3d = true
 view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(view)
 var game = load("res://scenes/main.tscn").instantiate()
 view.add_child(game)
 await process_frame
 if not game.ready_for_play: await game.boot_finished
 game.set_physics_process(false)
 game.music.stop()
 for e in game.enemies: e.node.hide()
 game.hero.position.x = 15
 game.camera.position.x = 17.5
 game.forest.follow_camera(17.5)
 game.help.get_parent().hide()
 game.message.hide()
 for frame in range(3):
  await create_timer(0.75).timeout
  RenderingServer.force_draw(false)
  view.get_texture().get_image().save_png("res://docs/water-%d.png" % frame)
 var lake = game.forest.get_node("Lake")
 print("WATER shader=",lake.material_override.shader.resource_path," mesh=",lake.mesh.get_class()," surface_y=",lake.position.y," captures=3")
 game.queue_free()
 await process_frame
 quit()
