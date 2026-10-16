import QtQuick
import QtQuick.Window
import QtTest
import QtQuick.Dialogs as Dialogs
import ".." as App

TestCase {
    id: tests
    name: "FileTransfer"
    when: windowShown
    width: 500
    height: 400
    QtObject { id: controller; property bool busy: false; function transfer(mode, file, format) {} }
    App.FileTransfer { id: transfer; controller: controller }
    function cleanup() {
        findChild(transfer, "fileTransferPicker").close();
    }
    function test_native_backend_is_disabled() {
        var picker = findChild(transfer, "fileTransferPicker");
        verify((picker.options & Dialogs.FileDialog.DontUseNativeDialog) !== 0);
    }
    function test_repeated_import_export_cancellation() {
        var picker = findChild(transfer, "fileTransferPicker");
        for (var i = 0; i < 10; i++) {
            transfer.open(i % 2 ? "export" : "import");
            tryCompare(transfer, "opened", true);
            picker.reject();
            tryCompare(transfer, "opened", false);
        }
    }
    function test_open_file_picker() {
        transfer.open("import");
        var picker = findChild(transfer, "fileTransferPicker");
        compare(picker.parentWindow, tests.Window.window);
        compare(picker.fileMode, Dialogs.FileDialog.OpenFile);
        compare(picker.nameFilters.length, 4);
        verify(picker.nameFilters[0].includes("*.opml"));
        verify(picker.nameFilters[0].includes("*.txt"));
        tryCompare(transfer, "opened", true);
    }
    function test_save_file_picker_and_format_suffix() {
        transfer.open("export");
        var picker = findChild(transfer, "fileTransferPicker");
        compare(picker.fileMode, Dialogs.FileDialog.SaveFile);
        picker.selectedNameFilter.index = 1;
        compare(picker.defaultSuffix, "opml");
        picker.selectedNameFilter.index = 2;
        compare(picker.defaultSuffix, "txt");
        tryCompare(transfer, "opened", true);
    }
}
