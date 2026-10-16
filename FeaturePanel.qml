import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root
    required property var controller
    property string mode: "settings"
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(640, parent ? parent.width - 32 : 640)
    height: Math.min(610, parent ? parent.height - 32 : 610)
    modal: true
    focus: true
    title: mode === "ai" ? "AI · selected branch" : mode === "settings" ? "Settings" : "Markdown · " + mode
    standardButtons: Dialog.NoButton
    closePolicy: controller.busy ? Popup.NoAutoClose : Popup.CloseOnEscape
    function show(mode) {
        root.mode = mode;
        message.text = ""; preview.text = "";
        path.text = mode === "settings" ? controller.dataPath : "";
        command.text = JSON.stringify(controller.aiCommand);
        open();
    }
    function showResult(text) { if (mode === "ai") preview.text = text; else message.text = text; }
    function failure(text) { message.text = text; }
    contentItem: ColumnLayout {
        spacing: 10
        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: root.mode === "settings" ? "Workspace file (.json). A new path receives a copy of current notes; an existing workspace opens after shell reload."
                : root.mode === "ai" ? "Send only the focused branch to your configured LLM CLI. Review the result before replacing it. Undo restores the original."
                : root.mode === "import" ? "Import Markdown as a new Roll. Existing content is kept." : "Export the current Roll or daily note. An existing file will not be overwritten."
        }
        TextField { id: path; Layout.fillWidth: true; visible: root.mode !== "ai"; placeholderText: "/home/you/notes/outline.json or ~/export.md"; }
        Label { visible: root.mode === "settings"; text: "LLM command (JSON argument array; stdin → stdout)"; }
        TextField { id: command; Layout.fillWidth: true; visible: root.mode === "settings"; }
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
        Label { id: message; Layout.fillWidth: true; wrapMode: Text.WordWrap; }
        Label { visible: root.controller.busy; text: "Working…"; }
        RowLayout {
            ActionLink { text: "Close"; enabled: !root.controller.busy; onClicked: root.close(); }
            ActionLink {
                text: root.mode === "settings" ? "Save settings" : root.mode === "ai" ? "Apply preview" : root.mode === "import" ? "Import as new Roll" : "Export"
                enabled: !root.controller.busy && (root.mode !== "ai" || !!preview.text.trim())
                onClicked: {
                    if (root.mode === "settings") root.controller.saveSettings(path.text, command.text);
                    else if (root.mode === "ai") root.controller.applyAI(preview.text);
                    else root.controller.markdown(root.mode, path.text);
                }
            }
        }
    }
}
