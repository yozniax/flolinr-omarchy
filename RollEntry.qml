import QtQuick
import QtQuick.Controls
import qs.Commons as Commons

ItemDelegate {
    id: entry
    required property var modelData
    required property var controller
    readonly property bool dragging: pointer.drag.active
    leftPadding: 24
    height: 28
    z: dragging ? 100 : 0
    text: controller.defaultRollIcon(modelData) + "  " + modelData.name
    highlighted: modelData.id === controller.activeRollId
    opacity: dragging ? 0.55 : 1
    background: Rectangle {
        radius: 8
        color: entry.highlighted
            ? Qt.rgba(Commons.Color.accent.r, Commons.Color.accent.g, Commons.Color.accent.b, 0.14)
            : pointer.containsMouse ? Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.055) : "transparent"
        border.width: entry.activeFocus ? 1 : 0
        border.color: Commons.Color.accent
    }
    contentItem: Label {
        text: entry.text
        color: Commons.Color.foreground
        font.pixelSize: 12
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }
    Item {
        id: proxy
        width: 1; height: 1
        Drag.active: pointer.drag.active
        Drag.source: entry
        Drag.keys: ["flolinr-roll"]
        Drag.supportedActions: Qt.MoveAction
        Drag.hotSpot: Qt.point(0, 0)
    }
    DropArea {
        id: drop
        anchors.fill: parent
        keys: ["flolinr-roll"]
        property bool after: false
        onEntered: function(event) {
            if (!event.source || !!event.source.modelData.archived !== !!entry.modelData.archived) { event.accepted = false; return; }
            after = event.y >= height / 2;
        }
        onPositionChanged: function(event) { after = event.y >= height / 2; }
        onDropped: function(event) {
            if (event.source && event.source !== entry) {
                entry.controller.reorderRoll(event.source.modelData.id, entry.modelData.id, after);
                event.acceptProposedAction();
            }
        }
        Rectangle {
            visible: drop.containsDrag && proxy.Drag.source !== drop.drag.source
            x: 16; width: parent.width - 16; height: 2
            y: drop.after ? parent.height - height : 0
            color: Commons.Color.accent
        }
    }
    MouseArea {
        id: pointer
        objectName: "rollDragArea"
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        drag.target: (pressedButtons & Qt.LeftButton) ? proxy : null
        drag.axis: Drag.YAxis
        property bool moved: false
        onPressed: function(mouse) { moved = false; proxy.x = mouse.x; proxy.y = mouse.y; }
        onPositionChanged: if (drag.active) { moved = true; proxy.x = mouseX; proxy.y = mouseY; }
        onReleased: { if (drag.active) proxy.Drag.drop(); }
        onCanceled: proxy.Drag.cancel()
        onClicked: function(mouse) {
            if (moved) return;
            entry.controller.selectRoll(entry.modelData.id);
            if (mouse.button === Qt.RightButton) entry.controller.chooseIcon();
        }
        onDoubleClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton && !moved) {
                entry.controller.selectRoll(entry.modelData.id);
                entry.controller.editRoll(false);
            }
        }
    }
}
