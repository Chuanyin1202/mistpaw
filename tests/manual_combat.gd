extends SceneTree
var failures:=0
func check(ok:bool,title:String):
 print(("PASS " if ok else "FAIL ")+title)
 if not ok:failures+=1
func _initialize():call_deferred("run")
func mouse(down:bool,button:=MOUSE_BUTTON_LEFT):
 var e:=InputEventKey.new()
 e.physical_keycode=KEY_K if button==MOUSE_BUTTON_RIGHT else KEY_J
 e.pressed=down
 Input.parse_input_event(e)
 Input.flush_buffered_events()
func step(g,n:int):
 for i in range(n):g._physics_process(1.0/60)
func run():
 root.size=Vector2i(1280,720)
 await process_frame
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 var enemy:Dictionary=g.enemies[0]
 for e in g.enemies:e.node.position.x=55
 enemy.node.position=g.hero.position+Vector3(1.8,0,0)
 enemy.hp=10000
 enemy.clock=-100
 check(not g.auto_attack,"預設手動普攻")
 step(g,30)
 check(enemy.hp==10000 and g.attack_time<0,"靠近敵人不會自行攻擊")
 mouse(true)
 step(g,1)
 print("MANUAL held=",g.attack_held," facing=",g.facing," attack=",g.attack_time)
 check(g.attack_time>=0 and g.facing==1,"J 鍵即刻朝面向出劍")
 step(g,40)
 check(enemy.hp<9980,"按住J 鍵可持續連段")
 g.get_window().focus_exited.emit()
 check(not g.attack_held and g.attack_buffer==0,"切走視窗不會卡住持續攻擊")
 mouse(false)
 step(g,30)
 var hp:float=enemy.hp
 step(g,30)
 check(enemy.hp==hp and g.attack_time<0,"放開後完成當下動作即停止")
 mouse(true,MOUSE_BUTTON_RIGHT)
 step(g,1)
 check(g.attack_power and g.attack_time>=0,"K 鍵可施放重劈")
 mouse(false,MOUSE_BUTTON_RIGHT)
 g.try_dash()
 var at:Vector3=g.hero.position
 step(g,5)
 check(g.dash_time>0 and g.dodge_effects.wake.visible,"閃躲中顯示定向氣流")
 check(g.dodge_effects.ghosts.any(func(p):return p.node.visible),"閃躲留下短暫殘影")
 if DisplayServer.get_name()!="headless":
  await process_frame
  await process_frame
  RenderingServer.force_draw(false)
  root.get_texture().get_image().save_png("res://docs/dodge-burst.png")
 step(g,6)
 check(g.dash_time==0 and absf(g.ground_distance(at,g.hero.position)-4.08)<0.02,"0.18秒完成原4.08單位閃躲")
 check(g.dash_cd>0.8 and g.invulnerable>0,"保留冷卻與既有無敵時間")
 g.try_dash()
 check(g.dash_time==0,"冷卻期間不能重複閃躲")
 step(g,15)
 check(not g.dodge_effects.wake.visible and not g.dodge_effects.ghosts.any(func(p):return p.node.visible),"殘影收尾不留殘片")
 g.auto_attack=true
 enemy.node.position=g.hero.position+Vector3(1.8,0,0)
 g.attack_cd=0
 step(g,1)
 check(g.attack_time>=0,"自動輔助仍可主動出招")
 g.toggle_pause()
 mouse(true)
 check(not g.attack_held and g.attack_buffer==0,"選單點擊不儲存攻擊輸入")
 mouse(false)
 g.toggle_pause()
 g.finish(false)
 check(not g.dodge_effects.wake.visible,"死亡清除閃躲效果")
 for child in g.get_children():
  if child is AudioStreamPlayer:child.stop()
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 quit(1 if failures else 0)
