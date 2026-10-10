import React from 'react';
import{createRoot}from'react-dom/client';
import Preloader from './Preloader';
const stories=window.STORIES||[];
const selected=stories.find(s=>s.id===new URLSearchParams(location.search).get('story'));
const sources=Array.from(new Set(location.pathname.startsWith('/web/flow')?['/web/flow/story.json']:selected?[selected.background,selected.ink,...Object.values(selected.portraits)]:stories.flatMap(s=>[s.background,s.cover]).filter(Boolean)));
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
