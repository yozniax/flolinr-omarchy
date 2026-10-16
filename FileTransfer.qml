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
        title: root.operation === "import" ? "Import as a new Roll" : "Export current Roll"
        fileMode: root.operation === "import" ? Dialogs.FileDialog.OpenFile : Dialogs.FileDialog.SaveFile
        nameFilters: root.operation === "import"
            ? ["Supported files (*.opml *.md *.markdown *.txt *.text)", "OPML (*.opml)", "Markdown (*.md *.markdown)", "Plaintext (*.txt *.text)"]
            : ["Markdown (*.md)", "OPML (*.opml)", "Plaintext (*.txt)"]
        defaultSuffix: root.operation === "export" ? ["md", "opml", "txt"][selectedNameFilter.index] || "md" : ""
        onAccepted: {
            var format = root.operation === "import"
                ? ["auto", "opml", "markdown", "plaintext"][selectedNameFilter.index]
                : ["markdown", "opml", "plaintext"][selectedNameFilter.index];
            root.controller.transfer(root.operation, selectedFile.toString(), format);
        }
    }
}
