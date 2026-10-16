import QtQuick
import Quickshell.Io
import "Model.js" as Model

Item {
    id: root
    required property var editor
    required property var settings
    readonly property string dataPath: settings.dataPath
    readonly property var aiCommand: settings.aiCommand
    readonly property bool busy: process.running
    property var request: null
    property string aiRollId: ""
    property string aiNodeId: ""
    property string aiBefore: ""
    signal result(string text)
    signal failure(string text)
    signal done()
    function saveSettings(path, command) {
        try {
            var next = settings.validate({dataPath: path, aiCommand: JSON.parse(command)});
            if (!editor.ready) { settings.save(path, command); return; }
            editor.commitRoll();
            run({operation: "location", path: next.dataPath, commandText: command, text: Model.encodeWorkspace(editor.activeRollId, editor.rolls)});
        } catch (e) { failure(e.message); }
    }
    Connections {
        target: root.settings
        function onSaved() { root.result("Settings saved. Reload the shell to use the new location or CLI command."); }
        function onErrorChanged() { if (root.settings.error) root.failure(root.settings.error); }
    }
    function run(value) {
        if (busy) return;
        request = value;
        process.stdinEnabled = true;
        process.running = true;
        startupCheck.restart();
    }
    function markdown(mode, path) {
        editor.commitRoll();
        if (mode === "import") run({operation: "import", path: path});
        else {
            var i = Model.indexOf(editor.rolls, editor.activeRollId);
            if (i >= 0) run({operation: "export", path: path, text: Model.exportMarkdown(editor.rolls[i])});
        }
    }
    function generateAI(task) {
        try {
            editor.commitRoll();
            aiRollId = editor.activeRollId; aiNodeId = editor.focusedNode || editor.zoom;
            aiBefore = Model.branchSnapshot(editor.nodes, aiNodeId);
            var branch = JSON.parse(aiBefore);
            run({operation: "ai", task: task, command: aiCommand, text: Model.markdownNodes(branch, branch[0].depth)});
        } catch (e) { failure(e.message); }
    }
    function applyAI(text) {
        try {
            if (!aiBefore || editor.activeRollId !== aiRollId) throw new Error("Generate a preview for the current branch first");
            var next = Model.applyBranch(editor.nodes, aiNodeId, aiBefore, text);
            editor.snapshot(); editor.nodes = next; editor.changed(); editor.refresh(aiNodeId);
            aiBefore = ""; done();
        } catch (e) { failure(e.message); }
    }
    Process {
        id: process
        command: ["python3", decodeURIComponent(Qt.resolvedUrl("bridge.py").toString().replace(/^file:\/\//, ""))]
        stdinEnabled: true
        onStarted: { write(JSON.stringify(root.request)); stdinEnabled = false; }
        stdout: StdioCollector { id: output; waitForEnd: true }
        stderr: StdioCollector { id: errors; waitForEnd: true }
        onExited: function(code) {
            startupCheck.stop();
            var job = root.request; root.request = null;
            try {
                var response = JSON.parse(output.text);
                if (!response.ok) throw new Error(response.error);
                if (job.operation === "location") { root.settings.save(job.path, job.commandText); }
                else if (job.operation === "import") {
                    var roll = Model.importMarkdown(response.text, response.name);
                    root.editor.rolls = root.editor.rolls.concat([roll]);
                    root.editor.selectRoll(roll.id, false); root.editor.changed(); root.done();
                } else if (job.operation === "export") root.result("Exported: " + response.path);
                else root.result(response.text);
            } catch (e) { root.failure(e.message + (errors.text ? " · " + errors.text.slice(-1000) : "")); }
        }
    }
    Timer {
        id: startupCheck
        interval: 2000
        onTriggered: if (root.request && !process.running) { root.request = null; root.failure("Could not start the Markdown / AI helper"); }
    }
}
