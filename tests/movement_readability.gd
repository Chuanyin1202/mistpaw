extends SceneTree
var failures := 0
func check(ok: bool, title: String):
 print(("PASS " if ok else "FAIL ")+title)
 if not ok: failures += 1
func key(g, code: Key, down: bool, repeat_event := false):
 var held := InputEventKey.new()
 held.physical_keycode=code
 held.pressed=down
 held.echo=repeat_event
 Input.parse_input_event(held)
 Input.flush_buffered_events()
 if down:
  var event := InputEventKey.new()
  event.physical_keycode=code
  event.pressed=true
  event.echo=repeat_event
  g._unhandled_key_input(event)
func step(g, ticks: int):
 for i in range(ticks):g._physics_process(1.0/60)
func reset(g):
 for code in [KEY_A,KEY_D,KEY_W,KEY_S]:key(g,code,false)
 g.hero.position=Vector3(0,1.87,0)
 g.facing=1
 g.last_direction_time=-1
 g.run_direction=0
 g.backstep_time=0
 g.backstep_pose_time=0
 g.locomotion_depth=0
 g.backstep_cd=0
 g.dash_time=0
 g.dash_cd=0
 g.invulnerable=0
 g.jump_height=0
 g.jump_velocity=0
 g.jumps_used=0
 g.attack_time=-1
 g.spin_time=-1
func _initialize():call_deferred("run")
func run():
 var view := SubViewport.new()
 view.size=Vector2i(1280,720)
 view.own_world_3d=true
 view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(view)
 var g=load("res://scenes/main.tscn").instantiate()
 view.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 g.set_process_unhandled_key_input(false)
 g.music.stop()
 g.sound_voices=5
 for e in g.enemies:e.node.position.x=55
 reset(g)
 key(g,KEY_W,true)
 step(g,8)
 check(g.hero.texture.resource_path.ends_with("cat-walk-away.png"),"moving away uses back-facing art")
 await capture(view,"movement-away")
 key(g,KEY_W,false)
 step(g,1)
 check(g.hero.texture.resource_path.ends_with("cat-idle-away.png"),"stopping preserves depth-facing idle pose")
 key(g,KEY_S,true)
 step(g,8)
 check(g.hero.texture.resource_path.ends_with("cat-walk-toward.png"),"moving toward uses front-facing art")
 await capture(view,"movement-toward")
 key(g,KEY_S,false)
 reset(g)
 g.try_backstep(1)
 step(g,6)
 check(g.hero.texture.resource_path.ends_with("cat-backstep.png") and g.hero.frame==1,"backstep uses dedicated guard-hop pose")
 g.try_dash()
 step(g,1)
 check(not g.hero.texture.resource_path.ends_with("cat-backstep.png"),"dash exits retreat pose")
 reset(g)
 for e in g.enemies:e.node.hide()
 g.enemies.clear()
 g.room=2
 g.spawn_room()
 g.hero.position=Vector3(30,1.87,-1.5)
 for i in range(g.enemies.size()):
  var e=g.enemies[i]
  e.node.position=Vector3(33+(i%3)*0.15,e.home.y,-1.5+(i/3)*0.15)
 g.invulnerable=99
 for tick in range(480):
  for e in g.enemies:g.update_enemy(e,1.0/60)
 g.camera.position.x=31
 g.camera.look_at(Vector3(31,1.3,0))
 g.forest.follow_camera(31)
 var e=g.enemies[0]
 e.aim=g.hero.position.x
 e.aim_z=g.hero.position.z
 e.windup=0.2
 e.node.flip_h=true
 e.marker.update_for(e)
 check(e.marker.visible,"windup shows ground marker")
 await capture(view,"crowd-telegraph")
 e.windup=-1
 e.marker.update_for(e)
 check(not e.marker.visible,"resolved attack hides ground marker")
 var weasel=g.enemies.filter(func(enemy):return enemy.kind==1)[0]
 weasel.windup=0.5
 weasel.aim=g.hero.position.x
 weasel.aim_z=g.hero.position.z
 weasel.marker.update_for(weasel)
 var landing=g.constrain_ground(weasel.node.position.move_toward(Vector3(weasel.aim,weasel.node.position.y,weasel.aim_z),3))
 check(g.ground_distance(landing,weasel.marker.position)<0.001,"lunge marker predicts constrained landing position")
 for code in [KEY_A,KEY_D,KEY_W,KEY_S]:key(g,code,false)
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 print("MOVEMENT TRIAL FAILURES=",failures)
 quit(1 if failures else 0)
func capture(view:SubViewport,name:String):
 if DisplayServer.get_name()=="headless":return
 await process_frame
 await process_frame
 RenderingServer.force_draw(false)
 view.get_texture().get_image().save_png("res://docs/"+name+".png")
