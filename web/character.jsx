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
 <section><h2>同行者，也有自己的选择</h2><p className="muted">新增姓名和后续经历为设定草案；既有试玩仍沿用原称呼。</p>{bible.relationships.map(r=><details key={r.name}><summary>{r.name}<span>{r.role}</span></summary><small>{r.status}</small>{[['他/她要什么',r.want],['与艾琳的冲突',r.tension],['自己的变化',r.arc],['玩家选择的影响',r.choice]].map(([title,text])=><p key={title}><strong>{title}：</strong>{text}</p>)}</details>)}</section>
 <footer><a href="#/home">返回故事目录</a><span>设定会随逐章创作与试玩反馈完善。</span></footer>
 </main></div>
}
