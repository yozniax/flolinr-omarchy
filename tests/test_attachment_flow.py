"""Real outliner -> bridge -> fake CLI -> protected application -> workspace save."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


@unittest.skipUnless(shutil.which('quickshell'), 'Quickshell is required')
class AttachmentFlowTests(unittest.TestCase):
    def test_real_outliner_never_sends_embedded_source_and_restores_it_on_apply(self):
        source = Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory(prefix='flolinr-attachment-flow-') as directory:
            root = Path(directory)
            (root/'runtime').mkdir(mode=0o700)
            (root/'config/flolinr').mkdir(parents=True)
            fake_cli = root/'fake_cli.py'
            fake_cli.write_text('''import os,re,sys
prompt=sys.stdin.read()
assert 'TOPSECRET_INSERTED' not in prompt
assert 'secret.html' not in prompt
assert not os.listdir('.')
tokens=re.findall(r'\\[FLOLINR_PROTECTED_[a-z0-9_]+\\]',prompt)
assert len(tokens)==1
assert 'Keep every token exactly once' in prompt
print('- AI heading\\n  - '+tokens[0])
''')
            profile=dict(id='fake',name='Fake CLI',provider='custom',model='',baseUrl='',executable='',command=['python3',str(fake_cli)])
            settings=dict(dataPath=str(root/'outline.json'),language='en',aiConnections=[profile],activeAiConnectionId='fake')
            (root/'config/flolinr/settings.json').write_text(json.dumps(settings))
            qml = root/'shell.qml'
            qml.write_text('''import QtQuick
import Quickshell
import "''' + source.as_uri() + '''" as App
import "''' + (source/'Model.js').as_uri() + '''" as Model
ShellRoot {
 id: test
 property var features: null
 property string original: "  <div>TOPSECRET_INSERTED</div>\\n\\t<script>neverExecute()</script>\\r\\n"
 App.Outliner { id: app; manifest: ({id:"yozniax.flolinr",version:"test"}) }
 Timer {
  interval: 150; running: true; repeat: true
  onTriggered: {
   if (!app.ready) return;
   stop();
   app.nodes=[Model.node("Heading",0),Model.node("/insert",1)]; app.zoom=""; app.refresh();
   app.insertAttachment({kind:"code",name:"secret.html",mime:"text/plain",language:"html",content:test.original},"",app.nodes[1].id,"/insert");
   app.children.forEach(function(child) { if (typeof child.generateAI === "function") test.features=child; });
   if (!test.features) { console.log("FAIL_NO_CONTROLLER"); Qt.quit(); return; }
   test.features.generateAI("summarize");
  }
 }
 Connections {
  target: test.features
  function onResult(text) {
   test.features.applyAI(text);
  }
  function onFailure(text) { console.log("FAIL",text); Qt.quit(); }
  function onDone() {
   if (app.nodes.length===2 && app.nodes[0].text==="AI heading" && app.nodes[1].attachment.content===test.original && app.nodes[1].depth===1)
    console.log("PASS_PROTECTED_APPLY");
   app.save(); Qt.quit();
  }
 }
 Timer { interval: 5000; running: true; onTriggered: Qt.quit(); }
}
''')
            result = subprocess.run(['quickshell','-p',str(qml)],capture_output=True,text=True,timeout=9,
                env=dict(os.environ,QT_QPA_PLATFORM='offscreen',QT_QPA_PLATFORMTHEME='',QT_QUICK_CONTROLS_STYLE='Basic',
                         QML_IMPORT_PATH=str(source/'tests/fixtures'),XDG_RUNTIME_DIR=str(root/'runtime'),XDG_CONFIG_HOME=str(root/'config')))
            output=result.stdout+result.stderr
            self.assertEqual(result.returncode,0,output)
            self.assertIn('PASS_PROTECTED_APPLY',output)
            workspace=json.loads((root/'outline.json').read_text())
            nodes=workspace['rolls'][0]['nodes']
            self.assertEqual(nodes[0]['text'],'AI heading')
            self.assertEqual(nodes[1]['attachment']['content'],'  <div>TOPSECRET_INSERTED</div>\n\t<script>neverExecute()</script>\r\n')


if __name__=='__main__': unittest.main()
