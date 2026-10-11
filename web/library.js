export function mountLibrary(){
 const list=document.getElementById('stories');
 for(const story of window.STORIES){
  const card=document.createElement('article');card.className='card '+story.id;
  const book=document.createElement('a');book.className='art book-link';book.href='#/story?story='+encodeURIComponent(story.id);book.setAttribute('aria-label','打开《'+story.title+'》');book.style.backgroundImage=`url("${story.background}")`;
  if(story.cover){const img=document.createElement('img');img.src=story.cover;img.alt='';book.append(img);}
  const title=document.createElement('div');title.className='cover-title';
  const subtitle=document.createElement('div');subtitle.className='subtitle';subtitle.textContent=story.subtitle;
  const heading=document.createElement('h2');heading.textContent=story.title;title.append(subtitle,heading);book.append(title);card.append(book);list.append(card);
 }
 document.getElementById('count').textContent=window.STORIES.length;
}
