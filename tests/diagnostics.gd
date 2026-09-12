extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var view := SubViewport.new()
	view.size = Vector2i(1280, 720)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var game = load("res://scenes/main.tscn").instantiate()
	view.add_child(game)
	await process_frame
	if not game.ready_for_play: await game.boot_finished
	game.set_physics_process(false)
	game.music.stop()
	game.sound_voices = 5
	for i in range(5): await process_frame
	RenderingServer.force_draw(false)
	for zone in range(1, 4):
		for e in game.enemies: e.node.hide()
		game.enemies.clear()
		await process_frame
		game.room = zone
		var begin := Time.get_ticks_usec()
		game.encounter_started[game.room] = false
		game.spawn_room()
		var spawned := Time.get_ticks_usec()
		game.hero.position.x = zone * 14 + 2
		game.camera.position.x = zone * 14 + 4.5
		game.forest.follow_camera(game.camera.position.x)
		await process_frame
		RenderingServer.force_draw(false)
		var drawn := Time.get_ticks_usec()
		print("PROFILE/flow room=",zone," spawn_cpu_ms=",(spawned-begin)/1000.0," through_first_draw_ms=",(drawn-begin)/1000.0)
	for e in game.enemies: e.node.position.x = 55
	game.room = 1
	game.hero.position.x = 16
	game.start_attack(false)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_D
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	for i in range(5):
		game._physics_process(0.1)
		print("PROFILE/flow attack=",game.attack_time," held_right=",Input.is_physical_key_pressed(KEY_D)," hero_x=",game.hero.position.x," world_elapsed=",game.elapsed)
	game.attack_time = -1
	game.hero.position.x = 27.99
	game._physics_process(0.1)
	print("PROFILE/flow wall right x=",game.hero.position.x," enemies=",game.enemies.size()," room=",game.room)
	key = key.duplicate()
	key.pressed = false
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	game.hero.position.x = 2
	game.camera.position.x = 4.5
	game.forest.follow_camera(4.5)
	for direction in [-1, 1]:
		game.facing = direction
		game.slash_effect(2.7,Color.WHITE,false)
		var fx = game.effects.slash
		for frame in range(4):
			game.effects.slash_material.set_shader_parameter("life", frame / 4.0)
			await process_frame
			await process_frame
			RenderingServer.force_draw(false)
			view.get_texture().get_image().save_png("/private/tmp/mistpaw-fx-after-%d-%d.png" % [direction,frame])
			print("PROFILE/flow fx direction=",direction," life=",frame/4.0," x=",fx.position.x)
		game.effects.clear()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
