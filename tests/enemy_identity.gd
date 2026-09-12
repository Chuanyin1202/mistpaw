extends SceneTree
var failures:=0
func check(ok:bool,title:String):
 print(("PASS " if ok else "FAIL ")+title)
 if not ok:failures+=1
func _initialize():call_deferred("run")
func run():
 var view:=SubViewport.new()
 view.size=Vector2i(1280,720)
 view.own_world_3d=true
 view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(view)
 var g=load("res://scenes/main.tscn").instantiate()
 view.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 g.music.stop()
 g.sound_voices=5
 for e in g.enemies:e.node.hide()
 var kinds:Dictionary={}
 for pool in g.enemy_pools:
  for e in pool:kinds[e.kind]=e
 g.enemies.clear()
 g.hero.position=Vector3(4,g.HERO_GROUND_Y,0)
 g.camera.position.x=3
 g.camera.look_at(Vector3(3,1.3,0))
 for kind in range(5):
  var e:Dictionary=kinds[kind]
  g.enemies.append(e)
  e.node.show()
  e.node.position=Vector3(2,e.home.y,0)
  e.windup=0.6
  e.aim=4
  e.aim_z=0
  g.hp=100
  g.invulnerable=0
  g.update_enemy(e,0.01)
  check(e.node.texture==g.ENEMY_ATTACK_TEXTURES[kind] and g.hp==100,"distinct windup without early damage "+str(kind))
  e.windup=0.1
  g.update_enemy(e,0.01)
  check(e.node.frame==1,"late anticipation pose "+str(kind))
  var shots_before:int=g.shots.size()
  g.update_enemy(e,0.10)
  if kind==1:g.update_enemy(e,0.24)
  check(e.node.frame==2 and e.recovery>0,"contact pose on damage tick "+str(kind))
  check(g.shots.size()==shots_before+1 if kind==2 else g.hp<100,"attack releases only at contact "+str(kind))
  g.update_hud()
  await capture(view,"enemy-"+str(kind)+"-contact")
  g.update_enemy(e,g.ENEMY_RECOVERIES[kind]*0.6 if kind<4 else 0.2)
  check(e.node.frame==3,"recovery pose "+str(kind))
  e.recovery=0
  e.windup=-1
  e.clock=0
  g.damage_enemy(e,1)
  g.update_enemy(e,0.01)
  check(e.node.texture==g.ENEMY_FALL_TEXTURES[kind] and e.node.frame==0,"species-specific hurt pose "+str(kind))
  g.damage_enemy(e,10000)
  check(not e in g.enemies and e in g.dying,"dying actor stops being a combat target "+str(kind))
  g.update_deaths(g.ENEMY_FALL_DURATIONS[kind]*0.65)
  check(e.node.frame==3 and e.node.visible and e.node.scale==Vector3.ONE,"drawn collapse keeps scale "+str(kind))
  await capture(view,"enemy-"+str(kind)+"-fallen")
  g.update_deaths(g.ENEMY_FALL_DURATIONS[kind]*0.36)
  check(not e.node.visible and not e in g.dying,"death returns pooled actor "+str(kind))
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 print("ENEMY IDENTITY FAILURES=",failures)
 quit(1 if failures else 0)
func capture(view:SubViewport,name:String):
 if DisplayServer.get_name()=="headless":return
 await process_frame
 await process_frame
 RenderingServer.force_draw(false)
 view.get_texture().get_image().save_png("res://docs/"+name+".png")
