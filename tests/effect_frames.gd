extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var view := SubViewport.new()
 view.size = Vector2i(960,540)
 view.own_world_3d = true
 view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(view)
 var g = load("res://scenes/main.tscn").instantiate()
 view.add_child(g)
 await process_frame
 if not g.ready_for_play: await g.boot_finished
 g.set_physics_process(false)
 g.music.stop()
 g.sound_voices = 5
 g.hero.position.x = 3
 for i in range(g.enemies.size()):
  g.enemies[i].node.position.x = 5.1+i*0.6
  g.enemies[i].clock = 2.3+i*0.03
 DirAccess.make_dir_recursive_absolute("res://docs/effect-frames")
 var log := FileAccess.open("res://docs/effect-frames/states.csv",FileAccess.WRITE)
 log.store_line("frame,attack,slash,impacts,windups,forest_nodes")
 for i in range(120):
  g._physics_process(1.0/60)
  await process_frame
  await RenderingServer.frame_post_draw
  view.get_texture().get_image().save_png("res://docs/effect-frames/%03d.png" % i)
  log.store_line("%d,%.3f,%s,%d,%d,%d" % [i,g.attack_time,g.effects.slash.visible,g.effects.impacts.filter(func(h):return h.node.visible).size(),g.enemies.filter(func(e):return e.windup>=0).size(),g.forest.get_child_count()])
 log.close()
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 print("EFFECT_FRAMES captured=120")
 quit()
