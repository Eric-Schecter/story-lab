"""Run real inklecate preview routes, including hidden-ending lock boundaries."""
import os
import re
import select
import subprocess
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMPILER = '/Applications/Inky.app/Contents/Resources/app.asar.unpacked/main-process/ink/inklecate_mac'


def play(ending, clues, codex):
    p = subprocess.Popen([COMPILER, '-p', str(ROOT / 'stories/fishing/ink/fishing.ink')], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    pending = b''
    transcript = ''
    deadline = time.monotonic() + 15
    saw_final = False
    while time.monotonic() < deadline:
        readable, _, _ = select.select([p.stdout], [], [], .2)
        if not readable:
            continue
        chunk = os.read(p.stdout.fileno(), 65536)
        if not chunk:
            break
        pending += chunk
        if b'?> ' not in pending:
            continue
        block, pending = pending.split(b'?> ', 1)
        text = block.decode()
        transcript += text
        options = [(int(n), label) for n, label in re.findall(r'^(\d+): (.+)$', text, re.M)]
        assert options, text
        labels = [label for _, label in options]
        choose = options[0][0]
        if '点亮探照灯' in labels:
            saw_final = True
            assert any('柔光：' in x for x in labels) == (clues == 5 and codex)
            label = {'light':'点亮探照灯','entrust':'交给老林','gentle':'柔光：'}[ending]
            choose = next(n for n, x in options if x.startswith(label))
        elif '当前线索：' in text:
            have = int(re.search(r'当前线索：(\d)', text)[1])
            if have < clues:
                choose = next(n for n, x in options if x.startswith('拾取：'))
            elif codex and '完整图鉴：未完成' in text:
                choose = next(n for n, x in options if x.startswith('模拟补全'))
            else:
                choose = next(n for n, x in options if x.startswith('带着线索'))
        p.stdin.write(f'{choose}\n'.encode())
        p.stdin.flush()
    else:
        p.kill()
        raise AssertionError('Preview stalled')
    transcript += pending.decode()
    p.wait(timeout=3)
    assert saw_final and '—— 主线完成' in transcript, transcript[-1000:]
    assert not p.stderr.read(), 'Runtime errors'
    print(f'PASS ending={ending}, clues={clues}, codex={codex}')


for case in [('light',1,False), ('entrust',1,False), ('light',5,False), ('light',4,True), ('gentle',5,True)]:
    play(*case)
