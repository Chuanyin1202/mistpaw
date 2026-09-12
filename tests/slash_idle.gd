extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var view := SubViewport.new()
 view.size = Vector2i(1280,720)
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
 for e in g.enemies: e.node.position.x = 55
 var flashes := 0
 for i in range(120):
  g._physics_process(1.0/120)
  if g.effects.slash.visible: flashes += 1
 print("BUGFIX/idle-slash empty_idle_visible_ticks=",flashes)
 var e = g.enemies[0]
 e.node.position.x = g.hero.position.x + 2
 g.jump_height = 2.9
 g.jump_velocity = 0
 g.attack_cd = 0
 g.attack_time = -1
 var hp: float = e.hp
 for i in range(15): g._physics_process(1.0/120)
 print("BUGFIX/idle-slash airborne height=",g.jump_height," attack_time=",g.attack_time," slash_visible=",g.effects.slash.visible," damage=",hp-e.hp)
 var ok: bool = flashes == 0 and not g.effects.slash.visible and g.attack_time < 0
 if DisplayServer.get_name() != "headless":
  await process_frame
  await process_frame
  RenderingServer.force_draw(false)
  view.get_texture().get_image().save_png("res://docs/airborne-no-slash.png")
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 quit(0 if ok else 1)
