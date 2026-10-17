"""Exercise the real Quickshell FileView settings lifecycle in an isolated directory."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


@unittest.skipUnless(shutil.which('quickshell'), 'Quickshell is required')
class LanguageSettingsTests(unittest.TestCase):
    def test_legacy_default_save_and_reload_all_languages_preserve_other_settings(self):
        source = Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory(prefix='flolinr-language-test-') as directory:
            root = Path(directory)
            runtime = root / 'runtime'
            runtime.mkdir(mode=0o700)
            config = root / 'config'
            settings_path = config / 'flolinr/settings.json'
            settings_path.parent.mkdir(parents=True)
            workspace = root / 'outline.json'
            workspace.write_text('untouched user content')
            original = dict(dataPath=str(workspace), aiConnections=[dict(id='test', name='My 接続', provider='codex', model='', baseUrl='', executable='', command=[])], activeAiConnectionId='test')
            settings_path.write_text(json.dumps(original))  # Legacy settings have no language field.
            qml = root / 'shell.qml'
            qml.write_text('''import QtQuick
import Quickshell
import "''' + source.as_uri() + '''" as App
ShellRoot {
 App.AppSettings {
  id: settings
  onReadyChanged: if (ready) {
   if (language !== Quickshell.env("FLOLINR_TEST_EXPECT") || App.I18n.language !== language) {
    console.log("LANGUAGE_MISMATCH"); Qt.quit(); return;
   }
   console.log("PASS_LOADED");
   var next = Quickshell.env("FLOLINR_TEST_NEXT");
   if (next) save(dataPath, aiConnections, activeAiConnectionId, next);
   else Qt.quit();
  }
  onSaved: {
   if (language === Quickshell.env("FLOLINR_TEST_NEXT") && App.I18n.language === language)
    console.log("PASS_SAVED");
   Qt.quit();
  }
 }
 Timer { interval: 4000; running: true; onTriggered: Qt.quit(); }
}
''')
            def run(expected, next_language=''):
                result = subprocess.run(['quickshell', '-p', str(qml)], capture_output=True, text=True, timeout=8,
                    env=dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QPA_PLATFORMTHEME='', QT_QUICK_CONTROLS_STYLE='Basic',
                             XDG_CONFIG_HOME=str(config), XDG_RUNTIME_DIR=str(runtime),
                             FLOLINR_TEST_EXPECT=expected, FLOLINR_TEST_NEXT=next_language))
                output = result.stdout + result.stderr
                self.assertEqual(result.returncode, 0, output)
                self.assertIn('PASS_LOADED', output)
                if next_language:
                    self.assertIn('PASS_SAVED', output)
            current = 'en'
            for language in ('en', 'ja', 'zh-CN', 'zh-TW', 'ko', 'es', 'pt', 'fr', 'it'):
                run(current, language)
                saved = json.loads(settings_path.read_text())
                self.assertEqual(saved['language'], language)
                for key, value in original.items():
                    self.assertEqual(saved[key], value)
                run(language)
                self.assertEqual(workspace.read_text(), 'untouched user content')
                current = language
            settings_path.write_text(json.dumps(dict(original, language='unsupported')))
            run('en')


if __name__ == '__main__':
    unittest.main()
