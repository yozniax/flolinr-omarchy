pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.Commons as Commons
import "Model.js" as Model

Item {
    id: row
    required property var controller
    signal colorRequested(string nodeId)
    required property var modelData
    height: Math.max(23, editor.contentHeight)
    function edit() { editor.forceActiveFocus(); editor.cursorPosition = editor.length; }
    Rectangle {
        anchors.fill: parent
        radius: 4
        color: Commons.Color.accent
        opacity: editor.activeFocus ? 0.045 : 0
    }
    Rectangle {
        x: row.modelData.depth * 24 + 24
        width: 1; height: parent.height
        color: Commons.Color.foreground; opacity: 0.1
        visible: row.modelData.children && !row.modelData.collapsed
    }
    Text {
        x: row.modelData.depth * 24
        y: 3
        text: row.modelData.children ? (row.modelData.collapsed ? "▸" : "▾") : " "
        color: Commons.Color.foreground; opacity: 0.5
        MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: row.controller.action(row.modelData.id, "fold", 0); }
    }
    Text {
        x: row.modelData.depth * 24 + 18; y: 4
        text: "•"; color: row.controller.nodeColor(row.modelData.color); opacity: 0.85
        MouseArea {
            anchors.fill: parent; anchors.margins: -5
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    row.colorRequested(row.modelData.id);
                } else row.controller.enterZoom(row.modelData.id);
            }
        }
    }
    TextArea {
        id: editor
        x: row.modelData.depth * 24 + 40
        width: parent.width - x
        height: Math.max(23, contentHeight)
        text: row.modelData.text
        textFormat: TextEdit.PlainText
        color: row.controller.nodeColor(row.modelData.color)
        selectionColor: Commons.Color.accent
        font.family: Commons.Style.fontFamily
        font.pixelSize: 16
        wrapMode: TextEdit.Wrap
        readOnly: !row.controller.ready
        padding: 0
        topPadding: 0
        bottomPadding: 0
        background: Item {}
        property bool sessionRecorded: false
        onActiveFocusChanged: {
            if (activeFocus) row.controller.focusedNode = row.modelData.id;
            else sessionRecorded = false;
        }
        onTextChanged: {
            if (!activeFocus || !row.controller.ready) return;
            var i = Model.indexOf(row.controller.nodes, row.modelData.id);
            if (i >= 0 && row.controller.nodes[i].text !== text) {
                if (!sessionRecorded) { row.controller.snapshot(); sessionRecorded = true; }
                row.controller.nodes[i].text = text; Model.touch([row.controller.nodes[i]]); row.controller.changed();
            }
        }
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
            if (inputMethodComposing) return;
            var kind = "", dir = 0;
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) kind = "add";
            else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                kind = "indent"; dir = event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1;
            } else if ((event.modifiers & Qt.AltModifier) && (event.key === Qt.Key_Up || event.key === Qt.Key_Down)) {
                kind = "move"; dir = event.key === Qt.Key_Up ? -1 : 1;
            } else if (event.key === Qt.Key_Backspace && text === "") kind = "delete";
            if (kind) { event.accepted = true; row.controller.action(row.modelData.id, kind, dir); }
        }
    }
}
