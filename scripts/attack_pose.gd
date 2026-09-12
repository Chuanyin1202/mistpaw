extends RefCounted
## Pose timing only. Contact/damage clocks remain owned by game.gd.
static func frame(stage:int,heavy:bool,time:float,contact:float,duration:float)->int:
 var anticipation=[0.22,0.50,0.78]
 var follow_through=[0.24,0.53,0.79]
 if heavy:
  anticipation=[0.28,0.59,0.84]
  follow_through=[0.32,0.60,0.82]
 elif stage==1:
  anticipation=[0.18,0.43,0.68]
  follow_through=[0.16,0.43,0.74]
 elif stage==2:
  anticipation=[0.12,0.32,0.57]
  follow_through=[0.13,0.35,0.65]
 var t:float=time/contact if time<contact else (time-contact)/(duration-contact)
 var result:=0 if time<contact else 4
 for threshold in (anticipation if time<contact else follow_through):
  if t>=threshold:result+=1
 return mini(result,7)
