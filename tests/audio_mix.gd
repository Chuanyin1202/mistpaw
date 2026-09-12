extends SceneTree
var failures:=0
func check(ok:bool,title:String):
 print(("PASS " if ok else "FAIL ")+title)
 if not ok:failures+=1
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 g.music.stop()
 check(AudioServer.get_bus_count()==5,"music, regular hits, boss impacts and pickups have separate buses")
 g.sound_voices=5
 g.sound("boss-fracture.wav",-2)
 check(g.important_sound.playing and g.important_sound.stream==g.SOUNDS["boss-fracture.wav"],"boss landing still plays when all regular voices are occupied")
 g.pickup_sound()
 check(g.pickup_player.playing and g.important_sound.playing,"pickup plays without interrupting the boss impact")
 g.advance_audio(0.01)
 check(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))==-4 and AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))==-3,"important impact briefly makes room in music and ordinary hits")
 check(g.sound_voices==5,"priority sounds do not grow the ordinary voice count")
 g.advance_audio(1)
 check(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))==0 and AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))==0,"mix returns to normal after the impact tail")
 g.sound("stage-clear.mp3",-8)
 check(g.important_sound.stream==g.SOUNDS["stage-clear.mp3"],"victory cue has a guaranteed playback slot")
 g.toggle_mute()
 check(AudioServer.is_bus_mute(0),"master mute covers every new bus")
 g.toggle_mute()
 g.queue_free()
 await process_frame
 await create_timer(0.3).timeout
 print("AUDIO MIX FAILURES=",failures)
 quit(1 if failures else 0)
