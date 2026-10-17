import QtQuick
import QtQuick.Controls

ListView {
    id: view
    clip: true
    // Prepare nearby editors across frames before they enter the viewport.
    cacheBuffer: height
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar {}

    WheelHandler {
        target: null
        acceptedDevices: PointerDevice.Mouse
        acceptedModifiers: Qt.NoModifier
        onWheel: function(event) {
            // Preserve high-resolution scrolling and touchpad momentum.
            if (event.pixelDelta.y || !event.angleDelta.y) {
                event.accepted = false;
                return;
            }
            view.cancelFlick();
            var top = view.originY;
            var bottom = top + Math.max(0, view.contentHeight - view.height);
            view.contentY = Math.max(top, Math.min(bottom,
                view.contentY - event.angleDelta.y / 120 * 96));
            event.accepted = true;
        }
    }
}
