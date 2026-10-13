import React,{useEffect} from 'react';
import bible from '../stories/wind-and-contract/design/story-bible.json';
export default function CharacterView({onReady}){
 const config=window.STORIES.find(s=>s.id==='wind-and-contract');
 useEffect(()=>{document.title='艾琳 · 人物设定';let active=true;const img=new Image();img.src=config.cover;const timer=setTimeout(()=>{if(active)onReady()},8000);img.decode().catch(()=>{}).then(()=>{clearTimeout(timer);if(active)onReady()});return()=>{active=false;clearTimeout(timer)}},[onReady,config.cover]);
 return <div className="dossier"><header><a href="#/home">故事目录</a><span>风与契约 · 人物设定</span></header><main>
 <section className="hero"><div><p className="eyebrow">{bible.version}</p><h1>{bible.hero.name}</h1><p className="identity">{bible.hero.age} · 商人船长</p><p className="premise">{bible.premise}</p><p>{bible.hero.role}</p><p className="notice">{bible.status}</p></div><img src={config.cover} alt="艾琳人物立绘"/></section>
 <section><h2>她想守住什么</h2><div className="traits">{[['表面的愿望',bible.hero.want],['真正需要学会的事',bible.hero.need],['不愿承认的恐惧',bible.hero.fear]].map(([title,text])=><article key={title}><h3>{title}</h3><p>{text}</p></article>)}</div></section>
 <section><h2>人设细节</h2><div className="traits">{[['经历',bible.hero.past],['擅长与短板',bible.hero.strength+' '+bible.hero.flaw],['信念的变化',bible.hero.belief],['说话方式',bible.hero.voice],['外观方向',bible.hero.look],['创作边界',bible.hero.boundaries]].map(([title,text])=><article key={title}><h3>{title}</h3><p>{text}</p></article>)}</div><details><summary>习惯与随身物</summary><ul>{bible.hero.habits.map(t=><li key={t}>{t}</li>)}</ul></details></section>
 <section><h2>选择怎样塑造她</h2><div className="traits">{bible.tracks.map(t=><article key={t.title}><h3>{t.title}</h3><p>{t.question}</p><p>{t.effect}</p><small>{t.implemented}</small></article>)}</div></section>
 <section><h2>船员与其他人物</h2><p className="muted">已登场人物与新增船员分别标注进度；新增背景不改变现有剧本的事件与结局。展开人物可查看详细设定。</p>{['船上同伴','港口与盟友','家族与商会'].map(group=><div className="cast-group" key={group}><h3>{group}</h3>{bible.relationships.filter(r=>r.group===group).map(r=><details key={r.name}><summary>{r.name}<span>{r.role} · {r.age}</span></summary><p className="cast-status">{r.status}</p><div className="traits">{[['经历',r.past],['想要的生活',r.want],['能力与短板',r.strength+' '+r.flaw],['与艾琳的冲突',r.tension],['人物成长',r.arc],['选择与后果',r.choice],['外观方向',r.look],['说话方式',r.voice],['习惯与随身物',r.habit],['创作边界',r.boundary]].map(([title,text])=><article key={title}><h4>{title}</h4><p>{text}</p></article>)}</div></details>)}</div>)}</section>
 <footer><a href="#/home">返回故事目录</a></footer>
 </main></div>
}
