export function mountPlayer(search,onReady=()=>{}){
let active=true;document.body.setAttribute('data-story-loading','');
let story,storyData,config;const $=id=>document.getElementById(id),log=[];
function start(){story=new inkjs.Story(storyData);log.length=0;$('choices').replaceChildren();if(config.id==='wind-and-contract'&&new URLSearchParams(search).get('chapter')==='ch1'){chapterSetup();return;}if(config.id==='fishing'&&fishingChapterSetup())return;step();}
function chapterSetup(){
 $('chapter').textContent='第一章';$('episode').textContent='追索令';$('location').textContent='承接序章的选择';
 display('进入第一章前，选择序章中艾琳的决定。此入口使用对应结算状态开始第一章；从序章游玩则自动延续你的实际选择。');$('next').hidden=true;
 for(const [label,money,guild,port,debt,decision] of [['履行契约 · 1200 金币',1200,1,-1,0,'履行契约'],['违约运粮 · 100 金币',100,-1,1,0,'违约运粮'],['借款雇船 · 900 金币，欠船员 200',900,0,1,200,'借款雇船']]){
 const b=document.createElement('button');b.textContent=label;b.onclick=()=>{for(const [key,value] of Object.entries({money,guild_relation:guild,port_relation:port,crew_debt:debt,decision}))story.variablesState[key]=value;story.ChoosePathString('ch1_notice');$('choices').replaceChildren();$('next').hidden=false;step();};$('choices').append(b);
 }
}

function fishingChapterSetup(){
 const chapter=config.chapters.find(c=>c.id===new URLSearchParams(search).get('chapter'));
 if(!chapter)return false;
 $('chapter').textContent=chapter.title;$('episode').textContent='章节审阅';$('location').textContent='雾海 · 章节入口';
 display('章节试玩：'+chapter.title+'。从本章开始阅读，之前主线视为已推进至此；按钮仅模拟任务完成，不读取游戏存档。'+(chapter.id==='finale'?'请选择线索与图鉴状态，决定柔光结局是否开放。':chapter.id==='ch3'?'请选择阿海委托状态；它影响鱼市老板娘支线是否开放。':'后续章节会继续衔接，支线和收集保留原有条件。'));
 $('next').hidden=true;
 const presets=chapter.id==='finale'?[['普通收集 · 1 份碎片，图鉴未全',{fragments:1,codex_complete:false,clue_log_1:true}],['完整收集 · 5 份碎片，完整图鉴',{fragments:5,codex_complete:true,clue_log_1:true,clue_log_2:true,clue_fisher_tale:true,clue_last_note:true,clue_salvage:true}]]:chapter.id==='ch3'?[['阿海委托尚未完成',{ahai_done:false}],['阿海委托已完成（模拟前情）',{ahai_done:true}]]:[['开始本章',{}]];
 for(const [label,vars] of presets){const b=document.createElement('button');b.textContent=label;b.onclick=()=>{for(const [key,value] of Object.entries(vars))story.variablesState[key]=value;story.ChoosePathString(chapter.entry);$('choices').replaceChildren();$('next').hidden=false;step();};$('choices').append(b);}
 return true;
}
function display(text){if(config.id==='fishing'){const chapter=config.chapters.find(c=>c.title===text);if(chapter){$('chapter').textContent=chapter.title;$('episode').textContent='剧情审阅';$('location').textContent=config.location;}}if(text.startsWith('《风与契约》——第一章：')){$('chapter').textContent='第一章';$('episode').textContent='追索令';$('location').textContent='暮潮港 · 七日之限';}else if(text.startsWith('《风与契约》——序章：')){$('chapter').textContent='序章';$('episode').textContent='装满的货舱';$('location').textContent=config.location;}text=text.replace('《风与契约》——第一章：装满的货舱','《风与契约》——序章：装满的货舱').replace('点击 Inky 右侧的“重新开始剧本”，可以比较其他选择。','点击右上角“重新开始”，可以比较其他选择。');const m=text.match(/^([^：“]{1,12})：“([\s\S]*)”$/);const name=m?m[1]:null; $('portrait').hidden=!name; $('dialogue').classList.toggle('has-portrait',!!name); $('portrait').classList.toggle('is-captain',!!config.portraits[name]); if(name){$('portrait-image').src=!!config.portraits[name]?config.portraits[name]:'/stories/wind-and-contract/avg/assets/unknown.svg';$('portrait-image').alt=!!config.portraits[name]?name+'头像':name+'（临时剪影头像）';}else{$('portrait-image').removeAttribute('src');$('portrait-image').alt='';} $('speaker').textContent=name||'旁白';$('line').textContent=m?m[2]:text;log.push(text);}
function step(){if($('choices').childElementCount)return;if(story.canContinue){let t=story.Continue().trim();if(!t)return step();display(t);return;}if(story.currentChoices.length){$('next').hidden=true;story.currentChoices.forEach(c=>{const b=document.createElement('button');b.textContent=c.text;b.onclick=()=>{story.ChooseChoiceIndex(c.index);$('choices').replaceChildren();$('next').hidden=false;step();};$('choices').append(b);});}else{$('next').textContent='故事结束 · 再体验另一条路';$('next').onclick=()=>{reset();};}}
function reset(){$('next').hidden=false;$('next').innerHTML='继续 <span>▸</span>';$('next').onclick=step;start();}
$('restart').onclick=reset;$('next').onclick=step;$('history').onclick=()=>{$('entries').replaceChildren(...log.map(t=>{const p=document.createElement('p');p.textContent=t;return p;}));$('log').showModal();};$('close').onclick=()=>$('log').close();const onKey=e=>{if(e.code==='Space'&&!$('log').open&&e.target===document.body){e.preventDefault();if(!$('next').hidden)$('next').click();}};document.addEventListener('keydown',onKey);
loadStory();

async function preloadStoryImage(source){
 const image=new Image();
 image.src=source;
 await Promise.race([image.decode(),new Promise((_,reject)=>setTimeout(()=>reject(Error('图片加载超时')),8000))]);
 return image;
}
function revealStory(){
 // Keep the first rendered frame behind the loading gate, including cached visits.
 requestAnimationFrame(()=>requestAnimationFrame(()=>{if(active){document.body.removeAttribute('data-story-loading');onReady();}}));
}
async function loadStory(){
 const id=new URLSearchParams(search).get('story');
 config=window.STORIES.find(item=>item.id===id);
 if(!config){$('speaker').textContent='故事未找到';$('line').textContent='请返回故事目录，选择已有作品。';$('next').hidden=true;$('restart').disabled=true;revealStory();return;}
 document.title=config.title+' · 故事试玩';$('story-title').textContent=config.title;$('chapter').textContent=config.chapter;$('episode').textContent=config.episode;$('location').textContent=config.location;$('story-note').textContent=config.note+' · 点击继续 / 空格推进';$('stage').style.backgroundImage=`url("${config.background}")`;
 $('next').disabled=true;$('restart').disabled=true;
 try{
 const images=Array.from(new Set([config.background,...Object.values(config.portraits),'/stories/wind-and-contract/avg/assets/unknown.svg']));
 // Start image decode and script loading together; do not reveal an undecoded background.
 const [data]=await Promise.all([
  fetch(config.ink+'?v=wind-chapter-1',{signal:AbortSignal.timeout(15000)}).then(response=>{if(!response.ok)throw Error(response.status);return response.json();}),
  Promise.allSettled(images.map(preloadStoryImage))
 ]);
 if(!active)return;storyData=data;reset();$('next').disabled=false;$('restart').disabled=false;
 }
 catch(error){if(!active)return;$('speaker').textContent='暂时无法打开故事';$('line').textContent='故事资源加载失败，请返回目录重试。';$('next').hidden=true;}
 finally{if(active)revealStory();}
}

return()=>{active=false;document.removeEventListener('keydown',onKey);document.body.removeAttribute('data-story-loading');};
}
