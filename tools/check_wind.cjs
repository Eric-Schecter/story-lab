// Explore every later-chapter choice from all seven legal prologue/chapter-one paths.
const fs=require('fs'),vm=require('vm'),assert=require('assert');
const context={console};vm.createContext(context);vm.runInContext(fs.readFileSync('stories/wind-and-contract/avg/vendor/ink.js','utf8'),context);
const Story=context.inkjs.Story,data=JSON.parse(fs.readFileSync('stories/wind-and-contract/ink/wind-and-contract.json'));
function drain(s){let text='';while(s.canContinue)text+=s.Continue();assert(!s.hasError,(s.currentErrors||[]).join('\n'));return text;}
function pick(s,match){drain(s);const i=s.currentChoices.findIndex(c=>c.text.includes(match));assert(i>=0,'Missing '+match);s.ChooseChoiceIndex(i);}
let count=0;const endings=new Set();
function explore(s){const text=drain(s);if(!s.currentChoices.length){assert(text.includes('第一部完'),'Unexpected early ending');for(const k of ['money','crew_debt','old_debt','compensation'])assert(s.variablesState[k]>=0,k+' negative');assert.equal(s.variablesState.bond,0);assert.equal(s.variablesState.old_debt+s.variablesState.crew_debt+s.variablesState.compensation>0&&s.variablesState.money>0,false,'Unused funds while debts remain');endings.add(s.variablesState.final_contract);count++;return;}
 const saved=s.state.ToJson();for(let i=0;i<s.currentChoices.length;i++){const child=new Story(data);child.state.LoadJson(saved);child.ChooseChoiceIndex(i);explore(child);}}
const branches=[['履行契约','交六百'],['履行契约','提交还款'],['卸下染料','接受小港'],['卸下染料','提交还款'],['向船员借','交六百'],['向船员借','接受小港'],['向船员借','提交还款']];
for(const [opening,reprieve] of branches){const s=new Story(data);pick(s,'决定航向');pick(s,opening);pick(s,'夜里');pick(s,'打开舱门');pick(s,'核对账册');pick(s,'召集大家');pick(s,reprieve);pick(s,'驶向灰礁港');explore(s);}
assert.equal(endings.size,4);console.log(`${count} complete paths verified across seven legal starting paths; all contract outcomes reached, no negative balances or stuck branches.`);
