import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Dialogs as Dialogs
import qs.Commons as Commons
import "Model.js" as Model

CompactDialog {
    id: root
    required property var controller
    property string targetId: ""
    property string editingId: ""
    property string replaceId: ""
    property string expectedText: ""
    property var original: null
    property var exporting: null
    readonly property bool choosing: picker.visible || savePicker.visible
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(600, parent ? parent.width - 32 : 600)
    height: Math.min(520, parent ? parent.height - 32 : 520)
    title: "📎 " + I18n.t("Insert file or code")
    palette.base: Qt.lighter(Commons.Color.background, 1.3)
    palette.button: Qt.lighter(Commons.Color.background, 1.5)
    palette.highlight: Commons.Color.accent
    modal: true
    focus: true
    closePolicy: controller.busy || choosing ? Popup.NoAutoClose : Popup.CloseOnEscape
    onClosed: { var focusId = replaceId || editingId; if (focusId && typeof controller.editor.restoreCommandFocus === "function") controller.editor.restoreCommandFocus(focusId); picker.close(); code.clear(); original = null; editingId = ""; replaceId = ""; }
    function showSlash(id, command) {
        if (controller.busy) return;
        var i = Model.indexOf(controller.editor.nodes, id);
        if (i < 0 || controller.editor.nodes[i].attachment) return;
        replaceId = id; expectedText = controller.editor.nodes[i].text;
        targetId = ""; editingId = ""; original = null;
        name.clear(); code.clear(); message.text = "";
        picker.nameFilters = [I18n.t("All files (*)")];
        open(); Qt.callLater(function() { code.forceActiveFocus(); });
    }
    function showEdit(id) {
        if (controller.busy) return;
        var i = Model.indexOf(controller.editor.nodes, id);
        if (i < 0 || !controller.editor.nodes[i].attachment) return;
        original = JSON.parse(JSON.stringify(controller.editor.nodes[i].attachment)); editingId = id;
        replaceId = "";
        name.text = original.name; code.text = original.content;
        message.text = ""; open();
    }
    function saveCode() {
        try {
            var attachment = original ? JSON.parse(JSON.stringify(original)) : {kind: "code", mime: "text/plain"};
            attachment.language = Model.detectAttachmentFormat(name.text, code.text);
            attachment.kind = attachment.language === "text" || attachment.language === "markdown" ? "text" : "code";
            attachment.name = name.text.trim() || "Untitled." + ({markdown:"md",text:"txt",python:"py",javascript:"js",typescript:"ts"}[attachment.language] || attachment.language);
            attachment.content = code.text;
            Model.validateAttachment(attachment);
            if (editingId) controller.editor.updateAttachment(editingId, attachment);
            else controller.editor.insertAttachment(attachment, targetId, replaceId, expectedText);
            close();
        } catch (e) { failure(e.message); }
    }
    function saveFile(attachment) {
        if (controller.busy) return;
        exporting = attachment;
        savePicker.selectedFile = "";
        savePicker.open();
    }
    function failure(text) { message.text = I18n.t(text); }
    Dialogs.FileDialog {
        id: picker
        objectName: "insertFilePicker"
        parentWindow: root.parent ? root.parent.Window.window : null
        title: "📎 " + I18n.t("Insert file")
        fileMode: Dialogs.FileDialog.OpenFile
        options: Dialogs.FileDialog.DontUseNativeDialog
        nameFilters: [I18n.t("All files (*)")]
        onAccepted: root.controller.loadAttachment(selectedFile.toString(), root.targetId, root.replaceId, root.expectedText)
    }
    Dialogs.FileDialog {
        id: savePicker
        objectName: "attachmentSavePicker"
        parentWindow: root.parent ? root.parent.Window.window : null
        title: "💾 " + I18n.t("Save file…")
        fileMode: Dialogs.FileDialog.SaveFile
        options: Dialogs.FileDialog.DontUseNativeDialog
        nameFilters: [I18n.t("All files (*)")]
        onAccepted: { root.controller.saveAttachment(selectedFile.toString(), root.exporting); root.exporting = null; }
        onRejected: root.exporting = null
    }
    contentItem: ColumnLayout {
        spacing: 8
        Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: I18n.t("Insert a copy under the selected item. Embedded content is never sent to AI."); }
        ModalSection { title: "File or pasted content" }
        ActionLink { visible: !root.editingId; enabled: !root.controller.busy; text: I18n.t("Choose file…"); onClicked: picker.open(); }
        TextField { id: name; objectName: "attachmentName"; Layout.fillWidth: true; placeholderText: I18n.t("Filename or title"); enabled: !root.controller.busy; maximumLength: 255; }
        Label { objectName: "attachmentLanguage"; Layout.fillWidth: true; text: Model.detectAttachmentFormat(name.text, code.text); opacity: 0.5; font.pixelSize: 11; }
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            TextArea { id: code; objectName: "attachmentCode"; font.family: "monospace"; wrapMode: TextEdit.NoWrap; textFormat: TextEdit.PlainText; readOnly: root.controller.busy; placeholderText: "Paste or Text"; }
        }
        Label { id: message; Layout.fillWidth: true; wrapMode: Text.WordWrap; }
        RowLayout {
            ActionLink { text: I18n.t("Cancel"); enabled: !root.controller.busy; onClicked: root.close(); }
            ActionLink { text: root.editingId ? I18n.t("Apply") : I18n.t("Insert code or text"); enabled: !root.controller.busy; onClicked: root.saveCode(); }
        }
    }
}
