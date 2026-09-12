extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 AudioServer.set_bus_mute(0,false)
 var recorder:=AudioEffectRecord.new()
 recorder.format=AudioStreamWAV.FORMAT_16_BITS
 var index:int=AudioServer.get_bus_effect_count(0)
 AudioServer.add_bus_effect(0,recorder)
 recorder.set_recording_active(true)
 var started:=Time.get_ticks_msec()
 var last_tick:=-1
 while Time.get_ticks_msec()-started<15000:
  var tick:int=(Time.get_ticks_msec()-started)/100
  if tick!=last_tick:
   last_tick=tick
   var section:int=tick/30
   if tick%30==0:print("AUDIO/section ",section)
   if section==1 and tick%3==0:g.sound("blade-contact.wav",-3)
   if section==2 and tick%6==0:
    g.feedback.heavy_hit(1)
    g.pickup_sound()
   if section==3 and tick%3==0:
    g.feedback.chain(false)
    g.sound("blade-contact.wav",-3)
   if section==4:
    if tick==120:
     g.room=3
     g.spawn_room()
    if tick%6==0:g.feedback.heavy_hit(1)
    if tick%15==0:g.sound("boss-fracture.wav",-2)
   g.advance_audio(.1)
  await process_frame
 recorder.set_recording_active(false)
 var recording:AudioStreamWAV=recorder.get_recording()
 print("AUDIO/save=",recording.save_to_wav("res://build/verification/final-mix.wav"))
 AudioServer.remove_bus_effect(0,index)
 g.feedback.clear()
 for c in g.get_children():
  if c is AudioStreamPlayer:c.stop()
 await create_timer(.3).timeout
 g.queue_free()
 await process_frame
 quit()
