extends SceneTree
var failures := 0
func check(ok: bool, title: String):
	print(("PASS " if ok else "FAIL ") + title)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func run():
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var g = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(g)
	await process_frame
	if not g.ready_for_play: await g.boot_finished
	g.set_physics_process(false)
	g.music.stop()
	g.sound_voices = 5
	g.hero.position.x = 2
	for e in g.enemies:
		e.node.position.x = 55
		e.node.position.z = 0
	var left = g.enemies[0]
	var right = g.enemies[1]
	var outside = g.enemies[2]
	left.node.position.x = 0
	right.node.position.x = 4
	outside.node.position.x = 5.05
	g.try_spin()
	g._physics_process(0.09)
	check(left.hp == 17 and right.hp == 17, "spin first pulse hits front and rear")
	check(g.spin_hits == 1, "first pulse resolves once")
	check(outside.hp == 36, "enemy outside visible ribbon is not hit")
	if DisplayServer.get_name() != "headless":
		for i in range(4):
			await process_frame
			await process_frame
			RenderingServer.force_draw(false)
			viewport.get_texture().get_image().save_png("res://docs/spin-%d.png" % i)
			g._physics_process(0.08)
	else: g._physics_process(0.32)
	check(left.hp == -2 and right.hp == -2, "second pulse resolves once across large timestep")
	check(not left in g.enemies and not right in g.enemies, "spin kills are removed through normal damage path")
	g.try_spin()
	check(g.spin_time < 0, "cooldown rejects repeated spin")
	g.spin_cd = 0
	g.try_spin()
	g.try_dash()
	check(g.spin_time < 0 and g.dash_time > 0 and not g.effects.slash.visible, "dash cancels spin and its effect")
	g.dash_time = 0
	g.spin_cd = 0
	g.start_attack(false)
	g.try_spin()
	check(g.spin_buffer > 0 and g.spin_time < 0, "spin queues behind unspent basic contact")
	g._physics_process(0.11)
	g._physics_process(0.01)
	check(g.spin_time >= 0 and g.attack_time < 0, "spin starts after queued basic contact")
	var t: float = g.spin_time
	g.paused = true
	g._physics_process(0.3)
	check(g.spin_time == t, "pause freezes spin")
	g.finish(false)
	check(g.spin_time < 0 and not g.effects.slash.visible, "death clears spin")
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("SPIN FAILURES=",failures)
	quit(1 if failures else 0)
