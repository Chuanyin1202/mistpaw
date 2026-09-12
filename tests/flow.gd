extends SceneTree
var failures := 0
func check(ok: bool, title: String):
	print(("PASS " if ok else "FAIL ") + title)
	if not ok: failures += 1
func key(code: int, pressed: bool):
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func _initialize(): call_deferred("run")
func run():
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	if not game.ready_for_play: await game.boot_finished
	game.set_physics_process(false)
	game.sound_voices = 5
	game.music.stop()
	var pool_id: int = game.enemy_pools[1][0].node.get_instance_id()
	var first_id: int = game.enemies[0].node.get_instance_id()
	for e in game.enemies: e.node.position.x = 50
	game.hero.position.x = 0
	key(KEY_D, true)
	for power in [false,true]:
		var before: float = game.hero.position.x
		game.start_attack(power)
		for i in range(5): game._physics_process(0.1)
		check(is_equal_approx(game.hero.position.x-before,2.25), "movement continues throughout %s" % ("heavy" if power else "basic"))
	game.hero.position.x = 11.95
	game.attack_time = -1
	game._physics_process(0.1)
	check(game.room == 0 and game.enemies.size() == 5, "walking onward does not skip unfinished formations")
	check(game.enemy_pools[1][0].node.get_instance_id() == pool_id, "area activation reuses the prebuilt actors")
	check(game.enemies[0].node.get_instance_id() == first_id, "previous enemies are not discarded")
	game.hero.position.x = 27.99
	game._physics_process(0.1)
	check(game.hero.position.x > 28, "old right-side arena wall is gone")
	key(KEY_D, false)
	key(KEY_A, true)
	game.hero.position.x = 24.01
	game._physics_process(0.1)
	check(game.hero.position.x < 24, "backtracking through previous area is unrestricted")
	key(KEY_A, false)
	var fx_id: int = game.effects.slash.get_instance_id()
	for facing in [-1,1]:
		game.facing = facing
		game.slash_effect(2.7,Color.WHITE,false)
		check(game.effects.slash.get_instance_id() == fx_id, "slashes reuse one render object")
		var difference: float = game.effects.slash.position.x-game.hero.position.x
		check(difference*facing > 0, "slash starts on correct side")
		var old_x: float = game.effects.slash.position.x
		game.hero.position.x += 1
		game.effects.advance(0.02,game.hero.position)
		check(is_equal_approx(game.effects.slash.position.x-old_x,1), "slash stays attached to moving actor")
	game.paused = true
	var fx_age: float = game.effects.age
	game._physics_process(0.5)
	check(game.effects.age == fx_age, "pause freezes combat effects")
	game.paused = false
	game.effects.advance(1,game.hero.position)
	check(not game.effects.slash.visible, "finished slash leaves no residual quad")
	# Inactive pools cannot grant rewards; each area gives its relic only once.
	for e in game.enemy_pools[1].duplicate(): game.damage_enemy(e,1000)
	check(game.cleared == 0 and game.drops.is_empty(), "inactive area cannot grant a reward")
	for e in game.enemy_pools[0].duplicate(): game.damage_enemy(e,1000)
	check(game.cleared == 0 and game.drops.size() == 1 and game.encounter_flow.pending == 0, "first formation grants relic and schedules next formation")
	game.feedback.clear()
	for child in game.get_children():
		if child is AudioStreamPlayer:child.stop()
	await create_timer(.3).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("FAILURES: ",failures)
	quit(1 if failures else 0)
