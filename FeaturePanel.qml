import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Dialogs as Dialogs
import "AiSettings.js" as AI
import qs.Commons as Commons

CompactDialog {
    id: root
    required property var controller
    signal editTemplatesRequested()
    property string mode: "settings"
    property var drafts: []
    property string selectedId: ""
    property bool loading: false
    property string scopeLabel: ""
    property bool expandPromptVisible: false
    readonly property var selected: AI.active(drafts, selectedId)
    readonly property bool isCLI: selected && ["codex", "claude", "custom"].indexOf(selected.provider) >= 0
    readonly property bool isAPI: selected && !isCLI
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(600, parent ? parent.width - 32 : 600)
    height: Math.min(mode === "ai" ? (expandPromptVisible ? 620 : 500) : 650, parent ? parent.height - 32 : 650)
    palette.base: Qt.lighter(Commons.Color.background, 1.3)
    palette.button: Qt.lighter(Commons.Color.background, 1.5)
    palette.highlight: Commons.Color.accent
    modal: true
    focus: true
    title: mode === "ai" ? "✨ " + I18n.t("AI · current view") : "⚙️ " + I18n.t("Settings · AI connections")
    standardButtons: Dialog.NoButton
    closePolicy: controller.busy || workspacePicker.visible || markdownPicker.visible ? Popup.NoAutoClose : Popup.CloseOnEscape
    onClosed: { workspacePicker.close(); markdownPicker.close(); key.clear(); expandPrompt.clear(); expandPromptVisible = false; controller.aiBefore = ""; controller.aiPreviewReady = false; }
    function show(mode) {
        if (controller.busy) return;
        root.mode = mode === "ai" && !controller.activeConnection ? "settings" : mode;
        message.text = root.mode !== mode ? I18n.t("Choose and save an AI connection first.") : "";
        preview.clear(); key.clear(); expandPrompt.clear(); expandPromptVisible = false; status.text = "";
        scopeLabel = controller.scopeLabel;
        controller.aiBefore = "";
        controller.aiPreviewReady = false;
        path.text = controller.dataPath;
        languagePicker.currentIndex = Math.max(0, I18n.languages.map(function(entry) { return entry.code; }).indexOf(controller.language || "en"));
        drafts = JSON.parse(JSON.stringify(controller.aiConnections));
        choose(controller.activeAiConnectionId || (drafts.length ? drafts[0].id : ""));
        open();
    }
    function localFileUrl(value) {
        return "file://" + value.split("/").map(function(part) { return encodeURIComponent(part); }).join("/");
    }
    function generate(task) {
        if (controller.busy) return;
        if (task !== "expand") expandPromptVisible = false;
        preview.clear(); message.text = "";
        scopeLabel = controller.scopeLabel;
        controller.generateAI(task, task === "expand" ? expandPrompt.text : "");
    }
    function configureExpansion() {
        if (controller.busy) return;
        preview.clear(); message.text = "";
        controller.aiBefore = ""; controller.aiPreviewReady = false;
        expandPromptVisible = true;
        Qt.callLater(function() { expandPrompt.forceActiveFocus(); });
    }
    function downloadMarkdown() {
        if (controller.busy || !controller.aiPreviewReady || controller.aiTask !== "markdown" || !preview.text.trim()) return;
        markdownPicker.open();
    }
    Connections {
        target: root.controller
        function onMarkdownSaved(path) { message.text = I18n.t("Markdown saved: {0}", [path]); }
    }
    Dialogs.FileDialog {
        id: markdownPicker
        objectName: "aiMarkdownPicker"
        parentWindow: root.parent ? root.parent.Window.window : null
        title: "📤 " + I18n.t("Save AI Markdown")
        fileMode: Dialogs.FileDialog.SaveFile
        options: Dialogs.FileDialog.DontUseNativeDialog
        nameFilters: ["Markdown (*.md)"]
        defaultSuffix: "md"
        onAccepted: root.controller.saveMarkdown(selectedFile.toString(), preview.text)
    }
    function browseWorkspace() {
        if (controller.busy) return;
        var value = path.text;
        if (value.startsWith("~/")) value = String(controller.homePath) + value.slice(1);
        if (!String(value).startsWith("/")) value = controller.dataPath;
        workspacePicker.currentFolder = localFileUrl(value.slice(0, value.lastIndexOf("/")) || "/");
        workspacePicker.selectedFile = localFileUrl(value);
        workspacePicker.open();
    }
    Dialogs.FileDialog {
        id: workspacePicker
        objectName: "workspaceFilePicker"
        parentWindow: root.parent ? root.parent.Window.window : null
        title: "📁 " + I18n.t("Choose workspace file (existing or new)")
        fileMode: Dialogs.FileDialog.SaveFile
        // Selection only edits the draft path. Settings preserves existing files.
        options: Dialogs.FileDialog.DontUseNativeDialog | Dialogs.FileDialog.DontConfirmOverwrite
        nameFilters: [I18n.t("Flolinr workspace (*.json)")]
        defaultSuffix: "json"
        onAccepted: {
            var match = /^file:\/\/(?:localhost)?(\/.*)$/.exec(selectedFile.toString());
            if (!match) { message.text = I18n.t("Choose a local workspace file"); return; }
            try { path.text = decodeURIComponent(match[1]); message.text = I18n.t("Path selected. Save settings to apply."); }
            catch (e) { message.text = I18n.t("Could not read the selected path"); }
        }
    }
    function choose(id) {
        selectedId = id; key.clear(); status.text = ""; loadFields();
        if (mode === "settings" && selected) controller.checkAI(selected);
    }
    function loadFields() {
        loading = true;
        name.text = selected ? selected.name : "";
        modelId.text = selected ? selected.model : "";
        url.text = selected ? selected.baseUrl : "";
        executable.text = selected ? selected.executable : "";
        command.text = selected ? JSON.stringify(selected.command) : "[]";
        loading = false;
    }
    function update(field, value) {
        if (loading || !selected) return;
        var copy = JSON.parse(JSON.stringify(drafts));
        AI.active(copy, selectedId)[field] = value;
        drafts = copy;
    }
    function addConnection(provider) {
        var id = "ai-" + Date.now() + "-" + Math.floor(Math.random() * 100000);
        drafts = drafts.concat([AI.defaults(provider, id)]); choose(id);
    }
    function showResult(text) {
        if (mode === "ai") preview.text = text;
        else { key.clear(); message.text = I18n.t(text); }
    }
    function connectionStatus(text) { status.text = I18n.t(text); }
    function failure(text) { message.text = I18n.t(text); }
    contentItem: ColumnLayout {
        spacing: 8
        ScrollView {
            visible: root.mode === "settings"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            ColumnLayout {
                width: parent.width
                spacing: 10
                enabled: !root.controller.busy
                ModalSection { title: "Language" }
                ComboBox {
                    id: languagePicker
                    objectName: "languagePicker"
                    Layout.fillWidth: true
                    model: I18n.languages
                    textRole: "name"
                }
                ModalSection { title: "Templates" }
                ActionLink { objectName: "manageTemplates"; text: "📋 " + I18n.t("Templates"); onClicked: root.editTemplatesRequested(); }
                ModalSection { title: "Workspace" }
                Label { text: I18n.t("Workspace file (.json)"); opacity: 0.72; font.pixelSize: 12 }
                RowLayout {
                    Layout.fillWidth: true
                    TextField { id: path; objectName: "workspacePath"; Layout.fillWidth: true; placeholderText: "/home/you/notes/outline.json"; }
                    ActionLink { text: I18n.t("Browse…"); objectName: "browseWorkspace"; onClicked: root.browseWorkspace(); }
                }
                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: I18n.t("Choose an existing workspace or name a new .json file. Selection does not write a file. Save settings to apply; changing the workspace requires a shell reload.")
                }
                ModalSection { title: "AI Connections" }
                ComboBox {
                    id: connectionPicker
                    objectName: "aiConnectionPicker"
                    Layout.fillWidth: true
                    model: [{id: "", name: I18n.t("AI disabled / not configured")}].concat(root.drafts)
                    textRole: "name"
                    currentIndex: {
                        for (var i = 0; i < root.drafts.length; i++) if (root.drafts[i].id === root.selectedId) return i + 1;
                        return 0;
                    }
                    onActivated: root.choose(model[currentIndex].id)
                }
                RowLayout {
                    ComboBox { id: provider; objectName: "aiProviderPicker"; Layout.fillWidth: true; model: AI.labels.map(function(label) { return I18n.t(label); }); }
                    ActionLink { text: I18n.t("Add connection"); onClicked: root.addConnection(AI.providers[provider.currentIndex]); }
                }
                Label {
                    visible: !root.selected
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: I18n.t("Add a connection to enable AI. Nothing is sent automatically.")
                }
                ColumnLayout {
                    visible: !!root.selected
                    Layout.fillWidth: true
                    ModalSection { title: "Connection details" }
                    Label { text: root.selected ? I18n.t(AI.labels[AI.providers.indexOf(root.selected.provider)]) : ""; opacity: 0.72; font.pixelSize: 12 }
                    TextField { id: name; objectName: "aiConnectionName"; Layout.fillWidth: true; placeholderText: I18n.t("Connection name"); onTextEdited: root.update("name", text); }
                    Label { text: I18n.t("Model ID"); }
                    TextField {
                        id: modelId
                        objectName: "aiModel"
                        Layout.fillWidth: true
                        placeholderText: root.isCLI ? I18n.t("Leave empty for CLI default") : I18n.t("Enter the model ID available on your account / server")
                        onTextEdited: root.update("model", text)
                    }
                    Label {
                        visible: root.isAPI
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: root.selected && root.selected.provider === "openai" ? I18n.t("Endpoint: {0} · API usage is billed separately.", ["https://api.openai.com/v1"])
                            : root.selected && root.selected.provider === "anthropic" ? I18n.t("Endpoint: {0} · API usage is billed separately.", ["https://api.anthropic.com/v1"])
                            : I18n.t("Base URL · Ollama uses /api/chat; compatible APIs use /chat/completions. Remote servers require HTTPS.")
                    }
                    TextField {
                        id: url
                        objectName: "aiBaseUrl"
                        visible: root.selected && ["ollama", "compatible"].indexOf(root.selected.provider) >= 0
                        Layout.fillWidth: true
                        placeholderText: "https://your-server.example/v1"
                        onTextEdited: { root.update("baseUrl", text); status.text = I18n.t("Endpoint changed. Refresh status; a key saved for the old endpoint will not be reused."); }
                    }
                    Label {
                        visible: root.isCLI
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: I18n.t("Uses this device’s CLI login. Flolinr does not copy CLI credentials.")
                    }
                    TextField {
                        id: key
                        objectName: "aiApiKey"
                        visible: root.isAPI
                        Layout.fillWidth: true
                        echoMode: TextInput.Password
                        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                        placeholderText: I18n.t("API key · leave empty to keep saved key (optional for local services)")
                    }
                    Label {
                        visible: root.isAPI
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: I18n.t("Save stores the key in this device’s desktop keyring, separate from notes and settings. Test uses a typed key without saving it.")
                    }
                    RowLayout {
                        ActionLink { text: I18n.t("Refresh status"); onClicked: root.controller.checkAI(root.selected); }
                        ActionLink {
                            text: I18n.t("Log in")
                            visible: root.selected && ["codex", "claude"].indexOf(root.selected.provider) >= 0
                            onClicked: root.controller.loginAI(root.selected)
                        }
                        ActionLink { text: I18n.t("Connection test"); onClicked: root.controller.testAI(root.selected, key.text); }
                    }
                    Label { id: status; objectName: "aiAuthStatus"; Layout.fillWidth: true; wrapMode: Text.WordWrap; }
                    Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: I18n.t("Connection test sends a fixed sentence, never your notes. Provider usage limits / charges may apply."); }
                    CheckBox { id: advanced; text: I18n.t("Advanced"); }
                    ColumnLayout {
                        visible: advanced.checked
                        Layout.fillWidth: true
                        ModalSection { title: "Advanced" }
                        Label { visible: root.isCLI && root.selected.provider !== "custom"; text: I18n.t("CLI executable path (optional)"); }
                        TextField {
                            id: executable
                            Layout.fillWidth: true
                            visible: root.isCLI && root.selected.provider !== "custom"
                            placeholderText: "/path/to/cli"
                            onTextEdited: root.update("executable", text)
                        }
                        Label { visible: root.selected && root.selected.provider === "custom"; text: I18n.t("Command · JSON argument array; stdin → Markdown stdout"); }
                        TextField {
                            id: command
                            Layout.fillWidth: true
                            visible: root.selected && root.selected.provider === "custom"
                            onTextEdited: {
                                try { root.update("command", JSON.parse(text)); message.text = ""; }
                                catch (e) { message.text = I18n.t("CLI command must be a JSON argument array"); }
                            }
                        }
                        ActionLink { visible: root.isAPI; text: I18n.t("Delete saved API key on this device"); onClicked: root.controller.deleteKey(root.selected); }
                        ActionLink {
                            text: I18n.t("Remove connection (save to apply)")
                            onClicked: { var id = root.selectedId; root.drafts = root.drafts.filter(function(p) { return p.id !== id; }); root.choose(""); }
                        }
                    }
                }
            }
        }
        Label {
            visible: root.mode === "ai"
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: root.controller.activeConnection ? I18n.t("Connection: {0} · {1}", [root.controller.activeConnection.name, root.controller.activeConnection.model || I18n.t("CLI default")]) : I18n.t("AI not configured")
        }
        Label {
            visible: root.mode === "ai"
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: I18n.t("Scope: {0}", [root.scopeLabel]) + "\n" + I18n.t("Zoom limits the target to that branch, including its collapsed descendants. Markdown conversion saves a separate .md file; your outline stays unchanged.")
        }
        ActionLink { visible: root.mode === "ai"; text: I18n.t("Change AI connection"); enabled: !root.controller.busy; onClicked: root.show("settings"); }
        Flow {
            Layout.fillWidth: true
            spacing: 4
            visible: root.mode === "ai"
            ActionLink { text: I18n.t("Summarize"); enabled: !root.controller.busy; onClicked: root.generate("summarize"); }
            ActionLink { objectName: "aiExpand"; text: I18n.t("Expand"); enabled: !root.controller.busy; onClicked: root.configureExpansion(); }
            ActionLink { text: I18n.t("Reorder"); enabled: !root.controller.busy; onClicked: root.generate("reorder"); }
            ActionLink { objectName: "aiConvertMarkdown"; text: I18n.t("Convert to Markdown"); enabled: !root.controller.busy; onClicked: root.generate("markdown"); }
        }
        Label { visible: root.mode === "ai" && root.expandPromptVisible; text: I18n.t("Expansion instructions (optional)"); }
        ScrollView {
            visible: root.mode === "ai" && root.expandPromptVisible
            Layout.fillWidth: true
            Layout.preferredHeight: 74
            clip: true
            TextArea {
                id: expandPrompt
                objectName: "aiExpandPrompt"
                readOnly: root.controller.busy
                wrapMode: TextEdit.Wrap
                textFormat: TextEdit.PlainText
                placeholderText: I18n.t("For example: add practical examples and break each step into smaller tasks.")
            }
        }
        ActionLink {
            objectName: "aiGenerateExpansion"
            visible: root.mode === "ai" && root.expandPromptVisible
            text: I18n.t("Generate expansion")
            enabled: !root.controller.busy
            onClicked: root.generate("expand")
        }
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.mode === "ai"
            TextArea { id: preview; objectName: "aiPreview"; readOnly: root.controller.busy; wrapMode: TextEdit.Wrap; textFormat: TextEdit.PlainText; placeholderText: I18n.t("Preview appears here. Edit it before applying or saving as Markdown."); }
        }
        Label { id: message; objectName: "aiMessage"; Layout.fillWidth: true; wrapMode: Text.WordWrap; }
        Label { visible: root.controller.busy; text: I18n.t("Working…"); }
        RowLayout {
            ActionLink { text: I18n.t("Close"); enabled: !root.controller.busy; onClicked: root.close(); }
            ActionLink {
                objectName: "aiPreviewAction"
                text: root.mode === "settings" ? I18n.t("Save settings") : root.controller.aiTask === "markdown" ? I18n.t("Download .md") : I18n.t("Apply preview")
                enabled: !root.controller.busy && (root.mode !== "ai" || (!!preview.text.trim() && root.controller.aiPreviewReady && !!root.controller.aiBefore))
                onClicked: {
                    if (root.mode === "settings") {
                        try {
                            if (root.selected && root.selected.provider === "custom") root.update("command", JSON.parse(command.text));
                            root.controller.saveSettings(path.text, root.drafts, root.selectedId, root.selected, key.text, I18n.languages[languagePicker.currentIndex].code);
                        } catch (e) { message.text = I18n.t("CLI command must be a JSON argument array"); }
                    }
                    else if (root.controller.aiTask === "markdown") root.downloadMarkdown();
                    else root.controller.applyAI(preview.text);
                }
            }
        }
    }
}
