import QtQuick
import QtTest
import ".." as App
import "../Model.js" as Model
import "../CommandActions.js" as Commands

TestCase {
    id: tests
    name: "SlashCommands"
    when: windowShown
    visible: true
    width: 700; height: 650
    property var result: null
    property var jump: null
    QtObject {
        id: mock
        property bool ready: true
        property string activeRollId: "roll"
        property var nodes: []
        property var rolls: [{id:"destination",name:"Reference",nodes:[{id:"target",text:"Needle item",depth:0}]}]
        property string focusedNode: ""
        function nodeColor(value) { return "white"; }
        function snapshot() {}
        function changed() {}
        function toggleTodo(id) {
            nodes[0].text=Commands.toggleTodo(nodes[0].text);
            var next=JSON.parse(JSON.stringify(row.modelData));next.text=nodes[0].text;row.modelData=next;
        }
        function clearTodo(id) { tests.result="clearTodo"; }
        function splitItem(id,start,end) { tests.result={start:start,end:end}; }
        function followInternalLink(link) { tests.jump=link; }
        function applySlashCommand(id,command,expected,value) {
            Commands.target(nodes,id,expected);
            tests.result={id:id,command:command,value:value};
        }
    }
    App.CommandDialog { id: dialog; parent: tests; controller: mock }
    App.OutlineNode { id: row; y: 500; width: 500; controller: mock; modelData: ({id:"node",text:"",depth:0,collapsed:false,color:"default",children:false}) }
    function setup(text) {
        result=null;jump=null;mock.nodes=[Model.node(text,0)];mock.nodes[0].id="node";
        var value=JSON.parse(JSON.stringify(mock.nodes[0]));value.children=false;row.modelData=value;
    }
    function cleanup() { dialog.close(); }
    function test_date_today_and_cancellation() {
        setup("/date");dialog.show("node","date");tryCompare(dialog,"opened",true);
        findChild(dialog,"insertToday").clicked();compare(result.command,"date");compare(result.value,Model.dayKey(new Date()));
        setup("/date");dialog.show("node","date");dialog.close();compare(result,null);compare(mock.nodes[0].text,"/date");
    }
    function test_date_keyboard_only() {
        setup("/date");dialog.show("node","date");wait(10);
        dialog.selectedDate=new Date(2026,9,17,12);
        keyClick(Qt.Key_Right);keyClick(Qt.Key_Down);keyClick(Qt.Key_Return);
        compare(result.command,"date");compare(result.value,"2026-10-25");
    }
    function test_template_keyboard_only() {
        setup("/template");dialog.show("node","template");wait(10);
        keyClick(Qt.Key_Down);keyClick(Qt.Key_Return);
        compare(result.command,"template");compare(result.value,1);
    }
    function test_link_search_keyboard_and_stale_target() {
        setup("/link");dialog.show("node","link");
        var search=findChild(dialog,"linkSearch");search.text="needle";
        var choices=findChild(dialog,"commandChoices");tryCompare(choices,"count",1);
        search.forceActiveFocus();keyClick(Qt.Key_Down);keyClick(Qt.Key_Return);compare(result.value.rollId,"destination");compare(result.value.nodeId,"target");
        setup("/link");dialog.show("node","link");mock.nodes[0].text="Changed meanwhile";
        dialog.submit({rollId:"destination",nodeId:"target"});compare(result,null);verify(dialog.opened);
    }
    function test_template_choices_and_submit() {
        setup("/template");dialog.show("node","template");
        var choices=findChild(dialog,"commandChoices");compare(choices.count,3);
        choices.choose(2);compare(result.command,"template");compare(result.value,2);
    }
    function test_task_checkbox_edits_and_split_offsets() {
        setup("[ ] Write a note");row.edit({position:4});wait(10);
        var editor=findChild(row,"outlineEditor");compare(editor.text,"Write a note");
        findChild(row,"todoCheckbox").clicked();compare(Commands.todoState(mock.nodes[0].text),true);
        row.edit({position:4});wait(10);compare(editor.cursorPosition,0);
        keyClick(Qt.Key_End);keyClick(Qt.Key_Return);compare(result.start,16);
    }
    function test_url_preview_and_return_to_editing() {
        setup("Visit https://www.doyo.be/ for details");
        row.forceActiveFocus();wait(10);
        var preview=findChild(row,"urlPreview");verify(preview.visible);
        verify(preview.text.indexOf('<a href="https://www.doyo.be/">')>=0);
        row.edit({position:0});wait(10);verify(!preview.visible);verify(findChild(row,"outlineEditor").activeFocus);
    }
    function test_internal_link_display() {
        setup("[Reference](flolinr://roll/destination/item/target)");wait(10);
        verify(!findChild(row,"outlineEditor").visible);compare(row.height,23);
        findChild(row,"internalLink").clicked();compare(jump.rollId,"destination");compare(jump.nodeId,"target");
        setup("---");wait(10);verify(findChild(row,"outlineEditor").visible);
    }
}
