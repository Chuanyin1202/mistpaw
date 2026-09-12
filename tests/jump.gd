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
	for e in g.enemies: e.node.position.x = 55
	g.hero.position.x = 15
	g.camera.position.x = 17.5
	g.forest.follow_camera(17.5)
	g.try_jump()
	g._physics_process(1.0/120)
	check(g.jump_height > 0, "jump starts on first simulation tick")
	var velocity: float = g.jump_velocity
	check(g.jumps_used == 1, "first jump consumes one charge")
	var apex := 0.0
	for i in range(110):
		g._physics_process(1.0/120)
		apex = maxf(apex,g.jump_height)
		if i in [8,40,65] and DisplayServer.get_name() != "headless":
			await process_frame
			await process_frame
			RenderingServer.force_draw(false)
			viewport.get_texture().get_image().save_png("res://docs/jump-%d.png" % i)
	check(apex > 1.5 and apex < 1.7, "jump reaches useful evasive height")
	check(g.jump_height == 0 and is_equal_approx(g.hero.position.y,1.87), "landing returns exactly to ground")
	check(is_equal_approx(g.hero.get_child(0).global_position.y,0.14), "shadow remains grounded")
	g.try_jump()
	for i in range(42): g._physics_process(1.0/120)
	var first_height: float = g.jump_height
	g.try_jump()
	check(g.jumps_used == 2 and g.jump_velocity == 8.8, "second jump resets upward velocity at apex")
	g._physics_process(1.0/120)
	velocity = g.jump_velocity
	g.try_jump()
	check(g.jumps_used == 2 and g.jump_velocity == velocity, "third jump is rejected")
	var double_apex := first_height
	for i in range(160):
		g._physics_process(1.0/120)
		double_apex = maxf(double_apex,g.jump_height)
	check(double_apex > 3.0, "second jump gains useful additional height")
	check(g.jump_height == 0 and g.jumps_used == 0, "landing restores both jumps")
	g.try_jump()
	check(g.jumps_used == 1 and g.jump_velocity == 8.8, "can jump again after landing")
	g.jump_velocity = 0
	var rat = g.enemies[0]
	rat.node.position.x = 15.8
	rat.node.position.z = g.hero.position.z
	rat.aim_z = g.hero.position.z
	rat.aim = 15
	rat.windup = 0.01
	g.jump_height = 1.3
	g.invulnerable = 0
	g.update_enemy(rat,0.02)
	check(g.hp == 100, "jump clears low rat strike without invulnerability")
	rat.windup = 0.01
	g.jump_height = 0
	g.update_enemy(rat,0.02)
	check(g.hp == 91, "same strike damages grounded hero")
	g.invulnerable = 0
	g.jump_height = 1.3
	g.spawn_shot(Vector3(15,2.3,0),15)
	g.shots[0].velocity = Vector3.ZERO
	g.update_projectiles(0.01)
	check(g.hp == 79, "projectile at airborne torso still connects")
	g.paused = true
	g.jump_velocity = 4
	g._physics_process(0.3)
	check(g.jump_height == 1.3 and g.jump_velocity == 4, "pause freezes jump trajectory")
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("JUMP apex=",apex," FAILURES=",failures)
	quit(1 if failures else 0)
