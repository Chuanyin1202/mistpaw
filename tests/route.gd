extends SceneTree
var render_begin:=0
var render_ms:=0.0
const Driver = preload("res://tests/demo_driver.gd")
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	RenderingServer.frame_pre_draw.connect(func():render_begin=Time.get_ticks_usec())
	RenderingServer.frame_post_draw.connect(func():render_ms=(Time.get_ticks_usec()-render_begin)/1000.0)
	var game = load("res://scenes/main.tscn").instantiate()
	var native := DisplayServer.get_name() != "headless"
	root.title = "Mistpaw 內部渲染檢查 · 約 90 秒自動結束"
	root.close_requested.connect(func():print("ROUTE INTERRUPTED: native window close requested"))
	var view := SubViewport.new()
	view.size = Vector2i(1280,720)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	view.add_child(game)
	if native:
		var display := TextureRect.new()
		display.texture = view.get_texture()
		display.mouse_filter = Control.MOUSE_FILTER_IGNORE
		display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(display)
		root.always_on_top="--visible-benchmark" in OS.get_cmdline_user_args()
		root.grab_focus()
	await process_frame
	if not game.ready_for_play: await game.boot_finished
	game.set_physics_process(false)
	game.sound_voices = 5
	game.music.stop()
	game.set_visual_profile(1 if "--balanced" in OS.get_cmdline_user_args() else (2 if "--clear" in OS.get_cmdline_user_args() else 0),false)
	var last_room := -1
	var held := {}
	var frame_times: Array[float] = []
	var previous_frame := Time.get_ticks_usec()
	var boss_was_winding := false
	var boss_moves: Array[int] = []
	for tick in range(18000):
		if game.ended: break
		var move := 0
		var depth_move := 0
		var nearest: Dictionary = game.nearest_enemy()
		if not nearest.is_empty():
			var dx: float = nearest.node.position.x - game.hero.position.x
			if absf(dx) > 2 or dx*game.facing<0: move = int(signf(dx))
			var dz: float = nearest.node.position.z-game.hero.position.z
			if absf(dz) > 0.25: depth_move = int(signf(dz))
			if absf(dx) < 4: game.try_heavy()
			if absf(dx) < 2.7 and tick % 240 == 0: game.try_spin()
			if game.hero.position.x > 13 and game.hero.position.x < 16: game.try_jump()
			for e in game.enemies:
				if game.dash_cd <= 0 and e.windup > 0 and e.windup < 0.2 and absf(e.aim - game.hero.position.x) < 3:
					game.facing = signf(e.node.position.x - game.hero.position.x)
					game.try_dash()
		elif not game.drops.is_empty():
			move = Driver.loot_movement(game.drops[0].node.position.x - game.hero.position.x)
			var dz: float = game.drops[0].node.position.z-game.hero.position.z
			if absf(dz)>1: depth_move=int(signf(dz))
		else: move = 1
		if game.room==3 and not game.enemies.is_empty():
			var enemy:Dictionary=game.enemies[0]
			if enemy.windup>=0 or (game.boss.pattern==2 and game.boss.active>=0):
				var back:float=game.Forest.road_back(game.hero.position.x)+0.6
				var safe:float=1.1 if absf(1.1-enemy.aim_z)>absf(back-enemy.aim_z) else back
				depth_move=int(signf(safe-game.hero.position.z)) if absf(safe-game.hero.position.z)>0.08 else 0
				if game.boss.pattern==2 and enemy.windup<0.2:game.try_jump()
			if game.boss.land_damaging and game.boss.land_age>0.4 and game.boss.land_age<1.3 and game.jump_height==0:game.try_jump()
		if not game.unlocked.is_empty():
			var choice:int=game.unlocked.back()
			if game.build!=choice:
				var choose:=InputEventKey.new()
				choose.physical_keycode=KEY_1+choice
				choose.pressed=true
				game._unhandled_key_input(choose)

		if tick==900 and "--focus-probe" in OS.get_cmdline_user_args():
			for code in [KEY_A,KEY_D,KEY_W,KEY_S]:
				var release:=InputEventKey.new()
				release.physical_keycode=code
				release.pressed=false
				Input.parse_input_event(release)
			Input.flush_buffered_events()
			print("INPUT_PROBE released held input")
		for key in [KEY_A, KEY_D, KEY_W, KEY_S, KEY_J]:
			var pressed: bool = (key == KEY_A and move < 0) or (key == KEY_D and move > 0) or (key == KEY_W and depth_move < 0) or (key == KEY_S and depth_move > 0) or (key==KEY_J and not nearest.is_empty() and game.ground_distance(nearest.node.position,game.hero.position)<game.sword_reach(false))
			if not pressed and not held.get(key,false): continue
			var repeating: bool = pressed and held.get(key,false) and Input.is_physical_key_pressed(key)
			if pressed and held.get(key,false) and not repeating:print("INPUT_RESTORE tick=",tick," key=",key)
			held[key] = pressed
			var event := InputEventKey.new()
			event.physical_keycode = key
			event.pressed = pressed
			event.echo = repeating
			Input.parse_input_event(event)
		Input.flush_buffered_events()
		var logic_start:=Time.get_ticks_usec()
		game._physics_process(1.0 / 60)
		var boss_enemy:Dictionary=game.enemy_pools[3][0]
		var boss_winding:bool=boss_enemy in game.enemies and boss_enemy.windup>=0
		if boss_winding and not boss_was_winding:
			boss_moves.append(game.boss.pattern)
			print("BOSS MOVE ",game.boss.pattern," phase=",game.boss.phase," boss_hp=",boss_enemy.hp," player_hp=",game.hp)
		boss_was_winding=boss_winding
		var logic_ms:float=(Time.get_ticks_usec()-logic_start)/1000.0
		if game.room != last_room:
			last_room = game.room
			print("ROOM ", game.room, " HP ", game.hp, " TIME ", game.elapsed)
		if native:
			await process_frame
			var now := Time.get_ticks_usec()
			var frame_ms := (now-previous_frame)/1000.0
			frame_times.append(frame_ms)
			if frame_ms > 33.3: print("FRAME_SPIKE tick=",tick," room=",game.room," ms=",frame_ms," logic_ms=",logic_ms," enemies=",game.enemies.size()," fx=",game.build_effects.pool.filter(func(f):return f.node.visible).size()," objects=",Performance.get_monitor(Performance.OBJECT_NODE_COUNT)," draw_ms=",render_ms," process_ms=",Performance.get_monitor(Performance.TIME_PROCESS)*1000," focused=",root.has_focus()," message=",game.message.text)
			previous_frame = now
			if tick % 600 == 0:
				print("ROUTE_INPUT tick=",tick," intended=",move," actual=",game.movement_input()," paused=",game.paused," position=",game.hero.position)
				RenderingServer.force_draw(false)
				view.get_texture().get_image().save_png("res://docs/route-%d.png" % (tick/600))
				previous_frame = Time.get_ticks_usec()
		elif tick % 60 == 0: await process_frame
	print("ROUTE ended=", game.ended, " hp=", game.hp, " room=", game.room, " pickups=", game.pickups, " time=", game.elapsed)
	print("BOSS SEQUENCE ",boss_moves)
	if native:
		await process_frame
		RenderingServer.force_draw(false)
		view.get_texture().get_image().save_png("res://docs/route-result.png")
	var success: bool = game.ended and game.hp > 0 and game.room == 3 and game.pickups == 4
	if not frame_times.is_empty():
		frame_times.sort()
		print("NATIVE frame interval ms median=",frame_times[frame_times.size()/2]," p95=",frame_times[int(frame_times.size()*0.95)]," max=",frame_times[-1]," (screenshot readbacks excluded; scripted 60Hz combat)")
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if success else 1)
