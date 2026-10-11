import React,{useEffect,useState} from 'react';
import bible from '../stories/wind-and-contract/design/story-bible.json';
export default function CharacterView({onReady}){
 const [selected,setSelected]=useState('prologue');
 const chapter=bible.chapters.find(c=>c.id===selected);
 const config=window.STORIES.find(s=>s.id==='wind-and-contract');
 useEffect(()=>{document.title='艾琳 · 人物与故事规划';let active=true;const img=new Image();img.src=config.cover;const timer=setTimeout(()=>{if(active)onReady()},8000);img.decode().catch(()=>{}).then(()=>{clearTimeout(timer);if(active)onReady()});return()=>{active=false;clearTimeout(timer)}},[onReady,config.cover]);
 return <div className="dossier"><header><a href="#/home">故事目录</a><span>风与契约 · 人物与故事规划</span></header><main>
 <section className="hero"><div><p className="eyebrow">{bible.version}</p><h1>{bible.hero.name}</h1><p className="identity">{bible.hero.age} · 商人船长</p><p className="premise">{bible.premise}</p><p>{bible.hero.role}</p><p className="notice">{bible.status} 后续章节内容涉及剧情走向。</p></div><img src={config.cover} alt="艾琳人物立绘"/></section>
 <section><h2>她想守住什么</h2><div className="traits">{[['表面的愿望',bible.hero.want],['真正需要学会的事',bible.hero.need],['不愿承认的恐惧',bible.hero.fear]].map(([title,text])=><article key={title}><h3>{title}</h3><p>{text}</p></article>)}</div></section>
 <section><h2>人设细节</h2><div className="traits">{[['经历',bible.hero.past],['擅长与短板',bible.hero.strength+' '+bible.hero.flaw],['信念的变化',bible.hero.belief],['说话方式',bible.hero.voice],['外观方向',bible.hero.look],['创作边界',bible.hero.boundaries]].map(([title,text])=><article key={title}><h3>{title}</h3><p>{text}</p></article>)}</div><details><summary>习惯与随身物</summary><ul>{bible.hero.habits.map(t=><li key={t}>{t}</li>)}</ul></details></section>
 <section><h2>七个篇章，一条成长线</h2><p className="muted">选择篇章，查看事件、选择与人物变化。只有标注“可试玩”的章节已实现。</p><nav className="chapter-track" aria-label="故事成长章节">{bible.chapters.map((c,i)=><button key={c.id} aria-pressed={c.id===selected} onClick={()=>setSelected(c.id)}><small>{String(i+1).padStart(2,'0')} · {c.state}</small><strong>{c.title}</strong><span>{c.stage}</span></button>)}</nav>
 <article className="chapter-detail" aria-live="polite"><div className="chapter-heading"><h3>{chapter.title}</h3><span className="badge">{chapter.state}</span></div><p className="chapter-stage">{chapter.stage}</p><div className="chapter-grid">{[['发生什么',chapter.event],['玩家决定什么',chapter.choice],['艾琳如何变化',chapter.growth],['人物关系如何变化',chapter.relationship],['前因与后果',chapter.carry],['下一步',chapter.next]].map(([title,text])=><div key={title}><h4>{title}</h4><p>{text}</p></div>)}</div><blockquote>“{chapter.line}”<small>{chapter.lineNote}</small></blockquote>{chapter.state==='可试玩'&&<div className="actions"><a href={'#/play?story=wind-and-contract&chapter='+chapter.id}>试玩本章</a><a href={'#/flow?story=wind-and-contract&chapter='+chapter.id}>查看本章流程</a></div>}</article></section>
 <section><h2>选择怎样塑造她</h2><div className="traits">{bible.tracks.map(t=><article key={t.title}><h3>{t.title}</h3><p>{t.question}</p><p>{t.effect}</p><small>{t.implemented}</small></article>)}</div></section>
 <section><h2>同行者，也有自己的选择</h2><p className="muted">新增姓名和后续经历为设定草案；既有试玩仍沿用原称呼。</p>{bible.relationships.map(r=><details key={r.name}><summary>{r.name}<span>{r.role}</span></summary><small>{r.status}</small>{[['他/她要什么',r.want],['与艾琳的冲突',r.tension],['自己的变化',r.arc],['玩家选择的影响',r.choice]].map(([title,text])=><p key={title}><strong>{title}：</strong>{text}</p>)}</details>)}</section>
 <section><h2>终点不只是一面旗帜</h2><p className="muted">以下为结局方向规划，尚未实现为试玩结局。</p><div className="traits">{bible.endings.map(e=><article key={e.title}><h3>{e.title}</h3><p>{e.gain}</p><p>代价：{e.cost}</p><p>{e.variation}</p></article>)}</div></section>
 <details><summary>当前进度与连续性约定</summary><ul>{bible.continuity.map(t=><li key={t}>{t}</li>)}</ul></details>
 <footer><a href="#/home">返回故事目录</a><span>设定会随逐章创作与试玩反馈完善。</span></footer>
 </main></div>
}
