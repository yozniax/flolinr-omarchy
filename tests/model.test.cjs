const {test} = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const m = vm.createContext({});
vm.runInContext(fs.readFileSync(require('node:path').join(__dirname, '../Model.js'), 'utf8'), m);
const outline = () => [ ['a',0], ['b',1], ['c',2], ['d',1], ['e',0] ].map(([id,depth]) => ({id,depth,text:id,collapsed:false}));
const shape = n => n.map(x=>`${x.id}:${x.depth}`).join(',');
test('outdent a branch without adopting remaining siblings', () => {
    const n=outline(); m.indent(n,1,-1);
    assert.equal(shape(n),'a:0,d:1,b:0,c:1,e:0');
});
test('indent preserves descendants and opens new parent', () => {
    const n=outline(); n[0].collapsed=true; m.indent(n,4,1);
    assert.equal(shape(n),'a:0,b:1,c:2,d:1,e:1');
    assert.equal(n[0].collapsed,false);
});
test('moving a subtree swaps complete sibling branches', () => {
    const n=outline(); m.move(n,1,1);
    assert.equal(shape(n),'a:0,d:1,b:1,c:2,e:0');
    m.move(n,2,-1); assert.equal(shape(n),shape(outline()));
});
test('zoom and collapse expose the correct rows; search finds hidden descendants', () => {
    const n=outline(); n[1].collapsed=true;
    assert.equal(m.visible(n,'a','').map(x=>x.id).join(','),'b,d');
    assert.equal(m.visible(n,'a','c').map(x=>x.id).join(','),'c');
    assert.equal(m.visible(n,'b','')[0].depth,0);
});
test('reject malformed saved data instead of rewriting it', () => {
    for (const nodes of [[{id:'a',text:'a',depth:1,collapsed:false}], [{id:'a',text:'a',depth:0,collapsed:false},{id:'a',text:'b',depth:0,collapsed:false}]]) {
        assert.throws(()=>m.validate({version:1,nodes}));
    }
    assert.equal(m.validate({version:1,nodes:outline()}).length,5);
});

test('node colors survive serialization and remain visible after zoom', () => {
    const n=outline(); n[1].color='blue';
    const loaded=m.validate(JSON.parse(JSON.stringify({version:1,nodes:n})));
    assert.equal(m.visible(loaded,'a','')[0].color,'blue');
    assert.equal(m.visible(loaded,'a','')[2].color,'default');
    loaded[1].color='unknown';
    assert.throws(()=>m.validate({version:1,nodes:loaded}));
});
test('migrate the single outline into Inbox without losing nodes or colors', () => {
    const nodes=outline(); nodes[1].color='purple';
    const before=JSON.stringify(nodes);
    const ws=m.workspace({version:1,nodes});
    assert.equal(ws.version,2);
    assert.equal(ws.rolls.length,1);
    assert.equal(ws.rolls[0].name,'Inbox');
    assert.equal(ws.activeRollId,ws.rolls[0].id);
    assert.equal(JSON.stringify(ws.rolls[0].nodes),before);
});
test('Rolls keep separate branches and the active Roll across save/load', () => {
    const first=m.createRoll('First',outline()), second=m.createRoll('Second',outline());
    m.indent(second.nodes,4,1);
    const ws=m.workspace(JSON.parse(JSON.stringify({version:2,activeRollId:second.id,rolls:[first,second]})));
    assert.equal(ws.activeRollId,second.id);
    assert.equal(shape(ws.rolls[0].nodes),shape(outline()));
    assert.equal(shape(ws.rolls[1].nodes),'a:0,b:1,c:2,d:1,e:1');
});
test('reject empty workspaces, duplicate Roll IDs, invalid active Roll and corrupt outlines', () => {
    const r=m.createRoll('Inbox',outline());
    for (const data of [
        {version:2,rolls:[],activeRollId:''},
        {version:2,rolls:[r,r],activeRollId:r.id},
        {version:2,rolls:[r],activeRollId:'missing'},
        {version:2,rolls:[{...r,nodes:[{id:'bad',depth:3,text:'bad',collapsed:false}]}],activeRollId:r.id}
    ]) assert.throws(()=>m.workspace(data));
});
test('new nodes receive timestamps and edits preserve their creation time', () => {
    const n=m.node('new',0), created=n.createdAt;
    assert.ok(Number.isFinite(new Date(created).getTime()));
    assert.equal(n.updatedAt,created);
    m.touch([n],'2026-10-16T01:23:00.000Z');
    assert.equal(n.createdAt,created);
    assert.equal(n.updatedAt,'2026-10-16T01:23:00.000Z');
});
test('calendar collects all Rolls by local date and selected timestamp', () => {
    const day=new Date(2026,9,16,12).toISOString();
    const n=m.node('match',0); n.createdAt=day; n.updatedAt=new Date(2026,9,17,12).toISOString();
    const legacy=outline()[0];
    const rolls=[m.createRoll('A',[n]),m.createRoll('B',[{...n,id:'other',text:'second'},legacy])];
    assert.equal(m.activity(rolls,'2026-10-16','created').length,2);
    assert.equal(m.activity(rolls,'2026-10-16','updated').length,0);
    assert.equal(m.activity(rolls,'2026-10-17','updated').length,2);
    assert.equal(legacy.createdAt,undefined);
    assert.equal(m.dayKey(null),'');
    assert.equal(m.dayKey('invalid'),'');
});
test('calendar uses Monday-first grids, including leap day and year boundaries', () => {
    const feb=m.calendarDays(2024,1);
    assert.equal(feb.length,42);
    assert.equal(new Date(feb[0].key+'T12:00:00').getDay(),1);
    assert.ok(feb.some(d=>d.key==='2024-02-29' && d.current));
    assert.ok(m.calendarDays(2026,0).some(d=>d.key.startsWith('2025-')));
});
test('timestamps round-trip and invalid dates are rejected', () => {
    const n=m.node('timestamp',0);
    const ws=m.workspace(JSON.parse(JSON.stringify({version:2,rolls:[{id:'r',name:'Roll',nodes:[n]}],activeRollId:'r'})));
    assert.equal(ws.rolls[0].nodes[0].createdAt,n.createdAt);
    n.updatedAt='invalid';
    assert.throws(()=>m.validate({version:1,nodes:[n]}));
});
test('Roll emoji icons persist and older Rolls remain readable', () => {
    const roll=m.createRoll('Ideas',[]);
    assert.equal(roll.icon,'📄');
    roll.icon='🌱';
    const data=JSON.parse(JSON.stringify({version:2,activeRollId:roll.id,rolls:[roll]}));
    assert.equal(m.workspace(data).rolls[0].icon,'🌱');
    delete roll.icon;
    assert.equal(m.workspace({version:2,activeRollId:roll.id,rolls:[roll]}).rolls[0].icon,undefined);
    roll.icon=42;
    assert.throws(()=>m.workspace({version:2,activeRollId:roll.id,rolls:[roll]}));
});
test('archived Rolls retain content through saving and can be restored', () => {
    const r=m.createRoll('Archive',outline());r.archived=true;
    const ws=m.workspace(JSON.parse(JSON.stringify({version:2,rolls:[r],activeRollId:r.id})));
    assert.equal(ws.rolls[0].archived,true);
    assert.equal(ws.rolls[0].nodes.length,5);
    ws.rolls[0].archived=false;
    assert.equal(m.workspace(ws).rolls[0].archived,false);
    ws.rolls[0].archived='invalid';assert.throws(()=>m.workspace(ws));
});
test('delete only archived Rolls and always leave a usable workspace', () => {
    const a=m.createRoll('Keep',outline()), b=m.createRoll('Remove',outline());
    assert.throws(()=>m.removeArchived([a,b],b.id));
    b.archived=true;
    const kept=m.removeArchived([a,b],b.id);
    assert.equal(kept.length,1);assert.equal(kept[0].id,a.id);
    const fallback=m.removeArchived([b],b.id);
    assert.equal(fallback.length,1);assert.equal(fallback[0].name,'Inbox');
    assert.equal(fallback[0].archived,false);
});
test('nested calendar sorts newest first, paginates and collapses year/month', () => {
    const nodes=[];
    for(let i=1;i<=20;i++) { const n=m.node('day '+i,0);n.updatedAt=new Date(2026,9,i,12).toISOString(); nodes.push(n); }
    const rolls=[m.createRoll('Dates',nodes)];
    const tree=m.calendarTree(rolls,14,{},'updated');
    assert.equal(tree.total,20);
    assert.equal(tree.rows[0].label,'2026');
    assert.equal(tree.rows[1].label,'10');
    assert.equal(tree.rows[2].label,'20');
    const days=tree.rows.filter(r=>r.kind==='day');
    assert.equal(days.length,14);assert.equal(days[0].key,'2026-10-20');assert.equal(days[13].key,'2026-10-07');
    assert.equal(m.calendarTree(rolls,28,{},'updated').rows.filter(r=>r.kind==='day').length,20);
    assert.equal(m.calendarTree(rolls,14,{'2026':true},'updated').rows.length,1);
    assert.equal(m.calendarTree(rolls,14,{'2026-10':true},'updated').rows.length,2);
});
test('Today reuses one protected memopad per date and keeps past days', () => {
    const rolls=[];
    const today=m.ensureMemopad(rolls,'2026-10-16');today.nodes[0].text='journal';
    assert.equal(m.ensureMemopad(rolls,'2026-10-16').id,today.id);
    assert.equal(rolls.length,1);
    assert.equal(today.name,'memopad(2026-10-16)');
    m.ensureMemopad(rolls,'2026-10-17');
    assert.equal(rolls.length,2);assert.equal(rolls[0].nodes[0].text,'journal');
    assert.throws(()=>m.ensureMemopad(rolls,'2026-02-30'));
    assert.throws(()=>m.removeArchived(rolls,today.id));
    today.archived=true;
    assert.throws(()=>m.removeArchived(rolls,today.id));
    assert.throws(()=>m.workspace({version:2,rolls,activeRollId:today.id}));
});
test('memopads are separate from activity, but appear on their own calendar date', () => {
    const rolls=[],pad=m.ensureMemopad(rolls,'2026-10-16');
    pad.nodes[0].updatedAt=new Date(2026,9,18,12).toISOString();
    assert.equal(m.activity(rolls,'2026-10-18','updated').length,0);
    const tree=m.calendarTree(rolls,14,{},'updated');
    assert.equal(tree.rows.filter(r=>r.kind==='day')[0].key,'2026-10-16');
    const ws=m.workspace(JSON.parse(JSON.stringify({version:2,rolls,activeRollId:pad.id})));
    assert.equal(ws.rolls[0].memopadDate,'2026-10-16');
    ws.rolls.push({...ws.rolls[0],id:'duplicate'});
    assert.throws(()=>m.workspace(ws));
});
test('calendar can start fully folded and expand one level at a time', () => {
    const rolls=[];m.ensureMemopad(rolls,'2026-10-16');
    assert.equal(m.calendarTree(rolls,14,{},'updated',true).rows.length,1);
    assert.equal(m.calendarTree(rolls,14,{'2026':false},'updated',true).rows.length,2);
    assert.equal(m.calendarTree(rolls,14,{'2026':false,'2026-10':false},'updated',true).rows.length,3);
});
test('Roll input appends a blank root after all branches and reuses it on reopening', () => {
    const n=outline();const input=m.ensureInput(n,'');
    assert.equal(input.created,true);assert.equal(n[n.length-1].id,input.id);assert.equal(n[n.length-1].depth,0);
    assert.equal(m.ensureInput(n,'').created,false);assert.equal(n.length,6);
    n[n.length-1].text='written';assert.equal(m.ensureInput(n,'').created,true);
});
test('empty zoom creates a child inside that branch without disturbing following siblings', () => {
    const n=outline();const input=m.ensureInput(n,'c');
    assert.equal(input.created,true);
    const i=m.indexOf(n,input.id);assert.equal(n[i].depth,3);assert.equal(n[i+1].id,'d');
    assert.equal(m.visible(n,'c','')[0].id,input.id);
    assert.equal(m.ensureInput(n,'c').created,false);
    const empty=[];assert.equal(m.ensureInput(empty,'').created,true);assert.equal(empty[0].depth,0);
});

test('persistence round-trip preserves user text, IDs, and active Roll',()=>{
 const ws=m.initialWorkspace();
 ws.rolls[0].nodes[0].text='Flolinrへようこそ';
 const before=JSON.stringify(ws);
 const text=m.encodeWorkspace(ws.activeRollId,ws.rolls);
 const loaded=m.decodeWorkspace(text);
 assert.equal(loaded.needsSave,false);
 assert.equal(loaded.workspace.rolls[0].nodes[0].text,'Flolinrへようこそ');
 assert.equal(loaded.workspace.rolls[0].nodes[0].id,ws.rolls[0].nodes[0].id);
 assert.equal(loaded.workspace.activeRollId,ws.activeRollId);
 assert.equal(JSON.stringify(ws),before);
});
test('persistence rejects malformed input and invalid snapshots before writing',()=>{
 assert.throws(()=>m.decodeWorkspace('{broken'));
 assert.throws(()=>m.decodeWorkspace('{"version":99}'));
 const ws=m.initialWorkspace();
 assert.throws(()=>m.encodeWorkspace('missing',ws.rolls));
 ws.rolls[0].nodes[0].depth=4;
 assert.throws(()=>m.encodeWorkspace(ws.activeRollId,ws.rolls));
});
test('persistence flags v1 migration without translating user content',()=>{
 const loaded=m.decodeWorkspace(JSON.stringify({version:1,nodes:outline()}));
 assert.equal(loaded.needsSave,true);
 assert.equal(loaded.workspace.version,2);
 assert.equal(shape(loaded.workspace.rolls[0].nodes),shape(outline()));
});
