"""Short bounded interface/guard cues; deterministic PCM, no API or secrets."""
from pathlib import Path
import math,random,struct,wave
rate=44100
for name,duration in [('cooldown-tick',.095),('guard-clink',.18)]:
 rng=random.Random(903);data=[]
 for i in range(int(rate*duration)):
  t=i/rate
  env=min(1,t/.005)*math.exp(-t*(42 if name=='cooldown-tick' else 25))*min(1,(duration-t)/.015)
  if name=='cooldown-tick':v=.12*(math.sin(2*math.pi*660*t)+.3*math.sin(2*math.pi*440*t))
  else:v=.13*(math.sin(2*math.pi*1370*t)+.35*math.sin(2*math.pi*2193*t)+.22*rng.uniform(-1,1))
  data.append(v*env)
 with wave.open(str(Path(__file__).resolve().parents[1]/'audio'/(name+'.wav')),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate)
  f.writeframes(b''.join(struct.pack('<h',round(x*32767)) for x in data))
 print(name,'peak',max(abs(x) for x in data))
