import {build} from '../web/flow/node_modules/esbuild/lib/main.js';
await build({entryPoints:['web/app.jsx'],bundle:true,minify:true,nodePaths:['web/flow/node_modules'],outfile:'web/dist/app.js',loader:{'.css':'css'},plugins:[{name:'route-styles',setup(b){b.onLoad({filter:/\.css$/},()=>({contents:'',loader:'css'}));}}]});
