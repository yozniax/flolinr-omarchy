import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons as Commons

Item {
    id: root
    property bool ready: false
    property bool saving: false
    property string error: ""
    readonly property bool opened: window.visible
    signal submitted(string text)
    signal dismissed()
    function open() { window.visible = true; Qt.callLater(function() { input.forceActiveFocus(); }); }
    function close() { window.visible = false; }
    function saved() { input.text = ""; saving = false; error = ""; close(); }
    FloatingWindow {
        id: window
        title: "Flolinr · Quick note"
        visible: false
        implicitWidth: 540
        implicitHeight: root.error ? 108 : 70
        minimumSize: Qt.size(340, 70)
        color: Commons.Color.background
        onVisibleChanged: if (!visible) root.dismissed()
        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8
            TextField {
                id: input
                width: parent.width
                placeholderText: root.saving ? "Saving…" : "Today’s note · Enter to save · Esc to cancel"
                enabled: root.ready && !root.saving
                color: Commons.Color.foreground
                maximumLength: 10000
                onAccepted: if (text.trim()) root.submitted(text)
                Keys.onEscapePressed: if (!root.saving) root.close()
            }
            Label { width: parent.width; text: root.error; color: Commons.Color.foreground; visible: !!root.error; elide: Text.ElideRight; }
        }
    }
}
