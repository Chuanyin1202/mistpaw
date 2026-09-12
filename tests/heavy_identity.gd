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
	for e in g.enemies: e.node.hide()
	g.enemies.clear()
	g.room = 2
	g.spawn_room()
	for e in g.enemies: e.node.position.x = 55
	var elite = g.enemy_pools[2][4]
	g.hero.position.x = 14
	g.camera.position.x = 16.5
	g.forest.follow_camera(16.5)
	elite.node.position.x = 16
	elite.windup = 0.5
	elite.aim = 14
	g.start_attack(false)
	g._physics_process(0.05)
	var basic_texture = g.hero.texture
	g.start_attack(true)
	g._physics_process(0.13)
	check(g.hero.texture != basic_texture and g.hero.vframes == 4, "heavy has its own eight-frame two-handed animation")
	check(elite.hp == 100, "heavy windup does not deal premature damage")
	await capture(view,"heavy-windup")
	g._physics_process(0.065)
	check(elite.hp == 56 and g.contact_done, "heavy contact applies original damage once")
	check(elite.stagger > 0 and elite.windup < 0, "heavy interrupts surviving elite windup")
	check(elite.recoil > 0.8, "heavy reaction exceeds ordinary elite recoil")
	check(g.effects.impacts.any(func(h): return h.node.visible), "contact flash appears only with actual hit")
	await capture(view,"heavy-contact")
	var active = g.effects.impacts.filter(func(h): return h.node.visible)[0]
	var at: Vector3 = active.node.position
	g.hero.position.x -= 1
	g.effects.advance(0.01,g.hero.position)
	check(active.node.position == at, "impact stays on enemy contact point rather than following hero")
	var age: float = active.age
	g.paused = true
	g._physics_process(0.4)
	check(active.age == age, "pause freezes contact flash")
	g.paused = false
	g.effects.advance(0.3,g.hero.position)
	check(not active.node.visible, "contact flash clears quickly")
	var boss = g.enemy_pools[3][0]
	g.enemies.append(boss)
	boss.windup = 0.5
	g.damage_enemy(boss,44,2.6)
	check(boss.windup == 0.5 and boss.stagger == 0, "boss retains windup under heavy hit")
	g.effects.clear()
	check(g.effects.impacts.all(func(h): return not h.node.visible), "clear removes every pooled impact")
	g.feedback.clear()
	for child in g.get_children():
		if child is AudioStreamPlayer:child.stop()
	await create_timer(0.3).timeout
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("HEAVY FAILURES=",failures)
	quit(1 if failures else 0)
func capture(view: SubViewport, name: String):
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await process_frame
	RenderingServer.force_draw(false)
	view.get_texture().get_image().save_png("res://docs/"+name+".png")
