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
 var display:=TextureRect.new()
 display.texture=view.get_texture()
 root.add_child(display)
 var g=load("res://scenes/main.tscn").instantiate()
 view.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 g.music.stop()
 g.sound_voices=5
 for build in range(3):
  g.build=build
  var styles:={}
  for stage in range(3):
   g.effects.clear()
   g.build_effects.clear()
   g.hero.position=Vector3(0,g.HERO_GROUND_Y,0)
   g.combo_next=stage
   g.combo_window=1
   g.facing=1
   for i in range(g.enemies.size()):
    var e=g.enemies[i]
    e.node.position=Vector3(1.8+i*0.55,e.home.y,-1.3 if i>0 else 0)
    e.hp=1000
    e.clock=-100
    e.recoil=0
   g.start_attack(false)
   styles[g.combo_style()]=true
   for i in range(14):g._physics_process(1.0/120)
   check(g.contact_done and g.hero.texture==g.COMBO_TEXTURES[g.combo_style()],"流派姿勢與命中對齊 %d/%d"%[build,stage])
   check(is_equal_approx(g.attack_cd,g.COMBO_COOLDOWNS[stage]-14.0/120),"流派不延長普攻冷卻 %d/%d"%[build,stage])
   if stage==2:
    var active=g.build_effects.pool.filter(func(f):return f.node.visible)
    if build==0:check(active.any(func(f):return f.kind==0 and f.power),"波刃末式有強弱層次")
    if build==1:check(active.filter(func(f):return f.kind==1).size()==3,"雷擊末式跳三名鄰敵")
    if build==2:check(active.any(func(f):return f.kind==3 and f.power),"滿血也能辨識嗜血交叉斬")
    if DisplayServer.get_name()!="headless":
     await process_frame
     await process_frame
     RenderingServer.force_draw(false)
     view.get_texture().get_image().save_png("res://docs/finisher-"+str(build)+".png")
  check(styles.size()==3,"每個流派仍保留三種普攻姿勢 "+str(build))
 g.build=0
 g.enemies[0].node.position=Vector3(6.8,g.HERO_GROUND_Y,0)
 check(g.in_sword_range(g.enemies[0],true) and not g.in_sword_range(g.enemies[0],false),"波刃重劈有獨立遠距用途")
 g.build=1
 g.enemies[0].node.position=Vector3(1.8,g.HERO_GROUND_Y,0)
 g.enemies[0].hp=1000
 g.resolve_attack(true)
 check(g.enemies[0].hp==944,"雷系重劈對主目標追加落雷且不重複結算")
 for c in g.get_children():
  if c is AudioStreamPlayer:c.stop()
 await create_timer(0.3).timeout
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 quit(1 if failures else 0)
