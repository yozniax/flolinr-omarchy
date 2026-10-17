const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const european = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname, "../EuropeanTranslations.js"), "utf8"), european);
const catalog = {European: european};
vm.createContext(catalog);
vm.runInContext(fs.readFileSync(path.join(__dirname, '../Translations.js'), 'utf8').replace('.pragma library', '').replace(/^\.import.*$/m, ''), catalog);

test('all thirteen locales have complete catalogs and matching placeholders', () => {
 assert.equal(catalog.languages.length, 13);
 assert.ok(Object.keys(catalog.catalog).length >= 220);
 const placeholders = text => [...text.matchAll(/\{\d+\}/g)].map(m => m[0]).sort();
 for (const [source, values] of Object.entries(catalog.catalog)) {
  assert.equal(values.length, 8, source);
  for (const text of values) {
   assert.ok(typeof text === 'string' && text.trim(), source);
   assert.deepEqual(placeholders(text), placeholders(source), source);
  }
 }
});
test('legacy and unsupported locale settings fall back to English', () => {
 for (const value of [undefined, null, '', 'xx', 3]) assert.equal(catalog.normalize(value), 'en');
 assert.equal(catalog.translate('en', 'Node color'), 'Item color');
 assert.equal(catalog.translate('en', 'Connection test'), 'Test connection');
 assert.equal(catalog.translate('en', 'Settings · AI connections'), 'Settings');
 for (const entry of catalog.languages) assert.equal(catalog.normalize(entry.code), entry.code);
});
test('substitutions and user text remain literal; technical errors have a fallback', () => {
 assert.equal(catalog.translate('ja', 'Markdown saved: {0}', ['/tmp/{1} 日本語.md']), 'Markdownを保存しました：/tmp/{1} 日本語.md');
 assert.equal(catalog.translate('ja', 'unexpected provider diagnostic'), 'unexpected provider diagnostic');
 assert.equal(catalog.translate('ja', 'constructor'), 'constructor');
 assert.equal(catalog.translate('ja', 'Logged in · ChatGPT (this device)'), 'ログイン済み · ChatGPT（この端末）');
 assert.equal(catalog.translate('zh-TW', 'Saved'), '已儲存');
 assert.notEqual(catalog.translate('zh-CN', 'Saved'), catalog.translate('zh-TW', 'Saved'));
});
test('every literal translation call has all translations', () => {
 const names = fs.readdirSync(path.join(__dirname, '..')).filter(name => name.endsWith('.qml'));
 for (const name of names) {
  const source = fs.readFileSync(path.join(__dirname, '..', name), 'utf8');
  for (const match of source.matchAll(/I18n\.t\(("(?:[^"\\]|\\.)*")/g)) {
   const key = JSON.parse(match[1]);
   assert.ok(catalog.catalog[key], `${name}: ${key}`);
  }
 }
});
test('shortcut help descriptions are translated without changing keybindings', () => {
 const bindings = {}; vm.createContext(bindings);
 vm.runInContext(fs.readFileSync(path.join(__dirname, '../Keybindings.js'), 'utf8').replace('.pragma library', ''), bindings);
 for (const section of bindings.helpSections(bindings.resolve({}))) {
  assert.ok(catalog.catalog[section.title], section.title);
  for (const row of section.rows) assert.ok(catalog.catalog[row[1]], row[1]);
 }
});

test('additional catalogs are complete and language ordering cannot change translations',()=>{
 const codes=Array.from(catalog.languages,x=>x.code);
 assert.deepEqual(codes,['en','zh-CN','zh-TW','da','fr','de','it','ja','ko','pl','pt','ru','es']);
 const placeholders=text=>Array.from(text.matchAll(/\{\d+\}/g),m=>m[0]).sort();
 for(const code of ['da','de','ru','pl']) {
  for(const source of Object.keys(catalog.catalog)) {
   const text=european.catalog[code][source];assert.ok(text&&text.trim(),code+': '+source);
   assert.deepEqual(placeholders(text),placeholders(source),source);
   assert.equal(catalog.translate(code,source),text);
  }
 }
 assert.equal(catalog.translate('ja','Saved'),'保存済み');
 assert.equal(catalog.translate('de','Saved'),'Gespeichert');
 assert.equal(catalog.translate('ru','Saved'),'Сохранено');
});
