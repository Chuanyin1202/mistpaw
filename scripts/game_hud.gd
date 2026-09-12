extends CanvasLayer
## Presentation only: combat state remains owned by game.gd.
const GOLD=Color("ad8e59")
const PAPER=Color("eee4ce")
const INK=Color("111c20")
var game:Node3D
var canvas:Control
var world_text:Control
var status:Label
var hint:Label
var notice:Label
var hp_bar:ProgressBar
var hp_lag:ProgressBar
var hp_text:Label
var build_text:Label
var zone_text:Label
var route_text:Label
var boss_health:ProgressBar
var boss_health_holder:Control
var health_panel:Panel
var combat:Control
var slots:Array[Dictionary]=[]
var relics:Array[Dictionary]=[]
var pause_overlay:ColorRect
var resume_button:Button
var mute_button:Button
var quality_button:Button
var text_layout_frame:=-1
var text_rects:Array[Rect2]=[]
var text_obstacles:Array[Rect2]=[]
var last_hp:=100.0
var lag_wait:=0.0

func style(color:Color,border:Color=GOLD)->StyleBoxFlat:
 var s:=StyleBoxFlat.new()
 s.bg_color=color
 s.border_color=border
 s.set_border_width_all(1)
 s.set_corner_radius_all(3)
 s.content_margin_left=18
 s.content_margin_right=18
 s.content_margin_top=10
 s.content_margin_bottom=10
 return s
func place(n:Control,parent:Node,pos:Vector2,extent:Vector2,anchor:=Vector2.ZERO):
 parent.add_child(n)
 n.set_anchors_preset(Control.PRESET_TOP_LEFT)
 n.anchor_left=anchor.x
 n.anchor_right=anchor.x
 n.anchor_top=anchor.y
 n.anchor_bottom=anchor.y
 n.offset_left=pos.x
 n.offset_right=pos.x+extent.x
 n.offset_top=pos.y
 n.offset_bottom=pos.y+extent.y
 n.mouse_filter=Control.MOUSE_FILTER_IGNORE
func label(parent:Node,text:String,pos:Vector2,extent:Vector2,font:=18,anchor:=Vector2.ZERO)->Label:
 var n:=Label.new()
 n.text=text
 n.add_theme_font_size_override("font_size",font)
 n.add_theme_color_override("font_color",PAPER)
 n.add_theme_color_override("font_shadow_color",Color(0,0,0,0.7))
 n.add_theme_constant_override("shadow_offset_y",2)
 place(n,parent,pos,extent,anchor)
 return n
func panel(parent:Node,pos:Vector2,extent:Vector2,anchor:=Vector2.ZERO)->Panel:
 var n:=Panel.new()
 n.add_theme_stylebox_override("panel",style(Color(0.04,0.07,0.08,0.88)))
 place(n,parent,pos,extent,anchor)
 return n
func button(text:String,callback:Callable)->Button:
 var n:=Button.new()
 n.text=text
 n.custom_minimum_size=Vector2(0,48)
 n.add_theme_font_size_override("font_size",20)
 n.add_theme_color_override("font_color",PAPER)
 n.add_theme_stylebox_override("normal",style(Color("1a282a")))
 n.add_theme_stylebox_override("hover",style(Color("30403b"),PAPER))
 n.add_theme_stylebox_override("pressed",style(Color("3e4432"),Color("ebcc8a")))
 var focus:=style(Color(0,0,0,0),Color("f8d897"))
 focus.set_border_width_all(2)
 n.add_theme_stylebox_override("focus",focus)
 n.pressed.connect(func():
  game.sound("vital-arrival.wav",-20)
  callback.call())
 return n
func bar(parent:Node,pos:Vector2,extent:Vector2,color:Color)->ProgressBar:
 var n:=ProgressBar.new()
 n.show_percentage=false
 n.value=100
 var back=style(Color("101719"),Color("4c4937"))
 var fill=style(color,color)
 for s in [back,fill]:
  s.content_margin_top=0
  s.content_margin_bottom=0
  s.content_margin_left=0
  s.content_margin_right=0
 n.add_theme_stylebox_override("background",back)
 n.add_theme_stylebox_override("fill",fill)
 place(n,parent,pos,extent)
 return n
func build(g:Node3D):
 game=g
 canvas=Control.new()
 add_child(canvas)
 canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE
 world_text=Control.new()
 canvas.add_child(world_text)
 world_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 world_text.mouse_filter=Control.MOUSE_FILTER_IGNORE
 world_text.z_index=-10
 combat=Control.new()
 canvas.add_child(combat)
 combat.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 combat.mouse_filter=Control.MOUSE_FILTER_IGNORE
 health_panel=panel(combat,Vector2(36,32),Vector2(302,106))
 status=label(health_panel,"霧爪",Vector2(18,10),Vector2(130,26),22)
 hp_text=label(health_panel,"100 / 100",Vector2(150,14),Vector2(132,24),18)
 hp_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 hp_lag=bar(health_panel,Vector2(18,48),Vector2(266,12),Color("dca864"))
 hp_bar=bar(health_panel,Vector2(18,48),Vector2(266,12),Color("b94a43"))
 hp_bar.add_theme_stylebox_override("background",StyleBoxEmpty.new())
 label(health_panel,"一劍入青霧",Vector2(18,72),Vector2(266,22),15).modulate=Color("b8baa5")
 zone_text=label(combat,"青 霧 林",Vector2(-296,32),Vector2(260,32),24,Vector2(1,0))
 zone_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 route_text=label(combat,"",Vector2(-296,70),Vector2(260,28),17,Vector2(1,0))
 route_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 boss_health_holder=Control.new()
 place(boss_health_holder,combat,Vector2(-296,104),Vector2(260,8),Vector2(1,0))
 boss_health=bar(boss_health_holder,Vector2.ZERO,Vector2(260,8),Color("b45a42"))
 var phase_mark:=ColorRect.new()
 phase_mark.color=Color("ddc69a")
 place(phase_mark,boss_health_holder,Vector2(129,0),Vector2(2,8))
 hint=label(combat,"",Vector2(-210,-80),Vector2(420,64),16,Vector2(0.5,1))
 hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label(combat,"Esc  選單與操作",Vector2(-220,-30),Vector2(184,28),16,Vector2(1,1)).horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 build_text=label(combat,"未裝備法寶",Vector2(36,-138),Vector2(278,28),18,Vector2(0,1))
 for i in range(3):
  var tile=panel(combat,Vector2(36+i*62,-102),Vector2(54,62),Vector2(0,1))
  var art:=TextureRect.new()
  var atlas:=AtlasTexture.new()
  atlas.atlas=preload("res://assets/art/relic-atlas.png")
  atlas.region=Rect2((i%2)*192,(i/2)*192,192,192)
  art.texture=atlas
  art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  place(art,tile,Vector2(7,4),Vector2(40,40))
  var key=label(tile,str(i+1),Vector2(0,43),Vector2(54,18),14)
  key.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  relics.append({"tile":tile,"art":art,"key":key})
 var actions=["basic","heavy","spin","dash","jump"]
 var positions=[Vector2(110,132),Vector2(230,82),Vector2(136,22),Vector2(225,192),Vector2(22,174)]
 var cluster:=Control.new()
 place(cluster,combat,Vector2(-344,-350),Vector2(312,290),Vector2(1,1))
 for i in range(5):
  var diameter:=100.0 if i==0 else 72.0
  var tile=preload("res://scripts/action_button.gd").new()
  place(tile,cluster,positions[i],Vector2.ONE*diameter)
  tile.mouse_filter=Control.MOUSE_FILTER_STOP
  var action:String=actions[i]
  tile.button_down.connect(func():game.press_action(action))
  tile.button_up.connect(func():game.release_action(action))
  var glyph:=TextureRect.new()
  var atlas:=AtlasTexture.new()
  atlas.atlas=preload("res://assets/art/action-medallions.png")
  atlas.region=Rect2(47+(i%2)*487,36+(i/2)*478,440,440)
  atlas.filter_clip=true
  glyph.texture=atlas
  glyph.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  glyph.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  glyph.material=ShaderMaterial.new()
  glyph.material.shader=preload("res://shaders/action_medallion.gdshader")
  glyph.material.set_shader_parameter("diameter",diameter)
  place(glyph,tile,Vector2.ZERO,Vector2.ONE*diameter)
  tile.art=glyph
  var title=label(tile,["普攻","重劈","旋斬","閃躲","跳躍"][i],Vector2(-8,diameter+3),Vector2(diameter+16,20),15)
  title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  var badge:=Panel.new()
  badge.add_theme_stylebox_override("panel",style(Color("111d21"),Color("947b4d")))
  var key_width:=42.0 if i==4 else 26.0
  place(badge,tile,Vector2((diameter-key_width)/2,diameter-16),Vector2(key_width,20))
  var key=label(badge,["J","K","I","L","Space"][i],Vector2.ZERO,Vector2(key_width,20),12)
  key.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  var number=label(tile,"",Vector2(0,diameter/2-15),Vector2(diameter,30),24)
  number.add_theme_color_override("font_outline_color",Color("071214"))
  number.add_theme_constant_override("outline_size",5)
  number.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  slots.append({"tile":tile,"glyph":glyph,"number":number,"action":action})
 notice=label(combat,"",Vector2(-280,38),Vector2(560,60),17,Vector2(0.5,0))
 notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 make_overlays()
 var touch=preload("res://scripts/touch_controls.gd").new()
 touch.game=game
 canvas.add_child(touch)

func make_overlays():
 game.damage_edge=ColorRect.new()
 game.damage_edge.mouse_filter=Control.MOUSE_FILTER_IGNORE
 game.damage_edge.material=ShaderMaterial.new()
 game.damage_edge.material.shader=preload("res://shaders/damage_edge.gdshader")
 canvas.add_child(game.damage_edge)
 game.damage_edge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 pause_overlay=ColorRect.new()
 pause_overlay.color=Color(0.015,0.03,0.035,0.82)
 canvas.add_child(pause_overlay)
 pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var p=panel(pause_overlay,Vector2(-420,-280),Vector2(840,560),Vector2(0.5,0.5))
 label(p,"霧爪",Vector2(36,24),Vector2(768,56),42)
 label(p,"青霧林  /  暫停",Vector2(38,82),Vector2(760,28),18).modulate=Color("bda579")
 label(p,"身法與劍術",Vector2(38,134),Vector2(360,28),22)
 label(p,"W A S D　自由走位\nJ　按住連斬　　K　重劈\nI　旋斬　　L　閃躲\nSpace　跳躍 · 空中再按一次二段跳\n同方向雙按跑步 · WASD 決定面向",Vector2(38,177),Vector2(374,170),18)
 label(p,"法寶與流派",Vector2(440,134),Vector2(360,28),22)
 label(p,"1　衝擊波　橫掃清群、遠距重劈\n2　連鎖雷　末式跳電、重劈落雷\n3　嗜血刃　交叉斬、實傷 6% 回血\n\n每區三戰 · 首戰取得法寶\n戰間 F 提前迎戰，突破後向右",Vector2(440,177),Vector2(360,170),18)
 var row:=HBoxContainer.new()
 var assist:=CheckButton.new()
 assist.text="自動普攻輔助（靠近敵人出劍）"
 assist.button_pressed=game.auto_attack
 assist.toggled.connect(func(enabled:bool):game.auto_attack=enabled)
 place(assist,p,Vector2(38,350),Vector2(520,40))
 assist.mouse_filter=Control.MOUSE_FILTER_STOP
 quality_button=button("畫質：精緻",func():game.set_visual_profile((game.visual_profile+1)%3))
 place(quality_button,p,Vector2(38,398),Vector2(180,44))
 quality_button.mouse_filter=Control.MOUSE_FILTER_STOP
 var quality_help:="精緻：完整光影 · 均衡：減少反射與霧 · 清晰：減少裝飾"
 if RenderingServer.get_current_rendering_method()=="gl_compatibility":
  quality_help="Web：精緻／均衡效果相近，清晰減少裝飾\n不含桌面版的景深、體積霧與即時畫面反射"
 label(p,quality_help,Vector2(234,397),Vector2(570,58),15)
 place(row,p,Vector2(38,468),Vector2(764,58))
 row.add_theme_constant_override("separation",14)
 resume_button=button("繼續探索  ·  Esc",func():game.toggle_pause())
 row.add_child(resume_button)
 resume_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var retry=button("重新挑戰",func():game.retry_run())
 row.add_child(retry)
 retry.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 mute_button=button("聲音：開",func():game.toggle_mute())
 row.add_child(mute_button)
 mute_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 pause_overlay.hide()
 game.result_overlay=ColorRect.new()
 game.result_overlay.color=Color(0.025,0.04,0.05,0.88)
 canvas.add_child(game.result_overlay)
 game.result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var center:=CenterContainer.new()
 game.result_overlay.add_child(center)
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var content:=VBoxContainer.new()
 content.custom_minimum_size=Vector2(560,0)
 content.add_theme_constant_override("separation",20)
 center.add_child(content)
 game.result_title=label(content,"",Vector2.ZERO,Vector2.ZERO,44)
 game.result_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 game.result_detail=label(content,"",Vector2.ZERO,Vector2.ZERO,20)
 game.result_detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 game.retry_button=button("再次入林  ·  Enter / R",func():game.retry_run())
 content.add_child(game.retry_button)
 game.result_overlay.hide()

func refresh():
 var g=game
 combat.visible=not g.ended
 hint.visible=not g.ended
 hp_bar.value=g.hp
 hp_text.text="%d / 100"%ceili(g.hp)
 status.text="霧爪 · 危險" if g.hp<=25 and not g.ended else "霧爪"
 status.modulate=Color("ffb59d") if g.hp<=25 else PAPER
 zone_text.text="青 霧 林" if g.room<3 else "石 門 妖 王"
 route_text.text="%s   %d / 4"%["◆ ".repeat(g.room+1)+"◇ ".repeat(3-g.room),g.room+1]
 boss_health_holder.visible=false
 if g.room==3 and g.enemy_pools.size()>3:
  var enemy:Dictionary=g.enemy_pools[3][0]
  boss_health_holder.visible=enemy in g.enemies
  if boss_health_holder.visible:
   boss_health.value=enemy.hp/enemy.max_hp*100
   route_text.text=("狂怒 · " if g.boss.phase==2 else "石門對決 · ")+g.boss.posture_hint()
 build_text.text=g.BUILD_NAMES[g.build] if g.build>=0 else "清場後取得法寶"
 build_text.modulate=g.COLORS[g.build] if g.build>=0 else PAPER
 for i in range(3):
  relics[i].art.modulate=Color.WHITE if i in g.unlocked else Color(0.28,0.32,0.33,0.45)
  relics[i].key.text=str(i+1) if i in g.unlocked else "未得"
  relics[i].tile.modulate=Color.WHITE if i==g.build else Color(0.65,0.65,0.65)
 var remaining=[g.attack_cd,g.skill_cd,g.spin_cd,g.dash_cd,0.0]
 var durations=[0.52,2.8,3.4,1.1,1.0]
 var active=[g.attack_time>=0 and not g.attack_power,g.attack_time>=0 and g.attack_power,g.spin_time>=0,g.dash_time>0,g.jump_velocity>0]
 for i in range(5):
  slots[i].tile.active=active[i]
  slots[i].tile.update_cooldown(remaining[i],durations[i],0)
  slots[i].number.text="%.1f"%remaining[i] if remaining[i]>0 and i!=0 else ""
  slots[i].tile.dimmed=remaining[i]>0 and i!=0
  if i==4:
   slots[i].number.text="" if g.jumps_used==0 else str(2-g.jumps_used)
   slots[i].tile.dimmed=g.jumps_used>0
 hint.text="敵人 %d　·　%s"%[g.enemies.size(),"靠近自動出劍" if g.auto_attack else "按住 J 連斬"]
 if g.encounter_flow!=null:hint.text=g.encounter_flow.objective()+"　·　敵人 %d"%g.enemies.size()
 if g.enemies.is_empty() and (g.encounter_flow==null or g.encounter_flow.pending<0):
  hint.text=("試煉完成 · 整理戰果" if g.room==3 and g.encounter_cleared[3] else "向右探索 →") if g.drops.is_empty() else ("靠近光柱，收取最後戰利品" if g.room==3 else "靠近光柱，收取法寶")
 mute_button.text="聲音：關" if g.muted else "聲音：開"
 world_text.visible=not g.paused and not g.ended
 if pause_overlay.visible!=g.paused:
  pause_overlay.visible=g.paused
  if g.paused:resume_button.grab_focus()
  else:resume_button.release_focus()

func advance(dt:float):
 for slot in slots:slot.tile.update_cooldown(slot.tile.remaining,slot.tile.duration,dt)
 if game.hp<last_hp:lag_wait=0.22
 if game.hp>last_hp:
  hp_lag.value=game.hp
  hp_bar.modulate=Color("a9edc4")
 last_hp=game.hp
 lag_wait=maxf(0,lag_wait-dt)
 if lag_wait<=0:hp_lag.value=move_toward(hp_lag.value,game.hp,dt*95)
 hp_bar.modulate=hp_bar.modulate.lerp(Color.WHITE,minf(dt*7,1))

func place_combat_text(text_label:Label,center:Vector2)->Vector2:
 var frame:=Engine.get_process_frames()
 if text_layout_frame!=frame:
  text_layout_frame=frame
  text_rects.clear()
 var origin:=center-text_label.size*0.5
 var candidate:=Rect2(origin,text_label.size)
 for attempt in range(16):
  if not text_rects.any(func(other):return other.grow(2).intersects(candidate)) and not text_obstacles.any(func(other):return other.grow(3).intersects(candidate)):break
  var column:int=(attempt+1)%3
  candidate.position=origin+Vector2([0.0,1.0,-1.0][column]*maxf(38,text_label.size.x+4),-ceilf((attempt+1)/3.0)*(text_label.size.y+3))
 text_rects.append(candidate)
 return candidate.position.round()
