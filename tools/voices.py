#!/usr/bin/env python3
"""Development-only local Kokoro speech. The exported game never runs this tool."""
import argparse
import datetime
import hashlib
import json
import os
import re
from pathlib import Path
import shutil
import subprocess
import sys
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / 'assets/audio/voices/dialogue.json'
WORK = ROOT / '.tools/voices'
ENV = ROOT / '.tools/voice-env'
PROVENANCE = MANIFEST.with_name('provenance.json')
MODEL_LICENSE = 'https://huggingface.co/hexgrad/Kokoro-82M/blob/f3ff3571791e39611d31c381e3a41a3af07b4987/README.md'
AUDITIONS = ['start', 'eta', 'alert', 'variance_intro', 'opening', 'postmortem']
PROCESSING = 'trim-45db-pad80ms-loudnorm-20lufs-2dbtp-v1'
# The night shift's talk: crew, dialogue trees and blended voice profiles in one manifest.
TALK = ROOT / 'assets/audio/voices/talk.json'
TALK_DIR = ROOT / 'assets/audio/voices/talk'
TALK_PROVENANCE = TALK_DIR / 'provenance.json'


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def save(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + '.tmp')
    temporary.write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n')
    temporary.replace(path)


def run(args):
    subprocess.run([str(x) for x in args], check=True)


def setup(data):
    if not ENV.exists():
        run([sys.executable, '-m', 'venv', ENV])
    python = ENV / 'bin/python'
    run([python, '-m', 'pip', 'install', '-r', ROOT / 'tools/voice_requirements.txt'])
    model_dir = WORK / 'model' / data['model_revision']
    model_dir.mkdir(parents=True, exist_ok=True)
    names = ['config.json', 'kokoro-v1_0.pth', 'README.md'] + [f"voices/{p['voice']}.pt" for p in data['profiles'].values()]
    for name in names:
        target = model_dir / name
        if target.exists():
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        url = f"https://huggingface.co/{data['model']}/resolve/{data['model_revision']}/{name}"
        print('Download', name, flush=True)
        temporary = target.with_suffix(target.suffix + '.part')
        urllib.request.urlretrieve(url, temporary)
        temporary.replace(target)
    expected = json.loads((ROOT / 'tools/voice_model_lock.json').read_text())
    for name in names:
        if digest(model_dir / name) != expected[name]:
            raise SystemExit(f'Model checksum mismatch: {name}; remove the damaged local file and rerun setup.')
    save(model_dir / 'checksums.json', expected)
    print('Setup complete. Generation uses only the downloaded model and local environment.')


def fingerprint(data, line):
    payload = {'text': line.get('pronunciation_text', line['text']), 'profile': data['profiles'][line['voice_profile']],
               'model': data['model_revision'], 'processing': PROCESSING,
               'dependencies': digest(ROOT / 'tools/voice_requirements.txt')}
    return hashlib.sha256(json.dumps(payload, sort_keys=True).encode()).hexdigest()


def process(master, output, profile):
    if not shutil.which('ffmpeg'):
        raise SystemExit('ffmpeg is required for import/encoding; install it then rerun. No manifest changes made.')
    filters = ['silenceremove=start_periods=1:start_threshold=-45dB', 'areverse',
               'silenceremove=start_periods=1:start_threshold=-45dB', 'areverse', 'adelay=80', 'apad=pad_dur=0.08']
    if profile['processing'] == 'intercom':
        filters += ['highpass=f=180', 'lowpass=f=6500']
    elif profile['processing'] == 'double':
        filters += ['aecho=0.9:0.9:38:0.10']
    if profile.get('pitch'):
        # Shift pitch by semitones and keep the timing: a blended voice becomes a person.
        ratio = 2 ** (profile['pitch'] / 12)
        filters += [f'asetrate={round(24000 * ratio)}', 'aresample=24000', f'atempo={1 / ratio:.4f}']
    if profile['processing'] == 'monster':
        # A monster losing it, but every word readable: a slight warble, a growl a fifth
        # below mixed well under the line, gentle saturation and a short room.
        filters += ['highpass=f=80', 'vibrato=f=6:d=0.1',
                    'asplit=2[dry][low];[low]asetrate=16800,aresample=24000,atempo=1.4286,volume=0.45[growl];'
                    '[dry][growl]amix=inputs=2:weights=1 0.5:normalize=0',
                    'equalizer=f=2600:t=q:w=1.2:g=3', 'acompressor=threshold=-22dB:ratio=4:attack=4:release=90:makeup=4',
                    'asoftclip=type=atan', 'aecho=0.85:0.3:35:0.18']
    if profile['processing'] == 'hype':
        # Anime move call: presence, hard compression, a doubled voice, arena echo, soft
        # saturation; mastered louder than dialogue so it cuts through a fight.
        filters += ['highpass=f=140', 'equalizer=f=2800:t=q:w=1.2:g=6', 'aexciter=amount=2:drive=6',
                    'acompressor=threshold=-24dB:ratio=9:attack=2:release=90:makeup=9',
                    'chorus=0.7:0.9:22|36:0.35|0.3:0.3|0.45:1.8|1.2', 'aecho=0.85:0.55:70|150:0.3|0.16',
                    'asoftclip=type=tanh']
    if profile['processing'] == 'rage':
        # Losing it completely: the line driven into distortion, a growl an octave down
        # mixed in hard, a throat-shredding presence peak, crushed compression and a vault
        # of echo. Still every word readable.
        filters += ['highpass=f=90',
                    'asplit=2[dry][low];[low]asetrate=12000,aresample=24000,atempo=2.0,volume=0.7[growl];'
                    '[dry][growl]amix=inputs=2:weights=1 0.8:normalize=0',
                    'aexciter=amount=4:drive=9', 'equalizer=f=1800:t=q:w=1.0:g=7', 'equalizer=f=120:t=q:w=1.0:g=4',
                    'acompressor=threshold=-28dB:ratio=14:attack=1:release=80:makeup=12',
                    'asoftclip=type=hard:threshold=0.6', 'aecho=0.85:0.6:60|130|240:0.35|0.22|0.12',
                    'asoftclip=type=tanh']
    # Hold a wordless vocal effort through a cinematic charge without lowering its
    # pitch. Existing dialogue profiles have no stretch and retain their processing.
    if profile.get('stretch', 1.0) != 1.0:
        tempo = 1.0 / float(profile['stretch'])
        while tempo < 0.5:
            filters += ['atempo=0.5']
            tempo *= 2.0
        filters += [f'atempo={tempo:.6f}']
    loudness = profile.get('loudness', -20)
    filters += ['loudnorm=I=-20:TP=-2:LRA=11' if loudness == -20 else f'loudnorm=I={loudness}:TP=-1:LRA=7']
    output.parent.mkdir(parents=True, exist_ok=True)
    run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', master, '-af', ','.join(filters),
         '-ac', '1', '-ar', '24000', '-c:a', 'pcm_s16le', output.with_suffix('.mix.wav')])
    import soundfile as sf
    import numpy as np
    mixed = output.with_suffix('.mix.wav')
    audio, rate = sf.read(mixed)
    candidate = output.with_suffix('.candidate.ogg')
    sf.write(candidate, audio, rate, format='OGG', subtype='VORBIS')
    mixed.unlink()
    audio, rate = sf.read(candidate)
    if audio.ndim != 1 or not len(audio) or not np.isfinite(audio).all() or np.max(np.abs(audio)) >= 1 or np.max(np.abs(audio)) < .001:
        raise SystemExit(f'Invalid, silent, or clipping output: {output}')
    candidate.replace(output)
    return len(audio) / rate, float(np.max(np.abs(audio)))


def generate(data, ids, audition=False, replace_imported=False):
    unknown = set(ids) - {line['id'] for line in data['lines']}
    if unknown:
        raise SystemExit(f'Unknown dialogue IDs: {sorted(unknown)}')
    import espeakng_loader
    os.environ['PHONEMIZER_ESPEAK_LIBRARY'] = espeakng_loader.get_library_path()
    os.environ['ESPEAK_DATA_PATH'] = espeakng_loader.get_data_path()
    os.environ['HF_HUB_OFFLINE'] = '1'
    import torch
    import soundfile as sf
    import numpy as np
    from kokoro import KModel, KPipeline
    model_dir = WORK / 'model' / data['model_revision']
    if not (model_dir / 'checksums.json').exists():
        raise SystemExit('Run setup first; generation never downloads model assets.')
    for name, expected in json.loads((ROOT / 'tools/voice_model_lock.json').read_text()).items():
        if digest(model_dir / name) != expected:
            raise SystemExit(f'Model checksum mismatch: {name}')
    torch.set_num_threads(4)
    torch.manual_seed(11)
    model = KModel(repo_id=data['model'], config=str(model_dir/'config.json'), model=str(model_dir/'kokoro-v1_0.pth')).eval()
    pipelines = {lang: KPipeline(lang_code=lang, repo_id=data['model'], model=model) for lang in ['a', 'b']}
    provenance = json.loads(PROVENANCE.read_text()) if PROVENANCE.exists() else {}
    for line in data['lines']:
        if ids and line['id'] not in ids:
            continue
        if line['status'] == 'imported' and not audition and not replace_imported:
            print('Preserving imported replacement:', line['id'], flush=True)
            continue
        key = fingerprint(data, line)
        profile = data['profiles'][line['voice_profile']]
        master = WORK / 'takes' / f"{line['id']}-{key}.wav"
        master.parent.mkdir(parents=True, exist_ok=True)
        if not master.exists():
            print('Generate', line['id'], flush=True)
            voice = torch.load(model_dir / 'voices' / f"{profile['voice']}.pt", weights_only=True, map_location='cpu')
            chunks = [r.audio.numpy() for r in pipelines[profile['language']](line.get('pronunciation_text', line['text']), voice=voice, speed=profile['speed'])]
            sf.write(master, np.concatenate(chunks), 24000, subtype='PCM_16')
        output = WORK / 'auditions' / f"{line['voice_profile']}.ogg" if audition else ROOT / line['audio'].removeprefix('res://')
        prior = provenance.get(line['id'], {})
        if not audition and prior.get('fingerprint') == key and output.exists() and digest(output) == prior.get('sha256'):
            print('Cached', line['id'], flush=True)
            continue
        duration, peak = process(master, output, profile)
        if line.get('beat_budget', 100) < duration:
            print(f"TIMING REVIEW: {line['id']} lasts {duration:.2f}s; budget {line['beat_budget']:.2f}s", flush=True)
        if not audition:
            line['status'] = 'generated'
            provenance[line['id']] = dict(provider='local Kokoro', model=data['model'], model_revision=data['model_revision'],
                voice=profile['voice'], generation_date=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                usage_rights='Apache-2.0 model; stock voice; authored game script. See model license and docs/voices.md.',
                license_source=MODEL_LICENSE, processing=PROCESSING + '/' + profile['processing'],
                fingerprint=key, sha256=digest(output), master_sha256=digest(master), duration=duration, peak=peak,
                review_status='candidate; human listening acceptance pending')
            save(PROVENANCE, provenance)
            save(MANIFEST, data)
    print('Auditions ready in .tools/voices/auditions' if audition else 'Candidate assets recorded. Run validate and Godot import next.')


def import_clip(data, args):
    line = next((x for x in data['lines'] if x['id'] == args.id), None)
    if line is None:
        raise SystemExit('Unknown dialogue ID')
    source = Path(args.file).resolve()
    master = WORK / 'takes' / f"{args.id}-import-{digest(source)}{source.suffix}"
    master.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, master)
    output = ROOT / line['audio'].removeprefix('res://')
    duration, peak = process(master, output, data['profiles'][line['voice_profile']])
    provenance = json.loads(PROVENANCE.read_text()) if PROVENANCE.exists() else {}
    provenance[line['id']] = dict(provider=args.provider, model=args.model, voice=args.voice,
        generation_date=args.date, text=line['text'], imported_at=datetime.datetime.now(datetime.timezone.utc).isoformat(), usage_rights=args.rights,
        license_source=args.license, sha256=digest(output), master_sha256=digest(master), duration=duration, peak=peak,
        processing=PROCESSING, review_status='imported candidate; human listening acceptance pending')
    line['status'] = 'imported'
    save(PROVENANCE, provenance)
    save(MANIFEST, data)


def validate(data):
    provenance = json.loads(PROVENANCE.read_text()) if PROVENANCE.exists() else {}
    ids = set()
    for line in data['lines']:
        assert line['id'] not in ids, 'Duplicate ID'
        ids.add(line['id'])
        assert line['subtitle'] == line['text'], f"Subtitle mismatch: {line['id']}"
        assert line['voice_profile'] in data['profiles']
        assert line['priority'] in range(4) and line['fallback_duration'] > 0
        assert line['audio'] == f"res://assets/audio/voices/{line['id']}.ogg"
        assert line['trigger'] and line['direction'] and line['character']
        assert line['status'] in ('missing', 'generated', 'imported')
        path = ROOT / line['audio'].removeprefix('res://')
        if line['status'] != 'missing':
            assert path.is_file(), f'Missing declared asset: {path}'
            entry = provenance[line['id']]
            if line['status'] == 'generated':
                assert entry['fingerprint'] == fingerprint(data, line), f'Stale generated speech: {path}'
            else:
                assert entry['text'] == line['text'], f'Stale imported speech: {path}'
            assert digest(path) == entry['sha256'], f'Asset checksum mismatch: {path}'
            for field in ('provider', 'model', 'voice', 'generation_date', 'usage_rights', 'license_source', 'review_status'):
                assert entry[field], f'Missing provenance: {field}'
            assert entry['duration'] > 0 and 0 < entry['peak'] < 1
        else:
            assert not path.exists(), f'Untracked voice provenance: {path}'
    assert len(ids) == 96 and len(data["profiles"]) == 8
    print(f'PASS voice manifest: {len(ids)} lines; {sum(x["status"] != "missing" for x in data["lines"])} assets; remaining entries use subtitles.')


def reply_id(text):
    """Same rule as dialogues.gd reply_id(): the engineer's reply clip, shared by identical replies."""
    return 'you_' + re.sub(r'[^a-z0-9]+', '_', text.lower()).strip('_')[:40]


def voiced_reply(text):
    return not text.startswith('(') and any(c.isalnum() for c in text)


def spoken(talk, text):
    """Subtitles keep the written form; speech gets acronyms and numbers spelled for the voice."""
    for written in sorted(talk.get('spoken', {}), key=len, reverse=True):
        text = re.sub(r'(?<![\w])' + re.escape(written) + r'(?![\w])', talk['spoken'][written], text)
    return re.sub(r'\.\.(?!\.)', '.', text)


def talk_lines(talk):
    """Every voiced talk line, derived from the manifest so text and audio never drift."""
    lines = []
    replies = {}
    host_replies = [['Are you okay?'], ['Have you tried turning yourself off and on again?'], ['…I\'ll just go.'], ['(Back away slowly.)']]
    for tree in list(talk['trees'].values()) + [{'nodes': {'host': {'replies': host_replies}}}]:
        for entry in tree['nodes'].values():
            for reply in entry['replies']:
                if voiced_reply(reply[0]):
                    replies[reply_id(reply[0])] = reply[0]
    for key, text in sorted(replies.items()):
        lines.append({'id': key, 'text': text, 'voice_profile': 'you'})
    for name, tree in talk['trees'].items():
        for node, entry in tree['nodes'].items():
            lines.append({'id': f'talk_{name.lower()}_{node}', 'text': entry['text'], 'voice_profile': tree['profile']})
            for index, text in enumerate(entry.get('text_variants', []), start=1):
                lines.append({'id': f'talk_{name.lower()}_{node}_variant_{index}', 'text': text, 'voice_profile': tree['profile']})
    for kind, people in talk['crew'].items():
        for person in people:
            key = person['name'].lower()
            for node, text, profile in [('a', person['line'], key), ('wrong', talk['host_replies'].get(kind, 'Fine.'), key + '_turning'),
                                        ('snap', talk['host_snap'].get(kind, 'Off. And on. Sure.'), key + '_turning'),
                                        ('hover', talk['host_hover'], key), ('hr', talk['host_hr'], key),
                                        ('soon', talk['host_soon'], key + '_turning')]:
                lines.append({'id': f'host_{key}_{node}', 'text': person.get(node, text), 'voice_profile': profile})
    # The pantry birthday: the scene before the cake ambush, and the guests telling HR.
    party = talk.get('party', {})
    for line in party.get('scene', []):
        profile = 'you' if line['who'] == 'you' else line.get('profile', party['cast'][line['who']]['profile'])
        lines.append({'id': line['id'], 'text': line['text'], 'voice_profile': profile})
    for key, person in party.get('cast', {}).items():
        lines.append({'id': f'host_{key}_hr', 'text': talk['host_hr'], 'voice_profile': person['profile']})
    # The night shift charging into the boss fight, and what they scream on the way out.
    for name, moments in talk.get('cavalry', {}).items():
        for moment, text in moments.items():
            for index, said in (enumerate(text) if isinstance(text, list) else [(None, text)]):
                suffix = moment if index is None else f'{moment}_{index}'
                lines.append({'id': f'cavalry_{name.lower()}_{suffix}', 'text': said, 'voice_profile': talk['trees'][name]['profile']})
    # Monsters muttering and screaming about their workload.
    for kind, moments in talk.get('barks', {}).items():
        for moment, texts in moments.items():
            for index, text in enumerate(texts):
                lines.append({'id': f'bark_{kind}_{moment}_{index}', 'text': text, 'voice_profile': f'monster_{kind}'})
    # Move callouts, shouted anime style by the engineer.
    for key, call in talk.get('callouts', {}).items():
        lines.append({'id': f'call_{key}', 'text': call['text'], 'voice_profile': call.get('profile', 'shout'), 'pronunciation_text': call['say']})
    for line in lines:
        if line['id'] in talk.get('pronunciation', {}):
            line['pronunciation_text'] = talk['pronunciation'][line['id']]
        elif 'pronunciation_text' in line:
            pass
        elif spoken(talk, line['text']) != line['text']:
            line['pronunciation_text'] = spoken(talk, line['text'])
        line['audio'] = TALK_DIR / f"{line['id']}.ogg"
    return lines


def talk_data(data, talk):
    return {'model': data['model'], 'model_revision': data['model_revision'], 'profiles': talk['profiles']}


def talk_generate(data, talk, ids):
    """Voice the night shift locally: blends of the installed stock voices, no downloads."""
    merged = talk_data(data, talk)
    lock = json.loads((ROOT / 'tools/voice_model_lock.json').read_text())
    for name, profile in talk['profiles'].items():
        for voice in profile['blend']:
            if f'voices/{voice}.pt' not in lock:
                raise SystemExit(f'Profile {name} blends {voice}, which is not an installed, locked voice.')
    import espeakng_loader
    os.environ['PHONEMIZER_ESPEAK_LIBRARY'] = espeakng_loader.get_library_path()
    os.environ['ESPEAK_DATA_PATH'] = espeakng_loader.get_data_path()
    os.environ['HF_HUB_OFFLINE'] = '1'
    import torch
    import soundfile as sf
    import numpy as np
    from kokoro import KModel, KPipeline
    model_dir = WORK / 'model' / data['model_revision']
    for name, expected in lock.items():
        if digest(model_dir / name) != expected:
            raise SystemExit(f'Model checksum mismatch: {name}')
    torch.set_num_threads(4)
    torch.manual_seed(11)
    model = KModel(repo_id=data['model'], config=str(model_dir/'config.json'), model=str(model_dir/'kokoro-v1_0.pth')).eval()
    pipelines = {lang: KPipeline(lang_code=lang, repo_id=data['model'], model=model) for lang in ['a', 'b']}
    provenance = json.loads(TALK_PROVENANCE.read_text()) if TALK_PROVENANCE.exists() else {}
    for line in talk_lines(talk):
        if ids and line['id'] not in ids:
            continue
        key = fingerprint(merged, line)
        profile = talk['profiles'][line['voice_profile']]
        output = line['audio']
        prior = provenance.get(line['id'], {})
        if prior.get('fingerprint') == key and output.exists() and digest(output) == prior.get('sha256'):
            print('Cached', line['id'], flush=True)
            continue
        master = WORK / 'takes' / f"{line['id']}-{key}.wav"
        master.parent.mkdir(parents=True, exist_ok=True)
        if not master.exists():
            print('Generate', line['id'], flush=True)
            voice = sum(weight * torch.load(model_dir / 'voices' / f'{name}.pt', weights_only=True, map_location='cpu')
                        for name, weight in profile['blend'].items())
            chunks = [r.audio.numpy() for r in pipelines[profile['language']](line.get('pronunciation_text', line['text']), voice=voice, speed=profile['speed'])]
            sf.write(master, np.concatenate(chunks), 24000, subtype='PCM_16')
        duration, peak = process(master, output, profile)
        provenance[line['id']] = dict(provider='local Kokoro', model=data['model'], model_revision=data['model_revision'],
            voice='blend ' + ' + '.join(f'{name} {weight}' for name, weight in profile['blend'].items()),
            generation_date=datetime.datetime.now(datetime.timezone.utc).isoformat(),
            usage_rights='Apache-2.0 model; blended stock voices; authored game script. See model license and docs/voices.md.',
            license_source=MODEL_LICENSE, processing=PROCESSING + '/' + profile['processing'] + f"/pitch{profile.get('pitch', 0)}",
            fingerprint=key, sha256=digest(output), master_sha256=digest(master), duration=duration, peak=peak,
            review_status='candidate; human listening acceptance pending')
        save(TALK_PROVENANCE, provenance)
    print('Talk lines recorded. Run validate and Godot import next.')


def talk_validate(data, talk):
    merged = talk_data(data, talk)
    provenance = json.loads(TALK_PROVENANCE.read_text()) if TALK_PROVENANCE.exists() else {}
    lines = talk_lines(talk)
    ids = {line['id'] for line in lines}
    assert len(ids) == len(lines), 'Duplicate talk line ID'
    for line in lines:
        path = line['audio']
        assert line['voice_profile'] in talk['profiles'], f"Unknown talk voice: {line['voice_profile']}"
        assert path.is_file(), f'Missing talk line: {path}'
        entry = provenance[line['id']]
        assert entry['fingerprint'] == fingerprint(merged, line), f'Stale talk line: {path}'
        assert digest(path) == entry['sha256'], f'Talk checksum mismatch: {path}'
        assert entry['duration'] > 0 and 0 < entry['peak'] < 1
    for path in TALK_DIR.glob('*.ogg'):
        assert path.stem in ids, f'Untracked talk audio: {path}'
    print(f'PASS talk voices: {len(ids)} lines voiced across {len(talk["profiles"])} profiles.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    for command in ('setup', 'audition', 'validate', 'talk-validate'):
        commands.add_parser(command)
    generate_parser = commands.add_parser('generate')
    generate_parser.add_argument('--id', action='append', default=[])
    generate_parser.add_argument('--replace-imported', action='store_true')
    talk_parser = commands.add_parser('talk')
    talk_parser.add_argument('--id', action='append', default=[])
    imp = commands.add_parser('import')
    for name in ('id', 'file', 'provider', 'model', 'voice', 'date', 'rights', 'license'):
        imp.add_argument('--' + name, required=True)
    args = parser.parse_args()
    data = json.loads(MANIFEST.read_text())
    WORK.mkdir(parents=True, exist_ok=True)
    if args.command == 'setup': setup(data)
    elif args.command == 'validate': validate(data)
    elif args.command == 'talk': talk_generate(data, json.loads(TALK.read_text()), args.id)
    elif args.command == 'talk-validate': talk_validate(data, json.loads(TALK.read_text()))
    elif args.command == 'import': import_clip(data, args)
    else: generate(data, AUDITIONS if args.command == 'audition' else args.id, args.command == 'audition', getattr(args, 'replace_imported', False))


if __name__ == '__main__':
    main()
