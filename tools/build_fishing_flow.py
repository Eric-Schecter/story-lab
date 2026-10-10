"""Build the read-only web graph from the traceable Fishing story model."""
import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
source = root / 'stories/fishing/design/story-model.json'
m = json.loads(source.read_text())
chapters = {c['id']: c['title'] for c in m['chapters']}
nodes = []
for n in m['nodes']:
    if n['id'] == 'Fishing_Story' or n['id'] in chapters:
        continue
    kind = 'end' if n['id'].startswith('ending_') else 'decision' if n['id'] == 'm_choice' else 'scene' if n['kind'] == 'flow' else n['kind']
    nodes.append(dict(id=n['id'], title=n['title'], kind=kind, text=n['text'], changes=[], conditions=[n['condition']] if n.get('condition') else [], sourceLabel=chapters.get(n['parent'], '支线与审阅资料')))
by_id = {n['id']: n for n in nodes}
by_id['ending_entrust']['changes'] = ['奖励：500 金币']
by_id['ending_gentle']['conditions'] = ['当前碎片数量 ≥ 5，且收集完整十种鱼图鉴', '碎片庇护 300 秒后到期并清空；历史累计数量不算。']
by_id['sardines_for_ahai']['conditions'] = ['新手引导完成；提交 3 条沙丁鱼。']
by_id['tuna_for_market']['conditions'] = ['阿海委托已完成，且鱼市已建成；提交 1 条金枪鱼。']
edges = [dict(id=f'e{i}', source=a, target=b, label=label) for i, (a,b,label) in enumerate(m['edges'])]
def reference(a,b,label):
    edges.append(dict(id=f'e{len(edges)}', source=a, target=b, label=label, reference=True))
reference('tutorial_upgrade', 'sardines_for_ahai', '支线解锁参考')
reference('sardines_for_ahai', 'tuna_for_market', '另需鱼市建成')
reference('m_market', 'tuna_for_market', '另需阿海委托完成')
reference('m_searchlight', 'confession', '相关对白资料')
reference('confession', 'review', '原作矛盾审阅')
for n in nodes:
    if n['kind'] == 'clue':
        reference('m_sea_clue', n['id'], '可选线索·顺序自由')
main = [a for a,b,label in m['edges'][:24]] + ['m_choice']
routes = [dict(id=end, title=by_id[end]['title'], nodes=main+[end], result='；'.join(by_id[end]['conditions'])) for end in ['ending_light','ending_entrust','ending_gentle']]
result = dict(title='雾海传说', subtitle='六章 · 故事流程', storyId='fishing', initial='opening', source=str(source.relative_to(root)), source_commit=m['source_commit'], textHeading='原文与任务整理', routeNote='高亮主线通往该结局的路径；虚线为支线解锁或资料关联，不代表必经顺序。', legend='实线：主线推进 · 虚线：支线解锁或资料关联', nodes=nodes, edges=edges, routes=routes)
(root/'web/flow/fishing.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
