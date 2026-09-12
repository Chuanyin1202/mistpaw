"""Deterministic postprocessing; no API calls or credentials. Requires numpy/ffmpeg."""
import json
import pathlib
import subprocess
import sys
import wave
import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'assets/source/combat-audio'
DEST = ROOT / 'assets/audio'
DURATIONS = {'boss-fracture': 1.15, 'boss-rage': .8, 'boss-charge': .40, 'boss-slam': .50,
             'blade-contact': .24, 'blade-weight': .34, 'stone-contact': .23,
             'wave-air': .26, 'chain-snap': .19, 'vital-arrival': .30}
report = json.loads((SOURCE/'processing.json').read_text()) if (SOURCE/'processing.json').exists() else {}
for name, duration in DURATIONS.items():
    if len(sys.argv)>1 and name not in sys.argv[1:]:
        continue
    cutoff = {'blade-contact': 6500, 'blade-weight': 4500, 'chain-snap': 8000}.get(name)
    filters = ['-af', f'lowpass=f={cutoff}:p=2'] if cutoff else []
    raw = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(SOURCE/(name+'.mp3'))] + filters + [
                                   '-f', 'f32le', '-ac', '1', '-ar', '44100', '-'])
    samples = np.frombuffer(raw, dtype='<f4').copy()
    peak = float(np.max(np.abs(samples)))
    active = np.flatnonzero(np.abs(samples) > max(.004, peak*.012))
    start = max(0, int(active[0])-176) if len(active) else 0
    samples = samples[start:start+round(duration*44100)]
    samples *= .5/max(float(np.max(np.abs(samples))), 1e-8)
    fade_in, fade_out = round(.003*44100), round(.020*44100)
    samples[:fade_in] *= np.linspace(0, 1, fade_in)
    samples[-fade_out:] *= np.linspace(1, 0, fade_out)
    with wave.open(str(DEST/(name+'.wav')), 'wb') as out:
        out.setparams((1, 2, 44100, len(samples), 'NONE', 'not compressed'))
        out.writeframes((samples*32767).astype('<i2').tobytes())
    report[name] = {'source_peak': peak, 'lowpass_hz': cutoff, 'trim_lead_seconds': start/44100,
                    'duration_seconds': duration, 'peak': float(np.max(np.abs(samples)))}
(SOURCE/'processing.json').write_text(json.dumps(report, indent=2)+'\n')
if len(sys.argv)==1 or 'forest-battle' in sys.argv[1:]:
    subprocess.run(['ffmpeg', '-y', '-v', 'error', '-i', str(SOURCE/'forest-battle.mp3'),
                    '-af', 'loudnorm=I=-20:TP=-3:LRA=10,afade=t=in:d=.1,afade=t=out:st=59:d=1',
                    '-c:a', 'libvorbis', '-q:a', '6', str(DEST/'forest-battle.ogg')], check=True)

if 'boss-battle' in sys.argv:
    graph = '[0:a]asplit=3[a][b][c];[a]atrim=1:59,asetpts=PTS-STARTPTS[mid];[b]atrim=59:60,asetpts=PTS-STARTPTS[tail];[c]atrim=0:1,asetpts=PTS-STARTPTS[head];[tail][head]acrossfade=d=1:c1=tri:c2=tri[join];[mid][join]concat=n=2:v=0:a=1,loudnorm=I=-20:TP=-3:LRA=10[out]'
    subprocess.run(['ffmpeg', '-y', '-v', 'error', '-i', str(SOURCE/'boss-battle.mp3'),
                    '-filter_complex', graph, '-map', '[out]', '-c:a', 'libvorbis', '-q:a', '6', str(DEST/'boss-battle.ogg')], check=True)
