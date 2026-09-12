extends SceneTree
const Driver=preload("res://tests/demo_driver.gd")
## Scripted input choreography through normal actions; no combat-state cheats.
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 if not game.ready_for_play:await game.boot_finished
 game.set_physics_process(false)
 game.set_visual_profile(0,false)
 var held:={}
 var hold_ticks:=0
 var second_jump:=-1
 var aerial_rooms:={}
 var min_hp:=100.0
 var stats:={"dash":0,"double_jump":0,"spin":0,"heavy":0,"break":0,"run":0}
 var boss_was_winding:=false
 var was_broken:=false
 var boss_moves:Array[int]=[]
 print("DEMO START frame=",Engine.get_process_frames())
 for tick in range(18000):
  if game.ended:break
  var previous_heavy:bool=game.attack_power and game.attack_time>=0
  var previous_spin:float=game.spin_time
  var previous_run:float=game.run_direction
  var move:=0
  var depth:=0
  var want_dash:=false
  var nearest:Dictionary=game.nearest_enemy()
  if tick>=75:
   if not nearest.is_empty():
    var dx:float=nearest.node.position.x-game.hero.position.x
    var dz:float=nearest.node.position.z-game.hero.position.z
    if absf(dx)>1.8 or dx*game.facing<0:move=int(signf(dx))
    if absf(dz)>.22:depth=int(signf(dz))
    if game.room<3:
     for e in game.enemies:
      if e.windup>0 and e.windup<.20 and game.ground_distance(e.node.position,game.hero.position)<3.4 and game.dash_cd<=0:want_dash=true
     if not aerial_rooms.has(game.room) and game.room>0 and absf(dx)<3.2 and game.jump_height==0:
      aerial_rooms[game.room]=true
      game.press_action("jump")
      second_jump=tick+12
   elif not game.drops.is_empty():
    move=Driver.loot_movement(game.drops[0].node.position.x-game.hero.position.x)
    var dz:float=game.drops[0].node.position.z-game.hero.position.z
    if absf(dz)>.7:depth=int(signf(dz))
   elif game.encounter_flow.pending>=0:
    if game.encounter_flow.rest<3.2:
     var advance:=InputEventKey.new()
     advance.physical_keycode=KEY_F
     advance.pressed=true
     game._unhandled_key_input(advance)
   else:move=1
  if game.room==3 and not game.enemies.is_empty():
   var e:Dictionary=game.enemies[0]
   if e.windup>=0 or (game.boss.pattern==2 and game.boss.active>=0):
    var back:float=game.Forest.road_back(game.hero.position.x)+.6
    var safe:float=1.1 if absf(1.1-e.aim_z)>absf(back-e.aim_z) else back
    depth=int(signf(safe-game.hero.position.z)) if absf(safe-game.hero.position.z)>.08 else 0
    if game.boss.pattern==2 and e.windup<.2 and game.jump_height==0:
     game.press_action("jump")
     second_jump=tick+16
    if game.boss.pattern==0 and e.windup<.18 and game.dash_cd<=0 and depth!=0:want_dash=true
   if game.boss.land_damaging and game.boss.land_age>.4 and game.boss.land_age<1.3 and game.jump_height==0:
    game.press_action("jump")
    second_jump=tick+16
  if not game.unlocked.is_empty():
   var choice:int=game.unlocked.back()
   if game.build!=choice:
    var select:=InputEventKey.new()
    select.physical_keycode=KEY_1+choice
    select.pressed=true
    game._unhandled_key_input(select)
  # Double-tap the actual direction key on long travel, not a speed override.
  hold_ticks=hold_ticks+1 if move!=0 else 0
  var travel:bool=nearest.is_empty() or absf(nearest.node.position.x-game.hero.position.x)>4.5
  var tap_gap:bool=travel and hold_ticks==5
  for code in [KEY_A,KEY_D,KEY_W,KEY_S,KEY_J]:
   var pressed:bool=(code==KEY_A and move<0 and not tap_gap) or (code==KEY_D and move>0 and not tap_gap) or (code==KEY_W and depth<0) or (code==KEY_S and depth>0) or (code==KEY_J and tick>=75 and not nearest.is_empty() and game.ground_distance(nearest.node.position,game.hero.position)<game.sword_reach(false))
   if not pressed and not held.get(code,false):continue
   var event:=InputEventKey.new()
   event.physical_keycode=code
   event.pressed=pressed
   event.echo=pressed and held.get(code,false) and Input.is_physical_key_pressed(code)
   held[code]=pressed
   Input.parse_input_event(event)
  Input.flush_buffered_events()
  if want_dash:
   game.press_action("dash")
   stats.dash+=1
  if tick==second_jump and game.jumps_used==1:
   game.press_action("jump")
   stats.double_jump+=1
   if game.room<3:game.press_action("spin")
  if not nearest.is_empty() and not want_dash:
   var distance:float=game.ground_distance(nearest.node.position,game.hero.position)
   if distance<3.8 and game.skill_cd<=0 and game.jump_height<.4:game.press_action("heavy")
   elif distance<2.8 and game.spin_cd<=0 and game.attack_time<0:game.press_action("spin")
  game._physics_process(1.0/60)
  if game.attack_power and game.attack_time>=0 and not previous_heavy:stats.heavy+=1
  if game.spin_time>=0 and previous_spin<0:stats.spin+=1
  if previous_run==0 and game.run_direction!=0:stats.run+=1
  var e:Dictionary=game.enemy_pools[3][0]
  var winding:bool=e in game.enemies and e.windup>=0
  if winding and not boss_was_winding:boss_moves.append(game.boss.pattern)
  boss_was_winding=winding
  if game.boss.stunned>0 and not was_broken:stats.break+=1
  was_broken=game.boss.stunned>0
  min_hp=minf(min_hp,game.hp)
  await process_frame
 for code in [KEY_A,KEY_D,KEY_W,KEY_S,KEY_J]:
  var event:=InputEventKey.new()
  event.physical_keycode=code
  Input.parse_input_event(event)
 Input.flush_buffered_events()
 print("DEMO ended=",game.ended," hp=",game.hp," min_hp=",min_hp," pickups=",game.pickups," time=",game.elapsed," frame=",Engine.get_process_frames())
 print("DEMO BOSS SEQUENCE ",boss_moves," ACTIONS ",stats)
 var success:bool=game.ended and game.hp>0 and game.pickups==4 and stats.dash>0 and stats.double_jump>=2
 for i in range(150):await process_frame
 game.feedback.clear()
 for child in game.get_children():
  if child is AudioStreamPlayer:child.stop()
 await create_timer(.3).timeout
 game.queue_free()
 await process_frame
 quit(0 if success else 1)
