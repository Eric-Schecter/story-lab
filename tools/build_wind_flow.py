"""Extract the current wind-and-contract Ink subset into a source-linked graph.

Only knots, choices and direct diverts used by this source are supported.
Conditions/variable updates remain verbatim in node details, not evaluated here.
"""
import hashlib
import json
import re
from pathlib import Path

source = Path('stories/wind-and-contract/ink/wind-and-contract.ink')
lines = source.read_text().splitlines()
headers = [(i, re.fullmatch(r'=== (\w+) ===', line).group(1))
           for i, line in enumerate(lines) if re.fullmatch(r'=== (\w+) ===', line)]
titles = {'harbor': '暮潮港 · 启航前', 'contract': '查看契约', 'crew': '听取大副意见',
          'questions': '继续调查 / 作出决定', 'choose': '决定航向',
          'aftermath': '结算选择后果', 'reveal': '旧账册 · 隐瞒浮现'}
nodes, edges = [], []

def node(id, title, kind, start, end, text):
    nodes.append(dict(chapter='ch1' if id.startswith('ch1_') or id=='END' else 'prologue',id=id, title=title, kind=kind, line=start+1, endLine=end,
                      text='\n'.join(text).strip(), changes=[x.strip()[2:].strip() for x in text if x.strip().startswith('~ ')],
                      conditions=[x.strip() for x in text if x.strip().startswith('{') or re.match(r'^[+*] \{', x.strip())]))

def edge(a, b, label=''):
    edges.append(dict(id=f'{a}--{b}', source=a, target=b, label=label))

for index, (start, name) in enumerate(headers):
    end = headers[index+1][0] if index+1 < len(headers) else len(lines)
    choices = [i for i in range(start+1, end) if re.match(r'^[+*] (?:\{[^}]+\} )?\[', lines[i])]
    first = choices[0] if choices else end
    prefix = lines[start+1:first]
    node(name, titles.get(name, {'ch1_notice':'第一章 · 追索令','ch1_investigate':'码头调查','ch1_ledger':'还款记录','ch1_supplier':'灰礁港盐货订单','ch1_crew':'船员与欠款','ch1_decide':'决定保船办法','ch1_depart':'无旗快船','ch1_close':'第一章结算'}.get(name,name)), 'decision' if choices else 'scene', start, end, lines[start:end])
    if choices:
        for c, begin in enumerate(choices):
            finish = choices[c+1] if c+1 < len(choices) else end
            block = lines[begin:finish]
            label = re.match(r'^[+*] (?:\{[^}]+\} )?\[(.*?)\]', lines[begin]).group(1)
            cid = f'{name}-choice-{c+1}'
            kind = 'outcome' if any(x.strip().startswith('~ ') for x in block) else 'choice'
            node(cid, label, kind, begin, finish, block)
            edge(name, cid)
            targets = [x.strip()[3:] for x in block if x.strip().startswith('-> ')]
            assert len(targets) == 1, (name, block)
            edge(cid, targets[0])
    else:
        targets = [x.strip()[3:] for x in prefix if x.strip().startswith('-> ')]
        assert len(targets) == 1, name
        edge(name, targets[0])
node('END', '第一章结束', 'end', len(lines)-1, len(lines), ['现有试玩包含序章与第一章；第二章尚在规划。'])
assert all(e['target'] in {n['id'] for n in nodes} for e in edges)
model = dict(title='风与契约', subtitle='序章 / 第一章 · 故事流程', routeNote='高亮序章决策及第一章调查入口；后续保船方案需满足各自条件。', legend='带回线的调查可反复查看；第一章选项有金币、信任或证据门槛', source=str(source), sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
             initial={'money':300,'guild_relation':0,'port_relation':0,'decision':'尚未选择','crew_debt':0,'evidence':False,'chapter_one_route':'尚未选择'}, nodes=nodes, edges=edges,
             routes=[dict(id=f'route-{i+1}', title=title, nodes=['harbor','harbor-choice-3','choose',f'choose-choice-{i+1}','aftermath','aftermath-choice-1','reveal','reveal-choice-1','ch1_notice','ch1_investigate'],
                          result=result) for i,(title,result) in enumerate([
                              ('履行契约','1200 金币；商会关系 +1，小港关系 −1。'),
                              ('违约运粮','100 金币；商会关系 −1，小港关系 +1。'),
                              ('借款雇船','900 金币；小港关系 +1；另欠船员 200 金币。')])])
model['chapters']=[{'id':'prologue','title':'序章 · 装满的货舱'},{'id':'ch1','title':'第一章 · 追索令'}]
for i,(title,result) in enumerate([('保证金暂缓','需至少 600 金币；冻结保证金，换七日。'),('小港具保','需小港信任和至少 100 金币；盐货收益尚未结算。'),('公开复核','需核对还款记录；商会关系 −1。')]):
    model['routes'].append(dict(id=f'ch1-route-{i+1}',chapter='ch1',title=title,result=result,nodes=['ch1_notice','ch1_investigate','ch1_investigate-choice-1','ch1_ledger','ch1_investigate','ch1_investigate-choice-4','ch1_decide',f'ch1_decide-choice-{i+2}','ch1_depart','ch1_close','END']))
for route in model['routes'][:3]: route['chapter']='prologue'
# Future chapters are design references, never executable Ink branches.
bible = json.loads(Path('stories/wind-and-contract/design/story-bible.json').read_text())
model['chapters'] = [dict(id=c['id'], title=c['title'] + (' · 规划' if c['state'] != '可试玩' else ''), planned=c['state'] != '可试玩') for c in bible['chapters']]
for c in bible['chapters'][2:]:
    cid = c['id']
    def planned_node(suffix, title, kind, text):
        nid = cid + '-plan-' + suffix
        nodes.append(dict(id=nid, chapter=cid, title=title, kind=kind, planned=True, sourceLabel='剧情规划 · 人物与章节设定草案', text=text, changes=[], conditions=[]))
        return nid
    event = planned_node('event', c['title'], 'scene', c['event'] + '\n\n前因：' + c['carry'])
    decision = planned_node('decision', '玩家的艰难选择', 'decision', c['choice'])
    growth = planned_node('growth', c['stage'], 'outcome', c['growth'] + '\n\n人物关系：' + c['relationship'] + '\n\n台词方向：“' + c['line'] + '”')
    closing = planned_node('next', '本章后果与下一步', 'end', c['next'])
    pairs = [(event,decision),(decision,growth),(growth,closing)]
    if cid != 'finale':
        options = re.split('、|，或', c['choice'].split('。')[0].rstrip('。'))
        pairs = [(event,decision),(growth,closing)]
        for i, option in enumerate(options):
            branch = planned_node('choice-' + str(i), option, 'choice', '选择方向：' + option + '\n\n' + c['growth'] + '\n\n后果将结合前章记录细化，当前不代表已实现的变量结算。')
            pairs.extend([(decision,branch),(branch,growth)])
    if cid == 'finale':
        pairs = [(event,decision)]
        for i, ending in enumerate(bible['endings']):
            end = planned_node('ending-' + str(i), ending['title'], 'outcome', ending['gain'] + '\n\n代价：' + ending['cost'] + '\n\n' + ending['variation'])
            pairs.extend([(decision,end),(end,growth)])
        pairs.append((growth,closing))
    for a,b in pairs:
        edges.append(dict(id=a+'--'+b,source=a,target=b,reference=True,label='规划关系',style={'strokeDasharray':'6 4'}))
model['subtitle'] = '章节故事流程'
model['legend'] += '；虚线为后续剧情规划，尚未开放试玩'
Path('web/flow/story.json').write_text(json.dumps(model,ensure_ascii=False,indent=2)+'\n')
print(f'{len(nodes)} nodes, {len(edges)} edges; source {source}')
