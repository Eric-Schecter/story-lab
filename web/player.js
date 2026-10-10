let story,storyData,config;const $=id=>document.getElementById(id),log=[];
function start(){story=new inkjs.Story(storyData);log.length=0;$('choices').replaceChildren();step();}
function display(text){text=text.replace('《风与契约》——第一章：装满的货舱','《风与契约》——序章：装满的货舱').replace('点击 Inky 右侧的“重新开始剧本”，可以比较其他选择。','点击右上角“重新开始”，可以比较其他选择。');const m=text.match(/^([^：“]{1,12})：“([\s\S]*)”$/);const name=m?m[1]:null; $('portrait').hidden=!name; $('dialogue').classList.toggle('has-portrait',!!name); $('portrait').classList.toggle('is-captain',!!config.portraits[name]); if(name){$('portrait-image').src=!!config.portraits[name]?config.portraits[name]:'/stories/wind-and-contract/avg/assets/unknown.svg';$('portrait-image').alt=!!config.portraits[name]?name+'头像':name+'（临时剪影头像）';}else{$('portrait-image').removeAttribute('src');$('portrait-image').alt='';} $('speaker').textContent=name||'旁白';$('line').textContent=m?m[2]:text;log.push(text);}
function step(){if($('choices').childElementCount)return;if(story.canContinue){let t=story.Continue().trim();if(!t)return step();display(t);return;}if(story.currentChoices.length){$('next').hidden=true;story.currentChoices.forEach(c=>{const b=document.createElement('button');b.textContent=c.text;b.onclick=()=>{story.ChooseChoiceIndex(c.index);$('choices').replaceChildren();$('next').hidden=false;step();};$('choices').append(b);});}else{$('next').textContent='故事结束 · 再体验另一条路';$('next').onclick=()=>{reset();};}}
function reset(){$('next').hidden=false;$('next').innerHTML='继续 <span>▸</span>';$('next').onclick=step;start();}
$('restart').onclick=reset;$('next').onclick=step;$('history').onclick=()=>{$('entries').replaceChildren(...log.map(t=>{const p=document.createElement('p');p.textContent=t;return p;}));$('log').showModal();};$('close').onclick=()=>$('log').close();document.addEventListener('keydown',e=>{if(e.code==='Space'&&!$('log').open&&e.target===document.body){e.preventDefault();if(!$('next').hidden)$('next').click();}});
loadStory();

async function loadStory(){
 const id=new URLSearchParams(location.search).get('story');
 config=window.STORIES.find(item=>item.id===id);
 if(!config){$('speaker').textContent='故事未找到';$('line').textContent='请返回故事目录，选择已有作品。';$('next').hidden=true;$('restart').disabled=true;return;}
 document.title=config.title+' · 故事试玩';$('story-title').textContent=config.title;$('chapter').textContent=config.chapter;$('episode').textContent=config.episode;$('location').textContent=config.location;$('story-note').textContent=config.note+' · 点击继续 / 空格推进';$('stage').style.backgroundImage=`url("${config.background}")`;
 $('next').disabled=true;$('restart').disabled=true;
 try{const response=await fetch(config.ink);if(!response.ok)throw Error(response.status);storyData=await response.json();reset();$('next').disabled=false;$('restart').disabled=false;}
 catch(error){$('speaker').textContent='暂时无法打开故事';$('line').textContent='剧本加载失败，请返回目录重试。';$('next').hidden=true;}
}
