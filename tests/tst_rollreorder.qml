import QtQuick
import QtTest
import ".." as App
import "../Model.js" as Model

TestCase {
    id: test
    name: "RollReorder"
    when: windowShown
    visible: true
    width: 320; height: 260
    property var rolls: []
    property var moves: null
    property string selected: ""
    QtObject {
        id: mockController
        property string activeRollId: "a"
        function defaultRollIcon(r) { return r.icon || "🧾"; }
        function selectRoll(id) { test.selected = id; }
        function chooseIcon() {}
        function editRoll(value) {}
        function reorderRoll(source,target,after) {
            test.moves = {source:source,target:target,after:after};
            var next=Model.reorderRolls(test.rolls,source,target,after);
            if (next) test.rolls=next;
        }
    }
    Repeater {
        model: test.rolls
        App.RollEntry {
            required property int index
            controller: mockController
            width: 280
            y: index * 34
            objectName: "roll-" + modelData.id
        }
    }
    function init() {
        rolls=[{id:"a",name:"First",nodes:[]},{id:"b",name:"Second",nodes:[]},{id:"c",name:"Third",nodes:[]}]; moves=null; selected=""; wait(20);
    }
    function test_click_still_selects() {
        mouseClick(findChild(test,"roll-b"),60,14); compare(selected,"b"); compare(moves,null);
    }
    function test_drag_to_upper_half_moves_before() {
        var last=findChild(test,"roll-c");
        mousePress(last,70,14);
        mouseMove(test,70,60,30); mouseMove(test,70,30,30); mouseMove(test,70,5,30);
        mouseRelease(test,70,5);
        tryVerify(function() { return !!moves; });
        compare(moves.source,"c"); compare(moves.target,"a"); compare(moves.after,false);
        compare(rolls.map(function(r) { return r.id; }).join(","),"c,a,b");
    }
    function test_drag_to_lower_half_reorders_without_selecting() {
        var first=findChild(test,"roll-a");
        mousePress(first,70,14);
        mouseMove(test,70,30,30); mouseMove(test,70,60,30); mouseMove(test,70,90,30);
        mouseRelease(test,70,90);
        tryVerify(function() { return !!moves; });
        compare(moves.source,"a"); compare(moves.target,"c"); compare(moves.after,true);
        compare(rolls.map(function(r) { return r.id; }).join(","),"b,c,a"); compare(selected,"");
    }
}
