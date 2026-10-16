const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const b=vm.createContext({});
vm.runInContext(fs.readFileSync(require('node:path').join(__dirname,'../Keybindings.js'),'utf8'),b);
test('partial overrides preserve defaults and allow disabling',()=>{
 const keys=b.resolve({newRoll:'Ctrl+N',color:''});
 assert.equal(keys.newRoll,'Ctrl+N'); assert.equal(keys.color,''); assert.equal(keys.save,'Ctrl+S');
 assert.equal(b.defaults.newRoll,'Ctrl+Shift+N');
});
test('reject malformed settings and ambiguous bindings',()=>{
 for(const value of [null,[],{unknown:'Ctrl+N'},{save:5},{save:'oops'},{save:'Ctrl+Ctrl+S'},{newRoll:'Ctrl+S'},{newRoll:'Shift+Ctrl+Z'}])
  assert.throws(()=>b.resolve(value));
});
test('accept documented example and default reset',()=>{
 const example=JSON.parse(fs.readFileSync(require('node:path').join(__dirname,'../keybindings.example.json'),'utf8'));
 assert.equal(b.resolve(example).save,'Ctrl+S'); assert.equal(b.resolve({}).help,'Ctrl+/');
});
test('help uses action identity when two default keys are swapped',()=>{
 const keys=b.resolve({search:'Ctrl+S',save:'Ctrl+F',color:''});
 const rows=b.helpRows(keys);
 const search=rows.find(r=>r[1]===b.descriptions.search);
 const save=rows.find(r=>r[1]===b.descriptions.save);
 assert.equal(search[0],'Ctrl+S'); assert.equal(save[0],'Ctrl+F');
 assert.equal(b.label(keys,'color'),'Disabled');
 assert.equal(rows.length,Object.keys(b.defaults).length);
});

test('categorized help includes every action once and reflects remapped or disabled shortcuts',()=>{
 const keys=b.resolve({search:'Ctrl+S',save:'Ctrl+F',color:''});
 const sections=b.helpSections(keys);
 assert.equal(sections.length,8);
 const rows=sections.flatMap(s=>s.rows);
 for(const id of Object.keys(b.defaults)) {
  const matches=rows.filter(r=>r[1]===b.descriptions[id]);
  assert.equal(matches.length,1,id); assert.equal(matches[0][0],b.label(keys,id));
 }
 assert.ok(sections[0].rows.some(r=>r[0]==='Backspace at start'));
});
