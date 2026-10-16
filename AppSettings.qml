import QtQuick
import Quickshell
import Quickshell.Io
import "AiSettings.js" as AI

Item {
    id: root
    readonly property string home: Quickshell.env("HOME")
    readonly property string path: (Quickshell.env("XDG_CONFIG_HOME") || home + "/.config") + "/flolinr/settings.json"
    property bool ready: false
    property string dataPath: home + "/.local/share/flolinr/outline.json"
    property var aiConnections: []
    property string activeAiConnectionId: ""
    property var pending: null
    property string error: ""
    signal saved()
    function validate(value) {
        if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error("Expected settings object");
        var path = value.dataPath || root.dataPath;
        if (typeof path !== "string" || !(path.startsWith("/") || path.startsWith("~/")) || !path.endsWith(".json")) throw new Error("Choose an absolute .json file path");
        var ai = AI.migrate(value);
        return {dataPath: path.replace(/^~\//, root.home + "/"), aiConnections: ai.aiConnections, activeAiConnectionId: ai.activeAiConnectionId};
    }
    function save(path, connections, activeId) {
        try {
            pending = validate({dataPath: path, aiConnections: connections, activeAiConnectionId: activeId});
            file.setText(JSON.stringify(pending, null, 2)); root.error = "";
        } catch (e) { root.error = e.message; }
    }
    Process {
        command: ["mkdir", "-p", root.path.slice(0, root.path.lastIndexOf("/"))]
        running: true
        onExited: function(code) { if (code === 0) file.path = root.path; else root.error = "Could not create settings directory"; }
    }
    FileView {
        id: file
        atomicWrites: true
        blockWrites: true
        printErrors: false
        // Saving a different dataPath requires a shell reload, never switches a dirty editor.
        onLoaded: {
            if (root.ready) return;
            try {
                var value = root.validate(JSON.parse(text()));
                root.dataPath = value.dataPath; root.aiConnections = value.aiConnections; root.activeAiConnectionId = value.activeAiConnectionId; root.ready = true;
            } catch (e) { root.error = e.message; }
        }
        onLoadFailed: function(error) {
            if (error === FileViewError.FileNotFound) root.ready = true;
            else root.error = "Could not read settings: " + error;
        }
        onSaved: {
            if (root.pending) {
                root.aiConnections = root.pending.aiConnections;
                root.activeAiConnectionId = root.pending.activeAiConnectionId;
                root.pending = null;
            }
            root.saved();
        }
        onSaveFailed: function(error) { root.error = "Could not save settings: " + error; }
    }
}
