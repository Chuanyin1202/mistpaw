"""Reuse the existing ElevenLabs transport; keep credentials outside the repo."""
import importlib.util
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
helper = ROOT.parent / 'onepaw/tools/audio/generate.py'
spec = importlib.util.spec_from_file_location('onepaw_audio', helper)
audio = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audio)
OUT = ROOT / 'assets/source/combat-audio'
OUT.mkdir(exist_ok=True)
SOUNDS = {
    'boss-fracture': (1.4, 'A massive heavy beast slamming paws onto a weathered stone bridge. Immediate deep dry physical impact and loud brittle stone slab cracking at the very start, followed by a short cascade of uneven gravel and falling stone chips settling over one second. Weighty earthy crunch, organic rubble, detailed rocky debris. No metallic clang, no sword swoosh, no magic sparkle, no voice, no music, no distorted sub bass or explosion.'),
    'boss-rage': (1.0, 'One short fierce forest beast battle roar, low rat-like growl rising into a raspy challenging snarl then a breath, living powerful creature announcing a second phase, no death squeal, clean dry game sound, no human voice no music no reverb tail'),
    'boss-charge': (0.7, 'A single fast heavy beast charge burst, compressed rushing air and two tight heavy paw impacts with faint cloth cape whip, immediate acceleration, clean compact action game sound, no music no voice no distorted bass'),
    'boss-slam': (0.8, 'Single heavy creature landing on ancient stone, sharp gritty stone crack with a compact low body thud and small gravel scattering decay, immediate impact followed by silence, clear clean game sound, no explosion no music no voice no long cinematic rumble'),
    'blade-contact': (0.5, 'Single extremely short dry sword contact, sharp steel tick layered with a tight woody body impact, immediate attack at the beginning, tiny air swish, clean transient then silence, designed for rapid repeated action RPG hits, no voice no music no long ring no distortion'),
    'blade-weight': (0.7, 'One powerful downward sword impact, immediate crisp metallic crack with compact low wood thud, 200 millisecond impact followed by a short soft decay, strong but not boomy, clean action RPG heavy hit, no voice no music no cinematic long tail'),
    'stone-contact': (0.5, 'One small rough stone striking armor with a dry crunchy crack and two tiny falling gravel ticks, instantaneous short game impact, no voice no music no room echo'),
    'wave-air': (0.5, 'One short elegant magical sword air wave, fast wide airy swoosh with a bright fine crystalline edge, natural filtered wind rather than a laser, immediate onset and fast decay, no impact boom no voice no music'),
    'chain-snap': (0.5, 'One tight electric arc jumping between metal points, crisp brief crack snap with tiny fizz decay, clean restrained magical lightning sound for frequent game combat, no explosion no voice no music'),
    'vital-arrival': (0.5, 'A small warm magical energy wisp returning to the player, soft inward breath with a delicate low glass chime, short smooth pleasing arrival, no shrill sine beep no voice no music'),
}
MUSIC = 'Instrumental fantasy action game music for a swift sword-wielding cat adventuring across a misty ancient Chinese forest bridge. Nimble pipa ostinato, guqin accents, agile bowed strings, airy dizi melody, restrained low hand drums, around 132 BPM. A lyrical memorable heroic motif and steady forward motion with breathing room for sword impacts. Start with the rhythmic motif immediately, develop lightly, no huge trailer braams, no vocals or choir, no rock guitar, no silence break. A cohesive 60 second exploration-battle cue, lively and mysterious rather than meditative. Gentle final resolution.'
jobs = [('music', {'prompt': MUSIC, 'music_length_ms': 60000, 'force_instrumental': True, 'model_id': 'music_v1'}, 'forest-battle', 60)] if 'music' in sys.argv else [('sound-generation', {'text': p, 'duration_seconds': d, 'prompt_influence': 0.65}, name, d) for name, (d, p) in SOUNDS.items()]
if 'boss-music' in sys.argv:
    prompt = 'Instrumental high speed action RPG boss duel against an ancient stone gate beast king in a misty Chinese forest. Immediate urgent low war drums and driving sixteenth-note bowed strings, fierce pipa rhythmic attacks, dark brass and restrained gong accents, minor pentatonic heroic motif, 152 BPM. Clear accelerating battle pressure distinct from lyrical exploration, a dramatic middle rise then return to the driving motif. Keep room for sword impacts, tight controlled bass, no vocals no choir no trailer braams, no long ambient intro, no silence, no final cadence, continuous action loop energy. 60 seconds.'
    jobs = [('music', {'prompt': prompt, 'music_length_ms': 60000, 'force_instrumental': True, 'model_id': 'music_v1'}, 'boss-battle', 60)]
for endpoint, payload, name, duration in jobs:
    dest = OUT / (name+'.mp3')
    (OUT/(name+'-request.json')).write_text(json.dumps(payload, ensure_ascii=False, indent=2)+'\n')
    if dest.exists() and dest.stat().st_size > 2000:
        print('existing', name, flush=True)
        continue
    if not audio.post('https://api.elevenlabs.io/v1/'+endpoint, payload, dest):
        raise SystemExit(1)
    print(name, audio.verify(dest, duration), flush=True)
