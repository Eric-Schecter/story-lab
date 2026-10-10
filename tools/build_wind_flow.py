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
    nodes.append(dict(id=id, title=title, kind=kind, line=start+1, endLine=end,
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
Path('web/flow/story.json').write_text(json.dumps(model,ensure_ascii=False,indent=2)+'\n')
print(f'{len(nodes)} nodes, {len(edges)} edges; source {source}')
