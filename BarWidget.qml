import QtQuick
import qs.Ui as Ui

Ui.BarWidget {
    id: root
    moduleName: "yozniax.flolinr"
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight
    Ui.WidgetButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        labelVisible: false
        hasVisualContent: true
        fixedWidth: vertical ? barSize : 36
        FlolinrIcon { anchors.centerIn: parent; width: 20; height: 20; color: button.foreground; }
        tooltipText: "Flolinr"
        onPressed: function(buttonCode) {
            if (buttonCode === Qt.LeftButton && root.bar && root.bar.shell)
                root.bar.shell.toggle(root.moduleName, "{}");
        }
    }
}
