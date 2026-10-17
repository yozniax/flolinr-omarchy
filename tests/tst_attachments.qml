import QtQuick
import QtQuick.Dialogs as Dialogs
import QtTest
import ".." as App
import "../Model.js" as Model

TestCase {
    id: tests
    name: "Attachments"
    when: windowShown
    visible: true
    width: 700
    height: 700
    property var saved: null
    property var imported: null
    property var a: ({kind:"code",name:"test.html",mime:"text/plain",language:"html",content:"  <script>neverRun()</script>\n\t<div/>\n"})
    QtObject {
        id: editor
        property bool ready: true
        property string focusedNode: ""
        property var nodes: [{id:"target",text:"/insert",depth:0}]
        function attachmentTarget() { return "target"; }
        function insertAttachment(value, parent, target, expected) { tests.saved={attachment:value,target:target,expected:expected}; }
        function updateAttachment(id,value) { tests.saved={attachment:value,id:id}; }
        function setAttachmentCollapsed(id, value) {
            var next=JSON.parse(JSON.stringify(row.modelData));next.collapsed=value;row.modelData=next;
        }
        function nodeColor(color) { return "white"; }
    }
    QtObject {
        id: controller
        property bool busy: false
        property var editor: editor
        function loadAttachment(path,parent,target,expected) { tests.imported={path:path,target:target,expected:expected}; }
        function saveAttachment(path,value) { tests.saved={path:path,attachment:value}; }
    }
    App.AttachmentDialog { id: dialog; parent: tests; controller: controller }
    Component {
        id: imageComponent
        App.AttachmentView {
            width: 300
            attachment: ({kind:"image",name:"pixel.png",mime:"image/png",language:"",content:"iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNoOPD/PwAHQgM/vskMEgAAAABJRU5ErkJggg=="})
        }
    }
    App.OutlineNode {
        id: row
        y: 400
        width: 600
        controller: editor
        modelData: ({id:"a",text:"test.html",depth:2,color:"default",collapsed:false,children:true,attachment:tests.a})
    }
    function cleanup() { dialog.close(); findChild(dialog,"attachmentSavePicker").close(); }
    function test_code_is_plaintext_and_folding_releases_preview() {
        wait(20);
        var source=findChild(row,"attachmentSource");
        verify(source); compare(source.text,tests.a.content); compare(source.textFormat,TextEdit.PlainText);
        verify(source.readOnly); compare(source.wrapMode,TextEdit.NoWrap);
        row.grabToImage(function(result) { result.saveToFile("/tmp/flolinr-attachment-preview.png"); });
        wait(50);
        var filename=findChild(row,"attachmentFilename");
        compare(filename.horizontalAlignment,Text.AlignRight); compare(filename.font.pixelSize,9); compare(filename.opacity,0.35);
        verify(!findChild(row,"outlineEditor").visible);
        var expandedHeight=row.height;
        findChild(row,"attachmentCollapse").clicked();
        tryVerify(function() { return row.height < expandedHeight; }); compare(findChild(row,"attachmentSource"),null);
        compare(findChild(row,"attachmentExpand").text,"expand"); verify(filename.visible);
        findChild(row,"attachmentExpand").clicked();
        tryVerify(function() { return !!findChild(row,"attachmentSource"); });
    }
    function test_image_is_loaded_from_embedded_data_with_bounded_size() {
        var view=createTemporaryObject(imageComponent,tests);
        var image=findChild(view,"attachmentImage");
        verify(image.source.toString().startsWith("data:image/png;base64,"));
        tryCompare(image,"status",Image.Ready);
        verify(image.sourceSize.width<=1024); verify(image.sourceSize.height<=768);
    }
    function test_insertion_keeps_code_and_target_and_safe_file_dialogs() {
        dialog.showSlash("target","insert");
        findChild(dialog,"attachmentName").text="test.html";

        findChild(dialog,"attachmentCode").text=tests.a.content;
        compare(findChild(dialog,"attachmentLanguage").text,"html");
        dialog.saveCode();
        compare(tests.saved.target,"target"); compare(tests.saved.expected,"/insert"); compare(tests.saved.attachment.content,tests.a.content);
        dialog.showSlash("target","insert");
        var picker=findChild(dialog,"insertFilePicker");
        verify(dialog.opened); compare(picker.visible,false);
        compare(picker.nameFilters.length,1); verify(picker.nameFilters[0].endsWith("(*)"));
        verify((picker.options & Dialogs.FileDialog.DontUseNativeDialog)!==0);
        picker.selectedFile=Qt.resolvedUrl("../manifest.json"); picker.accepted();
        compare(tests.imported.target,"target"); verify(tests.imported.path.endsWith(".json"));
        dialog.close();
        dialog.saveFile(tests.a);
        var savePicker=findChild(dialog,"attachmentSavePicker");
        verify((savePicker.options & Dialogs.FileDialog.DontUseNativeDialog)!==0);
        savePicker.selectedFile="file:///tmp/saved.html"; savePicker.accepted();
        compare(tests.saved.attachment.content,tests.a.content);
    }
}
