extends SceneTree
var failures := 0
func check(ok: bool, title: String):
 print(("PASS " if ok else "FAIL ")+title)
 if not ok:failures+=1
func _initialize():call_deferred("run")
func run():
 var view:=SubViewport.new()
 view.size=Vector2i(1280,720)
 view.own_world_3d=true
 view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(view)
 var g=load("res://scenes/main.tscn").instantiate()
 view.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 g.set_process_unhandled_key_input(false)
 g.music.stop()
 AudioServer.set_bus_mute(0,true)
 g.sound_voices=0
 for enemy in g.enemies:enemy.node.hide()
 var e=g.enemies[0]
 g.enemies.clear()
 g.enemies.append(e)
 e.node.show()
 e.hp=1000
 e.max_hp=1000
 g.hero.position=Vector3(0,1.87,0)
 var textures:Dictionary={}
 for stage in range(3):
  e.node.position=Vector3(2,e.home.y,0)
  e.clock=0
  e.windup=-1
  g.effects.clear()
  var hp:float=e.hp
  g.start_attack(false)
  var hit_at:float=g.COMBO_CONTACTS[stage]
  g._physics_process(hit_at-0.005)
  textures[g.hero.texture.resource_path]=true
  check(g.combo_stage==stage,"correct stage "+str(stage+1))
  check(e.hp==hp and not g.effects.impacts.any(func(h):return h.node.visible),"no premature damage or impact "+str(stage+1))
  await capture(view,"combo-%d-windup"%(stage+1))
  g._physics_process(0.006)
  check(e.hp==hp-17 and g.contact_done,"one damage event at contact "+str(stage+1))
  check(g.hero.frame==4 and g.effects.stroke==stage,"contact pose and slash style agree "+str(stage+1))
  var voices=g.get_children().filter(func(n):return n is AudioStreamPlayer and n!=g.music)
  check(not voices.is_empty() and voices[-1].stream==g.SOUNDS["blade-weight.wav" if stage==2 else "blade-contact.wav"] and is_equal_approx(voices[-1].pitch_scale,[1.0,1.08,1.14][stage]),"contact plays stage-specific sound pitch "+str(stage+1))
  check(e.node.texture==g.ENEMY_FALL_TEXTURES[e.kind] and e.node.frame==0,"hit uses dedicated hurt pose instead of running frame "+str(stage+1))
  if stage==2:check(e.stagger>0 and e.recoil>2,"finisher gives brief minion stagger and stronger recoil")
  await capture(view,"combo-%d-contact"%(stage+1))
  g._physics_process(g.COMBO_DURATIONS[stage]-hit_at+0.01)
  check(e.hp==hp-17,"recovery cannot apply a second hit "+str(stage+1))
 check(textures.size()==3,"three distinct eight-frame character atlases")
 check(g.combo_next==0,"third hit loops back to first")
 g.combo_next=2
 g.combo_window=0.001
 e.node.position.x=55
 g._physics_process(0.05)
 g.start_attack(false)
 check(g.combo_stage==0,"idle timeout resets combo")
 var voice_count=g.get_children().filter(func(n):return n is AudioStreamPlayer and n!=g.music).size()
 g._physics_process(0.11)
 check(voice_count==g.get_children().filter(func(n):return n is AudioStreamPlayer and n!=g.music).size(),"whiff does not play impact sound")
 check(g.combo_window==0 and not g.effects.impacts.any(func(h):return h.node.visible),"whiff does not advance combo or create contact spark")
 g.combo_next=1
 g.combo_window=0.85
 g.start_attack(false)
 e.node.position=Vector3(2,e.home.y,0)
 var before:float=e.hp
 g.try_dash()
 g._physics_process(0.12)
 check(e.hp==before and g.attack_time<0 and not g.effects.slash.visible,"dash cancels unspent attack without ghost hit")
 g.dash_time=0
 g.hero.position=Vector3(0,1.87,0)
 g.facing=1
 g.combo_window=0
 g.start_attack(false)
 var key:=InputEventKey.new()
 key.physical_keycode=KEY_A
 key.pressed=true
 Input.parse_input_event(key)
 Input.flush_buffered_events()
 g._physics_process(0.02)
 check(g.hero.position.x<0 and g.facing==1,"reverse movement stays responsive without flipping in-flight sword")
 key=key.duplicate()
 key.pressed=false
 Input.parse_input_event(key)
 Input.flush_buffered_events()
 g.paused=true
 var attack_clock:float=g.attack_time
 var chain_clock:float=g.combo_window
 g._physics_process(0.5)
 check(g.attack_time==attack_clock and g.combo_window==chain_clock,"pause freezes attack and combo window")
 g.paused=false
 g.start_attack(true)
 check(g.combo_next==0 and g.combo_window==0,"heavy resets basic chain")
 g.feedback.clear()
 for child in g.get_children():
  if child is AudioStreamPlayer:child.stop()
 await create_timer(0.3).timeout
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 print("COMBO FAILURES=",failures)
 quit(1 if failures else 0)
func capture(view:SubViewport,name:String):
 if DisplayServer.get_name()=="headless":return
 await process_frame
 await process_frame
 RenderingServer.force_draw(false)
 view.get_texture().get_image().save_png("res://docs/"+name+".png")
