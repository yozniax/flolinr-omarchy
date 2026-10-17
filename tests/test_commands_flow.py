"""Run slash actions through the actual outliner and persist their results."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


@unittest.skipUnless(shutil.which('quickshell'), 'Quickshell is required')
class CommandFlowTests(unittest.TestCase):
    def test_commands_and_link_jump_(self):
        source=Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory(prefix='flolinr-command-flow-') as directory:
            root=Path(directory)
            (root/'runtime').mkdir(mode=0o700)
            (root/'config/flolinr').mkdir(parents=True)
            (root/'config/flolinr/settings.json').write_text(json.dumps(dict(dataPath=str(root/'notes.json'),language='en',
                aiConnections=[dict(id='test',name='Test',provider='codex',model='',baseUrl='',executable='',command=[])],activeAiConnectionId='test')))
            config=root/'shell.qml'
            config.write_text('''import QtQuick
import Quickshell
import "''' + source.as_uri() + '''" as App
import "''' + (source/'Model.js').as_uri() + '''" as Model
import "''' + (source/'CommandActions.js').as_uri() + '''" as Commands
ShellRoot {
 App.Outliner { id: app; manifest: ({id:"yozniax.flolinr",version:"test"}) }
 Timer {
  interval: 100; running: true; repeat: true
  onTriggered: {
   if (!app.ready) return;
   stop();
   try {
    var nodes=[Model.node("Outside scope",0),Model.node("[ ] Task",1),Model.node("/date",1),Model.node("/link",1),Model.node("/template",1),Model.node("Plain note",1),Model.node("/ai",1),Model.node("Inside AI scope",2)];
    var ids=nodes.map(function(n) { return n.id; });
    var first=Model.createRoll("Commands",nodes),other=Model.createRoll("Reference",[Model.node("Link destination",0)]);
    app.rolls=[first,other];app.activeRollId=first.id;app.nodes=nodes;app.zoom="";app.refresh();
    app.toggleTodo(ids[1]);
    if (app.nodes[1].text!=="[x] ") throw new Error("todo state");
    app.history(false);if (app.nodes[1].text!=="[ ] ") throw new Error("todo undo");
    app.history(true);if (app.nodes[1].text!=="[x] ") throw new Error("todo redo");
    app.applySlashCommand(ids[2],"date","/date","2026-10-17");
    app.applySlashCommand(ids[3],"link","/link",{rollId:other.id,nodeId:other.nodes[0].id});
    var link=Commands.parseLink(app.nodes[3].text);
    app.followInternalLink(link);
    if (app.activeRollId!==other.id || app.zoom!==other.nodes[0].id) throw new Error("link jump");
    app.selectRoll(first.id,false);app.zoom="";
    app.applySlashCommand(ids[4],"template","/template",0);
    app.openSlashCommand(ids[6],"ai");
    app.save();console.log("PASS_COMMANDS_AND_SCOPE");Qt.quit();
   } catch (e) { console.log("FAIL_COMMANDS",e.message);Qt.quit(); }
  }
 }
 Timer { interval: 4000; running: true; onTriggered: Qt.quit(); }
}
''')
            result=subprocess.run(['quickshell','-p',str(config)],capture_output=True,text=True,timeout=6,
                env=dict(os.environ,QT_QPA_PLATFORM='offscreen',QT_QPA_PLATFORMTHEME='',QT_QUICK_CONTROLS_STYLE='Basic',
                         QML_IMPORT_PATH=str(source/'tests/fixtures'),XDG_RUNTIME_DIR=str(root/'runtime'),XDG_CONFIG_HOME=str(root/'config')))
            output=result.stdout+result.stderr
            self.assertEqual(result.returncode,0,output)
            self.assertIn('PASS_COMMANDS_AND_SCOPE',output)
            self.assertNotIn('FAIL_COMMANDS',output)
            saved=json.loads((root/'notes.json').read_text())
            items=saved['rolls'][0]['nodes']
            self.assertTrue(any(n['text']=='[x] ' for n in items))
            self.assertTrue(any(n['text']=='Meeting notes' for n in items))
            self.assertTrue(any(n['text']=='2026-10-17' for n in items))


if __name__ == '__main__': unittest.main()
