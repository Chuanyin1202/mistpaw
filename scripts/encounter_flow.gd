extends Node
## Three authored formations per clearing, using the existing actor pools.
const TITLES=[
 ["林口試劍","林間夾擊","守住林口"],
 ["石橋交鋒","兩岸投石","突破包圍"],
 ["古林伏兵","精英追獵","石門前哨"]]
var waves:Array[int]=[0,0,0,0]
var pending:=-1
var rest:=0.0
var defeated:=0
var damage_taken:=0.0
func cleared_group(zone:int,at:Vector3):
 var g=get_parent()
 if zone==3 or waves[zone]==2:
  g.encounter_cleared[zone]=true
  g.cleared+=1
 if waves[zone]==0:g.spawn_drop(at,mini(zone,2))
 if zone<3 and waves[zone]<2:
  pending=zone
  rest=5.0
  g.toast("暫歇 · 收取法寶、調整站位\nF 提前迎戰",5)
 elif zone==3:
  g.toast("妖王已伏 · 收取最後戰利品",3)
 else:
  g.toast("區域突破 · 向右前進",3)
func advance(dt:float):
 if pending<0:return
 var g=get_parent()
 if g.drops.is_empty():rest=maxf(0,rest-dt)
 if rest>0 or not g.dying.is_empty() or not g.drops.is_empty():return
 var zone:=pending
 pending=-1
 waves[zone]+=1
 spawn_wave(zone)
func spawn_wave(zone:int):
 var g=get_parent()
 var center:float=clampf(g.hero.position.x,zone*14.0,zone*14.0+10)
 var wave:int=waves[zone]
 for i in range(g.enemy_pools[zone].size()):
  var e:Dictionary=g.enemy_pools[zone][i]
  e.hp=e.max_hp
  e.clock=-0.45-i*0.12-(0.45 if e.kind==2 else 0.0)
  e.windup=-1.0
  e.recovery=0.0
  e.stagger=0.0
  e.recoil=0.0
  e.flash=0.0
  e.pounce_time=-1.0
  e.retreat_left=1.2
  e.reaction_offset=Vector2.ZERO
  var side:float=-1 if i%2 else 1
  var x:float=center+side*(4.5+(i%3)*1.2) if wave==1 else center+3.5+(i%4)*1.8
  var z:float=[-3.4,-1.6,0.5][i%3]
  if zone>0:
   if e.kind==2:
    x=center+(6.5 if wave==1 else -5.5)
    z=-3.6+(i%3)*1.8
   elif e.kind==1:
    x=center+(-4.5 if wave==1 else side*5.0)
    z=0.65 if i%2 else -3.5
   elif e.kind==3:
    x=center+(-5.0 if wave==2 else 5.0)
    z=-2.7 if wave==2 else 0.4
  e.node.position=g.constrain_ground(Vector3(x,e.home.y,z))
  e.node.offset=Vector2.ZERO
  e.node.modulate=Color.WHITE
  e.node.texture=e.texture
  e.node.frame=0
  e.node.show()
  e.label.show()
  e.bar.ratio=1.0
  e.bar.trail=1.0
  g.enemies.append(e)
 var tactic:String="兩側來襲 · 留出閃躲路線" if wave==1 else ("投石在後方 · 突破包圍" if zone>0 else "橫掃清群 · K 重劈")
 g.toast(TITLES[zone][wave]+" · 第 %d / 3 戰\n"%(wave+1)+tactic,3)
func objective()->String:
 var g=get_parent()
 if pending>=0:
  if not g.drops.is_empty():return "靠近光柱收取法寶\n收取後準備下一戰 · F 提前迎戰"
  return "準備下一戰　%.0f 秒\nF 提前迎戰"%ceilf(rest)
 if g.room==3:
  if g.encounter_cleared[3]:return "收取最後戰利品 · 完成試煉"
  if g.boss.stunned>0:return "破防暈厥 · K 重劈全力反擊"
  if g.boss.wave_pending():return g.boss.recovery_hint()
  if not g.enemies.is_empty():
   var enemy:Dictionary=g.enemies[0]
   if enemy.recovery>0:return g.boss.recovery_hint()
   if enemy.windup>=0 or g.boss.active>=0:
    return ["爪擊 · 側移或 L 穿過", "衝撞 · 上下側移避開直線", "躍擊 · 離開圓形落點"][g.boss.pattern]
  return "正面架勢減傷 · 繞背或收勢時反擊"
 if g.encounter_cleared[g.room]:return "區域突破 · 向右前進 →"
 var hint: String = TITLES[g.room][waves[g.room]]+"　%d / 3"%(waves[g.room]+1)
 if g.room==0:
  hint += ("\nWASD 靠近出劍" if g.auto_attack else "\nWASD 走位 · 按住 J連斬") if defeated<2 else "\n紅色預告用 L 閃避"
 elif g.room==1:hint += "\nK 重劈 / I 旋斬"
 else:hint += "\nSpace 二段跳 · 避開地面攻擊"
 var nearest:Dictionary=g.nearest_enemy()
 if not nearest.is_empty() and nearest.node.position.x < g.hero.position.x-5:hint += " · 敵人在左 ←"
 return hint
