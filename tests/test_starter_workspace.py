"""Exercise actual first-run seeding and reopening through WorkspaceStore."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


@unittest.skipUnless(shutil.which('quickshell'), 'Quickshell is required')
class StarterWorkspaceTests(unittest.TestCase):
    def test_seed_once_and_preserve_user_removal_on_restart(self):
        source = Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory(prefix='flolinr-starter-') as directory:
            root = Path(directory)
            (root/'runtime').mkdir(mode=0o700)
            workspace = root/'notes.json'
            for expected, remove in [(5, False), (5, True), (4, False)]:
                config = root/'shell.qml'
                config.write_text('''import QtQuick
import Quickshell
import "''' + source.as_uri() + '''" as App
ShellRoot {
 App.WorkspaceStore {
  id: store
  active: true
  path: "''' + str(workspace) + '''"
  onWorkspaceLoaded: function(value, needsSave) {
   if (value.rolls.length !== ''' + str(expected) + ''') { console.log("FAIL_COUNT",value.rolls.length); Qt.quit(); return; }
   console.log("PASS_LOADED",value.rolls.length,needsSave);
   if (''' + str(remove).lower() + ''') value.rolls.pop();
   if (needsSave || ''' + str(remove).lower() + ''') store.write(value.activeRollId,value.rolls);
   Qt.callLater(Qt.quit);
  }
  onFailed: function(message) { console.log("FAIL_STORE",message); Qt.quit(); }
 }
 Timer { interval: 3000; running: true; onTriggered: Qt.quit(); }
}
''')
                result = subprocess.run(['quickshell', '-p', str(config)],capture_output=True,text=True,timeout=5,
                    env=dict(os.environ,QT_QPA_PLATFORM='offscreen',QT_QPA_PLATFORMTHEME='',QT_QUICK_CONTROLS_STYLE='Basic',
                             QML_IMPORT_PATH=str(source/'tests/fixtures'),XDG_RUNTIME_DIR=str(root/'runtime')))
                output=result.stdout+result.stderr
                self.assertEqual(result.returncode,0,output)
                self.assertIn('PASS_LOADED',output)
                self.assertNotIn('FAIL_',output)
            saved=json.loads(workspace.read_text())
            self.assertEqual(len(saved['rolls']),4)
            self.assertEqual(saved['rolls'][0]['name'],'01 Getting Started')


if __name__ == '__main__': unittest.main()
