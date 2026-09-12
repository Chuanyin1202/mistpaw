extends SceneTree
var failures := 0
func check(ok: bool, title: String):
 print(("PASS " if ok else "FAIL ")+title)
 if not ok: failures += 1
func hold(keys: Array):
 for key in [KEY_W,KEY_A,KEY_S,KEY_D]:
  var event := InputEventKey.new()
  event.physical_keycode = key
  event.pressed = key in keys
  Input.parse_input_event(event)
 Input.flush_buffered_events()
func _initialize(): call_deferred("run")
func run():
 var g = load("res://scenes/main.tscn").instantiate()
 g.auto_attack=true
 root.add_child(g)
 await process_frame
 if not g.ready_for_play: await g.boot_finished
 g.set_physics_process(false)
 g.music.stop()
 g.sound_voices = 5
 for e in g.enemies: e.node.position.x = 55
 g.hero.position = Vector3(0,1.87,0)
 hold([KEY_W])
 for i in range(30):g._physics_process(1.0/60)
 check(g.hero.position.z < -2 and g.jump_height == 0,"W walks into depth without jumping")
 var ground_y: float = g.hero.position.y
 check(is_equal_approx(ground_y,1.87),"ground depth stays separate from vertical height")
 g.hero.position = Vector3(0,1.87,0)
 hold([KEY_D,KEY_S])
 for i in range(12):g._physics_process(1.0/60)
 var displacement := Vector2(g.hero.position.x,g.hero.position.z).length()
 check(absf(displacement-0.9)<0.01,"diagonal walking has same speed as cardinal walking")
 hold([])
 g.hero.position = Vector3(0,1.87,-2)
 g.try_jump()
 for i in range(8):g._physics_process(1.0/60)
 check(g.jump_height>0 and g.hero.position.z == -2,"jump preserves ground depth")
 check(is_equal_approx(g.hero.get_child(0).global_position.y,0.14),"shadow stays on ground at new depth")
 g.jump_height=0
 g.jump_velocity=0
 g.hero.position = Vector3(8.8,1.87,-2.8)
 hold([KEY_D])
 for i in range(24):g._physics_process(1.0/60)
 check(g.hero.position.x>9 and g.hero.position.z>=-1.1001,"wide clearing narrows into bridge without blocking forward motion")
 hold([KEY_W])
 g.hero.position=Vector3(30,1.87,0)
 for i in range(60):g._physics_process(1.0/60)
 check(g.hero.position.z < -4 and g.hero.scale == Vector3.ONE,"far battle clearing has full depth without rescaling hero")
 hold([KEY_A])
 for i in range(140):g._physics_process(1.0/60)
 check(g.hero.position.x < 21 and g.hero.position.z >= -1.1001,"returning from far clearing tapers smoothly into bridge")
 hold([])
 g.hero.position=Vector3(0,1.87,0)
 var e = g.enemies[0]
 e.node.position=Vector3(1, e.home.y,-2.5)
 var hp: float=e.hp
 g.build=-1
 g.facing=1
 g.resolve_attack(false)
 check(e.hp==hp,"basic does not hit enemy on another depth lane")
 var reachable = g.enemies[1]
 reachable.node.position = Vector3(2,reachable.home.y,0)
 var reachable_hp: float = reachable.hp
 g.attack_time = -1
 g.attack_cd = 0
 g._physics_process(0.11)
 check(reachable.hp == reachable_hp-17 and e.hp == hp,"auto attack selects reachable target instead of nearer off-lane enemy")
 reachable.node.position.x = 55
 e.node.position.z=0
 g.resolve_attack(false)
 check(e.hp==hp-17,"same-depth basic retains damage")
 e.hp=100
 e.node.position=Vector3(2,e.home.y,-2)
 g.resolve_spin()
 check(e.hp==100,"spin uses circular ground range, not horizontal distance")
 e.node.position.z=-1
 g.resolve_spin()
 check(e.hp==81,"spin connects inside ground circle")
 e.hp=100
 e.recoil=0
 e.flash=0
 e.stagger=0
 e.node.position=Vector3(1,e.home.y,-2.5)
 e.aim=0
 e.aim_z=-2.5
 e.windup=0.01
 g.hp=100
 g.invulnerable=0
 g.update_enemy(e,0.02)
 check(g.hp==100,"depth sidestep avoids locked enemy strike")
 e.node.position.z=0
 e.aim_z=0
 e.windup=0.01
 g.update_enemy(e,0.02)
 check(g.hp==91,"same-depth enemy strike still damages")
 e.node.position=Vector3(4,e.home.y,-2.8)
 e.windup=-1
 e.recovery=0
 e.clock=0
 for i in range(60):g.update_enemy(e,1.0/60)
 check(e.node.position.z>-2.8 and e.node.position.x<4,"enemy pursues in both ground axes")
 g.hp=100
 g.invulnerable=0
 g.spawn_shot(Vector3(0,1,2),0,2)
 g.shots[-1].velocity=Vector3.ZERO
 g.update_projectiles(0.01)
 check(g.hp==100,"projectile in another depth lane misses")
 g.shots[-1].node.position.z=0
 g.update_projectiles(0.01)
 check(g.hp==88,"projectile at matching torso depth connects")
 g.spawn_drop(Vector3(0,0,-2),0)
 check(g.drops[-1].node.position.z == -2,"loot retains defeated enemy depth")
 g.paused=true
 var at: Vector3=g.hero.position
 hold([KEY_W,KEY_D])
 g._physics_process(0.1)
 check(g.hero.position==at,"pause freezes both ground axes")
 hold([])
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 print("DEPTH FAILURES=",failures)
 quit(1 if failures else 0)
