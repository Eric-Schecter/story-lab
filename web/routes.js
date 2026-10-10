export function currentRoute(){const value=location.hash.slice(1)||'/';const [pathname,search='']=value.split('?');return {pathname,search};}
export function routeLink(path,search=''){return '#'+path+(search?'?'+search:'');}
