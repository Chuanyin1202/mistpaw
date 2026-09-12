extends SceneTree
var failures:=0
func check(ok:bool,s:String):
 print(("PASS " if ok else "FAIL ")+s)
 if not ok:failures+=1
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 g.music.stop()
 g.sound_voices=5
 var f=g.encounter_flow
 var ids:Array=g.enemy_pools[0].map(func(e):return e.node.get_instance_id())
 for wave in range(3):
  for e in g.enemies.duplicate():g.damage_enemy(e,10000)
  check(g.cleared==(1 if wave==2 else 0),"only final formation clears area "+str(wave))
  if wave==0:
   check(g.drops.size()==1,"first formation gives one early relic")
   var rest:float=f.rest
   g.paused=true
   g._physics_process(1)
   check(f.rest==rest,"pause freezes preparation timer")
   g.paused=false
  else:check(g.drops.is_empty(),"later formation does not duplicate relic "+str(wave))
  if wave<2:
   for d in g.drops:
    d.node.position=g.hero.position
   for i in range(180):
    g.update_deaths(1.0/60)
    g.update_loot(1.0/60)
   f.rest=0
   f.advance(0.01)
   check(g.enemies.size()==5 and g.enemies.all(func(e):return e.hp==e.max_hp and e.pounce_time<0),"next formation restores pooled enemies cleanly "+str(wave))
   check(g.enemies.map(func(e):return e.node.get_instance_id())==ids,"formation reuses original actors "+str(wave))
 check(f.pending<0 and g.encounter_cleared[0],"third formation leaves no pending respawn")
 check(g.pickups==1 and f.defeated==15,"relic and kill totals are exact")
 g.hero.position.x=12.1
 g._physics_process(0.01)
 check(g.room==1 and g.enemies.size()==7,"next area activates after breakthrough")
 g.finish(false)
 check(g.result_detail.text.contains("擊退 15") and g.result_detail.text.contains("取得 1"),"result reports actual run performance")
 g.feedback.clear()
 for child in g.get_children():
  if child is AudioStreamPlayer:child.stop()
 await create_timer(.3).timeout
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 quit(1 if failures else 0)
