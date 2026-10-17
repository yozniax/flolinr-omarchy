import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons as Commons

Item {
    id: root
    property bool ready: false
    property bool saving: false
    property string error: ""
    property string mode: "memo"
    readonly property bool opened: window.visible
    readonly property bool hasDraft: mode === "memo" ? !!input.text.trim() : !!outline.text.trim()
    signal submitted(var payload)
    signal dismissed()

    function focusEditor() {
        if (mode === "memo") input.forceActiveFocus();
        else outline.forceActiveFocus();
    }
    function open() {
        window.height = window.implicitHeight;
        window.visible = true;
        Qt.callLater(root.focusEditor);
    }
    function close() { window.visible = false; }
    function chooseMode(value) {
        mode = value;
        Qt.callLater(function() { window.height = window.implicitHeight; });
        Qt.callLater(root.focusEditor);
    }
    function submit() {
        var text = root.mode === "memo" ? input.text : outline.text;
        if (!root.ready || root.saving || !text.trim()) return;
        root.submitted({mode: root.mode, text: text});
    }
    function indent(outdent) {
        var start = Math.max(0, outline.cursorPosition > 0 ? outline.text.lastIndexOf("\n", outline.cursorPosition - 1) + 1 : 0);
        var line = outline.text.slice(start);
        var currentIndent = (line.match(/^[\t ]*/) || [""])[0];
        if (outdent) {
            if (currentIndent.length) {
                var removeCount = currentIndent.endsWith("\t") ? 1 : currentIndent.endsWith("  ") ? 2 : 1;
                outline.remove(start + currentIndent.length - removeCount, start + currentIndent.length);
                if (outline.cursorPosition > start + currentIndent.length - removeCount) outline.cursorPosition -= removeCount;
            }
        } else {
            var insertion = start + currentIndent.length;
            var cursor = outline.cursorPosition;
            outline.insert(insertion, "\t");
            outline.cursorPosition = cursor <= insertion ? insertion + 1 : cursor + 1;
        }
    }
    function saved() {
        input.clear(); outline.clear(); saving = false; error = ""; mode = "memo"; close();
    }

    FloatingWindow {
        id: window
        title: "Flolinr · " + I18n.t("Quick note")
        visible: false
        implicitWidth: 510
        implicitHeight: root.mode === "memo" ? (root.error ? 154 : 130) : (root.error ? 338 : 312)
        minimumSize: Qt.size(370, root.mode === "memo" ? 118 : 230)
        color: Commons.Color.background
        onVisibleChanged: if (!visible) root.dismissed()

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                FlolinrIcon { Layout.preferredWidth: 18; Layout.preferredHeight: 18; }
                Label {
                    text: "Flolinr"
                    color: Commons.Color.foreground
                    font.pixelSize: 13
                    font.bold: true
                }
                Item { Layout.fillWidth: true; }
                ActionLink {
                    text: I18n.t("Quick note")
                    highlighted: root.mode === "memo"
                    enabled: !root.saving
                    onClicked: root.chooseMode("memo")
                }
                ActionLink {
                    text: I18n.t("Outline")
                    highlighted: root.mode === "outline"
                    enabled: !root.saving
                    onClicked: root.chooseMode("outline")
                }
                ActionLink {
                    text: I18n.t("Checklist")
                    highlighted: root.mode === "checklist"
                    enabled: !root.saving
                    onClicked: root.chooseMode("checklist")
                }
            }

            TextField {
                id: input
                objectName: "quickCaptureMemo"
                visible: root.mode === "memo"
                Layout.fillWidth: true
                placeholderText: I18n.t("Today’s note · Enter to save · Esc to cancel")
                enabled: root.ready && !root.saving
                color: Commons.Color.foreground
                maximumLength: 10000
                onAccepted: root.submit()
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Escape && !root.saving) {
                        root.close(); event.accepted = true;
                    } else event.accepted = false;
                }
            }

            ScrollView {
                objectName: "quickCaptureOutlineScroll"
                visible: root.mode !== "memo"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 110
                clip: true
                TextArea {
                    id: outline
                    objectName: "quickCaptureOutline"
                    enabled: root.ready && !root.saving
                    color: Commons.Color.foreground
                    font.family: "monospace"
                    font.pixelSize: 13
                    wrapMode: TextEdit.Wrap
                    textFormat: TextEdit.PlainText
                    placeholderText: root.mode === "checklist" ? I18n.t("Add checklist items, one per line…") : I18n.t("Add outline items, one per line…")
                    Keys.onPressed: function(event) {
                        if ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                            root.submit(); event.accepted = true;
                        } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                            root.indent(event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier));
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape && !root.saving) {
                            root.close(); event.accepted = true;
                        } else event.accepted = false;
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                visible: root.mode !== "memo"
                text: I18n.t("Tab indents · Shift+Tab outdents · nest as needed")
                color: Commons.Color.foreground
                opacity: 0.52
                font.pixelSize: 10
            }
            Label {
                Layout.fillWidth: true
                text: I18n.t(root.error)
                color: Commons.Color.foreground
                visible: !!root.error
                elide: Text.ElideRight
            }
            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: root.mode === "memo" ? I18n.t("Enter saves · Esc closes") : I18n.t("Ctrl+Enter saves")
                    color: Commons.Color.foreground
                    opacity: 0.48
                    font.pixelSize: 10
                }
                Item { Layout.fillWidth: true; }
                ActionLink { text: I18n.t("Cancel"); enabled: !root.saving; onClicked: root.close(); }
                ActionLink { text: root.saving ? I18n.t("Saving…") : I18n.t("Save"); enabled: root.ready && !root.saving && root.hasDraft; onClicked: root.submit(); }
            }
        }
    }
}
