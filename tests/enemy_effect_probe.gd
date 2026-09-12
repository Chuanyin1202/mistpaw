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
 var e = g.enemies[0]
 g.hero.position.x = 3
 e.node.position.x = 5
 e.aim = 3
 e.windup = 0.01
 g.invulnerable = 10
 await process_frame
 await process_frame
 var count: int = g.forest.get_child_count()
 g.update_enemy(e,0.02)
 print("EFFECT_PROBE source=enemy_melee hero_attack=",g.attack_time," hero_slash=",g.effects.slash.visible," new_nodes=",g.forest.get_child_count()-count," enemy_arcs=",g.effects.enemy_arcs.filter(func(a):return a.node.visible).size())
 if DisplayServer.get_name() != "headless":
  paused = true
  await process_frame
  await process_frame
  RenderingServer.force_draw(false)
  view.get_texture().get_image().save_png("res://docs/enemy-arc-fixed.png")
 paused = false
 var arcs = g.effects.enemy_arcs.filter(func(a):return a.node.visible)
 var ok: bool = g.forest.get_child_count() == count and arcs.size() == 1 and not g.effects.slash.visible
 g.effects.advance(0.13,g.hero.position)
 ok = ok and g.effects.enemy_arcs.all(func(a):return not a.node.visible)
 g.effects.enemy_strike(e.node.position,-1,1.45)
 g.effects.clear()
 ok = ok and g.effects.enemy_arcs.all(func(a):return not a.node.visible)
 print("ENEMY_ARC no_beam_expiry_clear=",ok)
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 quit(0 if ok else 1)
