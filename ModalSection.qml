import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons as Commons

RowLayout {
    required property string title
    Layout.fillWidth: true
    Layout.topMargin: 8
    spacing: 8
    Rectangle {
        Layout.preferredWidth: 3
        Layout.preferredHeight: 14
        radius: 1
        color: Commons.Color.accent
        opacity: 0.8
    }
    Label {
        Layout.fillWidth: true
        text: I18n.t(parent.title)
        color: Commons.Color.foreground
        font.pixelSize: 13
        font.weight: Font.DemiBold
        opacity: 0.9
        verticalAlignment: Text.AlignVCenter
    }
}
