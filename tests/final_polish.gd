extends SceneTree
var failures:=0
func check(ok:bool,title:String):
 print(("PASS " if ok else "FAIL ")+title)
 if not ok:failures+=1
func _initialize():call_deferred("run")
func capture(g,name:String):
 if DisplayServer.get_name()=="headless":return
 g.update_hud()
 for i in range(3):await process_frame
 RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png("res://docs/"+name+".png")
func run():
 root.size=Vector2i(1280,720)
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 g.music.stop()
 for e in g.enemies:e.node.hide()
 g.enemies.clear()
 g.room=3
 g.spawn_room()
 var e:Dictionary=g.enemies[0]
 g.hero.position=e.node.position+Vector3(-2,0,0)
 e.node.flip_h=true
 var before:float=e.hp
 g.damage_enemy(e,100)
 check(is_equal_approx(before-e.hp,60),"front guard reduces damage without immunity")
 g.hero.position.x=e.node.position.x+2
 before=e.hp
 g.damage_enemy(e,100)
 check(is_equal_approx(before-e.hp,100),"flanking bypasses committed facing guard")
 g.hero.position.x=e.node.position.x-2
 e.recovery=1
 before=e.hp
 g.damage_enemy(e,100)
 check(is_equal_approx(before-e.hp,100),"recovery opens full damage from front")
 e.recovery=0
 e.hp=e.max_hp
 g.build=2
 g.hp=50
 g.facing=1
 g.hero.position.z=e.node.position.z
 g.resolve_attack(true)
 check(is_equal_approx(g.hp,50+39.6*0.6*0.06),"lifesteal uses damage after boss guard")
 e.hp=e.max_hp
 g.boss.phase=2
 g.boss.begin(e,2)
 g.hero.position.z=1
 g.update_enemy(e,0.9)
 g.update_enemy(e,0.5)
 g.boss.advance_effects(0.3)
 g.update_enemy(e,0.01)
 check(g.boss.wave_pending() and not e.label.text.contains("反擊"),"pending shockwave never advertises a safe punish window")
 check(g.encounter_flow.objective().contains("跳躍"),"objective agrees with shockwave warning")
 g.camera.position.x=44
 g.camera.look_at(Vector3(44,1.3,0))
 g.forest.follow_camera(44)
 g.hero.position.x=44
 await capture(g,"polish-boss-warning")
 g.boss.advance_effects(1.05)
 g.update_enemy(e,1.05)
 check(not g.boss.wave_pending() and e.recovery>=0.7 and e.label.text.contains("反擊"),"after wave fades a real punish window remains")
 await capture(g,"polish-boss-punish")
 g.boss.clear()
 e.node.hide()
 g.enemies.clear()
 g.room=0
 g.hero.position=Vector3(0,g.HERO_GROUND_Y,0)
 g.build=0
 g.unlocked.assign([0])
 g.encounter_flow.pending=0
 g.encounter_flow.rest=5
 g.spawn_drop(g.hero.position,1)
 g.encounter_flow.advance(3)
 check(g.encounter_flow.rest==5,"relic approach does not consume preparation time")
 for i in range(180):g.update_loot(1.0/60)
 check(g.build==0 and 1 in g.unlocked,"new relic unlocks without overwriting chosen build")
 check(g.message.text.contains("按 2") and not g.message.text.contains("向右前進"),"relic pickup explains the choice instead of premature progression")
 var key:=InputEventKey.new()
 key.physical_keycode=KEY_2
 key.pressed=true
 g._unhandled_key_input(key)
 check(g.build==1,"existing keyboard shortcut chooses unlocked relic")
 g.encounter_flow.pending=-1
 g.hero.position=Vector3(14,g.HERO_GROUND_Y,0)
 g.camera.position.x=16.5
 g.camera.look_at(Vector3(16.5,1.3,0))
 g.forest.follow_camera(16.5)
 var hp:float=g.hp
 var cooldown:float=g.skill_cd
 for mode in range(3):
  g.set_visual_profile(mode,false)
  check(g.hp==hp and g.skill_cd==cooldown,"display mode does not alter combat state "+str(mode))
  check(g.forest.environment.ssr_enabled==(mode==0),"reflection setting applies "+str(mode))
  g.boss.begin(e,2)
  e.marker.update_for(e)
  check(e.marker.visible,"danger marker survives display mode "+str(mode))
  e.marker.hide()
  await capture(g,"polish-quality-"+str(mode))
 g.set_visual_profile(0,false)
 g.toggle_pause()
 await capture(g,"polish-settings")
 check(g.ui.quality_button.visible and g.paused,"quality menu is available inside paused game")
 for c in g.get_children():
  if c is AudioStreamPlayer:c.stop()
 g.queue_free()
 await process_frame
 await create_timer(0.3).timeout
 quit(1 if failures else 0)
