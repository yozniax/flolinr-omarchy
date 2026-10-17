import QtQuick
import Quickshell
import Quickshell.Io
import "AiSettings.js" as AI
import "Translations.js" as Catalog

Item {
    id: root
    readonly property string home: Quickshell.env("HOME")
    readonly property string path: (Quickshell.env("XDG_CONFIG_HOME") || home + "/.config") + "/flolinr/settings.json"
    property bool ready: false
    property string dataPath: home + "/.local/share/flolinr/outline.json"
    property var aiConnections: []
    property string activeAiConnectionId: ""
    property string language: "en"
    onLanguageChanged: I18n.language = language
    property var pending: null
    property string error: ""
    signal saved()
    function validate(value) {
        if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error("Expected settings object");
        var path = value.dataPath || root.dataPath;
        if (typeof path !== "string" || !(path.startsWith("/") || path.startsWith("~/")) || !path.endsWith(".json")) throw new Error(I18n.t("Choose an absolute .json file path"));
        var ai = AI.migrate(value);
        return {dataPath: path.replace(/^~\//, root.home + "/"), aiConnections: ai.aiConnections, activeAiConnectionId: ai.activeAiConnectionId,
            language: Catalog.normalize(value.language === undefined ? root.language : value.language)};
    }
    function save(path, connections, activeId, language) {
        try {
            pending = validate({dataPath: path, aiConnections: connections, activeAiConnectionId: activeId, language: language});
            file.setText(JSON.stringify(pending, null, 2)); root.error = "";
        } catch (e) { root.error = e.message; }
    }
    Process {
        command: ["mkdir", "-p", root.path.slice(0, root.path.lastIndexOf("/"))]
        running: true
        onExited: function(code) { if (code === 0) file.path = root.path; else root.error = I18n.t("Could not create settings directory"); }
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
                root.language = value.language; I18n.language = value.language;
                root.dataPath = value.dataPath; root.aiConnections = value.aiConnections; root.activeAiConnectionId = value.activeAiConnectionId; root.ready = true;
            } catch (e) { root.error = e.message; }
        }
        onLoadFailed: function(error) {
            if (error === FileViewError.FileNotFound) root.ready = true;
            else root.error = I18n.t("Could not read settings: {0}", [error]);
        }
        onSaved: {
            if (root.pending) {
                root.aiConnections = root.pending.aiConnections;
                root.activeAiConnectionId = root.pending.activeAiConnectionId;
                root.language = root.pending.language;
                root.pending = null;
            }
            root.saved();
        }
        onSaveFailed: function(error) { root.error = I18n.t("Could not save settings: {0}", [error]); }
    }
}
