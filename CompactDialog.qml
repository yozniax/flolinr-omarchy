import QtQuick
import QtQuick.Controls
import qs.Commons as Commons

// Shared quiet typography and chrome for all feature dialogs.
Dialog {
    id: root
    padding: 16
    spacing: 10
    font.family: Commons.Style.fontFamily
    font.pixelSize: 11
    font.weight: Font.Light
    palette.windowText: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.76)
    palette.text: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.86)
    palette.buttonText: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.76)
    palette.placeholderText: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.4)
    background: Rectangle {
        radius: 10
        color: Commons.Color.background
        border.width: 1
        border.color: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.13)
    }
    header: Label {
        text: root.title
        font.family: root.font.family
        font.pixelSize: 13
        font.weight: Font.Light
        color: Commons.Color.foreground
        opacity: 0.78
        leftPadding: 16
        rightPadding: 16
        topPadding: 14
        bottomPadding: 8
        elide: Text.ElideRight
    }
}
