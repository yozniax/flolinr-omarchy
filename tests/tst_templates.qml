import QtQuick
import QtTest
import ".." as App
import "../Templates.js" as Templates

TestCase {
 id:tests;name:"Templates";when:windowShown;visible:true;width:700;height:650
 QtObject {
  id:mock
  property var templates:Templates.normalize(Templates.defaults)
  property string error:""
  signal saved()
  function saveTemplates(value) { templates=Templates.normalize(value);saved();return true; }
 }
 App.TemplateManager { id:manager;parent:tests;settings:mock }
 function cleanup() { manager.close();mock.templates=Templates.normalize(Templates.defaults); }
 function test_edit_save_reopen_and_cancel() {
  manager.show();findChild(manager,"templateName").text="My plan";
  findChild(manager,"templateBody").text="First\n  [ ] Nested task";
  manager.save();compare(mock.templates[0].name,"My plan");compare(mock.templates[0].items[1][0],2);
  manager.show();compare(findChild(manager,"templateName").text,"My plan");
  findChild(manager,"templateName").text="Unsaved";manager.close();compare(mock.templates[0].name,"My plan");
 }
 function test_invalid_nesting_is_rejected_without_saving() {
  manager.show();findChild(manager,"templateBody").text="First\n      Skipped levels";
  manager.save();verify(manager.opened);verify(manager.message.length>0);compare(mock.templates.length,3);
 }
 function test_selection_commits_previous_template() {
  manager.show();findChild(manager,"templateName").text="Edited first";
  var picker=findChild(manager,"templatePicker");picker.currentIndex=1;picker.activated(1);
  compare(manager.drafts[0].name,"Edited first");compare(findChild(manager,"templateName").text,"Daily review");
 }
}
