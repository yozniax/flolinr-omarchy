import QtQuick
import QtQuick.Controls
import QtTest
import QtQuick.Window
import QtQuick.Dialogs as Dialogs
import ".." as App

TestCase {
    id: tests
    name: "AIConnections"
    when: windowShown
    width: 700
    height: 760
    QtObject {
        id: controller
        property bool busy: false
        property var aiConnections: []
        property string activeAiConnectionId: ""
        property var activeConnection: null
        property string homePath: "/home/user"
        property string dataPath: "/tmp/outline.json"
        property string scopeLabel: "Example branch"
        property string aiBefore: ""
        property var checked: null
        function checkAI(p) { checked = p; }
        function testAI(p, key) {}
        function loginAI(p) {}
        function deleteKey(p) {}
        function saveSettings(path, connections, activeId, draft, key) {}
    }
    App.FeaturePanel { id: panel; parent: tests; controller: controller }
    function cleanup() { panel.close(); controller.aiConnections = []; controller.activeConnection = null; controller.activeAiConnectionId = ""; }
    function test_unconfigured_routes_to_settings_and_does_not_select_provider() {
        panel.show("ai");
        compare(panel.mode, "settings"); compare(panel.selectedId, "");
        verify(findChild(panel, "aiMessage").text.includes("Choose"));
        compare(findChild(panel, "aiConnectionPicker").currentIndex, 0);
    }
    function test_add_switch_and_secret_is_not_part_of_draft() {
        panel.show("settings"); panel.addConnection("codex");
        compare(panel.selected.provider, "codex");
        var codex = panel.selectedId;
        panel.addConnection("openai"); panel.update("model", "my-model");
        compare(panel.drafts.length, 2);
        var key = findChild(panel, "aiApiKey"); key.text = "SECRET";
        verify(!JSON.stringify(panel.drafts).includes("SECRET"));
        panel.choose(codex); compare(key.text, "");
        compare(panel.selected.provider, "codex");
        panel.close(); compare(key.text, "");
    }
    function test_ai_dialog_identifies_the_entire_current_body_scope() {
        controller.activeConnection = {name: "Test Codex", provider: "codex", model: ""};
        controller.scopeLabel = "My Roll · entire Roll";
        panel.show("ai");
        compare(panel.mode, "ai"); compare(panel.title, "AI · current view");
        compare(panel.scopeLabel, "My Roll · entire Roll");
        panel.close(); controller.scopeLabel = "Zoom heading · entire zoomed branch";
        panel.show("ai"); compare(panel.scopeLabel, "Zoom heading · entire zoomed branch");
    }
    function test_workspace_picker_uses_safe_backend_and_cancellation_keeps_path() {
        panel.show("settings");
        var field = findChild(panel,"workspacePath");
        var picker = findChild(panel,"workspaceFilePicker");
        var before = field.text;
        panel.browseWorkspace();
        compare(picker.parentWindow,tests.Window.window);
        compare(picker.fileMode,Dialogs.FileDialog.SaveFile);
        compare(picker.defaultSuffix,"json");
        verify((picker.options & Dialogs.FileDialog.DontUseNativeDialog) !== 0);
        verify((picker.options & Dialogs.FileDialog.DontConfirmOverwrite) !== 0);
        tryCompare(picker,"visible",true);
        picker.reject();
        compare(field.text,before); verify(panel.opened);
    }
    function test_workspace_picker_accepts_unicode_and_special_characters_as_draft_only() {
        panel.show("settings");
        var picker = findChild(panel,"workspaceFilePicker");
        var field = findChild(panel,"workspacePath");
        picker.selectedFile = "file:///tmp/notes%20%E6%97%A5%E6%9C%AC%E8%AA%9E%23%25.json";
        picker.accepted();
        compare(field.text,"/tmp/notes 日本語#%.json");
        compare(controller.dataPath,"/tmp/outline.json");
        verify(panel.opened);
    }
    function test_workspace_picker_uses_typed_path_and_closes_with_settings() {
        panel.show("settings");
        var picker = findChild(panel,"workspaceFilePicker");
        findChild(panel,"workspacePath").text="~/notes/new file.json";
        panel.browseWorkspace();
        compare(picker.selectedFile.toString(),"file:///home/user/notes/new file.json");
        panel.close(); tryCompare(picker,"visible",false);
    }
    function test_saved_connection_loads_and_form_fits_window() {
        controller.aiConnections = [{id:"local",name:"Local",provider:"ollama",model:"local-model",baseUrl:"http://localhost:11434",executable:"",command:[]}];
        controller.activeAiConnectionId = "local";
        panel.show("settings");
        compare(findChild(panel,"aiModel").text, "local-model");
        compare(findChild(panel,"aiBaseUrl").text, "http://localhost:11434");
        compare(controller.checked.id,"local");
        verify(panel.height <= tests.height);
        panel.contentItem.grabToImage(function(result) { result.saveToFile("/tmp/flolinr-ai-settings.png"); });
        wait(100);
    }
}
