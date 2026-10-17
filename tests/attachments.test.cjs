const {test}=require('node:test');
const assert=require('node:assert/strict');
const m = require('./load-model.cjs')();
const plain=x=>JSON.parse(JSON.stringify(x));
const a=(kind='code')=>({kind,name:'example.html',mime:kind==='image'?'image/png':'text/plain',language:kind==='code'?'html':'',content:kind==='image'?'aGVsbG8=':'  <div>\n\t<script>neverExecute()</script>\r\n    ```\n  - keep indentation\n'});
test('embedded items preserve indentation, folding, reordering and workspace round trips',()=>{
 const nodes=[m.node('Heading',0),m.node('Sibling',0)];
 const id=m.insertAttachment(nodes,nodes[0].id,a());
 assert.equal(nodes[1].id,id);assert.equal(nodes[1].depth,1);
 assert.equal(m.visible(nodes,'','')[1].attachment.content,a().content);
 nodes[1].collapsed=true;assert.ok(m.visible(nodes,'','')[1].children);
 m.indent(nodes,1,-1);assert.equal(nodes[1].depth,0);assert.equal(nodes[1].attachment.content,a().content);
 m.move(nodes,1,1);assert.equal(nodes[2].id,id);
 const roll=m.createRoll('Notes',nodes);const w=m.decodeWorkspace(m.encodeWorkspace(roll.id,[roll])).workspace;
 assert.equal(w.rolls[0].nodes[2].attachment.content,a().content);
 assert.equal(m.mergeNode(nodes,2,nodes[1].id),null);
});
test('Markdown and structured formats retain attachment bytes and metadata',()=>{
 for(const attachment of [a(),a('image'),{...a(),kind:'text',language:'markdown'},{...a('image'),kind:'file',mime:'application/pdf'}]) {
  const n=m.node('A title\n  extra',0);n.attachment=attachment;
  const roll=m.createRoll('Test',[n]);const md=m.exportMarkdown(roll);
  const imported=m.importMarkdown(md,'Fallback');
  assert.equal(imported.nodes.length,1);assert.equal(imported.nodes[0].text,n.text);
  assert.deepEqual(plain(imported.nodes[0].attachment),attachment);
  const structured=m.importOutline([{text:m.interchangeText(n),depth:0}],'Test');
  assert.deepEqual(plain(structured.nodes[0].attachment),attachment);
 }
});
test('AI never receives inserted content, rejects missing, duplicate or modified tokens and preserves originals',()=>{
 const nodes=[m.node('Before',0),m.node('Target',0),m.node('After',0)];
 const id=m.insertAttachment(nodes,nodes[1].id,a());nodes[2].collapsed=true;
 const before=JSON.stringify(nodes),zoom=nodes[1].id,p=m.createAiScope(nodes,zoom),token=p.items[0].token;
 assert.ok(!p.text.includes('neverExecute'));assert.ok(!p.text.includes('example.html'));
 assert.ok(!p.text.includes('Before'));assert.ok(!p.text.includes('After'));
 const result=m.applyScope(nodes,zoom,p.snapshot,'- Rewritten\n  - '+token,p);
 assert.deepEqual(plain(result[2]),plain(nodes[2]));assert.equal(JSON.stringify(nodes),before);
 assert.equal(result[0].id,nodes[0].id);assert.equal(result[3].id,nodes[3].id);
 for(const invalid of ['- Gone','- Root\n  - '+token+'\n  - '+token,'- Root\n  - edited '+token,'- '+token])
  assert.throws(()=>m.applyScope(nodes,zoom,p.snapshot,invalid,p));
 assert.throws(()=>m.applyScope(nodes,zoom,p.snapshot,'- Gone'));
 nodes[2].attachment.content+='edit';assert.throws(()=>m.applyScope(nodes,zoom,p.snapshot,'- Root\n  - '+token,p));
 assert.ok(id);
});
test('AI document conversion reinserts exact source using collision-safe code fences',()=>{
 const nodes=[m.node('Code',0)];nodes[0].attachment=a();const p=m.createAiScope(nodes,'');
 const restored=m.restoreMarkdownAttachments('# Report\n\n'+p.items[0].token,p);
 assert.ok(restored.includes(a().content));assert.ok(restored.includes('````html'));
 assert.throws(()=>m.restoreMarkdownAttachments('# Missing',p));
 assert.throws(()=>m.restoreMarkdownAttachments('- '+p.items[0].token,p));
 assert.equal(JSON.stringify(nodes[0].attachment),JSON.stringify(a()));
});
test('malformed embedded metadata and unsafe preview MIME types are rejected',()=>{
 assert.throws(()=>m.validateAttachment({...a('image'),mime:'image/svg+xml'}));
 assert.throws(()=>m.validateAttachment({...a('image'),content:'https://example.org/image'}));
 assert.throws(()=>m.validateAttachment({...a(),language:'html\n```'}));
 assert.throws(()=>m.importMarkdown('- a\n  <!-- flolinr-attachment:'+encodeURIComponent(JSON.stringify({attachment:a(),end:'missing'}))+' -->','bad'));
});

test('slash replacement keeps the node identity, depth and children, and rejects stale targets',()=>{
 const nodes=[m.node('Heading',0),m.node('/json',1),m.node('Child',2),m.node('After',0)];
 const id=nodes[1].id,child=nodes[2].id;
 m.replaceWithAttachment(nodes,id,a(),'/json');
 assert.equal(nodes.length,4);assert.equal(nodes[1].id,id);assert.equal(nodes[1].depth,1);assert.equal(nodes[1].text,'');assert.equal(nodes[2].id,child);assert.equal(nodes[2].depth,2);
 assert.deepEqual(plain(nodes[1].attachment),a());
 assert.throws(()=>m.replaceWithAttachment(nodes,id,a(),'/json'));
 const blank=[m.node('/',0)];m.replaceWithAttachment(blank,blank[0].id,a(),'/');assert.equal(blank[0].text,'');
 const stale=[m.node('changed text',0)];assert.throws(()=>m.replaceWithAttachment(stale,stale[0].id,a(),'/code'));assert.equal(stale[0].text,'changed text');
});

test('insert detects file extensions and pasted formats without executing content',()=>{
 for(const [name,content,expected] of [
 ['notes.md','plain words','markdown'],['app.css','body { color: red; }','css'],
 ['data.json','{}','json'],['','{"a":[1]}','json'],['','<div>hello</div>','html'],
 ['','# Heading\n- list','markdown'],['','body { color: red; }','css'],
 ['','const x = 1;','javascript'],['','def hello():\n    pass','python'],
 ['','ordinary text','text'],['notes.txt','<div>literal</div>','text']])
 assert.equal(m.detectAttachmentFormat(name,content),expected);
});
