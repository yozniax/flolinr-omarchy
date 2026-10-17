import QtQuick
import QtQuick.Window
import QtQuick.Dialogs as Dialogs

Item {
    id: root
    required property var controller
    property string operation: "import"
    readonly property bool opened: picker.visible
    function open(mode) {
        if (controller.busy) return;
        operation = mode;
        var suffix = picker.selectedFile.toString().toLowerCase().split(".").pop();
        picker.selectedNameFilter.index = mode === "import" ? 0 : suffix === "opml" ? 1 : (suffix === "txt" || suffix === "text") ? 2 : 0;
        picker.open();
    }
    Dialogs.FileDialog {
        id: picker
        objectName: "fileTransferPicker"
        // GTK/GIO aborts in this shell process when creating the native chooser.
        // Always use Qt Quick's chooser for both import and export.
        options: Dialogs.FileDialog.DontUseNativeDialog
        parentWindow: root.Window.window
        title: root.operation === "import" ? "📥 " + I18n.t("Import as a new Roll") : "📤 " + I18n.t("Export current Roll")
        fileMode: root.operation === "import" ? Dialogs.FileDialog.OpenFile : Dialogs.FileDialog.SaveFile
        nameFilters: root.operation === "import"
            ? [I18n.t("Supported files (*.opml *.md *.markdown *.txt *.text)"), "OPML (*.opml)", "Markdown (*.md *.markdown)", I18n.t("Plaintext (*.txt *.text)")]
            : ["Markdown (*.md)", "OPML (*.opml)", I18n.t("Plaintext (*.txt)")]
        defaultSuffix: root.operation === "export" ? ["md", "opml", "txt"][selectedNameFilter.index] || "md" : ""
        onAccepted: {
            var format = root.operation === "import"
                ? ["auto", "opml", "markdown", "plaintext"][selectedNameFilter.index]
                : ["markdown", "opml", "plaintext"][selectedNameFilter.index];
            root.controller.transfer(root.operation, selectedFile.toString(), format);
        }
    }
}
