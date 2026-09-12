extends SceneTree
var failures:=0
func observe(view:SubViewport,tag:String,tick:int):
 if DisplayServer.get_name()=="headless":return
 await process_frame
 if tick in [0,92,155]:
  RenderingServer.force_draw(false)
  view.get_texture().get_image().save_png("res://build/verification/idle-"+tag+"-"+str(tick)+".png")
func check(ok:bool,title:String):
 print(("PASS " if ok else "FAIL ")+title)
 if not ok:failures+=1
func _initialize():call_deferred("run")
func run():
 var view:=SubViewport.new()
 view.size=Vector2i(1280,720)
 view.own_world_3d=true
 view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(view)
 var display:=TextureRect.new()
 display.texture=view.get_texture()
 root.add_child(display)
 root.title="Mistpaw 待機與動作銜接檢查"
 root.always_on_top=true
 var g=load("res://scenes/main.tscn").instantiate()
 view.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 for e in g.enemies:e.node.position.x=55
 var start:Vector3=g.hero.position
 var frames_seen:={}
 for i in range(210):
  g._physics_process(1.0/60)
  frames_seen[g.hero.frame]=true
  await observe(view,"side",i)
 check(frames_seen.size()==4,"側面待機播放四個一致姿勢")
 check(g.hero.position.is_equal_approx(start),"待機不移動角色與碰撞位置")
 check(g.attack_time<0 and not g.effects.slash.visible,"待機不觸發攻擊或白線")
 g.idle_time=1.47
 g._physics_process(0.001)
 check(g.hero.frame==2,"閉眼幀按短時序顯示")
 if DisplayServer.get_name()!="headless":
  await process_frame
  await process_frame
  RenderingServer.force_draw(false)
  view.get_texture().get_image().save_png("res://docs/cat-idle-blink.png")
 var clock:float=g.idle_time
 g.paused=true
 g._physics_process(0.1)
 check(g.idle_time==clock,"暫停凍結待機動畫")
 g.paused=false
 g.start_attack(false)
 g._physics_process(0.02)
 check(g.idle_time==0 and g.attack_time>0 and not g.contact_done,"出招立即中止待機")
 check(g.attack_entry_pose and g.hero.offset==Vector2(0,6),"首個蓄勢幀共用待機備戰姿勢")
 g._physics_process(0.06)
 check(g.hero.texture.resource_path.ends_with("cat-cut-eight.png"),"蓄勢後進入專屬揮劍動畫")
 g.attack_time=-1
 g.attack_settle=0
 for direction in [-1,1]:
  g.locomotion_depth=direction
  g.idle_time=0
  frames_seen.clear()
  for i in range(210):
   g._physics_process(1.0/60)
   frames_seen[g.hero.frame]=true
   await observe(view,str(direction),i)
  var suffix:String="cat-idle-away.png" if direction<0 else "cat-idle-toward.png"
  check(g.hero.texture.resource_path.ends_with(suffix) and frames_seen.size()==8,"前後朝向保留並播放完整待機 "+str(direction))
  check(g.hero.position.is_equal_approx(start),"前後待機不移動碰撞位置 "+str(direction))
 for build in [-1,0,1,2]:
  for power in [false,true]:
   g.build=build
   g.attack_time=-1
   g.attack_settle=0
   g.locomotion_depth=0
   g.idle_time=0
   g._physics_process(0.001)
   var ready_texture=g.hero.texture
   var ready_offset:Vector2=g.hero.offset
   g.start_attack(power)
   g._physics_process(0.001)
   check(g.hero.texture==ready_texture and g.hero.offset==ready_offset and g.hero.frame==0,"待機接蓄勢對位 build="+str(build)+" heavy="+str(power))
 g.attack_time=-1
 g.attack_settle=0
 var input:=InputEventKey.new()
 input.physical_keycode=KEY_D
 input.pressed=true
 Input.parse_input_event(input)
 Input.flush_buffered_events()
 g._physics_process(0.02)
 check(g.idle_time==0 and g.hero.offset==Vector2(0,12),"移動立即中止待機並使用走路接地對位")
 check(g.hero.texture.resource_path.ends_with("cat-walk-contact.png"),"四格承重與交錯行走動畫")
 var release:=InputEventKey.new()
 release.physical_keycode=KEY_D
 release.pressed=false
 Input.parse_input_event(release)
 Input.flush_buffered_events()
 for child in g.get_children():
  if child is AudioStreamPlayer:child.stop()
 g.feedback.clear()
 await create_timer(0.3).timeout
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 quit(0 if failures==0 else 1)
