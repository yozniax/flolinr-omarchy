import QtQuick
import Quickshell.Io
import "Model.js" as Model
import "AiSettings.js" as AI

Item {
    id: root
    required property var editor
    required property var settings
    readonly property string homePath: settings.home
    readonly property string dataPath: settings.dataPath
    readonly property var aiConnections: settings.aiConnections
    readonly property string activeAiConnectionId: settings.activeAiConnectionId
    readonly property string language: settings.language
    readonly property var activeConnection: AI.active(aiConnections, activeAiConnectionId)
    readonly property string scopeLabel: {
        var revision = editor.revision;
        var i = Model.indexOf(editor.nodes, editor.zoom);
        return i >= 0 ? (editor.nodes[i].text || I18n.t("(empty item)")).slice(0, 100) + " · " + I18n.t("Zoomed branch")
            : editor.rollName + " · " + I18n.t("Entire Roll");
    }
    property var saving: null
    signal aiStatus(string text)
    signal aiSettingsNeeded()
    readonly property bool busy: process.running
    property var request: null
    property string aiRollId: ""
    property string aiNodeId: ""
    property string aiBefore: ""
    property string aiTask: ""
    property bool aiPreviewReady: false
    property var aiProtection: ({items: []})
    signal markdownSaved(string path)
    signal result(string text)
    signal failure(string text)
    signal done()
    signal notice(string message)
    function saveSettings(path, connections, activeId, draft, key, language) {
        try {
            if (busy) return;
            saving = settings.validate({dataPath: path, aiConnections: connections, activeAiConnectionId: activeId, language: language});
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
        settings.save(value.dataPath, value.aiConnections, value.activeAiConnectionId, value.language);
    }
    function checkAI(connection) { run({operation: "ai_status", connection: connection}); }
    function loginAI(connection) { run({operation: "ai_login", connection: connection}); }
    function testAI(connection, key) { run({operation: "ai_test", connection: connection, key: key}); }
    function deleteKey(connection) { run({operation: "ai_secret_delete", connection: connection}); }
    Connections {
        target: root.settings
        function onSaved() { root.result(I18n.t("Settings saved. AI settings apply immediately. A workspace location change requires shell reload.")); }
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
                else value.roll = {name: roll.name, nodes: roll.nodes.map(function(n) { return {text: Model.interchangeText(n), depth: n.depth}; })};
                run(value);
            }
        } catch (e) { failure(e.message); }
    }
    function generateAI(task, instructions) {
        try {
            if (busy) return;
            aiBefore = "";
            aiPreviewReady = false;
            aiTask = task;
            if (!activeConnection) { aiSettingsNeeded(); return; }
            editor.commitRoll();
            aiRollId = editor.activeRollId; aiNodeId = editor.zoom;
            aiProtection = Model.createAiScope(editor.nodes, aiNodeId);
            aiBefore = aiProtection.snapshot;
            var outline = JSON.parse(aiBefore);
            if (!outline.length) throw new Error(I18n.t("Add an item before using AI"));
            run({operation: "ai", task: task, protectAttachments: aiProtection.items.length > 0, instructions: task === "expand" ? instructions || "" : "", scope: aiNodeId ? "branch" : "roll", connection: activeConnection, text: aiProtection.text});
        } catch (e) { failure(e.message); }
    }
    function applyAI(text) {
        try {
            if (aiTask === "markdown" || !aiPreviewReady) throw new Error(I18n.t("Generate an outline preview before applying"));
            if (!aiBefore || editor.activeRollId !== aiRollId || editor.zoom !== aiNodeId) throw new Error(I18n.t("The displayed scope changed. Generate a new preview first"));
            var next = Model.applyScope(editor.nodes, aiNodeId, aiBefore, text, aiProtection);
            editor.snapshot(); editor.nodes = next; editor.changed(); editor.refresh();
            if (editor.rows.length) editor.focusNode(editor.rows[0].id);
            aiBefore = ""; done();
        } catch (e) { failure(e.message); }
    }
    function saveMarkdown(path, text) {
        if (busy || aiTask !== "markdown" || !aiPreviewReady || !text.trim()) return;
        run({operation: "export", path: path, format: "markdown", text: text,
            overwrite: true, protectedPath: dataPath, aiMarkdown: true});
    }
    function loadAttachment(path, parentId, replaceId, expectedText) {
        if (!busy) run({operation: "attachment_import", path: path, parentId: parentId, replaceId: replaceId, expectedText: expectedText, rollId: editor.activeRollId});
    }
    function saveAttachment(path, attachment) {
        if (!busy) run({operation: "attachment_export", path: path, attachment: attachment, protectedPath: dataPath});
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
                        root.notice(I18n.t("Imported {0} items.", [roll.nodes.length]) + "\n\n" + response.warnings.map(function(warning) { return I18n.t(warning); }).join("\n"));
                } else if (job.operation === "attachment_import") {
                    if (root.editor.activeRollId !== job.rollId) throw new Error("The insertion target changed");
                    root.editor.insertAttachment(response.attachment, job.parentId, job.replaceId, job.expectedText); root.done();
                } else if (job.operation === "attachment_export") root.result(I18n.t("Exported: {0}", [response.path]));
                else if (job.operation === "export" && job.aiMarkdown) root.markdownSaved(response.path);
                else if (job.operation === "export") root.result(I18n.t("Exported: {0}", [response.path]));
                else {
                    if (job.operation === "ai" && job.task === "markdown" && root.aiProtection.items.length)
                        response.text = Model.restoreMarkdownAttachments(response.text, root.aiProtection);
                    if (job.operation === "ai") root.aiPreviewReady = true;
                    root.result(response.text);
                }
            } catch (e) {
                root.saving = null;
                if (job && job.operation === "ai") { root.aiBefore = ""; root.aiPreviewReady = false; }
                root.failure(e.message);
            }
        }
    }
    Timer {
        id: startupCheck
        interval: 2000
        onTriggered: if (root.request && !process.running) { root.aiPreviewReady = false; root.aiBefore = ""; root.request = null; root.failure(I18n.t("Could not start the import / export / AI helper")); }
    }
}
