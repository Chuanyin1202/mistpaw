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
 for e in g.enemies:e.node.hide()
 g.enemies.clear()
 g.room=2
 g.spawn_room()
 g.hero.position=Vector3(30,1.87,-1.5)
 g.invulnerable=99
 for i in range(g.enemies.size()):
  var e=g.enemies[i]
  e.node.position=Vector3(33+(i%3)*0.15,e.home.y,-1.5+(i/3)*0.15)
 var worst_windups:=0
 for tick in range(480):
  g.elapsed+=1.0/60
  for e in g.enemies:g.update_enemy(e,1.0/60)
  worst_windups=maxi(worst_windups,g.enemies.filter(func(e):return e.windup>=0).size())
 var close_pairs:=0
 var nearest_sum:=0.0
 for i in range(g.enemies.size()):
  var nearest:=100.0
  for j in range(g.enemies.size()):
   if i==j:continue
   var d:float=g.ground_distance(g.enemies[i].node.position,g.enemies[j].node.position)
   nearest=minf(nearest,d)
   if i<j and d<0.85:close_pairs+=1
  nearest_sum+=nearest
 print("CROWD close_pairs=",close_pairs," mean_nearest=",nearest_sum/g.enemies.size()," max_windups=",worst_windups)
 var ok=close_pairs==0 and nearest_sum/g.enemies.size()>1.0 and worst_windups>0 and worst_windups<=3
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 quit(0 if ok else 1)
