"""Extract preserved fishing sources into a traceable narrative model and Ink preview."""
import ast
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'stories/fishing'
SRC = BASE / 'source'


def gd_const(filename, name):
    text = (SRC / filename).read_text()
    start = re.search(r'const ' + name + r'\s*:?=\s*', text).end()
    quote = False
    escape = False
    depth = 0
    for end in range(start, len(text)):
        c = text[end]
        if quote:
            if escape:
                escape = False
            elif c == '\\':
                escape = True
            elif c == '"':
                quote = False
        elif c == '"':
            quote = True
        elif c in '[{':
            depth += 1
        elif c in ']}':
            depth -= 1
            if depth == 0:
                value = text[start:end + 1]
                # These preserved constants contain no inline comments.
                value = re.sub(r'\btrue\b', 'True', value)
                value = re.sub(r'\bfalse\b', 'False', value)
                return ast.literal_eval(value)
    raise ValueError(name)


def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


chapters = gd_const('story.gd', 'CHAPTERS')
milestones = gd_const('story.gd', 'MILESTONES')
quests = gd_const('commissions.gd', '_QUESTS')
endings = gd_const('ending_panel.gd', 'ENDINGS')
intro = gd_const('ending_panel.gd', 'INTRO_LINES')
steps = json.loads((SRC / 'chapter_tasks.json').read_text())['steps']
fragments = json.loads((SRC / 'fragments.json').read_text())['fragments']
fish = json.loads((SRC / 'fish.json').read_text())['fish']
main = (SRC / 'main.gd').read_text()
opening = re.findall(r'say\("([^"\n]+)"\)', main[main.index('say("三年前'):])[:3]
reveal = re.findall(r'say\("([^"\n]+)"\)', main[main.index('say("老林：雾鲸'):])[:3]
tutorial = gd_const('objectives.gd', '_TEXTS')

nodes = []


def node(id, title, text, parent='Fishing_Story', kind='flow', **extra):
    nodes.append(dict(id=id, title=title, text=text, parent=parent, kind=kind, **extra))


node('Fishing_Story', '雾海传说｜剧情总览', '阿舟靠钓鱼谋生，修复灯塔与鱼市，进入雾海寻找鲸落之光，最终决定光的归处。\n原作存活/死亡矛盾见审阅节点。', parent='Flow')
for i, ch in enumerate(chapters):
    node(ch['id'], ch['title'], ch['quote'], parent='Fishing_Story')
node('opening', '开场｜三年前的熄灯', '\n'.join(opening), parent='prologue')
previous = 'opening'
edges = []
for id, text in tutorial.items():
    node('tutorial_' + id, '教学｜' + text, '玩法目标：' + text + '\n原始判定：objectives.gd::_check。', parent='prologue')
    edges.append([previous, 'tutorial_' + id, '目标达成'])
    previous = 'tutorial_' + id
for s in steps:
    condition = f"类型={s['type']}；目标={s['target']}"
    node(s['id'], s['text'], s['dialog'] + '\n\n推进条件：' + condition, parent=chapters[s['chapter']]['id'], condition=condition)
    edges.append([previous, s['id'], '条件达成'])
    previous = s['id']
node('confession', '老林自白｜鲸落之光', '\n'.join(reveal), parent='ch4')
for f in fragments:
    node(f['id'], '线索｜' + f['title'], f['text'], parent='ch4', kind='clue')
for id, e in endings.items():
    condition = '碎片当前数量 ≥ 5 且完整鱼类图鉴' if id == 'gentle' else '无需额外收集条件'
    node('ending_' + id, '结局｜' + e['title'], '\n'.join(e['text']) + '\n\n条件：' + condition, parent='finale', condition=condition)
    edges.append(['m_choice', 'ending_' + id, condition])
for q in quests:
    node(q['id'], '支线｜' + q['npc'], q['request'] + '\n奖励：' + q['reward_text'] + '\n解锁：' + q['lock_text'] + '\n支线按阿海→老板娘顺序提供，不阻断主线。', parent='Fishing_Story', kind='sidequest')
node('review', '待确认｜雾鲸的生死', 'main.gd 的老林自白称“雾鲸……是我害死的”；ending_panel.gd 与碎片称它在睡梦中，强光会唤醒。原文均保留。\n另：碎片庇护在300秒后到期并清空当前收集，隐藏结局检查当前数量，而不是历史收集。', kind='review')
characters = [
    dict(id='Azou', title='阿舟｜玩家主角', text='原作姓名来自 dialog_box.gd。靠钓鱼、交易与建设谋生，想把三年前灯塔熄灭的真相捞出来。未补写年龄、性别或身世。'),
    dict(id='LaoLin', title='老林｜守塔人', text='三年前主动熄灯，隐瞒强光与雾鲸的关系。指引主角修复探照灯、打捞鲸落之光，终局提出两种选择。其自白与结局存在生死矛盾，暂保留。'),
    dict(id='Ahai', title='阿海｜老船工', text=quests[0]['request'] + '\n新手引导完成后提供沙丁鱼委托。'),
    dict(id='MarketOwner', title='鱼市老板娘', text=quests[1]['request'] + '\n阿海委托完成且鱼市建成后提供金枪鱼委托。'),
    dict(id='FogWhale', title='雾鲸｜海中的秘密', text='碎片记载：雾是它梦中的呼吸，强光会惊扰它，柔光能够引路。原作未确认老林所说死亡与睡梦的关系。'),
]
model = dict(title='雾海传说', chapters=chapters, nodes=nodes, edges=edges, characters=characters, milestones=milestones, fish_species=len(fish), source_commit='333e97f6ee6605843e7b0d9f73eaac3e825cff5d')
from fishing_side_stories import merge_side_stories
merge_side_stories(model, BASE)
write_json(BASE / 'design/story-model.json', model)
write_json(SRC / 'manifest.json', dict(project='/Users/eric/Documents/repos/ai/fishing', commit=model['source_commit'], files={p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(SRC.iterdir()) if p.name not in ['manifest.json', 'side_stories.json', 'commissions-v2.gd']}))

ink = ['// 从 fishing 原文整理。所有“模拟完成”只用于剧情审阅，不执行钓鱼与建设。',
       'VAR fragments = 0', 'VAR codex_complete = false', 'VAR ahai_done = false', 'VAR market_done = false',
       'VAR preview_reward_coins = 0', 'VAR ending = ""']
ink += ['VAR clue_' + f['id'] + ' = false' for f in fragments]
ink += ['-> opening', '', '=== opening ===', '# source: main.gd::_show_story_intro', '《雾海传说》剧情审阅版',
        '这里保留原游戏任务与对白。按钮模拟目标达成，不代表已在游戏里完成这些动作。']
ink += opening
ink += ['+ [开始序章教学] -> tutorial', '', '=== tutorial ===', '序章 · 雾海']
for text in tutorial.values():
    ink += ['玩法目标：' + text, '+ [模拟完成此目标]', '-']
ink += ['-> t_gear_trial']
for idx, s in enumerate(steps):
    ink += ['', '=== ' + s['id'] + ' ===', '# source: data/chapter_tasks.json#' + s['id']]
    if idx == 0 or steps[idx - 1]['chapter'] != s['chapter']:
        ink += [chapters[s['chapter']]['title'], chapters[s['chapter']]['quote']]
    ink += ['目标：' + s['text'], s['dialog']]
    if s['id'] == 'm_whalefall':
        ink += reveal
    if s['id'] == 'm_sea_clue':
        ink += ['+ [查看漂流瓶线索与图鉴收集] -> investigation']
    elif s['id'] == 'm_choice':
        ink += intro + ['-> final_choice']
    else:
        target = steps[idx + 1]['id']
        if s['id'] == 'm_fishing_trip':
            ink += ['+ {not ahai_done} [先听阿海的可选委托] -> ahai']
        if s['id'] == 'm_market_trade':
            ink += ['+ {ahai_done and not market_done} [先听鱼市老板娘的可选委托] -> market_owner']
        ink += ['+ [模拟达成目标，继续] -> ' + target]

ink += ['', '=== ahai ==='] + quests[0]['unlock_lines'] + [quests[0]['request'],
    '+ [模拟交付3条沙丁鱼，获得80金币]', '~ ahai_done = true', '~ preview_reward_coins += 80', '-> m_fishing_trip',
    '+ [暂不完成委托] -> m_fishing_trip', '', '=== market_owner ===']
ink += quests[1]['unlock_lines'] + [quests[1]['request'],
    '+ [模拟交付1条金枪鱼，获得300金币与5鱼饵]', '~ market_done = true', '~ preview_reward_coins += 300', '-> m_market_trade',
    '+ [暂不完成委托] -> m_market_trade', '', '=== investigation ===',
    '当前线索：{fragments}/5。完整图鉴：{codex_complete:已完成|未完成}。',
    '此处可选读线索；原游戏需要出海拾取。原作集齐后300秒会重置碎片，本审阅版不模拟计时。']
for f in fragments:
    ink += ['+ {not clue_' + f['id'] + '} [拾取：' + f['title'] + '] -> read_' + f['id']]
ink += ['+ {not codex_complete} [模拟补全鱼类图鉴（' + str(len(fish)) + '种）]', '~ codex_complete = true', '-> investigation',
        '+ {fragments >= 1} [带着线索继续打捞主线] -> m_whalefall']
for f in fragments:
    ink += ['', '=== read_' + f['id'] + ' ===', '# source: data/fragments.json#' + f['id'], f['text'],
            '~ clue_' + f['id'] + ' = true', '~ fragments += 1', '+ [继续调查] -> investigation']
ink += ['', '=== final_choice ===', '鲸落之光在你手里。你会怎么做？',
        '+ [点亮探照灯] -> ending_light', '+ [交给老林] -> ending_entrust',
        '+ {fragments >= 5 and codex_complete} [柔光：用知识寻找第三条路] -> ending_gentle',
        '{fragments < 5 or not codex_complete:？？？——似乎还有第三条路……（原作此选项锁定）}']
for id, e in endings.items():
    ink += ['', '=== ending_' + id + ' ===', '# source: scripts/ending_panel.gd#' + id, '~ ending = "' + id + '"', e['title']] + e['text']
    if e.get('reward_coins'):
        ink += ['~ preview_reward_coins += ' + str(e['reward_coins'])]
    ink += ['-> END']
(BASE / 'ink/fishing.ink').write_text('\n'.join(ink) + '\n')
print(f'Generated {len(nodes)} nodes, {len(edges)} edges, {len(characters)} characters, {len(fish)} fish species.')
