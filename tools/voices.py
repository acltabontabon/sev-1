#!/usr/bin/env python3
"""Development-only local Kokoro speech. The exported game never runs this tool."""
import argparse
import datetime
import hashlib
import json
import os
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
    filters += ['loudnorm=I=-20:TP=-2:LRA=11']
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
    assert len(ids) == 22 and len(data['profiles']) == 6
    print(f'PASS voice manifest: {len(ids)} lines; {sum(x["status"] != "missing" for x in data["lines"])} assets; remaining entries use subtitles.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    for command in ('setup', 'audition', 'validate'):
        commands.add_parser(command)
    generate_parser = commands.add_parser('generate')
    generate_parser.add_argument('--id', action='append', default=[])
    generate_parser.add_argument('--replace-imported', action='store_true')
    imp = commands.add_parser('import')
    for name in ('id', 'file', 'provider', 'model', 'voice', 'date', 'rights', 'license'):
        imp.add_argument('--' + name, required=True)
    args = parser.parse_args()
    data = json.loads(MANIFEST.read_text())
    WORK.mkdir(parents=True, exist_ok=True)
    if args.command == 'setup': setup(data)
    elif args.command == 'validate': validate(data)
    elif args.command == 'import': import_clip(data, args)
    else: generate(data, AUDITIONS if args.command == 'audition' else args.id, args.command == 'audition', getattr(args, 'replace_imported', False))


if __name__ == '__main__':
    main()
