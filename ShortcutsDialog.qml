pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.Commons as Commons
import "Keybindings.js" as Bindings

Dialog {
    id: dialog
    required property var bindings
    property string settingsPath: ""
    property string settingsError: ""
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(660, parent ? parent.width - 32 : 660)
    height: Math.min(620, parent ? parent.height - 32 : 620)
    title: "Keyboard shortcuts"
    padding: 24
    background: Rectangle { radius: 14; color: Commons.Color.background; border.width: 1; border.color: Qt.rgba(Commons.Color.accent.r, Commons.Color.accent.g, Commons.Color.accent.b, 0.35); }
    header: Label { text: "Keyboard shortcuts"; color: Commons.Color.foreground; font.pixelSize: 20; font.bold: true; padding: 24; }
    footer: ActionLink { text: "Close · Esc"; flat: true; palette.buttonText: Commons.Color.foreground; onClicked: dialog.close(); }
    modal: true
    focus: true
    standardButtons: Dialog.NoButton
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    contentItem: ScrollView {
        id: helpScroll
        clip: true
        Column {
            width: helpScroll.availableWidth
            spacing: 9
            Repeater {
                model: [
                    ["Enter", "Add a sibling after the current branch"],
                    ["Tab / Shift+Tab", "Indent / outdent the item and its children"],
                    ["Alt+Up / Alt+Down", "Move a branch among its siblings"],
                    ["Backspace", "Delete an empty item without children"]
                ].concat(Bindings.helpRows(dialog.bindings)).concat([
                    ["Enter / Esc in search", "Focus results / clear search and return"],
                    ["Esc", "Close this help"],
                    ["Right-click a bullet", "Choose a node color"],
                    ["Click a bullet", "Zoom into the item"],
                    ["Click a triangle", "Collapse or expand children"],
                    ["Click a breadcrumb", "Return to a parent or Home"]
                ])
                Row {
                    id: shortcutRow
                    required property var modelData
                    width: parent.width
                    spacing: 12
                    Rectangle {
                        width: 180
                        height: keyLabel.contentHeight + 12
                        radius: 5
                        color: Qt.rgba(Commons.Color.accent.r, Commons.Color.accent.g, Commons.Color.accent.b, 0.10)
                        Label { id: keyLabel; anchors.fill: parent; anchors.margins: 6; text: shortcutRow.modelData[0]; color: Commons.Color.accent; font.pixelSize: 11; wrapMode: Text.WordWrap; }
                    }
                    Label { width: parent.width - 192; text: shortcutRow.modelData[1]; color: Commons.Color.foreground; font.pixelSize: 12; wrapMode: Text.WordWrap; anchors.verticalCenter: parent.verticalCenter; }
                }
            }
            Label {
                width: parent.width
                text: (dialog.settingsError ? dialog.settingsError + "\n\n" : "") + "Customize shortcuts: " + dialog.settingsPath + "\nEnter, Tab, Backspace and dialog navigation use fixed editing keys.\n\nSearch spans all Rolls and daily notes. Select a result to zoom into the matching item."
                wrapMode: Text.WordWrap
                opacity: 0.65
            }
        }
    }
}
