import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons as Commons
import "Model.js" as Model
import "CommandActions.js" as Commands

CompactDialog {
    id: root
    objectName: "slashCommandDialog"
    required property var controller
    property string command: "date"
    property string nodeId: ""
    property string rollId: ""
    property string expectedText: ""
    property string focusId: ""
    onClosed: if (controller.activeRollId === rollId && typeof controller.restoreCommandFocus === "function") controller.restoreCommandFocus(focusId || nodeId)
    property date selectedDate: new Date()
    readonly property var targets: Commands.linkTargets(controller.rolls, query.text, rollId, nodeId)
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(command === "date" ? 340 : 520, parent ? parent.width - 32 : 520)
    height: Math.min(command === "date" ? 370 : 430, parent ? parent.height - 32 : 430)
    modal: true
    focus: true
    title: command === "date" ? "📅 " + I18n.t("Insert date") : command === "link" ? "🔗 " + I18n.t("Link to a Roll or item") : "📋 " + I18n.t("Insert template")
    function show(id, kind) {
        var i = Model.indexOf(controller.nodes, id);
        if (i < 0) return;
        focusId = ""; command = kind; nodeId = id; rollId = controller.activeRollId;
        expectedText = controller.nodes[i].text;
        selectedDate = new Date(); query.clear(); message.text = "";
        open();
        Qt.callLater(function() { if (kind === "link") query.forceActiveFocus(); else if (kind === "date") dateKeys.forceActiveFocus(); else choices.forceActiveFocus(); });
    }
    function submit(value) {
        try {
            if (controller.activeRollId !== rollId) throw new Error("The insertion target changed");
            focusId = controller.applySlashCommand(nodeId, command, expectedText, value) || nodeId;
            close();
        } catch (e) { message.text = I18n.t(e.message); }
    }
    contentItem: ColumnLayout {
        spacing: 8
        ColumnLayout {
            id: dateKeys
            visible: root.command === "date"
            Keys.onPressed: function(event) {
                var offset = event.key === Qt.Key_Left ? -1 : event.key === Qt.Key_Right ? 1 : event.key === Qt.Key_Up ? -7 : event.key === Qt.Key_Down ? 7 : 0;
                if (offset) root.selectedDate = new Date(root.selectedDate.getFullYear(),root.selectedDate.getMonth(),root.selectedDate.getDate()+offset,12);
                else if (event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown) root.selectedDate = new Date(root.selectedDate.getFullYear(),root.selectedDate.getMonth()+(event.key === Qt.Key_PageUp ? -1 : 1),1,12);
                else if (event.key === Qt.Key_T) root.selectedDate = new Date();
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.submit(Model.dayKey(root.selectedDate));
                else return;
                event.accepted = true;
            }
            Layout.fillWidth: true
            RowLayout {
                ActionLink { text: "‹"; onClicked: root.selectedDate = new Date(root.selectedDate.getFullYear(),root.selectedDate.getMonth()-1,1,12); }
                Label { Layout.fillWidth: true; text: root.selectedDate.toLocaleDateString(I18n.locale,"MMMM yyyy"); horizontalAlignment: Text.AlignHCenter; }
                ActionLink { text: "›"; onClicked: root.selectedDate = new Date(root.selectedDate.getFullYear(),root.selectedDate.getMonth()+1,1,12); }
            }
            Grid {
                id: days
                Layout.fillWidth: true
                columns: 7
                Repeater {
                    model: [1,2,3,4,5,6,7]
                    Label { required property int modelData; width: days.width/7; height: 20; text: I18n.locale.dayName(modelData,Locale.ShortFormat); horizontalAlignment: Text.AlignHCenter; }
                }
                Repeater {
                    model: Model.calendarDays(root.selectedDate.getFullYear(),root.selectedDate.getMonth())
                    ActionLink {
                        required property var modelData
                        width: days.width/7; height: 28
                        text: String(modelData.day)
                        opacity: modelData.current ? 1 : 0.35
                        highlighted: modelData.key === Model.dayKey(root.selectedDate)
                        onClicked: root.selectedDate = new Date(modelData.key + "T12:00:00")
                    }
                }
            }
            RowLayout {
                ActionLink { objectName: "insertToday"; text: I18n.t("Today"); onClicked: root.submit(Model.dayKey(new Date())); }
                Item { Layout.fillWidth: true; }
                ActionLink { objectName: "insertSelectedDate"; text: I18n.t("Insert") + " " + Model.dayKey(root.selectedDate); onClicked: root.submit(Model.dayKey(root.selectedDate)); }
            }
        }
        TextField {
            id: query
            objectName: "linkSearch"
            visible: root.command === "link"
            Layout.fillWidth: true
            placeholderText: I18n.t("Search Rolls and items")
            onTextChanged: choices.currentIndex = 0
            Keys.onDownPressed: { choices.forceActiveFocus(); choices.currentIndex = Math.max(0,choices.currentIndex); }
            onAccepted: if (choices.count) root.submit(root.targets[Math.max(0,choices.currentIndex)])
        }
        ListView {
            id: choices
            objectName: "commandChoices"
            visible: root.command !== "date"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.command === "link" ? root.targets : (root.controller.commandTemplates || Commands.templates)
            currentIndex: 0
            function choose(index) { root.submit(root.command === "link" ? root.targets[index] : index); }
            delegate: ItemDelegate {
                required property var modelData
                required property int index
                width: choices.width; height: 38
                text: root.command === "link" ? modelData.label : I18n.t(modelData.name)
                highlighted: index === choices.currentIndex
                contentItem: Label { text: parent.text; color: Commons.Color.foreground; opacity: 0.75; font.pixelSize: 12; elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter; }
                onClicked: choices.choose(index)
            }
            Keys.onReturnPressed: if (count) choose(currentIndex)
            Keys.onEnterPressed: if (count) choose(currentIndex)
            ScrollBar.vertical: ScrollBar {}
        }
        Label { visible: root.command !== "date" && !choices.count; text: I18n.t("No results"); opacity: 0.5; }
        Label { id: message; Layout.fillWidth: true; wrapMode: Text.WordWrap; }
        ActionLink { text: I18n.t("Cancel"); onClicked: root.close(); }
    }
}
