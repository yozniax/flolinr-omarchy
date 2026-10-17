import QtQuick
import QtQuick.Controls
import qs.Commons as Commons
import "CommandActions.js" as Commands

Popup {
    id: menu
    required property var editor
    required property var controller
    required property string nodeId
    readonly property var commands: Commands.commands
    readonly property var matches: commands.filter(function(command) { return command.startsWith(editor.text.trim().slice(1).toLowerCase()); })
    property int selected: 0
    parent: editor
    x: 0; y: editor.height
    width: Math.max(150, Math.min(260, editor.width))
    height: Math.min(240, matches.length * 28 + 12)
    padding: 6
    focus: false
    modal: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    background: Rectangle { color: Commons.Color.background; border.color: Commons.Color.accent; border.width: 1; radius: 6; }
    function update() {
        if (editor.activeFocus && !editor.inputMethodComposing && controller.ready && /^\/[a-z]*$/i.test(editor.text.trim()) && matches.length) {
            selected = 0; open();
        } else close();
    }
    function choose(index) {
        var command = matches[index];
        if (!command) return;
        close();
        controller.openSlashCommand(nodeId, command);
    }
    function handleKey(event) {
        if (!opened || (event.modifiers & (Qt.ShiftModifier | Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) || editor.inputMethodComposing) return false;
        if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
            selected = (selected + (event.key === Qt.Key_Down ? 1 : -1) + matches.length) % matches.length;
            options.positionViewAtIndex(selected, ListView.Contain);
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) choose(selected);
        else if (event.key === Qt.Key_Escape) close();
        else return false;
        event.accepted = true; return true;
    }
    contentItem: ListView {
        id: options
        clip: true
        model: menu.matches
        delegate: ActionLink {
            required property string modelData
            required property int index
            width: options.width; height: 28
            text: "/" + modelData
            highlighted: index === menu.selected
            focusPolicy: Qt.NoFocus
            onClicked: menu.choose(index)
        }
    }
}
