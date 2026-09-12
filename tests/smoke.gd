extends SceneTree
var failures := 0

func check(ok: bool, title: String) -> void:
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + title)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.music.stop()
	check(game.enemies.size() == 5, "first encounter contains a group")
	for e in game.enemies.slice(1):
		e.node.hide()
	game.enemies.resize(1)
	var enemy: Dictionary = game.enemies[0]
	enemy.node.position.x = 1.5
	enemy.node.position.z = 0
	game.hero.position.x = 0
	game.facing = 1
	game.start_attack(false)
	game._physics_process(0.05)
	check(enemy.hp == 36, "windup does not cause premature damage")
	game._physics_process(0.06)
	check(enemy.hp == 19, "contact applies damage exactly once")
	game._physics_process(0.05)
	check(enemy.hp == 19, "same attack cannot hit twice")
	game.attack_time = -1
	game.try_dash()
	game.take_damage(20)
	check(game.hp == 100, "dodge protects the player")
	game.invulnerable = 0
	game.take_damage(20)
	check(game.hp == 80, "player can take damage")
	game.damage_enemy(enemy, 100)
	check(game.enemies.is_empty() and game.drops.size() == 1, "clear grants one physical drop")
	check(game.pickups == 0, "ground drop does not grant before pickup")
	game.hero.position.x = game.drops[0].node.position.x
	for i in range(60): game.update_loot(0.05)
	check(game.pickups == 1 and game.build == 0 and game.drops.is_empty(), "absorption grants and equips exactly once")
	game.update_loot(1)
	check(game.pickups == 1, "pickup is idempotent")
	for wave in range(2):
		game.update_deaths(1)
		game.encounter_flow.rest=0
		game.encounter_flow.advance(0.01)
		for e in game.enemies.duplicate():game.damage_enemy(e,10000)
	game.hero.position.x = 12
	game.dash_time = 0
	game._physics_process(0.02)
	check(game.room == 1 and game.enemies.size() == 7, "moving onward opens mixed encounter")
	check(game.hp == 100, "room transition restores bounded health")
	var ranged: Dictionary = game.enemies[2]
	ranged.node.position.x = game.hero.position.x + 5
	ranged.clock = 4
	game.last_enemy_telegraph = game.elapsed - 1
	game.update_enemy(ranged, 0.01)
	check(ranged.windup > 0, "ranged attack gives a telegraph")
	game.update_enemy(ranged, 0.9)
	check(game.shots.size() == 1, "ranged telegraph emits an actual projectile")
	game.invulnerable = 0
	game.take_damage(1000)
	check(game.ended and game.hp == 0, "death reaches retry state")
	game.queue_free()
	await process_frame
	var fresh = load("res://scenes/main.tscn").instantiate()
	root.add_child(fresh)
	await process_frame
	fresh.set_physics_process(false)
	check(fresh.hp == 100 and not fresh.ended and fresh.room == 0, "fresh run resets combat state")
	fresh.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("FAILURES: ", failures)
	quit(1 if failures else 0)
