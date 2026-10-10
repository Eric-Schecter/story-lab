import React,{useState,useEffect,useLayoutEffect,useRef} from 'react';
import {createRoot} from 'react-dom/client';
import FlowView from './flow/app';
import Preloader from './preloader/Preloader';
import {mountLibrary} from './library';
import {mountPlayer} from './player';
import {homeMarkup,playerMarkup} from './templates';
import {currentRoute} from './routes';
const sources=[...new Set(window.STORIES.flatMap(s=>[s.background,s.cover,s.ink]).filter(Boolean))];
const styleSets={home:['/web/library.css'],play:['/stories/wind-and-contract/avg/style.css','/web/player.css'],flow:['/web/flow/dist/app.css']};
function stylesFor(name){return Promise.all((styleSets[name]||styleSets.home).map(href=>new Promise(resolve=>{
 const link=document.createElement('link');link.rel='stylesheet';link.href=href;link.dataset.routeStyle='';link.onload=resolve;link.onerror=resolve;document.head.append(link);
})));}
function PageMarkup({name,search}){
 const host=useRef(null);
 useLayoutEffect(()=>{if(name==='home'){document.title='Story Lab · 故事目录';mountLibrary();return;}return mountPlayer(search);},[name,search]);
 return <div ref={host} dangerouslySetInnerHTML={{__html:name==='home'?homeMarkup:playerMarkup}}/>;
}
function Application(){
 const [route,setRoute]=useState(currentRoute),[leaving,setLeaving]=useState(false),[ready,setReady]=useState(false);
 useEffect(()=>{let version=0,disposed=false;
 const navigate=async()=>{const next=currentRoute(),token=++version;setLeaving(true);await new Promise(r=>setTimeout(r,250));if(disposed||token!==version)return;
 const old=[...document.querySelectorAll('link[data-route-style]')];const name=next.pathname.slice(1);if(name)await stylesFor(name);if(disposed||token!==version)return;
 old.forEach(el=>el.remove());document.body.removeAttribute('data-story-loading');setRoute(next);setReady(true);setLeaving(false);window.scrollTo(0,0);
 };
 window.addEventListener('hashchange',navigate);void navigate();return()=>{disposed=true;version++;window.removeEventListener('hashchange',navigate)};
 },[]);
 const name=route.pathname.slice(1);
 const enter=()=>window.setTimeout(()=>location.replace('#/home'),900);
 return <div className={'route-shell'+(leaving?' route-leaving':'')} key={route.pathname+'?'+route.search}>
 {!name?<div id="preloader-root"><Preloader sources={sources} onEnter={enter}/></div>:ready?(name==='flow'?<FlowView search={route.search}/>:name==='home'||name==='play'?<PageMarkup name={name} search={route.search}/>:<main><h1>页面不存在</h1><a href="#/home">返回故事目录</a></main>):null}
 </div>;
}
createRoot(document.getElementById('app')).render(<Application/>);
