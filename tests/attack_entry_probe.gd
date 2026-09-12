extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 g.music.stop()
 g.sound_voices=5
 var target:Dictionary=g.enemies[0]
 for e in g.enemies:e.node.hide()
 g.enemies.clear()
 g.enemies.append(target)
 for build in [-1,0,1,2]:
  for pos in [Vector3(2,0,0),Vector3(3.5,0,0),Vector3(2,0,0.81)]:
   g.hero.position=Vector3(0,g.HERO_GROUND_Y,0)
   g.build=build
   g.attack_time=-1
   g.attack_cd=0
   g.combo_window=0
   g.dash_time=0
   g.spin_time=-1
   g.jump_height=0
   g.jump_velocity=0
   g.facing=1
   target.node.position=Vector3(pos.x,target.home.y,pos.z)
   target.clock=-100
   target.hp=1000
   target.recoil=0
   target.stagger=0
   target.windup=-1
   target.recovery=0
   g._physics_process(0.001)
   var started:bool=g.attack_time>=0
   target.node.position=Vector3(pos.x,target.home.y,pos.z)
   g.resolve_attack(false)
   print("ENTRY build=",build," x=",pos.x," depth=",pos.z," automatic=",started," forced_sword_damage=",1000-target.hp)
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 quit()
