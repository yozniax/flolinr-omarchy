import QtQuick
import QtTest
import ".." as App

TestCase {
    id: tests
    name: "OutlineScroll"
    when: windowShown
    visible: true
    width: 640
    height: 480
    property int created: 0
    QtObject {
        id: fakeController
        property bool ready: true
        property string focusedNode: ""
        function nodeColor(color) { return "white"; }
    }
    App.OutlineList {
        id: view
        width: 600; height: 400
        delegate: App.OutlineNode {
            width: view.width
            controller: fakeController
            Component.onCompleted: tests.created++
        }
    }
    function initTestCase() {
        var rows = [];
        for (var i = 0; i < 1600; ++i)
            rows.push({id: "n" + i, text: i % 4 ? "Note " + i : "Note " + i + "\nSecond line\nThird line", depth: i % 3, color: "default", children: false});
        view.model = rows;
        view.forceLayout();
        wait(150);
    }
    function test_wheel_and_virtualization() {
        verify(created < 200, "1600 editors must not be instantiated upfront");
        var start = view.contentY;
        mouseWheel(view, 180, 90, 0, -120);
        tryVerify(function() { return view.contentY > start; });
        compare(Math.round(view.contentY - start), 96);
        mouseWheel(view, 180, 90, 0, 120);
        tryCompare(view, "contentY", start);
        mouseWheel(view, 180, 90, 0, 120);
        compare(view.contentY, view.originY);
        view.positionViewAtEnd();
        wait(150);
        verify(view.atYEnd);
        mouseWheel(view, 180, 90, 0, -120);
        verify(view.atYEnd);
        mouseWheel(view, 180, 90, 0, 120);
        verify(!view.atYEnd);
        verify(created < 300, "jumping through a large outline should stay virtualized");
    }
}
