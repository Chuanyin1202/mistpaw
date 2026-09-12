extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var game = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(game)
	await process_frame
	if not game.ready_for_play: await game.boot_finished
	game.set_physics_process(false)
	game.music.stop()
	for zone in range(4):
		for e in game.enemies: e.node.hide()
		game.enemies.clear()
		game.room = zone
		game.encounter_started[game.room] = false
		game.spawn_room()
		game.hero.position.x = zone * 14 + 2
		game.camera.position.x = clampf(game.hero.position.x + 2.5, 3, 47)
		game.forest.follow_camera(game.camera.position.x)
		game.update_hud()
		for e in game.enemies: game.update_enemy(e, 0.01)
		for i in range(5): await process_frame
		RenderingServer.force_draw(false)
		viewport.get_texture().get_image().save_png("res://docs/scene-%d.png" % zone)
		print("CAPTURE zone=",zone)
	game.room = 0
	game.hero.position.x = 2
	game.camera.position.x = 4.5
	game.forest.follow_camera(4.5)
	for e in game.enemies: e.node.position.x = 40
	for step in range(4):
		var key := InputEventKey.new()
		key.physical_keycode = KEY_D
		key.pressed = true
		Input.parse_input_event(key)
		Input.flush_buffered_events()
		game._physics_process(0.112)
		await process_frame
		await process_frame
		RenderingServer.force_draw(false)
		viewport.get_texture().get_image().save_png("res://docs/walk-%d.png" % step)
		print("WALK frame=",game.hero.frame," x=",game.hero.position.x," texture=",game.hero.texture.resource_path)
	var release := InputEventKey.new()
	release.physical_keycode = KEY_D
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	game.hero.position.x = 2
	game.camera.position.x = 4.5
	game.forest.follow_camera(4.5)
	game.enemies[0].node.position.x = 4.6
	game.start_attack(false)
	for step in range(3):
		game._physics_process(0.07)
		if step == 1:
			for tween in get_processed_tweens(): tween.pause()
			game.effects.slash_material.set_shader_parameter("life", 0.1)
		await process_frame
		await process_frame
		RenderingServer.force_draw(false)
		viewport.get_texture().get_image().save_png("res://docs/strike-%d.png" % step)
		print("STRIKE frame=",game.hero.frame," hp=",game.enemies[0].hp)
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
