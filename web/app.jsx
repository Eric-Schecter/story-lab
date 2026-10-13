import React,{useState,useEffect,useLayoutEffect,useRef,useCallback} from 'react';
import {createRoot} from 'react-dom/client';
import StoryView from './story';
import CharacterView from './character';
import FlowView from './flow/app';
import Preloader from './preloader/Preloader';
import {mountLibrary} from './library';
import {mountPlayer} from './player';
import {homeMarkup,playerMarkup} from './templates';
import {currentRoute} from './routes';
const sources=[...new Set(window.STORIES.flatMap(s=>[s.background,s.cover,s.ink]).filter(Boolean))];
const styleSets={story:['/web/library.css?v=left-shelf-2'],character:['/web/character.css?v=cast-1'],home:['/web/library.css?v=left-shelf-2'],play:['/stories/wind-and-contract/avg/style.css','/web/player.css'],flow:['/web/flow/dist/app.css']};
function stylesFor(name){return Promise.all((styleSets[name]||styleSets.home).map(href=>new Promise(resolve=>{
 const link=document.createElement('link');link.rel='stylesheet';link.href=href;link.media='not all';link.dataset.routeStyle='';link.onload=()=>resolve(link);link.onerror=()=>resolve(link);document.head.append(link);
})));}
async function decodeCover(source){const img=new Image();img.src=source;let timer;try{await Promise.race([img.decode(),new Promise(resolve=>{timer=setTimeout(resolve,8000)})]);}finally{clearTimeout(timer)}}
const PageMarkup=React.memo(function PageMarkup({name,search,onReady}){
 const host=useRef(null);
 useLayoutEffect(()=>{if(name==='home'){document.title='Story Lab · 故事目录';mountLibrary();let active=true;Promise.allSettled(window.STORIES.flatMap(s=>[s.background,s.cover]).filter(Boolean).map(decodeCover)).then(()=>{if(active)onReady()});return()=>{active=false};}return mountPlayer(search,onReady);},[name,search,onReady]);
 return <div ref={host} dangerouslySetInnerHTML={{__html:name==='home'?homeMarkup:playerMarkup}}/>;
});
function Application(){
 const [route,setRoute]=useState(currentRoute),[phase,setPhase]=useState('hidden'),[ready,setReady]=useState(false);
 const reveal=useCallback(()=>requestAnimationFrame(()=>requestAnimationFrame(()=>setPhase(current=>current==='hidden'?'enter':current))),[]);
 useEffect(()=>{let version=0,disposed=false;
 const navigate=async(initial=false)=>{const next=currentRoute(),token=++version;
 if(!initial){setPhase('out');await new Promise(r=>setTimeout(r,250));}
 if(disposed||token!==version)return;
 const old=[...document.querySelectorAll('link[data-route-style]')];const name=next.pathname.slice(1);
 const links=name?await stylesFor(name):[];
 if(disposed||token!==version){links.forEach(el=>el.remove());return;}
 // Activate destination styles only after the outgoing content is invisible.
 old.forEach(el=>el.remove());links.forEach(el=>el.media='all');
 document.body.removeAttribute('data-story-loading');setPhase(name?'hidden':'enter');setRoute(next);setReady(true);window.scrollTo(0,0);
 if(name&&!['home','play','flow','character','story'].includes(name))reveal();
 };
 const changed=()=>void navigate();window.addEventListener('hashchange',changed);void navigate(true);
 return()=>{disposed=true;version++;window.removeEventListener('hashchange',changed)};
 },[reveal]);
 const name=route.pathname.slice(1);
 const enter=()=>window.setTimeout(()=>location.replace('#/home'),900);
 return <div className={'route-shell route-'+phase} aria-busy={phase==='hidden'}><div key={route.pathname+'?'+route.search}>
 {ready&&(!name?<div id="preloader-root"><Preloader sources={sources} onEnter={enter}/></div>:name==='story'?<StoryView search={route.search} onReady={reveal}/>:name==='character'?<CharacterView onReady={reveal}/>:name==='flow'?<FlowView search={route.search} onReady={reveal}/>:name==='home'||name==='play'?<PageMarkup name={name} search={route.search} onReady={reveal}/>:<main><h1>页面不存在</h1><a href="#/home">返回故事目录</a></main>)}
 </div></div>;
}
createRoot(document.getElementById('app')).render(<Application/>);
