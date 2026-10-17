const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const m=require('./load-model.cjs')();
const templates=vm.createContext({});vm.runInContext(fs.readFileSync(path.join(__dirname,"../Templates.js"),"utf8"),templates);
const c=vm.createContext({Model:m,Templates:templates});
vm.runInContext(fs.readFileSync(path.join(__dirname,'../CommandActions.js'),'utf8').replace(/^\.import.*$/gm,''),c);
const plain=x=>JSON.parse(JSON.stringify(x));
test('command replacements preserve IDs, descendants and nesting and reject stale input',()=>{
 const nodes=[m.node('Parent',0),m.node('/todo',1),m.node('Child',2),m.node('Sibling',0)];
 const id=nodes[1].id;
 c.replace(nodes,id,'/todo','[ ] ');assert.equal(nodes[1].id,id);assert.equal(nodes[2].depth,2);
 assert.equal(c.todoState(nodes[1].text),false);nodes[1].text=c.toggleTodo(nodes[1].text);
 assert.equal(c.todoState(nodes[1].text),true);assert.equal(c.toggleTodo('[x] Do it'),'[ ] Do it');
 assert.equal(c.todoState('ordinary'),null);assert.equal(c.todoState('[xml] ordinary'),null);
 const roll=m.createRoll('Tasks',nodes);const w=m.decodeWorkspace(m.encodeWorkspace(roll.id,[roll])).workspace;
 assert.equal(c.todoState(w.rolls[0].nodes[1].text),true);
 assert.throws(()=>c.replace(nodes,id,'/todo','---'));
});
test('templates insert complete nested branches without discarding existing children',()=>{
 for(let index=0;index<c.templates.length;index++) {
  const nodes=[m.node('Parent',0),m.node('/template',1),m.node('Existing child',2),m.node('After',0)];
  const target=nodes[1].id,child=nodes[2].id;
  c.insertTemplate(nodes,target,'/template',index);
  m.validate({version:1,nodes});assert.equal(nodes[1].id,target);
  assert.equal(nodes.find(n=>n.id===child).text,'Existing child');assert.equal(nodes.at(-1).text,'After');
  assert.ok(nodes.some(n=>c.todoState(n.text)===false));
 }
});
test('internal links safely encode IDs and resolve stable targets across reloads',()=>{
 const item=m.node('A [label]\nwith lines',0);item.id='id /?#%';const roll=m.createRoll('Roll', [item]);roll.id='roll /?';
 const text=c.linkText(roll,item),link=c.parseLink(text);
 assert.equal(link.rollId,roll.id);assert.equal(link.nodeId,item.id);assert.ok(!link.label.includes('['));
 assert.equal(c.parseLink('https://example.com'),null);assert.equal(c.parseLink('[a](flolinr://roll/%gg)'),null);
 assert.equal(c.linkTargets([roll],'label','other','').length,1);
 assert.equal(c.linkTargets([roll],'label',roll.id,item.id).length,0);
 const copy=m.decodeWorkspace(m.encodeWorkspace(roll.id,[roll])).workspace;
 assert.equal(copy.rolls[0].nodes[0].id,link.nodeId);
});
test('date validation and text-based controls round-trip through all outline formats',()=>{
 assert.equal(c.dateText('2028-02-29'),'2028-02-29');
 for(const value of ['2026-02-29','2026-13-01','today']) assert.throws(()=>c.dateText(value));
 const roll=m.createRoll('Commands',[m.node('[x] Done',0),m.node('---',0),m.node('2026-10-17',0),m.node('[Guide](flolinr://roll/abc/item/def)',0)]);
 const read=m.importMarkdown(m.exportMarkdown(roll),'fallback');
 assert.deepEqual(plain(read.nodes.map(n=>n.text)),plain(roll.nodes.map(n=>n.text)));
 assert.deepEqual(plain(m.importOutline(roll.nodes.map(n=>({text:m.interchangeText(n),depth:n.depth})),'x').nodes.map(n=>n.text)),plain(roll.nodes.map(n=>n.text)));
});

test('custom templates are validated and URLs are linked without interpreting markup',()=>{
 assert.deepEqual(Array.from(c.commands),['insert','date','link','template']);
 const custom=templates.fromText('My template','First\n  [ ] Nested');
 assert.equal(custom.items[1][0],2);
 const nodes=[m.node('/template',0)];c.insertTemplate(nodes,nodes[0].id,'/template',0,[custom]);
 assert.equal(nodes[0].text,'My template');assert.equal(nodes[2].depth,2);
 assert.throws(()=>templates.fromText('Bad','Top\n      Jump'));
 assert.equal(c.hasUrl('https://www.doyo.be/'),true);
 assert.equal(c.hasUrl('javascript:alert(1)'),false);
 const rendered=c.linkify('<script>x</script> https://example.org/?a=1&b=2.');
 assert.ok(rendered.includes('&lt;script&gt;'));assert.ok(!rendered.includes('<script>'));
 assert.ok(rendered.includes('href="https://example.org/?a=1&amp;b=2"'));
});
