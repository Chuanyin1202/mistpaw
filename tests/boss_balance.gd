extends SceneTree
func _initialize():call_deferred("run")
func key(code:int,pressed:bool):
 var e:=InputEventKey.new()
 e.physical_keycode=code
 e.pressed=pressed
 Input.parse_input_event(e)
func run():
 AudioServer.set_bus_mute(0,true)
 var results=[]
 for style in range(3):
  for policy in ["stand","chase","evade"]:
   var g=load("res://scenes/main.tscn").instantiate()
   root.add_child(g)
   await process_frame
   if not g.ready_for_play:await g.boot_finished
   g.set_physics_process(false)
   g.set_process_unhandled_key_input(false)
   g.music.stop()
   g.sound_voices=5
   for e in g.enemies:e.node.hide()
   g.enemies.clear()
   g.room=3
   g.spawn_room()
   var boss:Dictionary=g.enemies[0]
   g.hero.position=Vector3(43,g.HERO_GROUND_Y,-1)
   boss.node.position=Vector3(45,boss.home.y,-1)
   g.build=style
   g.press_action("basic")
   var low:=100.0
   var damage:=0.0
   var healing:=0.0
   var ticks:=0
   for tick in range(3600):
    ticks=tick
    if g.hp<=0 or boss.hp<=0:break
    var delta:Vector3=boss.node.position-g.hero.position
    var x:=signf(delta.x) if absf(delta.x)>2 or delta.x*g.facing<0 else 0.0
    var z:=signf(delta.z) if absf(delta.z)>0.25 else 0.0
    if policy=="stand":x=0;z=0
    if policy=="evade":
     if boss.windup>=0 or (g.boss.pattern==2 and g.boss.active>=0):
      var back:float=g.Forest.road_back(g.hero.position.x)+0.6
      var safe:float=1.1 if absf(1.1-boss.aim_z)>absf(back-boss.aim_z) else back
      z=signf(safe-g.hero.position.z) if absf(safe-g.hero.position.z)>0.08 else 0.0
      if g.boss.pattern==2 and boss.windup<0.2:g.try_jump()
     if g.boss.land_damaging and g.boss.land_age>0.4 and g.boss.land_age<1.3 and g.jump_height==0:g.try_jump()
    for pair in [[KEY_A,x<0],[KEY_D,x>0],[KEY_W,z<0],[KEY_S,z>0]]:key(pair[0],pair[1])
    Input.flush_buffered_events()
    if absf(delta.x)<4:g.try_heavy()
    if delta.length()<3:g.try_spin()
    var before:float=g.hp
    g._physics_process(1.0/60)
    damage+=maxf(0,before-g.hp)
    healing+=maxf(0,g.hp-before)
    low=minf(low,g.hp)
    if tick%30==0:await process_frame
   var result={"build":style,"policy":policy,"won":boss.hp<=0,"time":snappedf(ticks/60.0,0.01),"hp":g.hp,"min_hp":low,"net_damage_ticks":damage,"net_heal_ticks":healing,"boss_hp":boss.hp,"phase":g.boss.phase}
   results.append(result)
   print("BALANCE ",JSON.stringify(result))
   for code in [KEY_A,KEY_D,KEY_W,KEY_S]:key(code,false)
   Input.flush_buffered_events()
   g.release_action("basic")
   for c in g.get_children():
    if c is AudioStreamPlayer:c.stop()
   g.queue_free()
   await process_frame
 var file=FileAccess.open("res://build/verification/boss-balance.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(results,"  "))
 await create_timer(0.3).timeout
 quit()
