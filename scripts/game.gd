extends Node3D
## Prototype ownership: combat resolves only at contact; loot grants on arrival.
const CombatFx = preload("res://scripts/combat_fx.gd")
const Forest = preload("res://scripts/forest.gd")
const BUILD_NAMES = ["衝擊波", "連鎖雷", "嗜血刃"]
const BUILD_DETAILS = ["橫掃清群 · 重劈波刃延伸至遠處", "突刺引雷 · 連段末式多跳一敵，重劈落雷", "近身交叉斬 · 命中回復生命，傷害略降"]
const COLORS = [Color("8bd7e7"), Color("e4b6ff"), Color("ffcb79")]
const ENEMY_ATTACK_TEXTURES = [preload("res://assets/art/rat-bite.png"),preload("res://assets/art/weasel-pounce.png"),preload("res://assets/art/toad-spit.png"),preload("res://assets/art/elite-maul.png"),preload("res://assets/art/boss-claw.png")]
const ENEMY_FALL_TEXTURES = [preload("res://assets/art/rat-fall.png"),preload("res://assets/art/weasel-fall.png"),preload("res://assets/art/toad-fall.png"),preload("res://assets/art/elite-fall.png"),preload("res://assets/art/boss-fall.png")]
const ENEMY_FALL_DURATIONS = [0.28,0.30,0.40,0.42,0.60]
var encounter_flow:Node
var ui:CanvasLayer
var feedback:Node3D
var forest: Node3D
var camera: Camera3D
var hero: Sprite3D
var hud: Label
var help: Label
var message: Label
var health: ProgressBar
var enemies: Array[Dictionary] = []
var dying: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var hp := 100.0
var hurt_time:=0.0
var hero_death_time:=-1.0
var damage_edge:ColorRect
var facing := 1.0
var attack_cd := 0.0
var auto_attack:=false
var touch_movement:=Vector2.ZERO
var touch_running:=false
var visual_profile:=0
var attack_held:=false
var attack_buffer:=0.0
var buffered_facing:=1.0
var heavy_facing:=1.0
const INPUT_BUFFER:=0.55
var attack_time := -1.0
var attack_power := false
var contact_done := false
var attack_settle := 0.0
var attack_entry_pose:=false
var settle_texture:Texture2D
var combo_stage := 0
var combo_next := 0
var combo_window := 0.0
const COMBO_CONTACTS = [BASIC_CONTACT, 0.085, 0.095]
const COMBO_DURATIONS = [BASIC_DURATION, 0.25, 0.29]
const COMBO_COOLDOWNS = [0.32, 0.27, 0.34]
const COMBO_TEXTURES = [preload("res://assets/art/cat-cut-eight.png"),preload("res://assets/art/cat-combo-sweep.png"),preload("res://assets/art/cat-combo-thrust.png")]
var heavy_buffer := 0.0
var jump_height := 0.0
var jump_velocity := 0.0
var jumps_used := 0
var landing_time := 0.0
var spin_time := -1.0
var spin_cd := 0.0
var spin_buffer := 0.0
var spin_hits := 0
const HERO_GROUND_Y := 1.87
const BASIC_CONTACT := 0.105
const HEAVY_CONTACT := 0.19
const BASIC_DURATION := 0.30
const HEAVY_DURATION := 0.48
var dash_time := 0.0
const DASH_DURATION:=0.18
const DASH_DISTANCE:=4.08
var dodge_effects:Node3D
var dash_cd := 0.0
var dash_direction := Vector2.RIGHT
var last_direction_tap := 0.0
var last_direction_time := -1.0
var last_tap_facing := 1.0
const DIRECTION_TAP_WINDOW := 0.16
var run_direction := 0.0
var backstep_time := 0.0
var backstep_cd := 0.0
var backstep_pose_time := 0.0
var locomotion_depth := 0.0
var skill_cd := 0.0
var invulnerable := 0.0
var elapsed := 0.0
var idle_time := 0.0
var last_enemy_telegraph := -10.0
const ENEMY_INTERVALS = [1.65, 2.5, 3.1, 2.7]
const ENEMY_WINDUPS = [0.45, 0.70, 0.85, 0.95]
const ENEMY_RECOVERIES = [0.20, 0.48, 0.60, 0.70]
var room := 0
var cleared := 0
var build := -1
var unlocked: Array[int] = []
var ended := false
var paused := false
var muted := false
var sound_voices := 0
var pickups := 0
var best := 0
var important_sound:AudioStreamPlayer
var pickup_player:AudioStreamPlayer
var mix_duck:=0.0
var music: AudioStreamPlayer
var boss_music: AudioStreamPlayer
var boss_music_mix:=-1.0
var toast_time := 0.0
var result_overlay: ColorRect
var result_title: Label
var result_detail: Label
var retry_button: Button
var restarting := false
var walk_time := 0.0
var was_walking:=false
signal boot_finished
var ready_for_play := false
var enemy_pools: Array = []
var encounter_started: Array[bool] = [false, false, false, false]
var encounter_cleared: Array[bool] = [false, false, false, false]
var shadow_material: ShaderMaterial
var effects: Node3D
var build_effects: Node3D
var readability: Node3D
var boss:Node3D
var pickup_wave: AudioStreamWAV
const SOUNDS = {
 "boss-rage.wav":preload("res://assets/audio/boss-rage.wav"),
 "boss-charge.wav":preload("res://assets/audio/boss-charge.wav"),
 "boss-fracture.wav":preload("res://assets/audio/boss-fracture.wav"),
 "boss-slam.wav":preload("res://assets/audio/boss-slam.wav"),
 "stone-contact.wav":preload("res://assets/audio/stone-contact.wav"),
 "wave-air.wav":preload("res://assets/audio/wave-air.wav"),
 "chain-snap.wav":preload("res://assets/audio/chain-snap.wav"),
 "vital-arrival.wav":preload("res://assets/audio/vital-arrival.wav"),
 "blade-contact.wav": preload("res://assets/audio/blade-contact.wav"),
 "blade-weight.wav": preload("res://assets/audio/blade-weight.wav"),
 "beast-down.mp3": preload("res://assets/audio/beast-down.mp3"),
 "stage-clear.mp3": preload("res://assets/audio/stage-clear.mp3"),
}


func _ready() -> void:
	print("BOOT ready-start ms=",Time.get_ticks_msec())
	get_window().focus_exited.connect(_release_attack_input)
	forest = Forest.new()
	add_child(forest)
	shadow_material = ShaderMaterial.new()
	shadow_material.shader = preload("res://shaders/contact_shadow.gdshader")
	hero = actor("cat-cut-eight.png", 0, 0.022)
	hero.vframes = 4
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 38
	camera.size = 13
	# Retreat 14% along the existing view direction; keep the same pitch and FOV.
	camera.position = Vector3(3, 10.078, 20.52)
	add_child(camera)
	camera.look_at(Vector3(3, 1.3, 0))
	camera.current = true
	readability=preload("res://scripts/combat_readability.gd").new()
	add_child(readability)
	var lens := CameraAttributesPractical.new()
	lens.dof_blur_far_enabled = RenderingServer.get_current_rendering_method() != "gl_compatibility"
	lens.dof_blur_far_distance = 38.0
	lens.dof_blur_far_transition = 18.0
	lens.dof_blur_near_enabled = RenderingServer.get_current_rendering_method() != "gl_compatibility"
	lens.dof_blur_near_distance = 18.74
	lens.dof_blur_near_transition = 4.0
	lens.dof_blur_amount = 0.012
	camera.attributes = lens
	make_hud()
	var preferences:=ConfigFile.new()
	if preferences.load("user://preferences.cfg")==OK:
		set_visual_profile(clampi(int(preferences.get_value("display","profile",0)),0,2),false)
	var save := ConfigFile.new()
	if save.load("user://progress.cfg") == OK:
		best = int(save.get_value("progress", "best", 0))
	effects = CombatFx.new()
	add_child(effects)
	build_effects=preload("res://scripts/build_fx.gd").new()
	add_child(build_effects)
	dodge_effects=preload("res://scripts/dodge_fx.gd").new()
	add_child(dodge_effects)
	prepare_encounters()
	encounter_flow=preload("res://scripts/encounter_flow.gd").new()
	add_child(encounter_flow)
	boss=preload("res://scripts/boss_combat.gd").new()
	add_child(boss)
	feedback=preload("res://scripts/combat_feedback.gd").new()
	add_child(feedback)
	pickup_wave = create_pickup_wave()
	music = AudioStreamPlayer.new()
	music.stream = load("res://assets/audio/forest-battle.ogg")
	music.volume_db = -8
	music.bus="Music"
	important_sound=AudioStreamPlayer.new()
	important_sound.bus="Impact"
	add_child(important_sound)
	pickup_player=AudioStreamPlayer.new()
	pickup_player.bus="Pickup"
	add_child(pickup_player)
	advance_audio(0)
	add_child(music)
	music.finished.connect(func():
		if boss_music_mix<0 and not ended:music.play())
	boss_music=AudioStreamPlayer.new()
	boss_music.stream=preload("res://assets/audio/boss-battle.ogg")
	boss_music.bus="Music"
	boss_music.volume_db=-60
	add_child(boss_music)
	boss_music.finished.connect(func():
		if not ended:boss_music.play())
	print("BOOT scene-built ms=",Time.get_ticks_msec())
	result_title.text = "正在準備青霧林"
	result_detail.text = "整理行裝與場景光影…"
	retry_button.hide()
	result_overlay.color.a = 1.0
	result_overlay.show()
	# Render the actual actor/material/font variants before gameplay, then reuse
	# those nodes. Resource loading and pipeline compilation stay off transitions.
	if DisplayServer.get_name() != "headless":
		# One representative per enemy kind warms the same Web shader pipelines;
		# drawing every pooled duplicate together only adds overdraw on phones.
		var warmed_kinds:Dictionary={}
		for pool in enemy_pools:
			for e in pool:
				if OS.has_feature("web") and warmed_kinds.has(e.kind):continue
				warmed_kinds[e.kind]=true
				e.node.show()
				e.node.position.x = 3
				e.label.text = "0123456789 / 攻擊投石重擊衝撞側移躍擊離開落點狂怒留意震波收勢反擊機會"
				e.windup = 0.5
				e.marker.update_for(e)
		effects.strike(hero.position, 1.0, 4.2, Color.WHITE, true)
		effects.impact(hero.position, 2.6)
		effects.enemy_strike(hero.position, 1.0, 3.0)
		var warm_label: Label3D = floating("0123456789−踉蹌投石重擊", hero.position, Color.WHITE)
		var warm_stone=forest.sprite("stone-flight.png",Vector3(3,1,0),0.006)
		warm_stone.hframes=2
		warm_stone.vframes=2
		warm_stone.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
		var warm_loot = preload("res://scripts/loot_light.gd").new()
		add_child(warm_loot)
		warm_loot.position = Vector3(3,0.2,0)
		warm_loot.setup(COLORS[2],2)
		for kind in range(4):
			build_effects.emit(kind,hero.position,hero.position+Vector3(2,0,0),1)
		feedback.guard_target=hero
		feedback.guard_age=0
		feedback.heal_age=0
		feedback.advance(0)
		var saved_texture=hero.texture
		var saved_rows=hero.vframes
		hero.texture=preload("res://assets/art/cat-rush.png")
		hero.vframes=2
		dash_time=DASH_DURATION
		dodge_effects.advance(0,self)
		await get_tree().process_frame
		if not OS.has_feature("web"):RenderingServer.force_draw(false)
		dash_time=0
		dodge_effects.clear()
		print("BOOT initial-materials ms=",Time.get_ticks_msec())
		for stage in range(COMBO_TEXTURES.size()):
			effects.strike(hero.position,1.0,2.7,Color.WHITE,false,stage)
			hero.texture=COMBO_TEXTURES[stage]
			hero.vframes=4
			await get_tree().process_frame
			if not OS.has_feature("web"):RenderingServer.force_draw(false)
		for texture in [preload("res://assets/art/cat-walk-toward.png"),preload("res://assets/art/cat-walk-away.png"),preload("res://assets/art/cat-run.png"),preload("res://assets/art/cat-backstep.png"),preload("res://assets/art/cat-hurt.png"),preload("res://assets/art/cat-fall.png")]:
			hero.texture=texture
			hero.vframes=2
			await get_tree().process_frame
			if not OS.has_feature("web"):RenderingServer.force_draw(false)
		print("BOOT hero-materials ms=",Time.get_ticks_msec())
		hero.texture=saved_texture
		hero.vframes=saved_rows
		if not OS.has_feature("web"):RenderingServer.force_draw(false)
		warm_label.font_size=124
		await get_tree().process_frame
		if not OS.has_feature("web"):RenderingServer.force_draw(false)
		warm_label.queue_free()
		warm_stone.queue_free()
		warm_loot.queue_free()
		for textures in [ENEMY_ATTACK_TEXTURES,ENEMY_FALL_TEXTURES]:
			for pool in enemy_pools:
				for e in pool:e.node.texture=textures[e.kind]
			await get_tree().process_frame
			if not OS.has_feature("web"):RenderingServer.force_draw(false)
	if DisplayServer.get_name() != "headless":
		for texture in [boss.CHARGE,boss.LEAP]:
			enemy_pools[3][0].node.texture=texture
			await get_tree().process_frame
			if not OS.has_feature("web"):RenderingServer.force_draw(false)
		boss.land_age=0.1
		boss.advance_effects(0)
		await get_tree().process_frame
		if not OS.has_feature("web"):RenderingServer.force_draw(false)
		boss.clear()
	for pool in enemy_pools:
		for e in pool:
			e.windup = -1.0
			e.marker.hide()
			e.node.position = e.home
			e.node.texture = e.texture
			e.node.hide()
			e.label.text = ""
	effects.clear()
	build_effects.clear()
	feedback.clear()
	if jump_height<0.25:forest.atmosphere.disturb(hero.position,0.35)
	print("BOOT warmup-finished ms=",Time.get_ticks_msec())
	spawn_room()
	ready_for_play = true
	result_overlay.color.a = 0.88
	result_overlay.hide()
	retry_button.show()
	music.play()
	print("BOOT playable ms=",Time.get_ticks_msec())
	boot_finished.emit()
	toast("持續推動加速 · 點法寶切換" if DisplayServer.is_touchscreen_available() else "WASD 走位 · J 連斬 · L 閃避", 5)

func _exit_tree() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null

func actor(file: String, x: float, pixel: float) -> Sprite3D:
	var n: Sprite3D = forest.sprite(file, Vector3(x, 85 * pixel, 0), pixel)
	n.hframes = 2
	n.vframes = 2
	n.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	var shadow := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(pixel * 65, pixel * 28)
	shadow.mesh = quad
	shadow.rotation.x = -PI / 2
	shadow.position.y = -85 * pixel + 0.14
	shadow.material_override = shadow_material
	n.add_child(shadow)
	return n

func make_hud() -> void:
	ui=preload("res://scripts/game_hud.gd").new()
	add_child(ui)
	ui.build(self)
	hud=ui.status
	help=ui.hint
	message=ui.notice
	health=ui.hp_bar

func toggle_pause() -> void:
	if ended:return
	last_direction_time=-1
	run_direction=0
	attack_held=false
	attack_buffer=0
	paused=not paused
	ui.refresh()

func toggle_mute() -> void:
	muted=not muted
	AudioServer.set_bus_mute(0,muted)
	ui.refresh()

func prepare_encounters() -> void:
	var files := ["grass-rat.png", "beast-wind-weasel.png", "beast-stone-toad.png", "elite-grass-rat.png", "boss-grass-rat.png"]
	for zone in range(4):
		var pool: Array[Dictionary] = []
		var count := 5 + zone * 2 if zone < 3 else 1
		for i in range(count):
			var kind := i % 3 if zone > 0 else 0
			if zone == 2 and i == 4: kind = 3
			if zone == 3: kind = 4
			var n := actor(files[kind], zone * 14 + 7 + (i % 4) * 1.1 - 1.6, 0.032 if kind == 4 else 0.018)
			n.position.z = [-2.1, 0.7, -0.6, -1.4, 0.2][i] if zone == 0 else (i % 3 - 1) * 0.38
			n.position = constrain_ground(n.position)
			var marker := preload("res://scripts/enemy_telegraph.gd").new()
			add_child(marker)
			var life: float = [36.0, 30.0, 42.0, 100.0, 720.0][kind]
			var label := preload("res://scripts/world_text.gd").new()
			label.position.y = 1.65
			label.font_size = 76
			label.pixel_size = 0.0045
			label.outline_size = 8
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.no_depth_test = false
			label.alpha_cut = Label3D.ALPHA_CUT_DISABLED
			label.position.z = 0.8
			label.render_priority = 10
			label.outline_render_priority = 9
			n.add_child(label)
			label.setup(ui.world_text,camera,self)
			label.screen.z_index = 4
			var hp_bar := preload("res://scripts/enemy_health_bar.gd").new()
			ui.world_text.add_child(hp_bar)
			hp_bar.elite = kind == 3
			hp_bar.hide()
			n.hide()
			pool.append({"node": n, "marker": marker, "id": zone*10+i, "hp": life, "max_hp": life, "bar": hp_bar, "windup_length": 0.7, "kind": kind, "clock": i * 0.19, "windup": -1.0, "aim": 0.0, "aim_z": n.position.z, "flash": 0.0, "recoil": 0.0, "recovery": 0.0, "stagger": 0.0, "stride": i * 0.7, "texture": n.texture, "label": label, "room": zone, "home": n.position})
		enemy_pools.append(pool)

func spawn_room() -> void:
	if encounter_started[room]: return
	encounter_started[room] = true
	for e in enemy_pools[room]:
		e.node.show()
		enemies.append(e)
		if e.kind==4:
			boss_music_mix=0.0
			boss_music.play()
			e.clock=0.9
			# Enter with separation even if the player crossed the gate early.
			e.node.position.x=clampf(hero.position.x+(-7 if hero.position.x>49 else 7),42,55)

func _release_attack_input()->void:
	attack_held=false
	attack_buffer=0

func _input(event:InputEvent)->void:
	if event is InputEventKey and event.physical_keycode==KEY_J and not event.pressed:
		attack_held=false

func press_action(action:String)->void:
	if not ready_for_play or paused or ended:return
	match action:
		"basic":
			attack_held=true
			queue_basic()
		"heavy":
			if skill_cd>0.25:feedback.reject_heavy()
			try_heavy()
		"spin":try_spin()
		"dash":try_dash()
		"jump":try_jump()

func release_action(action:String)->void:
	if action=="basic":attack_held=false

func _unhandled_key_input(event: InputEvent) -> void:
	if not ready_for_play or not event is InputEventKey or not event.pressed or event.echo: return
	match event.physical_keycode:
		KEY_J:
			press_action("basic")
		KEY_ESCAPE:
			toggle_pause()
		KEY_M:
			toggle_mute()
		KEY_R:
			retry_run()
		KEY_SPACE:
			press_action("jump")
		KEY_L:
			press_action("dash")
		KEY_A, KEY_LEFT, KEY_D, KEY_RIGHT:
			tap_direction(-1.0 if event.physical_keycode in [KEY_A, KEY_LEFT] else 1.0)
		KEY_F:
			if not paused and not ended: encounter_flow.rest=0
		KEY_K:
			press_action("heavy")
		KEY_I:
			press_action("spin")
		KEY_1, KEY_2, KEY_3:
			select_build(event.physical_keycode - KEY_1)

func tap_direction(direction:float)->void:
	if paused or ended or dash_time>0 or backstep_time>0:return
	if direction==last_direction_tap and last_direction_time>=0 and elapsed-last_direction_time<=DIRECTION_TAP_WINDOW:
		last_direction_time=-1.0
		run_direction=direction
	else:
		last_direction_tap=direction
		last_direction_time=elapsed
		last_tap_facing=facing

func select_build(choice:int)->bool:
	if not ready_for_play or paused or ended or choice not in unlocked:return false
	build=choice
	toast("已裝備 · "+BUILD_NAMES[choice]+"\n"+BUILD_DETAILS[choice],3)
	return true

func try_jump() -> void:
	if ended or paused or jumps_used >= 2: return
	backstep_time = 0
	backstep_pose_time = 0
	jumps_used += 1
	jump_velocity = 8.8
	landing_time = 0

func try_backstep(original_facing: float) -> void:
	if ended or paused or backstep_cd > 0 or dash_time > 0 or jump_height > 0 or jump_velocity > 0: return
	facing = original_facing
	backstep_time = 0.26
	backstep_pose_time = 0.34
	locomotion_depth = 0
	backstep_cd = 0.7
	run_direction = 0
	jump_velocity = 3.2
	landing_time = 0
	attack_time = -1
	spin_time = -1
	heavy_buffer = 0
	spin_buffer = 0
	attack_cd = maxf(attack_cd,0.26)
	effects.clear()
	build_effects.clear()

func try_dash() -> void:
	if ended or paused or dash_cd > 0: return
	backstep_time = 0
	backstep_pose_time = 0
	locomotion_depth = 0
	run_direction = 0
	last_direction_time = -1
	dash_direction = movement_input()
	if dash_direction == Vector2.ZERO: dash_direction = Vector2(facing, 0)
	dash_time = DASH_DURATION
	heavy_buffer = 0
	spin_buffer = 0
	attack_buffer = 0
	dash_cd = 1.1
	invulnerable = 0.32
	attack_time = -1
	spin_time = -1
	effects.clear()
	build_effects.clear()
	attack_cd = 0.08
	if jump_height<0.25:forest.atmosphere.disturb(hero.position,0.9)
	sound("wave-air.wav",-12,1.25)

func try_spin() -> void:
	if ended or paused or spin_cd > 0.25: return
	attack_buffer=0
	heavy_buffer=0
	spin_buffer = INPUT_BUFFER
	consume_spin_buffer()

func consume_spin_buffer() -> void:
	if spin_buffer <= 0 or spin_cd > 0 or dash_time > 0 or backstep_time > 0 or spin_time >= 0: return
	if attack_time >= 0 and not contact_done: return
	spin_buffer = 0
	spin_time = 0
	locomotion_depth = 0
	backstep_pose_time = 0
	spin_hits = 0
	spin_cd = 3.4
	attack_time = -1
	attack_cd = 0.42

func resolve_spin() -> void:
	for e in enemies.duplicate():
		if ground_distance(e.node.position, hero.position) < 2.7 and target_in_height(e):
			damage_enemy(e, 19, 1.3)
	effects.spin(hero.position, facing, Color("b4edf2"))
	sound("blade-contact.wav", -7)

func try_heavy() -> void:
	if ended or paused or skill_cd > 0.25: return
	heavy_facing=movement_facing()
	attack_buffer=0
	spin_buffer=0
	heavy_buffer = INPUT_BUFFER
	consume_heavy_buffer()

func consume_heavy_buffer() -> void:
	if heavy_buffer <= 0 or skill_cd > 0 or dash_time > 0 or backstep_time > 0 or spin_time >= 0: return
	# Preserve the current hit, then cancel only its recovery into the queued skill.
	if attack_time >= 0 and not contact_done: return
	heavy_buffer = 0
	facing=movement_facing() if movement_input().x!=0 else heavy_facing
	start_attack(true)
	skill_cd = 2.8

func movement_facing()->float:
	var x:float=movement_input().x
	return signf(x) if x!=0 else facing

func queue_basic()->void:
	buffered_facing=movement_facing()
	attack_buffer=INPUT_BUFFER

func start_attack(power: bool) -> void:
	attack_entry_pose=idle_time>0 and locomotion_depth==0
	if power and feedback!=null:feedback.swing()
	attack_settle = 0.0
	combo_stage = 0 if power or combo_window <= 0 else combo_next
	if power:
		combo_next = 0
		combo_window = 0
	locomotion_depth = 0
	backstep_pose_time = 0
	attack_time = 0
	attack_power = power
	contact_done = false
	attack_cd = 0.52 if power else COMBO_COOLDOWNS[combo_stage]

func combo_style()->int:
	if build<0:return combo_stage
	return [[0,2,1],[1,0,2],[2,1,0]][build][combo_stage]

func _physics_process(dt: float) -> void:
	advance_audio(dt)
	if not ready_for_play: return
	update_hud()
	if ended:
		if hero_death_time>=0:
			hero.pixel_size=0.022
			hero.offset=Vector2.ZERO
			hero_death_time+=dt
			hero.texture=preload("res://assets/art/cat-fall.png")
			hero.vframes=2
			hero.frame=mini(3,int(hero_death_time/0.14))
			hero.position.y=move_toward(hero.position.y,HERO_GROUND_Y,dt*10)
			hero.get_child(0).position.y=-hero.position.y+0.14
			hero.get_child(0).scale=Vector3.ONE
		return
	if paused:return
	attack_buffer=maxf(0,attack_buffer-dt)
	attack_settle = maxf(0,attack_settle-dt)
	ui.advance(dt)
	hurt_time=maxf(0,hurt_time-dt)
	damage_edge.material.set_shader_parameter("strength",(0.12+0.035*sin(elapsed*3.0) if hp<=25 else 0.0)+hurt_time*0.7)
	elapsed += dt
	combo_window = maxf(0,combo_window-dt)
	toast_time -= dt
	if toast_time < 0: message.text = ""
	attack_cd = maxf(0, attack_cd - dt)
	dash_cd = maxf(0, dash_cd - dt)
	backstep_cd = maxf(0, backstep_cd - dt)
	backstep_pose_time = maxf(0,backstep_pose_time-dt)
	skill_cd = maxf(0, skill_cd - dt)
	spin_cd = maxf(0, spin_cd - dt)
	invulnerable = maxf(0, invulnerable - dt)
	landing_time = maxf(0, landing_time - dt)
	if jump_height > 0 or jump_velocity > 0:
		jump_velocity -= 24.0 * dt
		jump_height = maxf(0, jump_height + jump_velocity * dt)
		if jump_height == 0:
			jump_velocity = 0
			jumps_used = 0
			landing_time = 0.12
	hero.position.y = HERO_GROUND_Y + jump_height
	# The contact shadow stays on the bridge, not attached to airborne feet.
	hero.get_child(0).position.y = -HERO_GROUND_Y - jump_height + 0.14
	hero.get_child(0).scale = Vector3.ONE * (1.0 - minf(jump_height * 0.16, 0.3))
	consume_spin_buffer()
	consume_heavy_buffer()
	spin_buffer = maxf(0, spin_buffer-dt)
	heavy_buffer = maxf(0, heavy_buffer-dt)
	var movement := movement_input()
	var move := movement.x
	if signf(move) != run_direction: run_direction = 0
	var retreat_pending := false
	if move != 0 and dash_time <= 0 and backstep_time <= 0 and not retreat_pending and attack_time < 0 and spin_time < 0 and not attack_held and attack_buffer<=0: facing = signf(move)
	var ground_before:Vector3=hero.position
	if dash_time > 0:
		var travel_dt:=minf(dt,dash_time)
		dash_time = maxf(0,dash_time-dt)
		hero.position += Vector3(dash_direction.x,0,dash_direction.y) * (DASH_DISTANCE/DASH_DURATION) * travel_dt
	elif backstep_time > 0:
		hero.position.x -= facing * 9.0 * minf(dt,backstep_time)
		backstep_time = maxf(0,backstep_time-dt)
	else:
		var speed := 7.2 if is_running() else 4.5
		hero.position += Vector3(movement.x,0,movement.y) * speed * dt
	hero.position = constrain_ground(hero.position)
	var travelled:float=ground_distance(ground_before,hero.position)
	hero.flip_h = facing < 0
	hero.modulate = Color(1.35,0.65,0.5) if hurt_time>0.12 else (Color(0.5, 0.9, 1) if invulnerable > 0 else Color.WHITE)
	effects.advance(dt, hero.position)
	build_effects.advance(dt,hero.position)
	boss.advance_effects(dt)
	var manual_attack:bool=attack_held or Input.is_physical_key_pressed(KEY_J) or attack_buffer>0
	# Only explicit follow-up input can cancel a completed skill's recovery.
	# Both spin contacts / the heavy contact must have happened first.
	if manual_attack and spin_time>=0.26 and spin_hits>=2:
		spin_time=-1
		attack_cd=0
	if manual_attack and attack_time>=HEAVY_CONTACT+0.16 and attack_power and contact_done:
		attack_time=-1
		attack_cd=0
	if manual_attack and attack_time<0 and spin_time<0 and dash_time<=0 and backstep_time<=0 and attack_cd<=0:
		if attack_buffer>0:facing=movement_facing() if movement.x!=0 else buffered_facing
		else:facing=movement_facing()
		attack_buffer=0
		last_direction_time=-1
		start_attack(false)
	elif auto_attack and attack_time < 0 and spin_time < 0 and dash_time <= 0 and backstep_time <= 0 and not retreat_pending and attack_cd <= 0:
		var target: Dictionary = {}
		var closest := INF
		for e in enemies:
			if not in_sword_range(e, false): continue
			var dx: float = e.node.position.x - hero.position.x
			if move != 0 and dx * move <= 0: continue
			var distance := ground_distance(e.node.position, hero.position)
			if distance < closest:
				closest = distance
				target = e
		if not target.is_empty():
			if absf(target.node.position.x-hero.position.x) > 0.01: facing = signf(target.node.position.x - hero.position.x)
			start_attack(false)
	var jumping := (jump_height > 0 or landing_time > 0) and attack_time < 0 and spin_time < 0 and dash_time <= 0
	var walk_only := movement != Vector2.ZERO and travelled>0.0001 and attack_time < 0 and spin_time < 0 and dash_time <= 0 and not jumping
	if walk_only:
		if not was_walking:walk_time=0
		walk_time+=travelled/4.5
	was_walking=walk_only
	hero.frame = 0
	hero.texture = preload("res://assets/art/cat-rush.png") if dash_time > 0 else (preload("res://assets/art/cat-jump.png") if jumping else (preload("res://assets/art/cat-walk-contact.png") if walk_only else preload("res://assets/art/cat-cut-eight.png")))
	hero.vframes = 2 if dash_time > 0 or walk_only or jumping else 4
	var retreat_pose := backstep_pose_time>0 and (backstep_time>0 or movement==Vector2.ZERO) and attack_time<0 and spin_time<0 and dash_time<=0
	if walk_only:
		locomotion_depth=signf(movement.y) if absf(movement.y)>absf(movement.x)*1.05 else 0.0
		if locomotion_depth!=0:
			hero.texture=preload("res://assets/art/cat-walk-away.png") if locomotion_depth<0 else preload("res://assets/art/cat-walk-toward.png")
		elif is_running():
			hero.texture=preload("res://assets/art/cat-run.png")
			hero.vframes=2
		else:
			hero.texture=preload("res://assets/art/cat-walk-contact.png")
			hero.vframes=2
	elif not jumping and dash_time<=0 and attack_time<0 and spin_time<0 and locomotion_depth!=0:
		hero.texture=preload("res://assets/art/cat-walk-away.png") if locomotion_depth<0 else preload("res://assets/art/cat-walk-toward.png")
		hero.vframes=2
	if retreat_pose:
		hero.texture=preload("res://assets/art/cat-backstep.png")
		hero.vframes=2
	if spin_time >= 0:
		spin_time += dt
		hero.texture = preload("res://assets/art/cat-spin.png")
		hero.vframes = 2
		hero.frame = mini(3, int(spin_time / 0.1))
		while spin_hits < 2 and spin_time >= 0.08 + spin_hits * 0.16:
			spin_hits += 1
			resolve_spin()
		if spin_time >= 0.4: spin_time = -1
	elif attack_time >= 0:
		hero.texture = preload("res://assets/art/cat-heavy-eight.png") if attack_power else COMBO_TEXTURES[combo_style()]
		attack_time += dt
		var hit_at: float = HEAVY_CONTACT if attack_power else COMBO_CONTACTS[combo_stage]
		var duration: float = HEAVY_DURATION if attack_power else COMBO_DURATIONS[combo_stage]
		hero.frame = preload("res://scripts/attack_pose.gd").frame(combo_style(),attack_power,attack_time,hit_at,duration)
		if attack_time >= hit_at and not contact_done:
			contact_done = true
			resolve_attack(attack_power)
		if attack_time > duration:
			attack_time = -1
			attack_settle = 0.08
			settle_texture = hero.texture
	else:
		hero.frame = clampi(int((DASH_DURATION - dash_time) / (DASH_DURATION/4)), 0, 3) if dash_time > 0 else (int(walk_time * 9) % 4 if movement != Vector2.ZERO else 0)
		var side_walk:bool=walk_only and locomotion_depth==0 and not is_running()
		# Supporting foot travels about 32 px from contact to passing.
		if side_walk:hero.frame=int(walk_time*4.5/(32.0*0.0242))%4
		if walk_only and locomotion_depth==0 and move * facing < 0: hero.frame = 3 - hero.frame
		if jumping:
			hero.frame = 0 if landing_time > 0 else (1 if jump_velocity > 2.5 else (2 if jump_velocity > -2.5 else 3))
		elif attack_settle>0 and movement==Vector2.ZERO and dash_time<=0:
			hero.texture=settle_texture
			hero.vframes=4
			hero.frame=7
	if hurt_time>0 and attack_time<0 and spin_time<0 and dash_time<=0 and not jumping and not retreat_pose:
		hero.texture=preload("res://assets/art/cat-hurt.png")
		hero.vframes=2
		hero.frame=mini(3,int((0.24-hurt_time)/0.06))
	if retreat_pose: hero.frame=mini(3,int((0.34-backstep_pose_time)/0.085))
	var resting := (movement==Vector2.ZERO or travelled<=0.0001) and attack_time<0 and attack_settle<=0 and spin_time<0 and dash_time<=0 and not jumping and not retreat_pose and hurt_time<=0
	if resting:
		idle_time += dt
		hero.texture=preload("res://assets/art/cat-idle-side.png") if locomotion_depth==0 else (preload("res://assets/art/cat-idle-away.png") if locomotion_depth<0 else preload("res://assets/art/cat-idle-toward.png"))
		hero.vframes=4
		# 眼睛僅短暫閉合；衣襬各姿勢停留較久，避免待機也像出招。
		var phase := fmod(idle_time,3.5)
		hero.frame=0
		for boundary in [0.8,1.45,1.52,1.59,2.05,2.55,3.05]:
			if phase>=boundary: hero.frame+=1
		if locomotion_depth<0: hero.frame=mini(7,int(phase/3.5*8))
		if locomotion_depth==0:
			hero.texture=preload("res://assets/art/cat-ready.png")
			hero.vframes=2
			hero.frame=0 if phase<0.8 or phase>=2.8 else (1 if phase<1.45 or phase>=2.1 else (2 if phase<1.52 else 3))
	else:
		idle_time=0.0
	# Secondary motion belongs to the sprite only: input, shadow and hit tests remain immediate.
	var pose_offset:=Vector2.ZERO
	if walk_only and locomotion_depth==0 and not is_running():pose_offset.y=6
	if resting: pose_offset.y=6 if locomotion_depth==0 else (0 if locomotion_depth<0 else -2)
	if jumping and landing_time>0:
		pose_offset.y=-5.0*sin(landing_time/0.12*PI)
	if hurt_time>0 and attack_time<0 and dash_time<=0:
		pose_offset.x-=facing*4.0*sin(hurt_time/0.24*PI)
	# Share the neutral pose only for the first anticipation frame after idle.
	# Timing and hit contact are unchanged; subsequent combo attacks keep their own poses.
	if attack_entry_pose and attack_time>=0 and hero.frame==0:
		hero.texture=preload("res://assets/art/cat-ready.png")
		hero.vframes=2
		pose_offset.y=6
	# Match the 103px walk body to the 113px ready body around the same feet.
	var calibrated_walk:=hero.texture==preload("res://assets/art/cat-walk-contact.png")
	hero.pixel_size=0.0242 if calibrated_walk else 0.022
	if calibrated_walk:pose_offset.y=12
	hero.offset=pose_offset
	hero.flip_h = facing < 0
	dodge_effects.advance(dt,self)
	for e in enemies.duplicate(): update_enemy(e, dt)
	update_deaths(dt)
	update_projectiles(dt)
	update_loot(dt)
	encounter_flow.advance(dt)
	# Encounters are location triggers, not invisible arena walls. Earlier
	# enemies remain alive and can pursue when the player presses onward.
	for zone in range(1, 4):
		if hero.position.x >= zone * 14.0 - 2 and not encounter_started[zone] and encounter_cleared[zone-1]:
			room = zone
			hp = minf(100, hp + 20)
			spawn_room()
			toast("古林深處" if room < 3 else "石門妖王 · 繞背重劈破防，暈厥時反擊", 4)
	if cleared == 4 and enemies.is_empty() and dying.is_empty() and drops.is_empty() and not ended:
		finish(true)
	var cx := clampf(hero.position.x + 2.5, 3, 47)
	camera.position.x = lerpf(camera.position.x, cx, 4 * dt)
	forest.follow_camera(camera.position.x)
	feedback.advance(dt)
	readability.advance()
	forest.atmosphere.advance(dt,hero.position,is_running() and jump_height<=0 and dash_time<=0)

func is_running()->bool:
	return run_direction!=0 or touch_running

func movement_input() -> Vector2:
	var x := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	var z := float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	return (Vector2(x,z)+touch_movement).limit_length(1.0)

func ground_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x-b.x,a.z-b.z).length()

func target_in_height(e:Dictionary)->bool:
	var elevation:float=e.node.position.y-e.home.y
	return elevation<=jump_height+1.2 and jump_height<elevation+(3.0 if e.kind==4 else 1.8)

func constrain_ground(at: Vector3) -> Vector3:
	at.x = clampf(at.x,-8,56)
	at.z = clampf(at.z,Forest.road_back(at.x)+0.6,1.1)
	return at

func nearest_enemy(depth_width: float = INF) -> Dictionary:
	var result: Dictionary = {}
	var distance := INF
	for e in enemies:
		if absf(e.node.position.z-hero.position.z) > depth_width: continue
		var d: float = ground_distance(e.node.position,hero.position)
		if d < distance:
			distance = d
			result = e
	return result

func sword_reach(power: bool) -> float:
	if power and build==0:return 7.2
	return (4.2 if power else 2.7) + (1.6 if build == 0 else 0.0)

func in_sword_range(e: Dictionary, power: bool) -> bool:
	return ground_distance(e.node.position, hero.position) <= sword_reach(power) and absf(e.node.position.z-hero.position.z) <= (1.1 if power else 1.0) and target_in_height(e)

func resolve_attack(power: bool) -> void:
	if power and jump_height<0.3: forest.atmosphere.disturb(hero.position+Vector3(facing,0,0),1.1)
	var reach := sword_reach(power)
	var victims: Array[Dictionary] = []
	for e in enemies:
		var dx: float = e.node.position.x - hero.position.x
		if in_sword_range(e, power) and dx * facing >= -0.35: victims.append(e)
	victims.sort_custom(func(a,b):return ground_distance(a.node.position,hero.position)<ground_distance(b.node.position,hero.position))
	var damage := 44.0 if power else 17.0
	if build == 2: damage *= 0.9
	var limit := 8 if power or build == 0 else 3
	var hits := 0
	var dealt := 0.0
	for e in victims.slice(0, limit):
		var before_hp:float=maxf(e.hp,0)
		damage_enemy(e, damage, 2.6 if power else (1.7 if combo_stage == 2 else 1.0),3 if power else combo_stage)
		dealt+=before_hp-maxf(e.hp,0)
		hits += 1
	if not power:
		combo_next = (combo_stage+1)%3 if hits > 0 else 0
		combo_window = 0.85 if hits > 0 else 0.0
	if build == 0:
		build_effects.emit(0,hero.position+Vector3(facing*reach*0.35,0,0),Vector3.ZERO,facing,power or combo_stage==2)
		if hits>0:sound("wave-air.wav",-7)
	if build == 1 and hits > 0:
		var origin:Vector3=victims[0].node.position+Vector3(0,-0.25,0.7)
		var primary_origin:=origin
		var candidates=enemies.filter(func(e):return e!=victims[0] and ground_distance(e.node.position,hero.position)<=6)
		var links:=0
		while not candidates.is_empty() and links<(4 if power else (3 if combo_stage==2 else 2)):
			candidates.sort_custom(func(a,b):return ground_distance(a.node.position,origin)<ground_distance(b.node.position,origin))
			var e:Dictionary=candidates.pop_front()
			if ground_distance(e.node.position,origin)>4:break
			var endpoint:Vector3=e.node.position+Vector3(0,-0.25,0.7)
			build_effects.emit(1,origin,endpoint,1,power)
			damage_enemy(e,9,0.4)
			origin=endpoint
			links+=1
		if links>0 or power:feedback.chain(power)
		if power:
			build_effects.emit(1,primary_origin+Vector3(0,3.0,0),primary_origin,1,true)
			damage_enemy(victims[0],12,1.7)
	if build == 2 and hits > 0:
		build_effects.emit(3,hero.position,Vector3.ZERO,facing,power or combo_stage==2)
		var restored:=minf(100-hp,minf(dealt*0.06,7.5))
		hp+=restored
		if restored>0:
			feedback.heal()
			for e in victims.slice(0,mini(hits,3)):
				build_effects.emit(2,e.node.position+Vector3(0,-0.25,0.7),hero.position,facing,power)
			sound("vital-arrival.wav",-9)
	var color: Color = (Color("f18462") if build==2 else COLORS[build]) if build >= 0 else Color("f7db9c")
	slash_effect(reach, color, power)
	if hits>0:
		if power:feedback.heavy_hit(facing)
		else:sound("blade-weight.wav" if combo_stage==2 else "blade-contact.wav",-5 if combo_stage==2 else -3,[1.0,1.08,1.14][combo_stage])

func slash_effect(reach: float, color: Color, power: bool) -> void:
	effects.strike(hero.position, facing, reach, color, power, 0 if power else combo_style())

func damage_enemy(e: Dictionary, amount: float, impact: float = 1.0, stroke:int = -1) -> void:
	if not e in enemies: return
	var guarded:bool=e.kind==4 and boss.guarding(e)
	if guarded:
		amount*=0.6
		feedback.blocked(e.node)
	e["guard_flash"]=guarded
	e["heavy_flash"]=impact>=2.5
	e.hp -= amount
	if e.kind==4 and e.hp>0:boss.hit_posture(e,impact)
	e.flash = 0.12 if impact >= 1.6 else 0.09
	e.recoil = signf(e.node.position.x - hero.position.x) * (0.8 if e.kind >= 3 else 2.0) * impact
	# Sprite offset conveys weight without moving hitboxes, shadows or labels.
	var side:=signf(e.node.position.x-hero.position.x)
	e["reaction_offset"]=Vector2(side*4,0) if stroke==1 else (Vector2(side*7,1) if stroke==2 else Vector2(side*2,-7 if stroke==3 else -3))
	if e.kind>=3:e.reaction_offset*=0.45
	var contact_side := signf(hero.position.x-e.node.position.x)
	effects.impact(e.node.position + Vector3(contact_side*0.4, -0.35, 0.8), impact)
	if e.hp > 0 and ((impact >= 2 and e.kind < 4) or (impact >= 1.6 and e.kind < 3)):
		e.stagger = (0.12 if e.kind == 3 else 0.22) if impact >= 2 else 0.10
		e.windup = -1.0
		e.marker.hide()
		e.clock = minf(e.clock, 1.5)
	var number := floating(str(roundi(amount)), e.node.position + Vector3(0, 1.8, 0), Color("ffd278") if impact >= 1.6 else Color("ffe4a5"))
	if guarded:number.modulate=Color("a8c6d9")
	number.font_size = 124 if impact >= 1.6 else 90
	number.position.x += ((e.id % 3) - 1) * 0.32
	if e.hp <= 0:
		encounter_flow.defeated+=1
		if e.kind==4:boss.clear()
		var pos: Vector3 = e.node.position
		enemies.erase(e)
		e.label.hide()
		e.bar.hide()
		e.marker.hide()
		e.node.texture = ENEMY_FALL_TEXTURES[e.kind]
		e.node.frame = 0
		e.death_time = 0.0
		dying.append(e)
		var zone: int = e.room
		var remaining := false
		for other in enemy_pools[zone]:
			if other in enemies: remaining = true
		if not remaining and not encounter_cleared[zone]:
			encounter_flow.cleared_group(zone,pos)
			sound("beast-down.mp3", -9)

func update_deaths(dt: float) -> void:
	for e in dying.duplicate():
		e.death_time += dt
		var t: float = minf(e.death_time / ENEMY_FALL_DURATIONS[e.kind], 1)
		e.node.position.x += e.recoil * dt * (1-t)
		e.node.position = constrain_ground(e.node.position)
		e.node.frame = mini(3,int(t*5))
		# The artwork supplies the collapse; preserve body scale and ground plane.
		e.node.modulate = Color(0.85,0.85,0.80,1-smoothstep(0.72,1.0,t))
		e.node.position.y = e.home.y
		e.node.offset=e.node.offset.move_toward(Vector2.ZERO,dt*80)
		e.node.get_child(0).position.y = -e.home.y+0.14
		if t >= 1:
			e.node.hide()
			dying.erase(e)

func update_enemy(e: Dictionary, dt: float) -> void:
	e.clock += dt
	e.flash = maxf(0, e.flash - dt)
	e.recovery = maxf(0, e.recovery - dt)
	e.stagger = maxf(0, e.stagger - dt)
	var n: Sprite3D = e.node
	var reaction:Vector2=e.get("reaction_offset",Vector2.ZERO)
	n.offset=reaction
	e["reaction_offset"]=reaction.move_toward(Vector2.ZERO,dt*60)
	n.position.x += e.recoil * dt
	e.recoil = move_toward(e.recoil, 0, dt * 18)
	var dx: float = hero.position.x - n.position.x
	n.flip_h = (e.aim - n.position.x if e.windup >= 0 or e.recovery > 0 else dx) < 0
	n.frame = 0
	n.texture = e.texture
	n.position.y = e.home.y
	n.modulate = (Color(0.8,1.7,2.3) if e.get("guard_flash",false) else (Color(2.5,2.3,1.8) if e.get("heavy_flash",false) else Color(2,1.4,0.8))) if e.flash>0 else Color.WHITE
	e.label.text = ""
	e.bar.set_health(e.hp / e.max_hp, dt)
	e.label.modulate = Color("dfcba1")
	if e.kind==4 and boss.advance(e,dt):return
	if e.stagger > 0:
		e["pounce_time"] = -1.0
		n.texture = ENEMY_FALL_TEXTURES[e.kind]
		n.frame = 0
		e.label.text = "踉蹌"
		e.label.modulate = Color("ffe4a5")
	elif e.get("pounce_time", -1.0) >= 0:
		e.pounce_time += dt
		var t: float = clampf(e.pounce_time / 0.24, 0, 1)
		n.position = e.pounce_origin.lerp(e.pounce_target, t)
		n.position.y = e.home.y + sin(t * PI) * 0.55
		n.texture = ENEMY_ATTACK_TEXTURES[1]
		n.frame = 2
		n.flip_h = e.pounce_left
		if t >= 1:
			e.pounce_time = -1.0
			e.recovery = ENEMY_RECOVERIES[1]
			resolve_enemy_melee(e)
	elif e.windup >= 0:
		e.windup -= dt
		n.texture = ENEMY_ATTACK_TEXTURES[e.kind]
		n.frame = 1 if e.windup < 0.22 else 0
		if e.kind == 4:
			n.texture = preload("res://assets/art/boss-claw.png")
			n.frame = 1 if e.windup < 0.35 else 0
		e.label.text = ("爪擊 · 繞背破架勢" if e.kind==4 else "重擊！") if e.kind >= 3 else ("投石！" if e.kind == 2 else "")
		e.label.modulate = Color("ff8c70")
		if e.windup <= 0:
			e.windup = -1.0
			e.clock = 0.0
			e.recovery = ENEMY_RECOVERIES[e.kind] if e.kind < 4 else 0.18
			n.frame = 2
			if e.kind == 4:
				e.recovery = 0.75 if boss.follow_up else 0.30
				n.frame = 2
			if e.kind == 1:
				e["pounce_time"] = 0.0
				e["pounce_origin"] = n.position
				e["pounce_target"] = constrain_ground(n.position.move_toward(Vector3(e.aim,n.position.y,e.aim_z),3))
				e["pounce_left"] = n.flip_h
				e.recovery = 0.0
			elif e.kind == 2:
				e["retreat_left"] = 1.2
				spawn_shot(n.position+Vector3(-0.7 if n.flip_h else 0.7,-0.5,0), e.aim, e.aim_z)
			else:
				resolve_enemy_melee(e)
	elif e.recovery > 0:
		n.texture = ENEMY_ATTACK_TEXTURES[e.kind]
		n.frame = 2 if e.recovery > ENEMY_RECOVERIES[mini(e.kind,3)] * 0.55 else 3
		if e.kind == 4:
			n.texture = preload("res://assets/art/boss-claw.png")
			n.frame = 2 if e.recovery > (0.48 if boss.follow_up else 0.19) else 3
			e.label.text="收勢 · 反擊機會"
			e.label.modulate=Color("d7e4b9")
	else:
		var desired := 6.0 if e.kind == 2 else (2.6 if e.kind == 4 else 1.35)
		var delta := Vector2(dx,hero.position.z-n.position.z)
		var speed: float = [1.5, 2.4, 1.0, 0.95, 1.1][e.kind]
		var step := Vector2.ZERO
		if delta.length() > desired or absf(delta.y) > 0.5: step=delta.normalized()*speed
		# Toads keep a firing distance; closing in forces them to reposition.
		if e.kind == 2 and delta.length() < 3.8:
			var retreat: float = e.get("retreat_left",1.2)
			step = -delta.normalized()*speed if retreat>0 else Vector2.ZERO
			e["retreat_left"] = maxf(0,retreat-dt*speed)
		# Spacing continues after reaching attack distance; stationary overlap must resolve.
		for other in enemies:
			if other == e: continue
			var away := Vector2(n.position.x-other.node.position.x,n.position.z-other.node.position.z)
			var spacing := 2.65 if e.kind>=2 or other.kind>=2 else 2.15
			var distance := away.length()
			if distance < spacing:
				if distance < 0.01: away=Vector2.from_angle(float(e.id-other.id)*2.399)
				step+=away.normalized()*(spacing-distance)*3.5
		step=step.limit_length(speed)
		if step.length() > 0.08:
			n.position += Vector3(step.x,0,step.y)*dt
			if absf(step.x)>0.1:n.flip_h=step.x<0
			e.stride += dt * (12 if e.kind == 1 else 9)
			if e.kind <= 1:
				n.texture = preload("res://assets/art/rat-run.png") if e.kind == 0 else preload("res://assets/art/weasel-run.png")
				n.frame = int(e.stride) % 4
			elif e.kind == 2:
				n.position.y += maxf(0, sin(e.stride * 1.5)) * 0.14
			else:
				n.frame = int(e.stride * 0.5) % 2
		var interval: float = (0.80 if boss.phase==2 else 1.25) if e.kind==4 else ENEMY_INTERVALS[e.kind] + (e.id % 3) * 0.11
		var can_warn: bool = e.kind == 4 or elapsed - last_enemy_telegraph >= 0.20
		if can_warn and e.kind < 4:
			var contact_eta: float = ENEMY_WINDUPS[e.kind] + (0.24 if e.kind==1 else 0.0)
			for other in enemies:
				if other==e: continue
				var other_eta: float = other.windup + (0.24 if other.kind==1 else 0.0)
				if other.get("pounce_time",-1.0)>=0: other_eta=0.24-other.pounce_time
				if (other.windup>=0 or other.get("pounce_time",-1.0)>=0) and absf(contact_eta-other_eta)<0.18:
					can_warn=false
		if can_warn and e.clock > interval and enemies.filter(func(other):return other.windup>=0 or other.get("pounce_time",-1.0)>=0).size() < 3 and ground_distance(n.position,hero.position) < (11 if e.kind==4 else (8 if e.kind == 2 else (2.0 if e.kind == 0 else 3.5))) and (e.kind >= 4 or e.kind == 2 or absf(n.position.z-hero.position.z) < 0.65):
			e.windup = 0.9 if e.kind == 4 else ENEMY_WINDUPS[e.kind]
			e.windup_length = e.windup
			if e.kind < 4: last_enemy_telegraph = elapsed
			e.aim = hero.position.x
			e.aim_z = hero.position.z
			n.flip_h = e.aim < n.position.x
			if e.kind==4:boss.begin(e)
	if e.flash > 0 and e.windup < 0 and e.recovery <= 0 and e.get("pounce_time",-1.0)<0:
		n.texture = ENEMY_FALL_TEXTURES[e.kind]
		n.frame = 0
	n.position = constrain_ground(n.position)
	e.marker.update_for(e)
	n.get_child(0).position.y = -n.position.y + 0.14

func resolve_enemy_melee(e: Dictionary) -> void:
	var n: Sprite3D = e.node
	var reach := 3.0 if e.kind >= 3 else 1.45
	effects.enemy_strike(n.position, -1.0 if n.flip_h else 1.0, reach)
	if jump_height < (1.9 if e.kind >= 3 else 0.7) and absf(hero.position.z-e.aim_z) < (1.1 if e.kind >= 3 else 0.7) and absf(hero.position.z-n.position.z) < (1.1 if e.kind >= 3 else 0.7) and (hero.position.x-n.position.x) * (-1 if n.flip_h else 1) >= -0.35 and ground_distance(hero.position,Vector3(e.aim,0,e.aim_z)) < reach and ground_distance(hero.position,n.position) < reach + 0.7:
		take_damage(24 if e.kind >= 3 else 9)

func take_damage(amount: float) -> void:
	if ended or invulnerable > 0: return
	encounter_flow.damage_taken+=minf(hp,amount)
	hp = maxf(0, hp - amount)
	hurt_time=0.24
	sound("blade-contact.wav",-10,0.78)
	invulnerable = 0.35
	floating("−%d" % amount, hero.position + Vector3(0, 0.9, 0), Color("ff887f"))
	if hp <= 0: finish(false)

func spawn_shot(at: Vector3, aim: float, aim_z: float = 0.0) -> void:
	var n:Sprite3D = forest.sprite("stone-flight.png",at,0.006)
	n.hframes=2
	n.vframes=2
	n.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
	shots.append({"node": n, "velocity": (Vector3(aim, 1.0, aim_z) - at).normalized() * 7, "life": 3.0})

func update_projectiles(dt: float) -> void:
	for shot in shots.duplicate():
		shot.life -= dt
		shot.node.frame=int((3.0-shot.life)*16)%4
		var before: Vector3 = shot.node.position
		shot.node.position += shot.velocity * dt
		# Swept ellipsoid test: depth counts, and a fast stone cannot skip the torso.
		var torso := Vector3(hero.position.x,1.0+jump_height,hero.position.z)
		var start := (before-torso) / Vector3(0.5,0.85,0.45)
		var travel: Vector3 = (shot.node.position-before) / Vector3(0.5,0.85,0.45)
		var t := clampf(-start.dot(travel)/maxf(travel.length_squared(),0.00001),0,1)
		if (start+travel*t).length_squared() < 1.0:
			take_damage(12)
			sound("stone-contact.wav",-8)
			shot.life = 0
		if shot.life <= 0:
			shot.node.queue_free()
			shots.erase(shot)

func spawn_drop(at: Vector3, quality: int) -> void:
	var root := Node3D.new()
	root.position = Vector3(at.x, 0.2, at.z)
	add_child(root)
	var icon := Sprite3D.new()
	icon.texture = preload("res://assets/art/relic-atlas.png")
	icon.hframes = 2
	icon.vframes = 2
	icon.frame = quality
	icon.pixel_size = 0.007
	icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	icon.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	icon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	icon.position.y = 0.35
	root.add_child(icon)
	var pillar := preload("res://scripts/loot_light.gd").new()
	root.add_child(pillar)
	pillar.setup(COLORS[quality],quality)
	drops.append({"node": root, "age": 0.0, "quality": quality})
	toast("戰利品落地 · 靠近光柱收取", 4)

func update_loot(dt: float) -> void:
	for drop in drops.duplicate():
		drop.age += dt
		var target := hero.position - Vector3(0, 0.5, 0)
		var attracting:bool=drop.age > 1.1 and ground_distance(drop.node.position,hero.position) < 5
		drop.node.get_child(1).advance(dt,attracting)
		if attracting:
			drop.node.position = drop.node.position.move_toward(target, dt * (5 + drop.age * 3))
			if drop.node.position.distance_to(target) < 0.2:
				var q: int = drop.quality
				var first_relic:=build<0
				var is_new:=not q in unlocked
				if is_new: unlocked.append(q)
				if first_relic:build=q
				pickups += 1
				drop.node.queue_free()
				drops.erase(drop)
				var instruction:="已裝備 · K 重劈 / I 旋斬" if first_relic else ("按 %d 切換 · 保留目前流派"%(q+1) if is_new else "已集齊法寶 · 收下妖王戰利品")
				toast("取得「%s」· %s\n%s" % [BUILD_NAMES[q], BUILD_DETAILS[q],instruction], 5)
				pickup_sound()

func create_pickup_wave() -> AudioStreamWAV:
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var bytes := PackedByteArray()
	bytes.resize(5292 * 2)
	for i in range(5292):
		var t := float(i) / 22050
		var envelope := minf(t / 0.012, 1) * exp(-18 * t) * minf((0.24 - t) / 0.025, 1)
		var value := 0.16 * (sin(TAU * 880 * t) + 0.3 * sin(TAU * 1320 * t)) * envelope
		bytes.encode_s16(i * 2, int(value * 32767))
	wave.data = bytes
	return wave

func pickup_sound() -> void:
	pickup_player.stream=pickup_wave
	pickup_player.volume_db=-4
	pickup_player.play()

func sound(file: String, volume: float, pitch: float = 1.0) -> void:
	if file.begins_with("boss-") or file=="stage-clear.mp3":
		important_sound.stream=SOUNDS[file]
		important_sound.volume_db=volume
		important_sound.pitch_scale=pitch
		important_sound.play()
		mix_duck=0.85 if file=="boss-fracture.wav" else 0.45
	else:
		play_stream(SOUNDS[file], volume, pitch)

func play_stream(stream: AudioStream, volume: float, pitch: float = 1.0) -> void:
	if sound_voices >= 5: return
	sound_voices += 1
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus="SFX"
	player.volume_db = volume
	player.pitch_scale = pitch
	add_child(player)
	player.finished.connect(func(): sound_voices -= 1; player.queue_free())
	player.play()

func advance_audio(dt:float) -> void:
	if boss_music_mix>=0 and boss_music_mix<1:
		boss_music_mix=minf(1,boss_music_mix+dt/0.8)
		music.volume_db=linear_to_db(maxf(.001,(1-boss_music_mix)*0.3981))
		boss_music.volume_db=linear_to_db(maxf(.001,boss_music_mix*0.3981))
		if boss_music_mix>=1:music.stop()
	mix_duck=maxf(0,mix_duck-dt)
	var amount:=minf(mix_duck/0.18,1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),-3.0*amount)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"),-4.0*amount)

func beam(a: Vector3, b: Vector3, color: Color, duration: float) -> void:
	if a.distance_to(b) < 0.01: return
	var n: MeshInstance3D = forest.box((a + b) * 0.5, Vector3(0.055, 0.055, a.distance_to(b)), forest.material(color, 1.6))
	var direction := (b - a).normalized()
	n.look_at(b, Vector3.RIGHT if absf(direction.dot(Vector3.UP)) > 0.99 else Vector3.UP)
	var tween := create_tween()
	tween.tween_property(n, "scale", Vector3(0.02, 0.02, 1), duration)
	tween.tween_callback(n.queue_free)

func floating(text: String, at: Vector3, color: Color) -> Label3D:
	var n := preload("res://scripts/world_text.gd").new()
	n.text = text
	n.position = at
	n.modulate = color
	n.font_size = 108
	n.outline_size = 8
	n.pixel_size = 0.0045
	n.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	n.no_depth_test = false
	n.alpha_cut = Label3D.ALPHA_CUT_DISABLED
	n.position.z += 0.8
	n.render_priority = 12
	n.outline_render_priority = 11
	add_child(n)
	n.setup(ui.world_text,camera,self)
	var tween := n.create_tween().set_parallel(true)
	n.motion=tween
	tween.tween_property(n, "position:y", at.y + 0.8, 0.6)
	tween.tween_property(n, "modulate:a", 0.0, 0.20).set_delay(0.40)
	# Smooth alpha preserves antialiased glyph edges; remove fill and outline together.
	n.scale = Vector3.ONE * 0.8
	tween.tween_property(n, "scale", Vector3.ONE, 0.06)
	tween.chain().tween_callback(n.queue_free)
	return n

func toast(text: String, duration: float) -> void:
	message.text = text
	toast_time = duration

func retry_run() -> void:
	if restarting: return
	restarting = true
	var error := get_tree().reload_current_scene()
	if error != OK:
		restarting = false
		push_error("Unable to restart scene: %s" % error)

func finish(won: bool) -> void:
	feedback.clear()
	dodge_effects.clear()
	boss.clear()
	readability.silhouette.hide()
	if ended: return
	ended = true
	attack_held=false
	attack_buffer=0
	for e in enemies:e.marker.hide()
	backstep_time = 0
	backstep_pose_time = 0
	locomotion_depth = 0
	run_direction = 0
	last_direction_time = -1
	effects.clear()
	build_effects.clear()
	paused = false
	attack_time = -1
	dash_time = 0
	spin_time = -1

	if not won:
		hero_death_time=0
		hero.texture=preload("res://assets/art/cat-fall.png")
		hero.vframes=2
		hero.frame=0
		hero.modulate=Color.WHITE
		result_overlay.color.a=0.42
		result_overlay.get_child(0).position.y=-150
		damage_edge.material.set_shader_parameter("strength",0.0)
	if won:
		best = maxi(best, cleared)
		var save := ConfigFile.new()
		save.set_value("progress", "best", best)
		save.save("user://progress.cfg")
		sound("stage-clear.mp3", -8)
	message.text = ""
	result_title.text = "試煉完成" if won else "力竭倒下"
	result_title.modulate = Color("ffcb79") if won else Color("ffad98")
	result_detail.text = "用時 %d:%02d　·　擊退 %d 名敵人\n取得 %d 件法寶　·　承受傷害 %d\n\n%s" % [int(elapsed)/60,int(elapsed)%60,encounter_flow.defeated,pickups,roundi(encounter_flow.damage_taken),"石門已開 · 青霧林試煉完成" if won else "留意紅色預告，L 閃躲或 Space 跳躍，再次挑戰。"]
	result_overlay.show()
	retry_button.grab_focus()
	if music: music.stream_paused = true
	if boss_music:boss_music.stop()
	update_hud()

func update_hud() -> void:
	if ui!=null:ui.refresh()

func set_visual_profile(value:int,persist:bool=true)->void:
	visual_profile=clampi(value,0,2)
	var env:Environment=forest.environment
	var compatibility:=RenderingServer.get_current_rendering_method()=="gl_compatibility"
	env.ssr_enabled=visual_profile==0 and not compatibility
	env.volumetric_fog_enabled=visual_profile==0 and not compatibility
	env.ssao_enabled=visual_profile<2
	env.glow_intensity=0.25 if visual_profile==2 else 0.45
	camera.attributes.dof_blur_far_enabled=visual_profile<2 and not compatibility
	camera.attributes.dof_blur_near_enabled=visual_profile<2 and not compatibility
	forest.atmosphere.ambient_enabled=visual_profile<2
	forest.atmosphere.reactions_enabled=visual_profile<2
	forest.atmosphere.clear()
	for fog in forest.atmosphere.mist_layers:fog.visible=visual_profile==0
	if persist:
		var config:=ConfigFile.new()
		config.set_value("display","profile",visual_profile)
		var error:=config.save("user://preferences.cfg")
		if error!=OK:push_warning("Display preference could not be saved: "+str(error))
	if ui!=null and ui.quality_button!=null:ui.quality_button.text="畫質："+["精緻","均衡","清晰"][visual_profile]
