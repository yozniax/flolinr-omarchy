import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

@unittest.skipUnless(shutil.which('quickshell'), 'Quickshell is required')
class TemplateSettingsTests(unittest.TestCase):
 def test_templates_persist_and_preserve_pending_workspace_path(self):
  source=Path(__file__).resolve().parents[1]
  with tempfile.TemporaryDirectory(prefix='flolinr-templates-') as directory:
   root=Path(directory);(root/'runtime').mkdir(mode=0o700);(root/'config/flolinr').mkdir(parents=True)
   path=root/'config/flolinr/settings.json'
   initial=dict(dataPath=str(root/'old.json'),language='de',aiConnections=[],activeAiConnectionId='')
   path.write_text(json.dumps(initial))
   config=root/'shell.qml'
   config.write_text('''import QtQuick
import Quickshell
import "'''+source.as_uri()+'''" as App
ShellRoot {
 property int stage:0
 App.AppSettings {
  id:settings
  onReadyChanged: if(ready) {
   if(Quickshell.env("CHECK_ONLY")==="1") {
    if(templates.length===1 && templates[0].name==="My template") console.log("PASS_REOPEN");Qt.quit();
   } else save("'''+str(root/'new.json')+'''",aiConnections,activeAiConnectionId,language);
  }
  onSaved: {
   if(stage===0) {stage=1;saveTemplates([{name:"My template",title:"My template",items:[[1,"One"],[2,"[ ] Nested"]]}]);}
   else {console.log("PASS_SAVED");Qt.quit();}
  }
 }
 Timer { interval:3000;running:true;onTriggered:Qt.quit(); }
}
''')
   for check in ('0','1'):
    result=subprocess.run(['quickshell','-p',str(config)],capture_output=True,text=True,timeout=5,
      env=dict(os.environ,QT_QPA_PLATFORM='offscreen',QT_QPA_PLATFORMTHEME='',QT_QUICK_CONTROLS_STYLE='Basic',
       XDG_RUNTIME_DIR=str(root/'runtime'),XDG_CONFIG_HOME=str(root/'config'),CHECK_ONLY=check))
    output=result.stdout+result.stderr
    self.assertEqual(result.returncode,0,output)
    self.assertIn('PASS_REOPEN' if check=='1' else 'PASS_SAVED',output)
   saved=json.loads(path.read_text())
   self.assertEqual(saved['dataPath'],str(root/'new.json'))
   self.assertEqual(saved['language'],'de')
   self.assertEqual(saved['templates'][0]['name'],'My template')
   self.assertEqual(saved['aiConnections'],[])

if __name__=='__main__':unittest.main()
