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
 for e in g.enemies:e.node.position.x=55
 for i in range(3):
  g.start_attack(false)
  g._physics_process(0.05)
  print("COMBO_BASELINE stage=",i," texture=",g.hero.texture.resource_path," cooldown=",g.attack_cd)
 var e=g.enemies[0]
 e.node.position=Vector3(2,e.home.y,0)
 e.clock=0
 g.damage_enemy(e,1)
 g.update_enemy(e,0.02)
 print("COMBO_BASELINE hit_texture=",e.node.texture.resource_path," frame=",e.node.frame," stagger=",e.stagger," windup=",e.windup)
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 quit()
