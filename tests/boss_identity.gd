extends SceneTree
var failures := 0
func check(ok: bool, title: String):
	print(("PASS " if ok else "FAIL ")+title)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func run():
	var view := SubViewport.new()
	view.size = Vector2i(1280,720)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var g = load("res://scenes/main.tscn").instantiate()
	view.add_child(g)
	await process_frame
	if not g.ready_for_play: await g.boot_finished
	g.set_physics_process(false)
	g.music.stop()
	g.sound_voices = 5
	for enemy in g.enemies: enemy.node.hide()
	g.enemies.clear()
	g.room = 3
	g.spawn_room()
	var e = g.enemy_pools[3][0]
	g.hero.position.x = 44
	g.camera.position.x = 46
	g.forest.follow_camera(46)
	e.node.position.x = 46.5
	e.windup = 0.9
	e.aim = 44
	var hp: float = g.hp
	g.update_enemy(e,0.1)
	check(e.node.frame == 0 and e.node.texture != e.texture, "boss braces with independent attack art")
	g.update_enemy(e,0.5)
	check(e.node.frame == 1 and g.hp == hp, "raised claw telegraphs before damage")
	await capture(view,"boss-windup")
	e.flash = 0.1
	g.update_enemy(e,0.01)
	check(e.node.frame == 1, "taking damage preserves readable boss windup")
	g.update_enemy(e,0.3)
	check(e.node.frame == 2 and g.hp == hp-24, "claw contact and damage coincide")
	await capture(view,"boss-contact")
	g.hero.position.x = 49
	g.update_enemy(e,0.12)
	check(e.node.frame == 3 and e.node.flip_h, "follow-through keeps attack direction when hero crosses behind")
	check(g.hp == hp-24, "recovery does not repeat damage")
	await capture(view,"boss-recovery")
	g.update_enemy(e,0.2)
	check(e.node.texture == e.texture and not e.node.flip_h, "boss returns to locomotion and reacquires target")
	e.windup = 0.1
	e.aim = 44
	g.invulnerable = 0
	g.update_enemy(e,0.11)
	check(g.hp == hp-24, "escaping telegraphed location avoids claw hit")
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("BOSS FAILURES=",failures)
	quit(1 if failures else 0)
func capture(view: SubViewport, name: String):
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await process_frame
	RenderingServer.force_draw(false)
	view.get_texture().get_image().save_png("res://docs/"+name+".png")
