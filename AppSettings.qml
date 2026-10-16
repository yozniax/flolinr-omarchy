import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    readonly property string home: Quickshell.env("HOME")
    readonly property string path: (Quickshell.env("XDG_CONFIG_HOME") || home + "/.config") + "/flolinr/settings.json"
    property bool ready: false
    property string dataPath: home + "/.local/share/flolinr/outline.json"
    property var aiCommand: ["claude", "-p", "--tools", "", "--strict-mcp-config", "--no-session-persistence"]
    property string error: ""
    signal saved()
    function validate(value) {
        if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error("Expected settings object");
        var path = value.dataPath || root.dataPath;
        if (typeof path !== "string" || !(path.startsWith("/") || path.startsWith("~/")) || !path.endsWith(".json")) throw new Error("Choose an absolute .json file path");
        var command = value.aiCommand || root.aiCommand;
        if (!Array.isArray(command) || !command.length || !command.every(function(v) { return typeof v === "string"; })) throw new Error("AI command must be a JSON array");
        return {dataPath: path.replace(/^~\//, root.home + "/"), aiCommand: command};
    }
    function save(path, command) {
        try { file.setText(JSON.stringify(validate({dataPath: path, aiCommand: JSON.parse(command)}), null, 2)); root.error = ""; }
        catch (e) { root.error = e.message; }
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
                root.dataPath = value.dataPath; root.aiCommand = value.aiCommand; root.ready = true;
            } catch (e) { root.error = e.message; }
        }
        onLoadFailed: function(error) {
            if (error === FileViewError.FileNotFound) root.ready = true;
            else root.error = "Could not read settings: " + error;
        }
        onSaved: root.saved()
        onSaveFailed: function(error) { root.error = "Could not save settings: " + error; }
    }
}
