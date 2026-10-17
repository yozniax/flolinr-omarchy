pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.Commons as Commons
import "Model.js" as Model
import "CommandActions.js" as Commands

Item {
    id: row
    required property var controller
    signal colorRequested(string nodeId)
    signal editAttachmentRequested(string nodeId)
    signal saveAttachmentRequested(var attachment)
    signal removeAttachmentRequested(string nodeId)
    required property var modelData
    readonly property var todo: Commands.todoState(modelData.text)
    readonly property var internalLink: Commands.parseLink(modelData.text)
    property bool editingLink: false
    readonly property bool urlPreview: !row.modelData.attachment && !row.internalLink && Commands.hasUrl(textEditor.text) && !textEditor.activeFocus
    readonly property int todoPrefixLength: row.todo === null ? 0 : (/^\[[ xX]\]\s?/.exec(modelData.text) || [""])[0].length
    height: row.modelData.attachment ? Math.max(23, attachmentBody.height) : row.urlPreview ? Math.max(23, urlText.implicitHeight) : (row.internalLink && !row.editingLink) ? 23 : Math.max(23, textEditor.contentHeight)
    onActiveFocusChanged: if (activeFocus) controller.focusedNode = modelData.id
    Keys.onPressed: function(event) {
        if (row.internalLink && !row.editingLink && ((event.key === Qt.Key_Return && (event.modifiers & Qt.ControlModifier)) || event.key === Qt.Key_Space)) {
            row.controller.followInternalLink(row.internalLink); event.accepted = true; return;
        }
        if (row.internalLink && event.key === Qt.Key_F2) {
            row.editingLink = true; textEditor.forceActiveFocus(); event.accepted = true; return;
        }
        if (!row.modelData.attachment && !(row.internalLink && !row.editingLink)) return;
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            row.controller.action(row.modelData.id, "indent", event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1);
        } else if ((event.modifiers & Qt.AltModifier) && (event.key === Qt.Key_Up || event.key === Qt.Key_Down)) {
            row.controller.action(row.modelData.id, "move", event.key === Qt.Key_Up ? -1 : 1);
        } else if (!event.modifiers && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            row.controller.addAfterAttachment(row.modelData.id);
        } else if (!event.modifiers && (event.key === Qt.Key_Up || event.key === Qt.Key_Down)) {
            row.controller.navigateFrom(row.modelData.id, event.key === Qt.Key_Up ? -1 : 1, {position: 0});
        } else return;
        event.accepted = true;
    }
    Loader {
        id: attachmentBody
        x: textEditor.x; y: 0; width: textEditor.width
        active: !!row.modelData.attachment
        height: item ? item.implicitHeight : 0
        sourceComponent: AttachmentView {
            width: attachmentBody.width
            attachment: row.modelData.attachment
            collapsed: !!row.modelData.collapsed
            onExpandRequested: row.controller.setAttachmentCollapsed(row.modelData.id, false)
            onCollapseRequested: row.controller.setAttachmentCollapsed(row.modelData.id, true)
            onEditRequested: row.editAttachmentRequested(row.modelData.id)
            onSaveRequested: row.saveAttachmentRequested(row.modelData.attachment)
            onRemoveRequested: row.removeAttachmentRequested(row.modelData.id)
        }
    }
    function edit(target) {
        if (row.modelData.attachment || (row.internalLink && !row.editingLink)) { row.forceActiveFocus(); return; }
        textEditor.forceActiveFocus();
        if (target && target.x !== undefined) {
            var edge = textEditor.positionToRectangle(target.direction > 0 ? 0 : textEditor.length);
            textEditor.cursorPosition = textEditor.positionAt(target.x, edge.y + edge.height / 2);
        } else textEditor.cursorPosition = target && target.position !== undefined ? Math.max(0, Math.min(target.position - row.todoPrefixLength, textEditor.length)) : textEditor.length;
    }
    Rectangle {
        anchors.fill: parent
        radius: 4
        color: Commons.Color.accent
        opacity: textEditor.activeFocus || row.activeFocus ? 0.045 : 0
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
    CheckBox {
        objectName: "todoCheckbox"
        visible: row.todo !== null && !row.modelData.attachment
        x: row.modelData.depth * 24 + 35; y: -2
        width: 28; height: 26
        checked: row.todo === true
        enabled: row.controller.ready
        Accessible.name: row.modelData.text.slice(3).trim() || I18n.t("Task")
        onClicked: row.controller.toggleTodo(row.modelData.id)
    }
    ActionLink {
        objectName: "internalLink"
        visible: !!row.internalLink && !row.editingLink && !row.modelData.attachment
        x: row.modelData.depth * 24 + 40
        width: Math.max(40, parent.width - x - 30); height: 23
        horizontalPadding: 0; verticalPadding: 0
        text: "🔗 " + (row.internalLink ? row.internalLink.label : "")
        contentItem: Label { text: parent.text; font.pixelSize: 16; color: Commons.Color.accent; elide: Text.ElideRight; }
        onClicked: row.controller.followInternalLink(row.internalLink)
        MouseArea {
            anchors.fill: parent; acceptedButtons: Qt.RightButton
            onClicked: { row.editingLink = true; textEditor.forceActiveFocus(); }
        }
    }
    ActionLink {
        objectName: "deleteInternalLink"
        visible: !!row.internalLink && !row.editingLink && !row.modelData.attachment
        x: parent.width - 26; y: 0; width: 26; height: 23
        text: "×"
        Accessible.name: I18n.t("Delete")
        ToolTip.visible: hovered
        ToolTip.text: I18n.t("Delete")
        onClicked: row.controller.removeNode(row.modelData.id)
    }
    Text {
        id: urlText
        objectName: "urlPreview"
        z: 1
        visible: row.urlPreview
        x: textEditor.x; width: textEditor.width
        text: Commands.linkify(textEditor.text)
        textFormat: Text.RichText
        wrapMode: Text.Wrap
        font: textEditor.font
        color: row.controller.nodeColor(row.modelData.color)
        linkColor: Commons.Color.accent
        onLinkActivated: function(link) { if (/^https?:\/\//i.test(link)) Qt.openUrlExternally(link); }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            cursorShape: urlText.linkAt(mouseX,mouseY) ? Qt.PointingHandCursor : Qt.IBeamCursor
            onPressed: function(mouse) {
                if (mouse.button===Qt.RightButton || !urlText.linkAt(mouse.x,mouse.y)) { row.edit({position:row.modelData.text.length}); }
                else mouse.accepted=false;
            }
        }
    }
    TextArea {
        id: textEditor
        objectName: "outlineEditor"
        opacity: row.urlPreview ? 0 : (row.todo === true ? 0.55 : 1)
        visible: !row.modelData.attachment && (!row.internalLink || row.editingLink)
        x: row.modelData.depth * 24 + (row.todo !== null ? 66 : 40)
        width: parent.width - x
        height: Math.max(23, contentHeight)
        text: row.modelData.text.slice(row.todoPrefixLength)
        textFormat: TextEdit.PlainText
        color: row.controller.nodeColor(row.modelData.color)
        selectionColor: Commons.Color.accent
        font.family: Commons.Style.fontFamily
        font.pixelSize: 16
        font.strikeout: row.todo === true
        wrapMode: TextEdit.Wrap
        readOnly: !row.controller.ready
        padding: 0
        topPadding: 0
        bottomPadding: 0
        background: Item {}
        property bool sessionRecorded: false
        onInputMethodComposingChanged: if (!inputMethodComposing) slashMenu.update()
        onActiveFocusChanged: {
            if (activeFocus) { row.controller.focusedNode = row.modelData.id; slashMenu.update(); }
            else { sessionRecorded = false; slashMenu.close(); }
        }
        onTextChanged: {
            if (!activeFocus || !row.controller.ready) return;
            var i = Model.indexOf(row.controller.nodes, row.modelData.id);
            var value = row.modelData.text.slice(0, row.todoPrefixLength) + text;
            if (i >= 0 && row.controller.nodes[i].text !== value) {
                if (!sessionRecorded) { row.controller.snapshot(); sessionRecorded = true; }
                row.controller.nodes[i].text = value; Model.touch([row.controller.nodes[i]]); row.controller.changed();
            }
            slashMenu.update();
        }
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
            if (inputMethodComposing) return;
            if (slashMenu.handleKey(event)) return;
            var kind = "", dir = 0;
            var plain = !(event.modifiers & (Qt.ShiftModifier | Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier));
            if (plain && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                event.accepted = true;
                row.controller.splitItem(row.modelData.id, selectionStart + row.todoPrefixLength, selectionEnd + row.todoPrefixLength);
                return;
            }
            if (plain && event.key === Qt.Key_Backspace && cursorPosition === 0 && selectionStart === selectionEnd) {
                event.accepted = true;
                if (row.todo !== null) row.controller.clearTodo(row.modelData.id);
                else row.controller.mergeItem(row.modelData.id);
                return;
            }
            if (plain && selectionStart === selectionEnd) {
                var caret = positionToRectangle(cursorPosition);
                var up = event.key === Qt.Key_Up && caret.y <= positionToRectangle(0).y + 1;
                var down = event.key === Qt.Key_Down && caret.y >= positionToRectangle(length).y - 1;
                var left = event.key === Qt.Key_Left && cursorPosition === 0;
                var right = event.key === Qt.Key_Right && cursorPosition === length;
                if (up || down || left || right) {
                    var direction = up || left ? -1 : 1;
                    var target = up || down ? {x: caret.x, direction: direction} : {position: left ? 2147483647 : 0};
                    if (row.controller.navigateFrom(row.modelData.id, direction, target)) { event.accepted = true; return; }
                }
            }
            if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                kind = "indent"; dir = event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1;
            } else if ((event.modifiers & Qt.AltModifier) && (event.key === Qt.Key_Up || event.key === Qt.Key_Down)) {
                kind = "move"; dir = event.key === Qt.Key_Up ? -1 : 1;
            }
            if (kind) { event.accepted = true; row.controller.action(row.modelData.id, kind, dir); }
        }
    }
    SlashMenu { id: slashMenu; objectName: "nodeSlashMenu"; editor: textEditor; controller: row.controller; nodeId: row.modelData.id }
}
