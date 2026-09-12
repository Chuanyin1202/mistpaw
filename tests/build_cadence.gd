extends SceneTree
func _initialize():call_deferred("run")
func run():
 var report:Array=[]
 var native:=DisplayServer.get_name()!="headless"
 for scenario in (["single_fixed"] if native else ["single_fixed","crowd_fixed","single_recoil"]):
  for build in [-1,0,1,2]:
   var g=load("res://scenes/main.tscn").instantiate()
   root.add_child(g)
   await process_frame
   if not g.ready_for_play:await g.boot_finished
   g.set_physics_process(false)
   g.music.stop()
   g.sound_voices=5
   g.build=build
   g.auto_attack=true
   g.hp=50
   g.hero.position=Vector3(0,g.HERO_GROUND_Y,0)
   var actors:Array=g.enemies.slice(0,5 if scenario=="crowd_fixed" else 1)
   for e in g.enemies:e.node.hide()
   g.enemies.clear()
   for i in range(actors.size()):
    var e:Dictionary=actors[i]
    e.node.show()
    e.hp=100000
    e.max_hp=100000
    e.node.position=Vector3(1.8+i*0.15,e.home.y,0)
    e.clock=-100
    g.enemies.append(e)
   var contacts:Array[float]=[]
   var damage:=0.0
   var started:=Time.get_ticks_usec()
   for tick in range(600):
    var before:=0.0
    for i in range(actors.size()):
     var e:Dictionary=actors[i]
     if scenario!="single_recoil":
      e.node.position=Vector3(1.8+i*0.15,e.home.y,0)
      e.recoil=0
     e.clock=-100
     before+=e.hp
    var contacted:bool=g.contact_done
    var prior:float=g.attack_time
    g._physics_process(1.0/60)
    if g.attack_time>=0 and g.contact_done and (not contacted or prior<0):contacts.append(tick/60.0)
    var after:=0.0
    for e in actors:after+=e.hp
    damage+=before-after
    if native or tick%60==0:await process_frame
   var spacing:=0.0
   for i in range(1,contacts.size()):spacing+=contacts[i]-contacts[i-1]
   var row={"scenario":scenario,"build":build,"contacts":contacts.size(),"mean_contact_interval":spacing/maxi(1,contacts.size()-1),"wall_seconds":(Time.get_ticks_usec()-started)/1000000.0,"damage":damage,"dps":damage/10.0}
   report.append(row)
   print("CADENCE ",JSON.stringify(row))
   g.queue_free()
   await process_frame
 var file:=FileAccess.open("res://build/verification/build-cadence-native.json" if native else "res://build/verification/build-cadence.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"  "))
 await create_timer(0.3).timeout
 quit()
