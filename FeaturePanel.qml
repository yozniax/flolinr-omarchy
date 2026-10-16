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
    property string mode: "settings"
    property var drafts: []
    property string selectedId: ""
    property bool loading: false
    property string scopeLabel: ""
    readonly property var selected: AI.active(drafts, selectedId)
    readonly property bool isCLI: selected && ["codex", "claude", "custom"].indexOf(selected.provider) >= 0
    readonly property bool isAPI: selected && !isCLI
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(600, parent ? parent.width - 32 : 600)
    height: Math.min(mode === "ai" ? 500 : 650, parent ? parent.height - 32 : 650)
    palette.base: Qt.lighter(Commons.Color.background, 1.3)
    palette.button: Qt.lighter(Commons.Color.background, 1.5)
    palette.highlight: Commons.Color.accent
    modal: true
    focus: true
    title: mode === "ai" ? "AI · current view" : "Settings · AI connections"
    standardButtons: Dialog.NoButton
    closePolicy: controller.busy || workspacePicker.visible ? Popup.NoAutoClose : Popup.CloseOnEscape
    onClosed: { workspacePicker.close(); key.clear(); controller.aiBefore = ""; }
    function show(mode) {
        if (controller.busy) return;
        root.mode = mode === "ai" && !controller.activeConnection ? "settings" : mode;
        message.text = root.mode !== mode ? "Choose and save an AI connection first." : "";
        preview.clear(); key.clear(); status.text = "";
        scopeLabel = controller.scopeLabel;
        controller.aiBefore = "";
        path.text = controller.dataPath;
        drafts = JSON.parse(JSON.stringify(controller.aiConnections));
        choose(controller.activeAiConnectionId || (drafts.length ? drafts[0].id : ""));
        open();
    }
    function localFileUrl(value) {
        return "file://" + value.split("/").map(function(part) { return encodeURIComponent(part); }).join("/");
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
        title: "Choose workspace file (existing or new)"
        fileMode: Dialogs.FileDialog.SaveFile
        // Selection only edits the draft path. Settings preserves existing files.
        options: Dialogs.FileDialog.DontUseNativeDialog | Dialogs.FileDialog.DontConfirmOverwrite
        nameFilters: ["Flolinr workspace (*.json)"]
        defaultSuffix: "json"
        onAccepted: {
            var match = /^file:\/\/(?:localhost)?(\/.*)$/.exec(selectedFile.toString());
            if (!match) { message.text = "Choose a local workspace file"; return; }
            try { path.text = decodeURIComponent(match[1]); message.text = "Path selected. Save settings to apply."; }
            catch (e) { message.text = "Could not read the selected path"; }
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
        else { key.clear(); message.text = text; }
    }
    function connectionStatus(text) { status.text = text; }
    function failure(text) { message.text = text; }
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
                spacing: 8
                enabled: !root.controller.busy
                Label { text: "Workspace file (.json)"; }
                RowLayout {
                    Layout.fillWidth: true
                    TextField { id: path; objectName: "workspacePath"; Layout.fillWidth: true; placeholderText: "/home/you/notes/outline.json"; }
                    ActionLink { text: "Browse…"; objectName: "browseWorkspace"; onClicked: root.browseWorkspace(); }
                }
                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "Choose an existing workspace or name a new .json file. Selection does not write a file. Save settings to apply; changing the workspace requires a shell reload."
                }
                Label { text: "AI connection · selected connection becomes active when saved"; Layout.fillWidth: true; wrapMode: Text.WordWrap; }
                ComboBox {
                    id: connectionPicker
                    objectName: "aiConnectionPicker"
                    Layout.fillWidth: true
                    model: [{id: "", name: "AI disabled / not configured"}].concat(root.drafts)
                    textRole: "name"
                    currentIndex: {
                        for (var i = 0; i < root.drafts.length; i++) if (root.drafts[i].id === root.selectedId) return i + 1;
                        return 0;
                    }
                    onActivated: root.choose(model[currentIndex].id)
                }
                RowLayout {
                    ComboBox { id: provider; objectName: "aiProviderPicker"; Layout.fillWidth: true; model: AI.labels; }
                    ActionLink { text: "Add connection"; onClicked: root.addConnection(AI.providers[provider.currentIndex]); }
                }
                Label {
                    visible: !root.selected
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "Add a connection to enable AI. Nothing is sent automatically."
                }
                ColumnLayout {
                    visible: !!root.selected
                    Layout.fillWidth: true
                    Label { text: root.selected ? AI.labels[AI.providers.indexOf(root.selected.provider)] : ""; }
                    TextField { id: name; objectName: "aiConnectionName"; Layout.fillWidth: true; placeholderText: "Connection name"; onTextEdited: root.update("name", text); }
                    Label { text: "Model ID"; }
                    TextField {
                        id: modelId
                        objectName: "aiModel"
                        Layout.fillWidth: true
                        placeholderText: root.isCLI ? "Leave empty for CLI default" : "Enter the model ID available on your account / server"
                        onTextEdited: root.update("model", text)
                    }
                    Label {
                        visible: root.isAPI
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: root.selected && root.selected.provider === "openai" ? "Endpoint: https://api.openai.com/v1 · API usage is billed separately."
                            : root.selected && root.selected.provider === "anthropic" ? "Endpoint: https://api.anthropic.com/v1 · API usage is billed separately."
                            : "Base URL · Ollama uses /api/chat; compatible APIs use /chat/completions. Remote servers require HTTPS."
                    }
                    TextField {
                        id: url
                        objectName: "aiBaseUrl"
                        visible: root.selected && ["ollama", "compatible"].indexOf(root.selected.provider) >= 0
                        Layout.fillWidth: true
                        placeholderText: "https://your-server.example/v1"
                        onTextEdited: { root.update("baseUrl", text); status.text = "Endpoint changed. Refresh status; a key saved for the old endpoint will not be reused."; }
                    }
                    Label {
                        visible: root.isCLI
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: "Uses this device’s CLI login. Flolinr does not copy CLI credentials."
                    }
                    TextField {
                        id: key
                        objectName: "aiApiKey"
                        visible: root.isAPI
                        Layout.fillWidth: true
                        echoMode: TextInput.Password
                        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                        placeholderText: "API key · leave empty to keep saved key (optional for local services)"
                    }
                    Label {
                        visible: root.isAPI
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: "Save stores the key in this device’s desktop keyring, separate from notes and settings. Test uses a typed key without saving it."
                    }
                    RowLayout {
                        ActionLink { text: "Refresh status"; onClicked: root.controller.checkAI(root.selected); }
                        ActionLink {
                            text: "Log in"
                            visible: root.selected && ["codex", "claude"].indexOf(root.selected.provider) >= 0
                            onClicked: root.controller.loginAI(root.selected)
                        }
                        ActionLink { text: "Connection test"; onClicked: root.controller.testAI(root.selected, key.text); }
                    }
                    Label { id: status; objectName: "aiAuthStatus"; Layout.fillWidth: true; wrapMode: Text.WordWrap; }
                    Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Connection test sends a fixed sentence, never your notes. Provider usage limits / charges may apply."; }
                    CheckBox { id: advanced; text: "Advanced"; }
                    ColumnLayout {
                        visible: advanced.checked
                        Layout.fillWidth: true
                        Label { visible: root.isCLI && root.selected.provider !== "custom"; text: "CLI executable path (optional)"; }
                        TextField {
                            id: executable
                            Layout.fillWidth: true
                            visible: root.isCLI && root.selected.provider !== "custom"
                            placeholderText: "/absolute/path/to/codex or claude"
                            onTextEdited: root.update("executable", text)
                        }
                        Label { visible: root.selected && root.selected.provider === "custom"; text: "Command · JSON argument array; stdin → Markdown stdout"; }
                        TextField {
                            id: command
                            Layout.fillWidth: true
                            visible: root.selected && root.selected.provider === "custom"
                            onTextEdited: {
                                try { root.update("command", JSON.parse(text)); message.text = ""; }
                                catch (e) { message.text = "CLI command must be a JSON argument array"; }
                            }
                        }
                        ActionLink { visible: root.isAPI; text: "Delete saved API key on this device"; onClicked: root.controller.deleteKey(root.selected); }
                        ActionLink {
                            text: "Remove connection (save to apply)"
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
            text: root.controller.activeConnection ? "Connection: " + root.controller.activeConnection.name + " · " + (root.controller.activeConnection.model || "CLI default") : "AI not configured"
        }
        Label {
            visible: root.mode === "ai"
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "Scope: " + root.scopeLabel + "\nIncludes collapsed items in this scope. Send the entire outline shown in the right body to this connection. Review before replacing; Ctrl+Z restores the original."
        }
        ActionLink { visible: root.mode === "ai"; text: "Change AI connection"; enabled: !root.controller.busy; onClicked: root.show("settings"); }
        RowLayout {
            visible: root.mode === "ai"
            ActionLink { text: "Summarize"; enabled: !root.controller.busy; onClicked: root.controller.generateAI("summarize"); }
            ActionLink { text: "Expand"; enabled: !root.controller.busy; onClicked: root.controller.generateAI("expand"); }
            ActionLink { text: "Reorder"; enabled: !root.controller.busy; onClicked: root.controller.generateAI("reorder"); }
        }
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.mode === "ai"
            TextArea { id: preview; wrapMode: TextEdit.Wrap; textFormat: TextEdit.PlainText; placeholderText: "Preview appears here. You can edit it before applying."; }
        }
        Label { id: message; objectName: "aiMessage"; Layout.fillWidth: true; wrapMode: Text.WordWrap; }
        Label { visible: root.controller.busy; text: "Working…"; }
        RowLayout {
            ActionLink { text: "Close"; enabled: !root.controller.busy; onClicked: root.close(); }
            ActionLink {
                text: root.mode === "settings" ? "Save settings" : "Apply preview"
                enabled: !root.controller.busy && (root.mode !== "ai" || (!!preview.text.trim() && !!root.controller.aiBefore))
                onClicked: {
                    if (root.mode === "settings") {
                        try {
                            if (root.selected && root.selected.provider === "custom") root.update("command", JSON.parse(command.text));
                            root.controller.saveSettings(path.text, root.drafts, root.selectedId, root.selected, key.text);
                        } catch (e) { message.text = "CLI command must be a JSON argument array"; }
                    }
                    else root.controller.applyAI(preview.text);
                }
            }
        }
    }
}
