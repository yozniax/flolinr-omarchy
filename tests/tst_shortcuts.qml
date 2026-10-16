import QtQuick
import QtTest
import ".." as App
import "../Keybindings.js" as Bindings

TestCase {
    id: tests
    name: "ShortcutSections"
    when: windowShown
    width: 720
    height: 760
    App.ShortcutsDialog {
        id: dialog
        parent: tests
        bindings: Bindings.resolve({search:"Ctrl+S",save:"Ctrl+F",color:""})
        settingsPath: "/home/user/.config/flolinr/keybindings.json"
    }
    function cleanup() { dialog.close(); }
    function test_grouped_help_scrolls_without_horizontal_overflow() {
        dialog.open();
        compare(dialog.sections.length,8);
        compare(dialog.sections[0].title,"Writing & editing");
        var scroll=findChild(dialog,"shortcutScroll");
        wait(50);
        verify(scroll.contentItem.contentHeight>scroll.height);
        verify(scroll.contentItem.contentWidth<=scroll.width);
        dialog.contentItem.grabToImage(function(result) { result.saveToFile("/tmp/flolinr-shortcuts-top.png"); });
        wait(100);
        scroll.contentItem.contentY=scroll.contentItem.contentHeight-scroll.height;
        wait(50);
        dialog.contentItem.grabToImage(function(result) { result.saveToFile("/tmp/flolinr-shortcuts-bottom.png"); });
        wait(100);
    }
    function test_binding_change_updates_grouped_rows() {
        dialog.open();
        compare(dialog.sections[4].rows[0][0],"Ctrl+S");
        compare(dialog.sections[5].rows[0][0],"Disabled");
    }
}
