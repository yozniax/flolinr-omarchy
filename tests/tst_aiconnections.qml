import QtQuick
import QtQuick.Controls
import QtTest
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
