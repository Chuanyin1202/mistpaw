extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(ok:bool,title:String):
 print(("PASS " if ok else "FAIL ")+title)
 if not ok:failures+=1
func capture(g,tag:String):
 if DisplayServer.get_name()=="headless":return
 g.update_hud()
 await process_frame
 await process_frame
 RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png("res://docs/revision-"+tag+".png")
func run():
 root.size=Vector2i(1280,720)
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 for e in g.enemies:e.node.hide()
 g.enemies.clear()
 g._physics_process(.01)
 var idle_height:float=113*g.hero.pixel_size
 await capture(g,"idle")
 var key:=InputEventKey.new()
 key.physical_keycode=KEY_D
 key.pressed=true
 Input.parse_input_event(key)
 Input.flush_buffered_events()
 g._physics_process(.01)
 check(absf(103*g.hero.pixel_size-idle_height)<.015,"walk and ready body heights agree within one percent")
 check(absf((186-96-g.hero.offset.y)*g.hero.pixel_size-86*.022)<.015,"walk and ready soles share ground anchor")
 await capture(g,"walk")
 key=key.duplicate()
 key.pressed=false
 Input.parse_input_event(key)
 Input.flush_buffered_events()
 g._physics_process(.01)
 check(is_equal_approx(g.hero.pixel_size,.022),"stop restores normal sprite scale")
 g.feedback.heal()
 g.feedback.advance(.12)
 await capture(g,"healing")
 g.room=3
 g.spawn_room()
 check(g.boss_music.playing and g.boss_music.stream!=g.music.stream,"boss entrance starts a distinct music track")
 g.advance_audio(.8)
 check(not g.music.playing and g.boss_music.volume_db>-9,"music transition retires forest cue")
 var b:Dictionary=g.enemies[0]
 b.hp=720
 g.hero.position=b.node.position+Vector3(-2,0,0)
 g.camera.position.x=b.node.position.x
 g.camera.look_at(Vector3(b.node.position.x,1.3,0))
 g.forest.follow_camera(b.node.position.x)
 b.node.flip_h=true
 for i in range(7):g.damage_enemy(b,1,2.6)
 check(g.boss.posture==98 and g.boss.stunned==0,"seven guarded heavy contacts threaten but do not yet break posture")
 g.boss.begin(b,0)
 g.damage_enemy(b,1,2.6)
 g.update_enemy(b,.01)
 check(g.boss.stunned>1.5 and b.windup<0 and b.marker.visible==false,"eighth guarded heavy breaks guard and cancels windup")
 check(not g.boss.guarding(b),"stunned boss loses frontal reduction")
 var before:float=b.hp
 g.damage_enemy(b,10)
 check(is_equal_approx(before-b.hp,10),"frontal hit deals full damage during stun")
 var hp:float=g.hp
 var at:Vector3=b.node.position
 for i in range(60):g.update_enemy(b,.01)
 check(g.hp==hp and b.node.position.distance_to(at)<.15,"stunned boss cannot attack or chase")
 await capture(g,"break")
 var remaining:float=g.boss.stunned
 g.paused=true
 g._physics_process(.5)
 check(g.boss.stunned==remaining,"pause freezes boss stun")
 g.paused=false
 for i in range(110):g.update_enemy(b,.01)
 check(g.boss.stunned==0 and g.boss.break_lock>4.5,"stun expires into anti-lock protection")
 for i in range(10):g.damage_enemy(b,1,2.6)
 check(g.boss.posture==0,"protected boss cannot immediately be stunned again")
 g.boss.break_lock=0
 b.recovery=1
 g.boss.hit_posture(b,2.6)
 check(g.boss.posture==28,"recovery punish gains twice the frontal posture pressure")
 g.boss.posture=100
 g.boss.active=.1
 g.boss.pattern=2
 g.boss.origin=b.node.position
 g.boss.destination=b.node.position
 b.windup=-1
 g.boss.advance(b,.01)
 check(g.boss.stunned==0,"airborne leap does not freeze in midair")
 g.boss.active=-1
 g.boss.land_damaging=true
 g.boss.land_age=.4
 g.boss.advance(b,.01)
 check(g.boss.stunned==0,"dangerous pending wave defers break window")
 g.boss.land_age=1.4
 g.boss.advance(b,.01)
 check(g.boss.stunned>0,"safe landing opens deferred break window")
 g.finish(false)
 check(g.boss.stunned==0 and not g.boss_music.playing,"game end clears stun and boss music")
 g.feedback.clear()
 for c in g.get_children():
  if c is AudioStreamPlayer:c.stop()
 await create_timer(.3).timeout
 g.queue_free()
 await process_frame
 quit(1 if failures else 0)
