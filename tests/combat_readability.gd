extends SceneTree
var failures:=0
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
 var g=load("res://scenes/main.tscn").instantiate()
 view.add_child(g)
 await process_frame
 if not g.ready_for_play:await g.boot_finished
 g.set_physics_process(false)
 g.music.stop()
 g.sound_voices=5
 for e in g.enemies:e.node.hide()
 var actors=g.enemies.slice(0,3)
 g.enemies.clear()
 for e in actors:g.enemies.append(e)
 g.hero.position=Vector3(14,1.87,0)
 g.camera.position.x=16.5
 g.camera.look_at(Vector3(16.5,1.3,0))
 g.forest.follow_camera(16.5)
 for e in actors:e.node.position.x=55
 var e=actors[0]
 e.node.position=Vector3(14.25,e.home.y,0.7)
 e.node.show()
 g.readability.advance()
 check(g.readability.silhouette.visible,"foreground enemy activates hero silhouette")
 check(g.readability.silhouette.frame==g.hero.frame and g.readability.silhouette.texture==g.hero.texture,"silhouette matches exact hero pose")
 await capture(view,"combat-occlusion")
 e.node.position.z=0
 g.readability.advance()
 print("OCCLUSION same_depth_visible=",g.readability.silhouette.visible)
 check(g.readability.silhouette.visible,"same-depth enemy also preserves hero visibility")
 await capture(view,"combat-same-depth")
 e.node.position.z=-1
 g.readability.advance()
 check(not g.readability.silhouette.visible,"background enemy does not activate silhouette")
 g.build=0
 e.node.position=Vector3(16,e.home.y,0)
 e.hp=1000
 g.start_attack(true)
 g._physics_process(0.191)
 check(g.build_effects.lights[0].light_energy>0,"wave lights nearby scene")
 check(g.build_effects.lights[0].light_energy<=0.65,"light energy is bounded")
 await capture(view,"combat-bridge-wave")
 g.build_effects.advance(1,g.hero.position)
 check(g.build_effects.lights.all(func(l):return l.light_energy==0),"effect lights expire fully")
 g.readability.advance()
 check(g.readability.key_light.light_cull_mask==4 and g.hero.layers==5,"hero fill does not brighten whole scene")
 g.queue_free()
 await process_frame
 await create_timer(0.2).timeout
 print("BUILD FAILURES=",failures)
 quit(1 if failures else 0)
func capture(view:SubViewport,name:String):
 if DisplayServer.get_name()=="headless":return
 await process_frame
 await process_frame
 RenderingServer.force_draw(false)
 view.get_texture().get_image().save_png("res://docs/"+name+".png")
