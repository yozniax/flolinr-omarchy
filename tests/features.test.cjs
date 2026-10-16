const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const m=vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname,'../Model.js'),'utf8'),m);
const texts=nodes=>JSON.stringify(nodes.map(n=>[n.text,n.depth]));
test('global search includes collapsed, archived and dated notes with jump IDs',()=>{
 const a=m.createRoll('A',[m.node('parent',0),m.node('Needle child',1)]); a.nodes[0].collapsed=true;
 const b=m.createRoll('B',[m.node('needle archived',0)]); b.archived=true;
 const rolls=[a,b]; m.appendCapture(rolls,'2026-10-16','needle daily');
 const hits=m.searchWorkspace(rolls,'NEEDLE');
 assert.equal(hits.length,3); assert.equal(hits[0].path,'parent');
 assert.equal(hits[0].nodeId,a.nodes[1].id); assert.equal(hits[1].archived,true);
 assert.equal(hits[2].memopadDate,'2026-10-16'); assert.equal(m.searchWorkspace(rolls,'  ').length,0);
});
test('capture appends to today without replacing past days or changing IDs',()=>{
 const rolls=[]; const first=m.appendCapture(rolls,'2026-10-15','yesterday');
 const today=m.appendCapture(rolls,'2026-10-16','first');
 m.appendCapture(rolls,'2026-10-16','second');
 assert.equal(rolls.length,2); assert.equal(rolls[0].nodes[0].id,first);
 assert.equal(rolls[1].nodes[0].id,today); assert.equal(rolls[1].nodes[1].text,'second');
 assert.throws(()=>m.appendCapture(rolls,'2026-10-16','a\nb'));
 assert.throws(()=>m.appendCapture(rolls,'2026-10-16','  '));
});
test('Markdown round-trip preserves hierarchy, multiline and literal list-looking text',()=>{
 const roll=m.createRoll('日本語',[m.node('root\n- literal\n1. numbered\n\\- escaped\n\\\\- double escape\n\nlast',0),m.node('child',1),m.node('',1),m.node('other',0)]);
 const out=m.exportMarkdown(roll), imported=m.importMarkdown(out,'fallback');
 assert.equal(imported.name,'日本語'); assert.equal(texts(imported.nodes),texts(roll.nodes));
 assert.notEqual(imported.nodes[0].id,roll.nodes[0].id);
});
test('Markdown accepts conventional lists and rejects impossible hierarchy',()=>{
 const roll=m.importMarkdown('# Heading\n\n- One\n  - Two\n- Three\n','Fallback');
 assert.equal(texts(roll.nodes),JSON.stringify([['One',0],['Two',1],['Three',0]]));
 assert.throws(()=>m.importMarkdown('- Root\n    - Skipped level','x'));
 assert.throws(()=>m.importMarkdown('   - Odd spaces','x'));
});
test('AI replacement is isolated to selected branch, validates preview and detects stale data',()=>{
 const nodes=[m.node('first',0),m.node('child',1),m.node('last',0)];
 const before=m.branchSnapshot(nodes,nodes[0].id);
 const next=m.applyBranch(nodes,nodes[0].id,before,'- Summary\n  - detail');
 assert.equal(next[0].id,nodes[0].id); assert.equal(next[2].id,nodes[2].id);
 assert.equal(nodes[0].text,'first');
 assert.throws(()=>m.applyBranch(nodes,nodes[0].id,before,'- a\n- b'));
 nodes[1].text='changed'; assert.throws(()=>m.applyBranch(nodes,nodes[0].id,before,'- Summary'));
});
