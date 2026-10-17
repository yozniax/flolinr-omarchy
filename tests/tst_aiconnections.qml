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
        property string language: "en"
        property string scopeLabel: "Example branch"
        property string aiBefore: ""
        property string aiTask: ""
        property bool aiPreviewReady: false
        property var generated: null
        property string expansionInstructions: ""
        property var markdownSave: null
        signal markdownSaved(string path)
        function generateAI(task, instructions) { generated = task; expansionInstructions = instructions || ""; aiTask = task; aiPreviewReady = false; aiBefore = "snapshot"; }
        function saveMarkdown(path, text) { markdownSave = {path: path, text: text}; }
        property var checked: null
        function checkAI(p) { checked = p; }
        function testAI(p, key) {}
        function loginAI(p) {}
        function deleteKey(p) {}
        function saveSettings(path, connections, activeId, draft, key, language) { controller.language = language; App.I18n.language = language; }
    }
    App.FeaturePanel { id: panel; parent: tests; controller: controller }
    function cleanup() { panel.close(); controller.aiConnections = []; controller.activeConnection = null; controller.activeAiConnectionId = ""; controller.language = "en"; App.I18n.language = "en"; tests.width = 700; }
    function test_multilingual_ai_actions_wrap_in_a_narrow_window() {
        tests.width = 420;
        controller.activeConnection = {name: "Test", provider: "codex"};
        for (var i = 0; i < App.I18n.languages.length; ++i) {
            App.I18n.language = App.I18n.languages[i].code;
            panel.show("ai"); wait(20);
            var convert = findChild(panel, "aiConvertMarkdown");
            verify(convert.x + convert.width <= convert.parent.width + 1, App.I18n.language);
            verify(convert.y + convert.height <= convert.parent.height + 1, App.I18n.language);
            if (App.I18n.language === "ja" || App.I18n.language === "fr") {
                var target = "/tmp/flolinr-ai-" + App.I18n.language + ".png";
                panel.contentItem.grabToImage(function(result) { result.saveToFile(target); });
                wait(50);
            }
            panel.close();
        }
    }
    function test_expand_waits_for_optional_prompt_and_sends_it_only_to_expand() {
        controller.activeConnection = {name: "Test", provider: "codex"};
        controller.generated = null;
        panel.show("ai");
        findChild(panel, "aiExpand").clicked();
        compare(controller.generated, null); verify(panel.expandPromptVisible);
        var field = findChild(panel, "aiExpandPrompt");
        field.text = "具体例を3つ追加して\nKeep the original structure.";
        findChild(panel, "aiGenerateExpansion").clicked();
        compare(controller.generated, "expand");
        compare(controller.expansionInstructions, field.text);
        panel.generate("summarize"); compare(controller.expansionInstructions, "");
        verify(!panel.expandPromptVisible);
        panel.configureExpansion(); field.text = "";
        findChild(panel, "aiGenerateExpansion").clicked();
        compare(controller.generated, "expand"); compare(controller.expansionInstructions, "");
        field.text = "private instructions";
        panel.close(); compare(field.text, "");
    }
    function test_language_selection_applies_on_save_and_is_restored_when_reopened() {
        panel.show("settings");
        var picker = findChild(panel, "languagePicker");
        var action = findChild(panel, "aiPreviewAction");
        compare(picker.currentIndex, 0); compare(picker.count, 13);
        picker.currentIndex = 1;
        compare(App.I18n.language, "en");
        panel.close(); panel.show("settings"); compare(picker.currentIndex, 0);
        for (var i = 0; i < App.I18n.languages.length; ++i) {
            picker.currentIndex = i;
            action.clicked();
            compare(controller.language, App.I18n.languages[i].code);
            compare(panel.title, "⚙️ " + App.I18n.t("Settings · AI connections"));
            compare(action.text, App.I18n.t("Save settings"));
            panel.close(); panel.show("settings"); compare(picker.currentIndex, i);
        }
    }
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
        compare(panel.mode, "ai"); compare(panel.title, "✨ AI · current view");
        compare(panel.scopeLabel, "My Roll · entire Roll");
        panel.close(); controller.scopeLabel = "Zoom heading · entire zoomed branch";
        panel.show("ai"); compare(panel.scopeLabel, "Zoom heading · entire zoomed branch");
    }
    function test_markdown_preview_download_and_cancellation_preserve_outline() {
        controller.activeConnection = {name: "Test", provider: "codex"};
        panel.show("ai");
        panel.generate("markdown");
        compare(controller.generated, "markdown");
        var action = findChild(panel, "aiPreviewAction");
        var preview = findChild(panel, "aiPreview");
        compare(action.text, "Save Markdown…"); verify(!action.enabled);
        panel.showResult("# Title\n\n| A | B |\n|---|---|\n| 1 | 2 |\n\n```js\nx()\n```");
        controller.aiPreviewReady = true;
        verify(action.enabled);
        var text = preview.text;
        var picker = findChild(panel, "aiMarkdownPicker");
        panel.downloadMarkdown();
        compare(picker.parentWindow, tests.Window.window);
        compare(picker.fileMode, Dialogs.FileDialog.SaveFile);
        compare(picker.defaultSuffix, "md");
        verify((picker.options & Dialogs.FileDialog.DontUseNativeDialog) !== 0);
        tryCompare(picker, "visible", true); picker.reject();
        compare(preview.text, text); verify(panel.opened);
        picker.selectedFile = "file:///tmp/%E6%97%A5%E6%9C%AC%E8%AA%9E.md";
        picker.accepted();
        compare(controller.markdownSave.text, text);
        verify(controller.markdownSave.path.endsWith(".md"));
        controller.markdownSaved("/tmp/日本語.md");
        compare(preview.text, text);
        verify(findChild(panel, "aiMessage").text.includes("Markdown saved"));
        panel.generate("summarize");
        compare(preview.text, ""); compare(action.text, "Apply preview"); verify(!action.enabled);
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
