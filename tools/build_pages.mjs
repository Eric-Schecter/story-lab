// Export only the public story experience, with a configurable project-site base.
import {build} from '../web/flow/node_modules/esbuild/lib/main.js';
import {readFile,writeFile,mkdir,cp,rm} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const out=path.join(root,'dist-pages');
const base=process.env.PAGES_BASE||'/story-lab/';
if(!/^\/(?:[\w-]+\/)*$/.test(base))throw Error('PAGES_BASE must be an absolute directory path');
const adapt=text=>text.replace(/(["'`])\/(web\/|stories\/)/g,(_,quote,dir)=>quote+base+dir).replace(/href=(["'])\/\1/g,(_,quote)=>'href='+quote+base+quote);
await rm(out,{recursive:true,force:true});
async function copy(file){const dest=path.join(out,file);await mkdir(path.dirname(dest),{recursive:true});await cp(path.join(root,file),dest,{recursive:true});}
async function adapted(file){const dest=path.join(out,file);await mkdir(path.dirname(dest),{recursive:true});await writeFile(dest,adapt(await readFile(path.join(root,file),'utf8')));}
for(const file of ['index.html','web/home.html','web/play.html','web/flow/index.html','web/library.js','web/stories.js','web/player.js'])await adapted(file);
for(const file of ['web/app.css','web/player.css','web/library.css','web/flow/story.json','web/flow/fishing.json',
 'stories/wind-and-contract/avg/assets','stories/wind-and-contract/avg/vendor','stories/wind-and-contract/avg/style.css','stories/wind-and-contract/ink/wind-and-contract.json',
 'stories/fishing/avg/assets','stories/fishing/ink/fishing.json'])await copy(file);
const plugin={name:'project-base',setup(b){b.onLoad({filter:/\.(jsx|js)$/},async args=>{
 if(args.path.includes('node_modules'))return;
 return {contents:adapt(await readFile(args.path,'utf8')),loader:args.path.endsWith('.jsx')?'jsx':'js'};
})}};
for(const [entry,target] of [['web/flow/app.jsx','web/flow/dist/app.js'],['web/preloader/main.jsx','web/preloader/dist/preloader.js']])await build({entryPoints:[path.join(root,entry)],bundle:true,minify:true,nodePaths:[path.join(root,'web/flow/node_modules')],outfile:path.join(out,target),loader:{'.css':'css'},plugins:[plugin]});
await build({entryPoints:[path.join(root,'web/app.jsx')],bundle:true,minify:true,nodePaths:[path.join(root,'web/flow/node_modules')],outfile:path.join(out,'web/dist/app.js'),loader:{'.css':'css'},plugins:[plugin,{name:'route-styles',setup(b){b.onLoad({filter:/\.css$/},()=>({contents:'',loader:'css'}));}}]});
await writeFile(path.join(out,'.nojekyll'),'');
console.log(`GitHub Pages build ready: dist-pages (base ${base})`);
