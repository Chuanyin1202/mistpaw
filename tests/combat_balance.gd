extends SceneTree
## Deterministic damage-per-time comparison, not a player-skill simulation.
func _initialize():call_deferred("run")
func run():
 var rows:Array=[]
 var failures:=0
 for layout in ["single","line","spread"]:
  for build in [-1,0,1,2]:
   for skills in [false,true]:
    var g=load("res://scenes/main.tscn").instantiate()
    root.add_child(g)
    await process_frame
    if not g.ready_for_play:await g.boot_finished
    g.set_physics_process(false)
    g.music.stop()
    g.sound_voices=5
    g.build=build
    g.hp=30
    var actors:Array=g.enemies.slice(0,1 if layout=="single" else 5)
    for e in g.enemies:e.node.hide()
    g.enemies.clear()
    for e in actors:
     e.hp=100000
     e.max_hp=100000
     g.enemies.append(e)
    g.press_action("basic")
    for tick in range(600):
     for i in range(actors.size()):
      var e:Dictionary=actors[i]
      e.node.position=Vector3(1.7+i*0.65,e.home.y,-1.4 if layout=="spread" and i>0 else 0)
      e.clock=-100
      e.recoil=0
     if skills:
      if g.skill_cd<=0:g.try_heavy()
      elif g.spin_cd<=0:g.try_spin()
     g._physics_process(1.0/60)
    var damage:=0.0
    for e in actors:damage+=100000-e.hp
    var row={"layout":layout,"build":build,"skills":skills,"dps":damage/10,"heal":g.hp-30}
    rows.append(row)
    print("BALANCE ",JSON.stringify(row))
    g.release_action("basic")
    for c in g.get_children():
     if c is AudioStreamPlayer:c.stop()
    g.queue_free()
    await process_frame
 for i in range(0,rows.size(),2):
  var ok:bool=rows[i+1].dps>rows[i].dps
  print(("PASS " if ok else "FAIL ")+"skills improve DPS "+str(rows[i].layout)+" / "+str(rows[i].build))
  if not ok:failures+=1
 var f=FileAccess.open("res://build/verification/combat-balance.json",FileAccess.WRITE)
 f.store_string(JSON.stringify(rows,"  "))
 await create_timer(0.3).timeout
 quit(1 if failures else 0)
