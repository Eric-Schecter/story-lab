import React from 'react';
import{createRoot}from'react-dom/client';
import Preloader from './Preloader';
const stories=window.STORIES||[];
const selected=stories.find(s=>s.id===new URLSearchParams(location.search).get('story'));
const sources=Array.from(new Set(location.pathname.startsWith('/web/flow')?[new URLSearchParams(location.search).get('story')==='fishing'?'/web/flow/fishing.json':'/web/flow/story.json']:selected?[selected.background,selected.ink,...Object.values(selected.portraits)]:stories.flatMap(s=>[s.background,s.cover]).filter(Boolean)));
const root=document.getElementById('preloader-root');
const sessionKey='story-lab:intro-seen';
let seen=false;
try{seen=sessionStorage.getItem(sessionKey)==='1'}catch{}
if(seen){
 document.body.removeAttribute('data-preloading');
 root.remove();
}else{
 createRoot(root).render(<Preloader sources={sources} onEnter={()=>{
  try{sessionStorage.setItem(sessionKey,'1')}catch{}
  document.body.removeAttribute('data-preloading');
 }}/>);
}

// Page fades are independent of the one-time intro.
if(seen)document.body.setAttribute('data-page-entering','');
let navigating=false;
document.addEventListener('click',event=>{
 const link=event.target.closest?.('a[href]');
 if(!link||event.defaultPrevented||event.button!==0||event.metaKey||event.ctrlKey||event.shiftKey||event.altKey||link.hasAttribute('download')||(link.target&&link.target!=='_self'))return;
 const destination=new URL(link.href,location.href);
 if(destination.origin!==location.origin||!/^https?:$/.test(destination.protocol)||destination.href===location.href||(destination.pathname===location.pathname&&destination.search===location.search&&destination.hash))return;
 if(!/\/$|\.html$/.test(destination.pathname))return;
 event.preventDefault();
 if(navigating)return;
 navigating=true;
 document.body.setAttribute('data-page-leaving','');
 window.setTimeout(()=>location.assign(destination.href),250);
});
window.addEventListener('pageshow',event=>{
 if(!event.persisted)return;
 navigating=false;
 document.body.removeAttribute('data-page-leaving');
 document.body.removeAttribute('data-page-entering');
 requestAnimationFrame(()=>document.body.setAttribute('data-page-entering',''));
});
