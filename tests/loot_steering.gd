extends SceneTree
const Driver = preload("res://tests/demo_driver.gd")
var failures := 0
func _initialize(): call_deferred("run")
func run():
	for manual in [false,true]:
		var g = load("res://scenes/main.tscn").instantiate()
		root.add_child(g)
		await process_frame
		if not g.ready_for_play: await g.boot_finished
		g.set_physics_process(false)
		g.music.stop()
		g.sound_voices = 5
		for e in g.enemies: e.node.hide()
		g.enemies.clear()
		g.spawn_drop(Vector3(0.02,0,0),0)
		var flips := 0
		var last: bool = g.hero.flip_h
		for tick in range(180):
			if g.drops.is_empty(): break
			var dx: float = g.drops[0].node.position.x-g.hero.position.x
			var move := 0 if manual else Driver.loot_movement(dx)
			for key in [KEY_A,KEY_D]:
				var event := InputEventKey.new()
				event.physical_keycode = key
				event.pressed = (key == KEY_A and move < 0) or (key == KEY_D and move > 0)
				Input.parse_input_event(event)
			Input.flush_buffered_events()
			g._physics_process(1.0/60)
			if last != g.hero.flip_h:
				flips += 1
				if flips <= 4: print("LOOT_STEERING manual=",manual," dx=",dx," move=",move," flip_h=",g.hero.flip_h)
			last = g.hero.flip_h
		print("LOOT_STEERING RESULT manual=",manual," flips=",flips," pickups=",g.pickups)
		if flips != 0 or g.pickups != 1: failures += 1
		g.queue_free()
		await process_frame
	await create_timer(0.2).timeout
	for dx in [-7.0,7.0]:
		if Driver.loot_movement(dx) != int(signf(dx)): failures += 1
	print("LOOT STEERING FAILURES=",failures)
	quit(1 if failures else 0)
