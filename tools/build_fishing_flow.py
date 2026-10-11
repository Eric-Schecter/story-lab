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
    chapter = n['parent'] if n['parent'] in chapters else {'sardines_for_ahai':'ch1','tuna_for_market':'ch3','review':'ch4'}[n['id']]
    nodes.append(dict(chapter=chapter,id=n['id'], title=n['title'], kind=kind, text=n['text'], changes=n.get('changes', []), conditions=[n['condition']] if n.get('condition') else [], sourceLabel=n.get('source_label', chapters.get(n['parent'], '支线与审阅资料'))))
by_id = {n['id']: n for n in nodes}
by_id['ending_entrust']['changes'] = ['奖励：500 金币']
by_id['ending_gentle']['conditions'] = ['当前碎片数量 ≥ 5，且收集完整十种鱼图鉴', '碎片庇护 300 秒后到期并清空；历史累计数量不算。']
by_id['sardines_for_ahai']['conditions'] = ['新手引导完成；提交 3 条沙丁鱼。']
by_id['tuna_for_market']['conditions'] = ['鱼市已建成即可独立提交 1 条金枪鱼；不再要求先完成阿海委托。']
edges = [dict(id=f'e{i}', source=a, target=b, label=label) for i, (a,b,label) in enumerate(m['edges'])]
def reference(a,b,label):
    edges.append(dict(id=f'e{len(edges)}', source=a, target=b, label=label, reference=True))
reference('t_gear_return', 'sardines_for_ahai', '完成全部教程后解锁')
reference('m_market', 'tuna_for_market', '鱼市建成后独立解锁')
reference('m_searchlight', 'confession', '相关对白资料')
reference('confession', 'review', '原作矛盾审阅')
for n in nodes:
    if n['kind'] == 'clue':
        reference('m_sea_clue', n['id'], '可选线索·顺序自由')
for a,b in [('m_lighthouse','ahai_old_route'),('m_market','market_late_supper'),('m_searchlight','lin_old_lampshade')]:
    reference(a,b,'可选人物故事 · 不阻塞主线')
main = [a for a,b,label in m['edges'][:24]] + ['m_choice']
routes = [dict(id=end, title=by_id[end]['title'], nodes=main+[end], result='；'.join(by_id[end]['conditions'])) for end in ['ending_light','ending_entrust','ending_gentle']]
for route in routes: route['chapter']='finale'
for q in json.loads((root/'stories/fishing/source/side_stories.json').read_text())['quests']:
    prefix=[q['id']]+([q['id']+'_observe'] if q['quest_type']=='visit' else [])+[q['id']+'_choice']
    for choice in q['choices']:
        outcome=q['id']+'_'+choice['id']
        routes.append(dict(id=outcome,title=q['title']+' · '+choice['text'],chapter='ch'+str(q['chapter']),nodes=prefix+[outcome],result='奖励：'+choice['reward_text']+'；可选、互斥，不影响主线。'))
result = dict(chapters=m['chapters'],title='雾海传说', subtitle='六章 · 五条可选支线', storyId='fishing', initial='opening', source=str(source.relative_to(root)), source_commit=m['source_commit'], side_stories_commit=m.get('side_stories_commit'), textHeading='原文与任务整理', routeNote='高亮主线通往该结局的路径；虚线为支线解锁或资料关联，不代表必经顺序。', legend='实线：主线或支线内部推进 · 虚线：可选解锁 / 资料关联。新增三条人物故事已在游戏实装；Ink/articy 试玩仍为原版快照。', nodes=nodes, edges=edges, routes=routes)
(root/'web/flow/fishing.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
