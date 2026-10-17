import QtQuick
import QtQuick.Controls
import qs.Commons as Commons

Item {
    id: root
    objectName: "attachmentBlock"
    required property var attachment
    property bool collapsed: false
    signal expandRequested()
    signal collapseRequested()
    signal editRequested()
    signal saveRequested()
    signal removeRequested()
    implicitHeight: details.height + 8
    Column {
        id: details
        width: parent.width
        spacing: 4
        Loader {
            width: parent.width
            active: !root.collapsed
            visible: active
            sourceComponent: root.attachment.kind === "image" ? picture : root.attachment.kind === "file" ? binary : sourceText
        }
        Label {
            id: filename
            objectName: "attachmentFilename"
            width: parent.width
            text: root.attachment.name
            color: Commons.Color.foreground
            opacity: 0.35
            font.pixelSize: 9
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideMiddle
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.RightButton; onClicked: extras.popup(); }
        }
        Row {
            ActionLink { objectName: "attachmentExpand"; text: "expand"; enabled: root.collapsed; onClicked: root.expandRequested(); }
            ActionLink { objectName: "attachmentCollapse"; text: "collapse"; enabled: !root.collapsed; onClicked: root.collapseRequested(); }
            ActionLink { objectName: "attachmentDelete"; text: "delete"; onClicked: root.removeRequested(); }
        }

    }
    Menu {
        id: extras
        MenuItem { text: "edit"; enabled: root.attachment.kind === "text" || root.attachment.kind === "code"; onTriggered: root.editRequested(); }
        MenuItem { text: "save file"; onTriggered: root.saveRequested(); }
    }
    Component {
        id: picture
        Item {
            width: parent ? parent.width : 400
            height: 240
            Image {
                id: image
                objectName: "attachmentImage"
                anchors.fill: parent
                source: "data:" + root.attachment.mime + ";base64," + root.attachment.content
                asynchronous: true
                cache: false
                sourceSize: Qt.size(1024, 768)
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.AlignLeft
                autoTransform: true
            }
            Label { anchors.centerIn: parent; visible: image.status === Image.Error; text: I18n.t("Image preview unavailable"); color: Commons.Color.foreground; }
        }
    }
    Component {
        id: binary
        Label { text: root.attachment.mime; color: Commons.Color.foreground; opacity: 0.5; font.pixelSize: 11; wrapMode: Text.WordWrap; }
    }
    Component {
        id: sourceText
        ScrollView {
            id: scroll
            width: parent ? parent.width : 400
            height: Math.min(240, Math.max(40, code.implicitHeight))
            clip: true
            palette.base: Commons.Color.background
            background: Rectangle { color: Qt.lighter(Commons.Color.background, 1.15); radius: 4; }
            TextArea {
                id: code
                objectName: "attachmentSource"
                text: root.attachment.content
                textFormat: TextEdit.PlainText
                readOnly: true
                selectByMouse: true
                wrapMode: TextEdit.NoWrap
                font.family: "monospace"
                font.pixelSize: 12
                color: Commons.Color.foreground
                background: null
            }
        }
    }
}
