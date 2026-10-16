const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const a = {}; vm.createContext(a); vm.runInContext(fs.readFileSync(require('node:path').join(__dirname, '../AiSettings.js'), 'utf8').replace('.pragma library', ''), a);
const plain = x => JSON.parse(JSON.stringify(x));
test('new users have no implicit provider and legacy custom CLI is preserved', () => {
 assert.deepEqual(plain(a.migrate({})), {aiConnections: [], activeAiConnectionId: ''});
 const legacy = a.migrate({aiCommand: ['custom', '-p']});
 assert.equal(legacy.aiConnections[0].provider, 'custom');
 assert.deepEqual(plain(legacy.aiConnections[0].command), ['custom', '-p']);
});
test('multiple connections validate and unknown settings never retain API keys', () => {
 const c = a.defaults('codex', 'codex'); const o = {...a.defaults('openai', 'api'), model: 'my-model', apiKey: 'secret'};
 const v = a.validate({aiConnections: [c,o], activeAiConnectionId: 'api'});
 assert.equal(v.aiConnections.length, 2); assert.equal(a.active(v.aiConnections, 'api').model, 'my-model');
 assert.ok(!JSON.stringify(v).includes('secret')); assert.equal(a.active(v.aiConnections, ''), null);
});
test('reject invalid profiles, missing API model, duplicate IDs and missing active connection', () => {
 const c = a.defaults('codex', 'c');
 for (const v of [{aiConnections:[c,c]}, {aiConnections:[a.defaults('openai','o')]}, {activeAiConnectionId:'missing'}, {aiConnections:[{...c, provider:'unknown'}]}, {aiConnections:[{...c,id:'bad/id'}]}]) assert.throws(()=>a.validate(v));
});
