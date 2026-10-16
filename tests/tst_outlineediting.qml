import QtQuick
import QtTest
import ".." as App
import "../Model.js" as Model

TestCase {
    id: tests
    name: "OutlineEditing"
    when: windowShown
    width: 600
    height: 500
    QtObject {
        id: controller
        property bool ready: true
        property string focusedNode: ""
        property var nodes: []
        property var movement: null
        property var split: null
        property string merged: ""
        property var actionTaken: null
        function nodeColor(color) { return "white"; }
        function snapshot() {}
        function changed() {}
        function navigateFrom(id, direction, target) { movement={id:id,direction:direction,target:target}; return true; }
        function mergeItem(id) { merged=id; }
        function splitItem(id, start, end) { split={id:id,start:start,end:end}; }
        function action(id, kind, dir) { actionTaken={id:id,kind:kind,dir:dir}; }
    }
    App.OutlineNode { id: row; width: 250; controller: controller; modelData: ({id:"a",text:"",depth:0,color:"default",collapsed:false,children:false}) }
    function setup(text) {
        controller.nodes=[{id:"a",text:text,depth:0,color:"default",collapsed:false}];
        row.modelData={id:"a",text:text,depth:0,color:"default",collapsed:false,children:false};
        controller.movement=null; controller.merged=""; controller.split=null; controller.actionTaken=null;
        row.edit({position:0}); wait(10);
        return findChild(row,"outlineEditor");
    }
    function test_backspace_joins_only_at_unselected_start() {
        var e=setup("abc"); e.cursorPosition=0; keyClick(Qt.Key_Backspace);
        compare(controller.merged,"a"); compare(e.text,"abc");
        controller.merged=""; e.cursorPosition=2; keyClick(Qt.Key_Backspace);
        compare(controller.merged,""); compare(e.text,"ac");
        e.select(0,1); keyClick(Qt.Key_Backspace);
        compare(controller.merged,""); compare(e.text,"c");
        setup(""); keyClick(Qt.Key_Backspace); compare(controller.merged,"a");
    }
    function test_enter_passes_cursor_and_selection_for_split() {
        var e=setup("abcdef"); e.cursorPosition=3; keyClick(Qt.Key_Return);
        compare(controller.split.start,3); compare(controller.split.end,3);
        controller.split=null; e.select(1,4); keyClick(Qt.Key_Return);
        compare(controller.split.start,1); compare(controller.split.end,4);
    }
    function test_shift_enter_is_a_line_break_and_does_not_split() {
        var e=setup("abcdef"); e.cursorPosition=3;
        keyClick(Qt.Key_Return,Qt.ShiftModifier);
        compare(controller.split,null); compare(e.text,"abc\ndef");
    }
    function test_up_down_cross_nodes_only_at_visual_edges() {
        var e=setup("first\nmiddle\nlast");
        e.cursorPosition=8; keyClick(Qt.Key_Up); compare(controller.movement,null);
        e.cursorPosition=2; keyClick(Qt.Key_Up); compare(controller.movement.direction,-1);
        controller.movement=null; e.cursorPosition=8; keyClick(Qt.Key_Down); compare(controller.movement,null);
        e.cursorPosition=e.length-1; keyClick(Qt.Key_Down); compare(controller.movement.direction,1);
    }
    function test_wrapped_lines_keep_native_vertical_movement() {
        var e=setup("a long sentence that wraps into several visual lines in this narrow editor and continues here");
        e.cursorPosition=0; keyClick(Qt.Key_Down);
        compare(controller.movement,null); verify(e.cursorPosition>0);
        e.cursorPosition=e.length; keyClick(Qt.Key_Down); compare(controller.movement.direction,1);
    }
    function test_left_right_only_cross_at_text_boundaries() {
        var e=setup("abc"); e.cursorPosition=1; keyClick(Qt.Key_Left); compare(controller.movement,null);
        keyClick(Qt.Key_Left); compare(controller.movement.direction,-1);
        controller.movement=null; e.cursorPosition=2; keyClick(Qt.Key_Right); compare(controller.movement,null);
        keyClick(Qt.Key_Right); compare(controller.movement.direction,1); compare(controller.movement.target.position,0);
    }
    function test_shift_selection_and_alt_branch_move_are_preserved() {
        var e=setup("abc"); e.cursorPosition=0; keyClick(Qt.Key_Right,Qt.ShiftModifier);
        compare(controller.movement,null); compare(e.selectedText,"a");
        e.deselect(); keyClick(Qt.Key_Down,Qt.AltModifier);
        compare(controller.actionTaken.kind,"move"); compare(controller.actionTaken.dir,1);
    }
    function test_edit_positions_cursor_at_split_start_and_vertical_target() {
        var e=setup("first\nlast"); row.edit({position:0}); compare(e.cursorPosition,0);
        row.edit({x:0,direction:-1}); compare(e.cursorPosition,6);
        row.edit({x:0,direction:1}); compare(e.cursorPosition,0);
    }
}
