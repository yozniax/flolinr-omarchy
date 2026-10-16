import QtQuick
import QtQuick.Controls
import qs.Commons as Commons

Button {
    id: root
    flat: true
    font.pixelSize: 11
    horizontalPadding: 8
    verticalPadding: 4
    hoverEnabled: true
    background: Item {}
    contentItem: Label {
        text: root.text
        color: root.highlighted || root.activeFocus ? Commons.Color.accent : Commons.Color.foreground
        opacity: root.enabled ? (root.highlighted || root.hovered || root.activeFocus ? 1 : 0.58) : 0.25
        font: root.font
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }
}
