"""Deterministic short synthesized magical accents; soft onset, bounded PCM."""
import math, random, struct, wave
from pathlib import Path
rate=44100
root=Path(__file__).resolve().parents[1]/'audio'
for kind,name,duration in [(0,'wave-swish',.18),(1,'lightning-crack',.13),(2,'vital-return',.23)]:
 rng=random.Random(410+kind); samples=[]; phase=0.; smooth=0.
 for i in range(int(rate*duration)):
  t=i/rate; u=t/duration
  env=min(1,t/.012)*max(0,1-u)**2
  noise=rng.uniform(-1,1); smooth=.72*smooth+.28*noise
  freq=(680-440*u) if kind==0 else ((1400-1000*u) if kind==1 else (520+360*u))
  phase+=2*math.pi*freq/rate
  tone=math.sin(phase)
  value=(smooth*.75+tone*.25) if kind==0 else ((noise*.45+tone*.4+math.sin(phase*1.49)*.15) if kind==1 else (tone*.7+math.sin(phase*1.5)*.3))
  samples.append(value*env*.22)
 with wave.open(str(root/(name+'.wav')),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate)
  f.writeframes(b''.join(struct.pack('<h',round(v*32767)) for v in samples))
 print(name,'peak',max(abs(v) for v in samples))
