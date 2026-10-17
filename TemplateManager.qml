import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons as Commons
import "Templates.js" as Templates

CompactDialog {
    id: root
    required property var settings
    property var drafts: []
    property bool saving: false
    property bool loading: false
    property string message: ""
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(580,parent ? parent.width-32 : 580)
    height: Math.min(560,parent ? parent.height-32 : 560)
    title: "📋 " + I18n.t("Templates")
    modal: true; focus: true
    palette.base: Qt.lighter(Commons.Color.background,1.3)
    palette.button: Qt.lighter(Commons.Color.background,1.5)
    function show() {
        drafts=Templates.normalize(settings.templates);message="";saving=false;
        open();choose(drafts.length ? 0 : -1);
    }
    function choose(index) {
        loading=true;picker.currentIndex=index;picker.previousIndex=index;
        name.text=index>=0 ? drafts[index].name : "";
        body.text=index>=0 ? Templates.toText(drafts[index]) : "";
        loading=false;
    }
    function commit() {
        var index=picker.currentIndex;
        if (index<0) return;
        var next=drafts.slice();next[index]=Templates.fromText(name.text,body.text);drafts=next;
    }
    function select(index) {
        try { commit();choose(index);message=""; }
        catch(e) { message=I18n.t(e.message); }
    }
    function save() {
        try { commit();Templates.normalize(drafts);saving=true;if (settings.saveTemplates(drafts) === false) { saving=false;message=settings.error; } }
        catch(e) { saving=false;message=I18n.t(e.message); }
    }
    Connections {
        target: root.settings
        function onSaved() { if (root.saving) { root.saving=false;root.close(); } }
        function onErrorChanged() { if (root.opened && root.settings.error) { root.saving=false;root.message=root.settings.error; } }
    }
    contentItem: ColumnLayout {
        spacing: 8
        enabled: !root.saving
        RowLayout {
            ComboBox {
                id: picker;objectName:"templatePicker"
                Layout.fillWidth:true;model:root.drafts;textRole:"name"
                property int previousIndex: 0
                onPressedChanged: if (pressed) previousIndex=currentIndex
                onActivated: function(index) { currentIndex=previousIndex;root.select(index);previousIndex=currentIndex; }
            }
            ActionLink {
                text:I18n.t("Add");onClicked: {
                    try { root.commit();root.drafts=root.drafts.concat([{name:"New template",title:"New template",items:[]}]);root.choose(root.drafts.length-1);name.forceActiveFocus(); }
                    catch(e) { root.message=I18n.t(e.message); }
                }
            }
            ActionLink { text:I18n.t("Delete");enabled:picker.currentIndex>=0;onClicked: { var next=root.drafts.slice();next.splice(picker.currentIndex,1);root.drafts=next;root.choose(Math.min(picker.currentIndex,next.length-1)); } }
        }
        TextField { id:name;objectName:"templateName";Layout.fillWidth:true;enabled:picker.currentIndex>=0;placeholderText:I18n.t("Template name");maximumLength:200; }
        ModalSection { title: "Template outline" }
        Label { Layout.fillWidth:true;wrapMode:Text.WordWrap;text:I18n.t("One item per line. Use two spaces or a Tab to indent.");opacity:0.6; }
        ScrollView {
            Layout.fillWidth:true;Layout.fillHeight:true;clip:true
            TextArea { id:body;objectName:"templateBody";enabled:picker.currentIndex>=0;font.family:"monospace";font.pixelSize:12;textFormat:TextEdit.PlainText;wrapMode:TextEdit.NoWrap; Keys.onTabPressed: function(event) { insert(cursorPosition,"\t"); event.accepted=true; } }
        }
        Label { Layout.fillWidth:true;wrapMode:Text.WordWrap;text:root.message; }
        RowLayout {
            ActionLink { text:I18n.t("Cancel");onClicked:root.close(); }
            ActionLink { text:I18n.t("Restore defaults");onClicked: { root.drafts=Templates.normalize(Templates.defaults);root.choose(0); } }
            Item { Layout.fillWidth:true; }
            ActionLink { objectName:"saveTemplates";text:I18n.t("Save");onClicked:root.save(); }
        }
    }
}
