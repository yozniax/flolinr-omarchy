pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.Commons as Commons
import "Keybindings.js" as Bindings

CompactDialog {
    id: dialog
    required property var bindings
    readonly property var sections: Bindings.helpSections(bindings)
    property string settingsPath: ""
    property string settingsError: ""
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(640, parent ? parent.width - 32 : 640)
    height: Math.min(650, parent ? parent.height - 32 : 650)
    title: "Keyboard shortcuts"
    footer: ActionLink { text: "Close · Esc"; flat: true; palette.buttonText: Commons.Color.foreground; onClicked: dialog.close(); }
    modal: true
    focus: true
    standardButtons: Dialog.NoButton
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    contentItem: ScrollView {
        id: helpScroll
        objectName: "shortcutScroll"
        clip: true
        contentWidth: availableWidth
        Column {
            width: helpScroll.availableWidth
            spacing: 5
            Repeater {
                model: dialog.sections
                Column {
                    id: section
                    required property var modelData
                    width: parent.width
                    spacing: 5
                    Item { width: 1; height: 9; }
                    Label {
                        objectName: "shortcutSectionTitle"
                        width: parent.width
                        text: section.modelData.title
                        color: Commons.Color.accent
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        wrapMode: Text.WordWrap
                    }
                    Rectangle { width: parent.width; height: 1; color: Commons.Color.foreground; opacity: 0.13; }
                    Repeater {
                        model: section.modelData.rows
                        Item {
                            id: shortcutRow
                            required property var modelData
                            width: parent.width
                            height: Math.max(keyLabel.implicitHeight + 10, descriptionLabel.implicitHeight + 8)
                            readonly property real keyWidth: Math.min(165, width * 0.36)
                            Rectangle {
                                width: shortcutRow.keyWidth
                                height: keyLabel.implicitHeight + 8
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 4
                                color: Qt.rgba(Commons.Color.accent.r, Commons.Color.accent.g, Commons.Color.accent.b, 0.06)
                                Label {
                                    id: keyLabel
                                    x: 5; y: 4
                                    width: parent.width - 10
                                    text: shortcutRow.modelData[0]
                                    color: Commons.Color.accent
                                    font.pixelSize: 11
                                    wrapMode: Text.WordWrap
                                }
                            }
                            Label {
                                id: descriptionLabel
                                x: shortcutRow.keyWidth + 14
                                width: parent.width - x
                                text: shortcutRow.modelData[1]
                                color: Commons.Color.foreground
                                opacity: 0.8
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }
            Label {
                width: parent.width
                text: (dialog.settingsError ? dialog.settingsError + "\n\n" : "") + "Customize shortcuts: " + dialog.settingsPath + "\nEnter, Tab, Backspace and dialog navigation use fixed editing keys.\n\nSearch spans all Rolls and daily notes. Select a result to zoom into the matching item."
                wrapMode: Text.WordWrap
                font.pixelSize: 10
                opacity: 0.55
            }
        }
    }
}
