import {build} from 'esbuild';
import {fileURLToPath} from 'node:url';
await build({entryPoints:[fileURLToPath(new URL('../preloader/main.jsx',import.meta.url))],bundle:true,minify:true,nodePaths:[fileURLToPath(new URL('./node_modules',import.meta.url))],outfile:fileURLToPath(new URL('../preloader/dist/preloader.js',import.meta.url)),loader:{'.css':'css'}});
