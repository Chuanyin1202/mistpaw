extends SceneTree
var failures := 0
func check(ok: bool, title: String):
	print(("PASS " if ok else "FAIL ") + title)
	if not ok: failures += 1
func _initialize():
	call_deferred("run")
func run():
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	if not game.ready_for_play: await game.boot_finished
	game.set_physics_process(false)
	game.take_damage(1000)
	check(game.ended and game.result_overlay.visible and game.result_title.text == "力竭倒下", "death displays explicit result overlay")
	check(game.retry_button.has_focus() and not game.help.visible and game.music.stream_paused, "death focuses retry, hides combat controls and pauses music")
	var x: float = game.hero.position.x
	game._physics_process(1)
	check(game.hero.position.x == x and game.hp == 0, "death stops combat")
	if DisplayServer.get_name() != "headless":
		for i in range(10): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/death-retry.png")
	game.retry_button.pressed.emit()
	await process_frame
	await process_frame
	var fresh = current_scene
	fresh.set_physics_process(false)
	check(fresh != game and fresh.hp == 100 and not fresh.ended and not fresh.result_overlay.visible, "retry button reloads a live run")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_D
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	fresh._physics_process(0.1)
	key = key.duplicate()
	key.pressed = false
	Input.parse_input_event(key)
	print("RETRY x=",fresh.hero.position.x," hp=",fresh.hp," enemies=",fresh.enemies.size())
	check(fresh.hero.position.x > 0 and fresh.enemies.size() == 5, "retry restores movement and encounter")
	fresh.take_damage(1000)
	key = InputEventKey.new()
	key.physical_keycode = KEY_R
	key.pressed = true
	fresh._unhandled_key_input(key)
	await process_frame
	await process_frame
	check(current_scene != fresh and current_scene.hp == 100, "R also restarts after death")
	var before_enter = current_scene
	before_enter.take_damage(1000)
	var enter := InputEventKey.new()
	enter.physical_keycode = KEY_ENTER
	enter.keycode = KEY_ENTER
	enter.pressed = true
	Input.parse_input_event(enter)
	Input.flush_buffered_events()
	enter = enter.duplicate()
	enter.pressed = false
	Input.parse_input_event(enter)
	Input.flush_buffered_events()
	await process_frame
	await process_frame
	check(current_scene != before_enter and current_scene.hp == 100, "Enter activates the focused retry button")
	current_scene.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("FAILURES: ", failures)
	quit(1 if failures else 0)
