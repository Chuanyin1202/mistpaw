extends SceneTree
var failures := 0
func check(ok: bool, title: String):
	print(("PASS " if ok else "FAIL ")+title)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func run():
	var g = load("res://scenes/main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	if not g.ready_for_play: await g.boot_finished
	g.set_physics_process(false)
	g.music.stop()
	g.sound_voices = 5
	var rat = g.enemies[0]
	rat.clock = 0
	rat.node.position.x = 8
	var frames := {}
	for i in range(4):
		g.update_enemy(rat,0.112)
		frames[rat.node.frame] = true
	check(frames.size() == 4 and rat.node.texture.resource_path.ends_with("rat-run.png"), "moving rat advances four actual gait poses")
	check(rat.node.flip_h, "new gait retains leftward approach facing")
	g.damage_enemy(rat,17)
	var before: float = rat.node.position.x
	g.update_enemy(rat,0.02)
	check(rat.node.position.x > before and rat.flash > 0, "hit visibly recoils target without global freeze")
	g.damage_enemy(rat,100)
	check(not rat in g.enemies and rat in g.dying and rat.node.visible, "death removes combat target while playing visible exit")
	g.update_deaths(0.1)
	check(rat.node.visible and rat.node.frame > 0 and rat.node.texture == g.ENEMY_FALL_TEXTURES[0] and rat.node.scale == Vector3.ONE, "death advances drawn collapse poses without shrinking the body")
	var t: float = rat.death_time
	g.paused = true
	g._physics_process(0.5)
	check(rat.death_time == t, "pause freezes death presentation")
	g.update_deaths(0.2)
	check(not rat.node.visible and not rat in g.dying, "death presentation terminates and pooled actor hides")
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("ENEMY MOTION FAILURES=",failures)
	quit(1 if failures else 0)
