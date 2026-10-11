"""Merge implemented optional stories without rewriting the original source snapshot."""
import json

def merge_side_stories(model, base):
    data_path = base / 'source/side_stories.json'
    if not data_path.exists():
        return
    quests = json.loads(data_path.read_text())['quests']
    manifest = json.loads((base / 'design/side-stories-manifest.json').read_text())
    model['side_stories_commit'] = manifest['commit']
    for n in model['nodes']:
        if n['id'] == 'tuna_for_market':
            n['condition'] = '鱼市建成即可独立提交；新版已移除阿海委托前置。'
    for q in quests:
        chapter = 'ch' + str(q['chapter'])
        unlock = q['lock_text'] + ' 接取后独立进行，不卡主线。'
        source = '已实装 · data/side_stories.json#' + q['id'] + ' · ' + manifest['commit'][:7]
        def add(id, title, text, kind, condition='', changes=None):
            model['nodes'].append(dict(id=id,title=title,text=text,parent=chapter,kind=kind,condition=condition,source_label=source,changes=changes or []))
        add(q['id'], '支线｜' + q['title'], q['request'], 'sidequest', unlock)
        previous = q['id']
        if q['quest_type'] == 'visit':
            observe = q['id'] + '_observe'
            x,y = q['position']
            condition = f'接取后抵达 X {x} · Y {y}，范围 {q["radius"]}；停船连续观察 {q["observe_seconds"]} 秒；离开区域重新计时。'
            if q.get('period') == 'night': condition += ' 必须夜晚。'
            add(observe, '调查｜' + q['title'], q['visit_text'] + '\n钓鱼和港口菜单中不累计观察。调查只记录结果，不发奖励。', 'flow', condition)
            model['edges'].append([previous,observe,'接取并调查'])
            previous=observe
        decision=q['id']+'_choice'
        add(decision,'选择｜'+q['title'],'返港打开委托板后选择一种处理方式。各选项互斥；完成后不能重复提交。','decision')
        model['edges'].append([previous,decision,'返港交谈' if q['quest_type']=='visit' else '备齐任一种菜品后返港'])
        for choice in q['choices']:
            id=q['id']+'_'+choice['id']
            condition='关闭全部港口菜单后播放后续对白。'
            if choice.get('fish_id'): condition=f'提交 {choice["count"]} 条 {choice["fish_id"]}；只扣所选菜品。'+condition
            add(id,choice['text'],'\n'.join(choice['lines']),'outcome',condition,['奖励：'+choice['reward_text'],'记录互斥选择：'+q['id']+' = '+choice['id']])
            model['edges'].append([decision,id,choice['text']])
