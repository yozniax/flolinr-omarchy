import QtQuick
import Quickshell.Io
import "Model.js" as Model
import "AiSettings.js" as AI

Item {
    id: root
    required property var editor
    required property var settings
    readonly property string dataPath: settings.dataPath
    readonly property var aiConnections: settings.aiConnections
    readonly property string activeAiConnectionId: settings.activeAiConnectionId
    readonly property var activeConnection: AI.active(aiConnections, activeAiConnectionId)
    readonly property string scopeLabel: {
        var revision = editor.revision;
        var i = Model.indexOf(editor.nodes, editor.zoom);
        return i >= 0 ? (editor.nodes[i].text || "(empty item)").slice(0, 100) + " · entire zoomed branch"
            : editor.rollName + " · entire Roll";
    }
    property var saving: null
    signal aiStatus(string text)
    signal aiSettingsNeeded()
    readonly property bool busy: process.running
    property var request: null
    property string aiRollId: ""
    property string aiNodeId: ""
    property string aiBefore: ""
    signal result(string text)
    signal failure(string text)
    signal done()
    signal notice(string message)
    function saveSettings(path, connections, activeId, draft, key) {
        try {
            if (busy) return;
            saving = settings.validate({dataPath: path, aiConnections: connections, activeAiConnectionId: activeId});
            if (key) run({operation: "ai_secret_save", connection: draft, key: key});
            else saveLocation();
        } catch (e) { saving = null; failure(e.message); }
    }
    function saveLocation() {
        if (!editor.ready) { finishSettings(); return; }
        editor.commitRoll();
        run({operation: "location", path: saving.dataPath, text: Model.encodeWorkspace(editor.activeRollId, editor.rolls)});
    }
    function finishSettings() {
        var value = saving; saving = null;
        settings.save(value.dataPath, value.aiConnections, value.activeAiConnectionId);
    }
    function checkAI(connection) { run({operation: "ai_status", connection: connection}); }
    function loginAI(connection) { run({operation: "ai_login", connection: connection}); }
    function testAI(connection, key) { run({operation: "ai_test", connection: connection, key: key}); }
    function deleteKey(connection) { run({operation: "ai_secret_delete", connection: connection}); }
    Connections {
        target: root.settings
        function onSaved() { root.result("Settings saved. AI settings apply immediately. A workspace location change requires shell reload."); }
        function onErrorChanged() { if (root.settings.error) root.failure(root.settings.error); }
    }
    function run(value) {
        if (busy) return;
        request = value;
        process.stdinEnabled = true;
        process.running = true;
        startupCheck.restart();
    }
    function transfer(mode, path, format) {
        try {
            editor.commitRoll();
            if (mode === "import") run({operation: "import", path: path, format: format});
            else {
                var i = Model.indexOf(editor.rolls, editor.activeRollId);
                if (i < 0) return;
                var roll = editor.rolls[i];
                var value = {operation: "export", path: path, format: format, overwrite: true, protectedPath: dataPath};
                if (format === "markdown") value.text = Model.exportMarkdown(roll);
                else value.roll = {name: roll.name, nodes: roll.nodes.map(function(n) { return {text: n.text, depth: n.depth}; })};
                run(value);
            }
        } catch (e) { failure(e.message); }
    }
    function generateAI(task) {
        try {
            if (busy) return;
            aiBefore = "";
            if (!activeConnection) { aiSettingsNeeded(); return; }
            editor.commitRoll();
            aiRollId = editor.activeRollId; aiNodeId = editor.zoom;
            aiBefore = Model.scopeSnapshot(editor.nodes, aiNodeId);
            var outline = JSON.parse(aiBefore);
            if (!outline.length) throw new Error("Add an item before using AI");
            run({operation: "ai", task: task, scope: aiNodeId ? "branch" : "roll", connection: activeConnection, text: Model.markdownNodes(outline, outline[0].depth)});
        } catch (e) { failure(e.message); }
    }
    function applyAI(text) {
        try {
            if (!aiBefore || editor.activeRollId !== aiRollId || editor.zoom !== aiNodeId) throw new Error("The displayed scope changed. Generate a new preview first");
            var next = Model.applyScope(editor.nodes, aiNodeId, aiBefore, text);
            editor.snapshot(); editor.nodes = next; editor.changed(); editor.refresh();
            if (editor.rows.length) editor.focusNode(editor.rows[0].id);
            aiBefore = ""; done();
        } catch (e) { failure(e.message); }
    }
    Process {
        id: process
        command: ["python3", "-B", decodeURIComponent(Qt.resolvedUrl("bridge.py").toString().replace(/^file:\/\//, ""))]
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
                if (job.operation === "ai_secret_save") { root.saveLocation(); }
                else if (job.operation === "location") { root.finishSettings(); }
                else if (["ai_status", "ai_login", "ai_test", "ai_secret_delete"].indexOf(job.operation) >= 0) root.aiStatus(response.text);
                else if (job.operation === "import") {
                    var roll = response.format === "markdown" ? Model.importMarkdown(response.text, response.name) : Model.importOutline(response.items, response.name);
                    root.editor.rolls = root.editor.rolls.concat([roll]);
                    root.editor.selectRoll(roll.id, false); root.editor.changed();
                    if (roll.nodes.length) root.editor.focusNode(roll.nodes[0].id);
                    root.done();
                    if (response.warnings && response.warnings.length)
                        root.notice("Imported " + roll.nodes.length + " items.\n\n" + response.warnings.join("\n"));
                } else if (job.operation === "export") root.result("Exported: " + response.path);
                else root.result(response.text);
            } catch (e) {
                root.saving = null;
                if (job && job.operation === "ai") root.aiBefore = "";
                root.failure(e.message);
            }
        }
    }
    Timer {
        id: startupCheck
        interval: 2000
        onTriggered: if (root.request && !process.running) { root.request = null; root.failure("Could not start the import / export / AI helper"); }
    }
}
