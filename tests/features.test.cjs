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

test('structured import creates fresh identities and rejects corrupt hierarchy',()=>{
 const roll=m.importOutline([{text:'Root',depth:0},{text:'Child',depth:1}], 'OPML');
 assert.equal(roll.name,'OPML'); assert.equal(roll.nodes[1].depth,1);
 assert.ok(roll.nodes[0].id); assert.notEqual(roll.nodes[0].id,roll.nodes[1].id);
 assert.throws(()=>m.importOutline([{text:'Skipped',depth:2}], 'bad'));
 assert.throws(()=>m.importOutline([{text:4,depth:0}], 'bad'));
});

test('AI at Roll root includes all roots and collapsed descendants and accepts a forest preview',()=>{
 const nodes=[m.node('first',0),m.node('hidden child',1),m.node('second',0)]; nodes[0].collapsed=true;
 const before=m.scopeSnapshot(nodes,'');
 assert.equal(JSON.parse(before).length,3);
 assert.ok(m.markdownNodes(JSON.parse(before),0).includes('hidden child'));
 const next=m.applyScope(nodes,'',before,'- reorganized first\n  - detail\n- reorganized second');
 assert.equal(next.length,3); assert.equal(next[2].depth,0);
 assert.equal(nodes[0].text,'first');
 assert.throws(()=>m.applyScope(nodes,'',before,''));
 nodes[2].text='changed elsewhere in the Roll';
 assert.throws(()=>m.applyScope(nodes,'',before,'- replacement'));
});
test('AI zoom scope includes the zoom heading and every descendant while preserving outside branches',()=>{
 const nodes=[m.node('outside before',0),m.node('zoom root',0),m.node('child',1),m.node('hidden',2),m.node('outside after',0)];
 nodes[2].collapsed=true;
 const zoom=nodes[1].id,before=m.scopeSnapshot(nodes,zoom);
 assert.equal(JSON.parse(before).length,3);
 const next=m.applyScope(nodes,zoom,before,'- revised heading\n  - revised child');
 assert.equal(next[0].id,nodes[0].id); assert.equal(next[3].id,nodes[4].id);
 assert.equal(next[1].id,zoom); assert.equal(next[1].text,'revised heading');
 assert.throws(()=>m.applyScope(nodes,zoom,before,'- a\n- b'));
 nodes[3].text='changed hidden descendant';
 assert.throws(()=>m.applyScope(nodes,zoom,before,'- result'));
});
