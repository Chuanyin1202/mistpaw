extends SceneTree
var failures := 0
func check(ok: bool, title: String):
	print(("PASS " if ok else "FAIL ") + title)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func run():
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	if not game.ready_for_play: await game.boot_finished
	game.set_physics_process(false)
	game.music.stop()
	for zone in range(4):
		for enemy in game.enemies: enemy.node.hide()
		game.enemies.clear()
		game.room = zone
		game.encounter_started[game.room] = false
		game.spawn_room()
		var actors:Array=game.enemies.duplicate()
		for e in actors:
			# Isolate pursuit from crowd separation; the old fixture stacked the
			# whole encounter at x=7 and mistook avoidance for reversed walking.
			game.enemies.clear()
			game.enemies.append(e)
			e.node.position.x = 7
			e.windup = -1
			e.clock = 0
			game.hero.position.x = -3
			game.update_enemy(e, 0.1)
			check(e.node.flip_h and e.node.position.x < 7, "kind %d approaches left facing left" % e.kind)
			e.clock = 0
			game.hero.position.x = 17
			var previous: float = e.node.position.x
			game.update_enemy(e, 0.1)
			check(not e.node.flip_h and e.node.position.x > previous, "kind %d approaches right facing right" % e.kind)
			e.windup = 0.5
			e.aim = e.node.position.x - 2
			game.update_enemy(e, 0.1)
			check(e.node.flip_h, "telegraph retains its attack direction when player passes behind")
		for e in actors:e.node.hide()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(1 if failures else 0)
