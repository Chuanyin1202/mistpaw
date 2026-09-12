extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(ok:bool,title:String):
 print(("PASS " if ok else "FAIL ")+title)
 if not ok:failures+=1
func capture(g,name:String):
 if DisplayServer.get_name()=="headless":return
 g.update_hud()
 await process_frame
 await process_frame
 RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png("res://docs/feedback-"+name+".png")
func run():
 root.size=Vector2i(1280,720)
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 g.music.stop()
 g.skill_cd=1
 g.press_action("heavy")
 check(g.feedback.voices.reject.playing and g.ui.slots[1].tile.rejected_left>0,"cooldown press gives sound and ring feedback")
 check(g.heavy_buffer==0 and g.skill_cd==1,"rejected press does not consume or queue heavy")
 var position:float=g.feedback.voices.reject.get_playback_position()
 g.press_action("heavy")
 check(g.feedback.reject_lock>0 and g.skill_cd==1,"repeated rejection is rate limited")
 await capture(g,"cooldown")
 g.skill_cd=0.2
 g.press_action("heavy")
 check(g.heavy_buffer>0,"last quarter-second still accepts buffered heavy")
 g.heavy_buffer=0
 g.skill_cd=0
 g.sound_voices=5
 var actors:Array=g.enemies.slice(0,3)
 for e in g.enemies:e.node.hide()
 g.enemies.clear()
 for i in range(actors.size()):
  var e:Dictionary=actors[i]
  e.hp=1000
  e.node.position=Vector3(1.6+i,e.home.y,0 if i==0 else -1.3)
  e.node.show()
  g.enemies.append(e)
 g.build=1
 g.resolve_attack(false)
 check(g.feedback.voices.chain.playing and g.feedback.voices.crackle.playing,"chain sound survives saturated ordinary voice pool")
 g.feedback.advance(0.04)
 await capture(g,"chain")
 g.build=2
 g.hp=50
 var hp:float=g.hp
 g.resolve_attack(false)
 g.feedback.advance(0.04)
 check(g.hp>hp and g.feedback.halo.visible,"actual healing lights a red halo")
 var before:Vector3=g.feedback.halo.position
 g.hero.position.x+=0.5
 g.feedback.advance(0.02)
 check(g.feedback.halo.position.x>before.x,"healing halo follows moving hero")
 await capture(g,"heal")
 g.feedback.clear()
 g.hp=100
 g.resolve_attack(false)
 g.feedback.advance(0.01)
 check(not g.feedback.halo.visible,"full health does not pretend to heal")
 g.build=-1
 g.hero.position.x=0
 g.build_effects.clear()
 g.effects.clear()
 g.start_attack(true)
 check(g.feedback.voices.swing.playing,"heavy windup has immediate swing sound")
 for i in range(14):g._physics_process(1.0/120)
 await capture(g,"heavy-windup")
 for i in range(14):g._physics_process(1.0/120)
 check(g.feedback.voices.heavy.playing and absf(g.camera.h_offset)>0,"heavy contact has dedicated impact and short camera impulse")
 await capture(g,"heavy")
 g.feedback.advance(0.2)
 check(g.camera.h_offset==0,"heavy camera impulse settles without hitstop")
 for e in actors:e.node.hide()
 g.enemies.clear()
 g.room=3
 g.spawn_room()
 var boss:Dictionary=g.enemies[0]
 g.hero.position=boss.node.position+Vector3(-2,0,0)
 boss.node.flip_h=true
 g.damage_enemy(boss,17)
 g.feedback.advance(0.02)
 check(g.feedback.guard.visible and g.feedback.voices.guard.playing,"guarded contact shows an arc and metallic cue")
 g.camera.position.x=44
 g.camera.look_at(Vector3(44,1.3,0))
 g.forest.follow_camera(44)
 await capture(g,"guard")
 var age:float=g.feedback.guard_age
 g.paused=true
 g._physics_process(0.5)
 check(g.feedback.guard_age==age,"pause freezes feedback effects")
 g.paused=false
 g.finish(false)
 check(not g.feedback.guard.visible and not g.feedback.halo.visible and g.camera.h_offset==0,"death clears feedback and camera impulse")
 for c in g.get_children():
  if c is AudioStreamPlayer:c.stop()
 await create_timer(0.3).timeout
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 quit(1 if failures else 0)
