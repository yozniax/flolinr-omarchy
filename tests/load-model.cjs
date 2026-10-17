const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

module.exports = function loadModel() {
    const starter = vm.createContext({});
    vm.runInContext(fs.readFileSync(path.join(__dirname, '../StarterContent.js'), 'utf8'), starter);
    const model = vm.createContext({StarterContent: starter});
    const source = fs.readFileSync(path.join(__dirname, '../Model.js'), 'utf8');
    vm.runInContext(source.replace(/^\.import "StarterContent.js" as StarterContent\s*/m, ''), model);
    return model;
};
