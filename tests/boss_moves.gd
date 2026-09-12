extends SceneTree
var failures:=0
var g
var e:Dictionary
var view:SubViewport
func check(ok:bool,title:String):
 print(("PASS " if ok else "FAIL ")+title)
 if not ok:failures+=1
func _initialize():call_deferred("run")
func reset():
 g.boss.clear()
 g.boss.pattern=0
 g.boss.phase=1
 g.hp=100
 g.invulnerable=0
 g.jump_height=0
 g.hero.position=Vector3(43,1.87,-1)
 e.node.position=Vector3(46.5,e.home.y,-1)
 e.hp=420
 e.windup=-1.0
 e.recovery=0.0
 e.clock=0.0
func run():
 view=SubViewport.new()
 view.size=Vector2i(1280,720)
 view.own_world_3d=true
 view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(view)
 g=load("res://scenes/main.tscn").instantiate()
 view.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 g.music.stop()
 g.sound_voices=5
 for enemy in g.enemies:enemy.node.hide()
 g.enemies.clear()
 g.room=3
 g.spawn_room()
 e=g.enemies[0]
 g.camera.position.x=45
 g.forest.follow_camera(45)
 reset()
 g.hero.position.x=46
 g.readability.advance()
 check(g.readability.silhouette.visible and is_equal_approx(g.readability.silhouette.modulate.a,0.65),"large boss overlap shows a stronger same-depth hero silhouette")
 await capture("boss-player-overlap")
 reset()
 g.boss.previous_pattern=-1
 var seen=[]
 for i in range(3):
  g.boss.begin(e)
  seen.append(g.boss.pattern)
 check(seen==[0,2,1],"close combat chooses claw, leap and charge rather than repeating one move")
 reset()
 g.boss.begin(e,1)
 var target:Vector3=g.boss.destination
 g.update_enemy(e,0.3)
 check(g.hp==100 and e.marker.visible and e.node.texture==g.boss.CHARGE,"charge has distinct art and harmless lane warning")
 await capture("boss-charge-warning")
 g.hero.position.z=1.0
 g.update_enemy(e,0.5)
 check(g.boss.destination==target,"sidestep does not move the locked charge lane")
 g.update_enemy(e,0.4)
 check(g.hp==100 and e.recovery>=0.8,"sidestep avoids charge and opens a punish window")
 reset()
 g.boss.begin(e,1)
 g.update_enemy(e,0.8)
 g.update_enemy(e,0.4)
 check(g.hp==78,"swept charge hits crossed player even in one large timestep")
 g.invulnerable=0
 g.update_enemy(e,0.2)
 check(g.hp==78,"charge recovery cannot hit twice")
 reset()
 g.boss.begin(e,2)
 g.update_enemy(e,0.9)
 g.update_enemy(e,0.23)
 check(e.node.position.y>e.home.y+2.5 and e.node.texture==g.boss.LEAP,"leap moves the body through a real airborne arc")
 check(e.marker.visible and e.marker.position.distance_to(Vector3(g.boss.destination.x,0.17,g.boss.destination.z))<0.01,"landing marker stays on locked ground location")
 var life:float=e.hp
 g.resolve_attack(true)
 check(e.hp==life,"ground blade does not hit a high airborne boss")
 await capture("boss-leap-air")
 g.hero.position.x=39
 g.update_enemy(e,0.3)
 check(g.hp==100 and is_equal_approx(e.node.position.y,e.home.y),"leaving landing circle avoids slam")
 reset()
 g.boss.begin(e,2)
 g.update_enemy(e,0.9)
 g.update_enemy(e,0.5)
 check(g.hp==74 and e.recovery==1.0,"slam contact deals damage once then fully recovers")
 g.boss.advance_effects(0.1)
 await capture("boss-slam-contact")
 reset()
 e.hp=200
 g.update_enemy(e,0.1)
 check(g.boss.phase==2 and g.boss.roar>0 and g.hp==100,"half health starts visible harmless rage transition")
 await capture("boss-rage")
 g.update_enemy(e,0.81)
 check(g.boss.pattern==2 and e.windup>0,"rage starts a telegraphed leap, not immediate damage")
 g.update_enemy(e,0.9)
 g.update_enemy(e,0.5)
 check(g.boss.land_damaging,"phase two slam arms delayed ground wave")
 g.hp=100
 g.invulnerable=0
 g.hero.position.x=g.boss.land_point.x+2.2
 g.hero.position.z=g.boss.land_point.z
 g.boss.advance_effects(0.5)
 check(g.hp==100 and g.boss.ring.visible,"wave has a readable delay before spreading")
 await capture("boss-wave-warning")
 g.boss.advance_effects(0.51)
 check(g.hp==86,"standing inside expanding wave takes one hit")
 g.invulnerable=0
 g.boss.advance_effects(0.1)
 check(g.hp==86,"same expanding wave cannot repeatedly damage player")
 g.boss.land(g.boss.land_point,true)
 g.hp=100
 g.jump_height=1.0
 g.boss.advance_effects(1.01)
 check(g.hp==100,"jumping clears the low ground wave")
 await capture("boss-wave-jump")
 reset()
 g.boss.phase=2
 g.boss.begin(e,1)
 g.hero.position.z=1.0
 g.update_enemy(e,0.8)
 g.update_enemy(e,0.4)
 check(g.boss.next_attack>=0,"rage charge schedules one follow-up rather than idle waiting")
 g.update_enemy(e,0.61)
 check(g.boss.follow_up and e.windup>0.7 and g.hp==100,"follow-up starts a full harmless warning")
 g.hero.position.z=1.0
 g.update_enemy(e,1.0)
 check(e.recovery>=0.74 and g.boss.next_attack<0,"follow-up claw ends in extended punish window with no endless chain")
 g.boss.land(Vector3(44,0.19,-1),false)
 g.boss.advance_effects(0.2)
 check(g.boss.fracture.visible and g.boss.debris.filter(func(s):return s.visible).size()==16,"slam creates fracture and sixteen pooled stone fragments")
 await capture("boss-fracture-contact")
 g.boss.advance_effects(0.9)
 check(g.boss.fracture.visible and not g.boss.ring.visible,"physical cracks remain after the luminous ring fades")
 g.hero.position.x=40
 e.node.position.x=48
 await capture("boss-fracture-after")
 g.hero.position.x=g.boss.land_point.x+2.2
 g.hero.position.z=g.boss.land_point.z
 g.boss.advance_effects(1.5)
 g.boss.advance_effects(0.01)
 check(not g.boss.fracture.visible and g.boss.debris.all(func(s):return not s.visible),"fracture and stones expire without permanent collision or residue")
 g.boss.land(g.boss.land_point,true)
 g.paused=true
 var age:float=g.boss.land_age
 g._physics_process(0.3)
 check(g.boss.land_age==age,"pause freezes boss wave damage and visuals together")
 g.paused=false
 g.boss.land(g.boss.land_point,true)
 g.hp=1
 g.jump_height=0
 g.invulnerable=0
 g.boss.advance_effects(1.01)
 check(g.ended and g.boss.land_age<0 and g.boss.debris.all(func(s):return not s.visible),"lethal wave cannot recreate debris after death cleanup")
 g.ended=false
 reset()
 g.hp=1
 g.boss.begin(e,2)
 g.update_enemy(e,0.9)
 g.update_enemy(e,0.5)
 check(g.ended and g.boss.land_age<0,"lethal landing cannot arm a post-death shockwave")
 g.damage_enemy(e,10000)
 check(g.boss.land_age<0 and not g.boss.ring.visible and g.boss.debris.all(func(s):return not s.visible),"boss death clears pending wave and debris")
 g.queue_free()
 await process_frame
 await create_timer(0.3).timeout
 print("BOSS MOVES FAILURES=",failures)
 quit(1 if failures else 0)
func capture(name:String):
 if DisplayServer.get_name()=="headless":return
 g.update_hud()
 g.readability.advance()
 await process_frame
 await process_frame
 RenderingServer.force_draw(false)
 view.get_texture().get_image().save_png("res://docs/"+name+".png")
