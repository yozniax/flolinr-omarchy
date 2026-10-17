import tempfile,os,subprocess,pathlib,json,unittest,shutil

@unittest.skipUnless(shutil.which("quickshell"),"Quickshell is required")
class CommandFocusTests(unittest.TestCase):
    def test_date_dialog_restores_actual_editor_focus(self):
        source=pathlib.Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory(prefix='flolinr-focus-') as d:
         r=pathlib.Path(d);(r/'runtime').mkdir(mode=0o700);(r/'config/flolinr').mkdir(parents=True);(r/'config/flolinr/settings.json').write_text(json.dumps(dict(dataPath=str(r/'notes.json'))))
         q=r/'shell.qml';q.write_text('''import QtQuick
        import Quickshell
        import QtTest
        import "'''+source.as_uri()+'''" as App
        import "'''+(source/'Model.js').as_uri()+'''" as Model
        ShellRoot {
         id:test
         TestCase {id:helper;when:false}
         property int step:0
         property string itemId:""
         App.Outliner { id:app;manifest:({id:"yozniax.flolinr",version:"test"}) }
         function walk(obj) {
          if (obj.activeFocus===true) console.log("ACTIVE",obj.objectName,obj.toString());
          if (obj.children) obj.children.forEach(walk);
          if (obj.contentItem) walk(obj.contentItem);
         }
         Timer { interval:200;running:true;repeat:true;onTriggered:{
          if (!app.ready) return;
          if (test.step===0) {app.open();app.nodes=[Model.node("/date",0)];test.itemId=app.nodes[0].id;app.zoom="";app.refresh();app.openSlashCommand(test.itemId,"date");test.step=1;}
          else if (test.step===1) {var dlg=null;function find(o){if(o.objectName==="slashCommandDialog")dlg=o;if(o.children)o.children.forEach(find);}dlg=helper.findChild(app,"slashCommandDialog");dlg.submit("2026-10-17");test.step=2;}
          else {console.log("FOCUSED_NODE",app.focusedNode===test.itemId,"PENDING",app.pendingFocus);var l=helper.findChild(app,"outlineList");var row=l ? l.itemAtIndex(l.currentIndex) : null;var e=row ? helper.findChild(row,"outlineEditor") : null;console.log("EDITOR_FOCUS",e ? e.activeFocus : "missing");app.save();Qt.quit();}
         }}
         Timer {interval:4000;running:true;onTriggered:Qt.quit();}
        }
        ''')
         p=subprocess.run(['quickshell','-p',str(q)],capture_output=True,text=True,timeout=6,env=dict(os.environ,QT_QPA_PLATFORM='offscreen',QT_QPA_PLATFORMTHEME='',QT_QUICK_CONTROLS_STYLE='Basic',QML_IMPORT_PATH=str(source/'tests/fixtures'),XDG_RUNTIME_DIR=str(r/'runtime'),XDG_CONFIG_HOME=str(r/'config')))
         output=p.stdout+p.stderr
         self.assertEqual(p.returncode,0,output)
         self.assertIn("EDITOR_FOCUS true",output)
         self.assertNotIn("TypeError",output)

if __name__=="__main__":unittest.main()
