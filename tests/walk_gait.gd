extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 print(("PASS " if ok else "FAIL ")+label)
 if not ok:failures+=1
func key(code:int,down:bool):
 var e:=InputEventKey.new()
 e.physical_keycode=code
 e.pressed=down
 Input.parse_input_event(e)
 Input.flush_buffered_events()
func run():
 root.size=Vector2i(1280,720)
 root.title="Mistpaw · 步態與接地檢查"
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 for e in g.enemies:e.node.hide()
 g.enemies.clear()
 var start:Vector3=g.hero.position
 var frames:Array[int]=[]
 key(KEY_D,true)
 for tick in range(32):
  g._physics_process(1.0/60)
  if not g.hero.frame in frames:
   frames.append(g.hero.frame)
   if DisplayServer.get_name()!="headless":
    await process_frame
    RenderingServer.force_draw(false)
    root.get_texture().get_image().save_png("res://docs/gait-step-"+str(g.hero.frame)+".png")
  await process_frame
 check(g.hero.texture.resource_path.ends_with("cat-walk-contact.png") and frames.size()==4,"contact and passing walk presents four gait poses")
 check(absf(g.walk_time*4.5-g.ground_distance(start,g.hero.position))<0.001,"gait phase follows actual ground displacement")
 check(absf(g.hero.position.y-g.HERO_GROUND_Y)<0.001,"walk never moves collision body above ground")
 key(KEY_D,false)
 g._physics_process(1.0/60)
 var stopped:Vector3=g.hero.position
 for i in range(20):g._physics_process(1.0/60)
 check(g.hero.position==stopped and g.hero.texture.resource_path.ends_with("cat-ready.png"),"release stops immediately without a slide")
 g.hero.position.x=-8
 key(KEY_A,true)
 for i in range(60):g._physics_process(1.0/60)
 var phase:float=g.walk_time
 for i in range(60):g._physics_process(1.0/60)
 check(g.walk_time==phase and g.hero.texture.resource_path.ends_with("cat-ready.png"),"blocked movement does not cycle walking feet")
 key(KEY_A,false)
 for c in g.get_children():
  if c is AudioStreamPlayer:c.stop()
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 quit(1 if failures else 0)
