extends SceneTree
var failures:=0
func check(ok:bool,title:String):
 print(("PASS " if ok else "FAIL ")+title)
 if not ok:failures+=1
func _initialize():call_deferred("run")
func run():
 var poses=preload("res://scripts/attack_pose.gd")
 check(poses.frame(0,false,0.04,0.105,0.30)!=poses.frame(2,false,0.04,0.095,0.29),"thrust extends earlier than downward cut")
 check(poses.frame(0,true,0.255,0.19,0.48)==4 and poses.frame(2,false,0.16,0.095,0.29)>4,"heavy holds contact while thrust already retracts")
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 g.music.stop()
 g.sound_voices=5
 for enemy in g.enemies:enemy.node.position.x=50
 g.start_attack(false)
 g._physics_process(0.31)
 g._physics_process(0.01)
 check(g.hero.frame==7 and g.attack_settle>0,"short combo gap keeps follow-through instead of snapping to ready pose")
 var key:=InputEventKey.new()
 key.physical_keycode=KEY_D
 key.pressed=true
 Input.parse_input_event(key)
 Input.flush_buffered_events()
 var before:float=g.hero.position.x
 g._physics_process(0.01)
 check(g.hero.position.x>before and g.hero.texture!=g.settle_texture,"movement immediately releases the settle pose")
 key=key.duplicate()
 key.pressed=false
 Input.parse_input_event(key)
 Input.flush_buffered_events()
 var e:Dictionary=g.enemies[0]
 e.node.position.x=2
 var shifts:Array[Vector2]=[]
 for stroke in range(4):
  g.damage_enemy(e,1,1.0,stroke)
  shifts.append(e.reaction_offset)
 check(shifts[3].y<shifts[0].y and shifts[2].x>shifts[1].x and shifts[1].y==0,"cleave compresses, sweep displaces, thrust drives back distinctly")
 var ground:float=e.node.position.y
 g.update_enemy(e,0.01)
 check(e.node.position.y==ground and e.node.offset==shifts[3],"reaction changes visible sprite without moving ground collision")
 for i in range(20):g.update_enemy(e,0.01)
 check(e.node.offset.length()<0.01,"visual recoil fully settles without accumulating drift")
 g.attack_time=-1
 g.attack_cd=10
 g.hurt_time=0
 g.jump_height=0.01
 g.jump_velocity=-1
 g._physics_process(0.02)
 g._physics_process(0.03)
 check(g.hero.offset.y<0 and g.jump_height==0,"landing compresses the visible pose while feet collision is grounded")
 key=key.duplicate()
 key.pressed=true
 Input.parse_input_event(key)
 Input.flush_buffered_events()
 before=g.hero.position.x
 g._physics_process(0.01)
 check(g.hero.position.x>before,"landing follow-through cannot lock movement")
 key=key.duplicate()
 key.pressed=false
 Input.parse_input_event(key)
 Input.flush_buffered_events()
 e.stagger=0
 e.flash=0.1
 e.windup=0.5
 g.update_enemy(e,0.01)
 check(e.node.texture==g.ENEMY_ATTACK_TEXTURES[e.kind],"light hit preserves readable enemy attack anticipation")
 g.queue_free()
 await process_frame
 await create_timer(0.3).timeout
 print("MOTION WEIGHT FAILURES=",failures)
 quit(1 if failures else 0)
