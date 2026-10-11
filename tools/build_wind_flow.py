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
    nodes.append(dict(chapter=next((c for c in ['ch1','ch2','ch3','ch4','ch5','finale'] if id.startswith(c+'_')), 'finale' if id.startswith('ending_') or id in ['story_end','END'] else 'prologue'),id=id, title=title, kind=kind, line=start+1, endLine=end,
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
node('END', '第一部结束', 'end', len(lines)-1, len(lines), ['七篇章试玩结束，未清责任延续至下一季。'])
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
    model['routes'].append(dict(id=f'ch1-route-{i+1}',chapter='ch1',title=title,result=result,nodes=['ch1_notice','ch1_investigate','ch1_investigate-choice-1','ch1_ledger','ch1_investigate','ch1_investigate-choice-4','ch1_decide',f'ch1_decide-choice-{i+2}','ch1_depart','ch1_close']))
for route in model['routes'][:3]: route['chapter']='prologue'
bible = json.loads(Path('stories/wind-and-contract/design/story-bible.json').read_text())
model['chapters'] = [dict(id=c['id'],title=c['title'],planned=False) for c in bible['chapters']]
titles.update({})
chapter_titles = {c['id']:c['title'] for c in bible['chapters']}
labels = {'ch2_arrival':'第二章 · 灰礁港抵达','ch2_market':'没有标价的航线 · 选择交易','ch2_receipt':'原始收据与父亲附件','ch3_return':'第三章 · 核定旧债','ch3_account':'决定如何公开旧账','ch3_luca':'决定卢卡去留','ch3_close':'责任与欠款结算','ch4_council':'第四章 · 旧船坞议事','ch4_rules':'选择同盟规则','ch4_trial':'短程试运与收益','ch5_offer':'第五章 · 维克的条件','ch5_decide':'最后一份契约','ch5_close':'退还保证金与清偿顺序','finale_settle':'终章 · 清偿账目','finale_direction':'选择下一季航向','ending_guild':'商会之旗','ending_alliance':'同盟之旗','ending_voyage':'远航之旗','story_end':'第一部后日谈'}
for n in nodes:
    if n['id'] in labels:n['title']=labels[n['id']]
model['subtitle']='序章至终章 · 故事流程'
model['legend']='所有节点来自可试玩 Ink 剧本；条件选项由前章选择解锁，跨章连接在全部章节视图中可见'
model['routeNote']='路线展示关键决策；实际结局还取决于交易、证据公开、授权和契约选择。'
Path('web/flow/story.json').write_text(json.dumps(model,ensure_ascii=False,indent=2)+'\n')
print(f'{len(nodes)} nodes, {len(edges)} edges; source {source}')
