import QtQuick
import Quickshell.Io
import "Model.js" as Model

// One owner per standalone panel. A bar widget never loads or writes notes.
Item {
    id: root
    required property string path
    property bool active: false
    property bool hasUnsavedChanges: false
    readonly property bool writable: state.writable
    signal workspaceLoaded(var workspace, bool needsSave)
    signal saved()
    signal failed(string message)

    function write(activeRollId, rolls) {
        if (!writable) { failed("Saving is paused. Resolve the workspace read/conflict error first."); return; }
        try {
            var text = Model.encodeWorkspace(activeRollId, rolls);
            file.setText(text);
            state.lastText = text;
        }
        catch (e) { failed("Could not save: " + e.message); }
    }
    QtObject {
        id: state
        property bool writable: false
        property bool initialized: false
        property string lastText: ""
    }
    Process {
        command: ["mkdir", "-p", root.path.slice(0, root.path.lastIndexOf("/"))]
        running: root.active
        onExited: function(code) {
            if (code === 0) file.path = root.path;
            else root.failed("Could not create the data folder");
        }
    }
    FileView {
        id: file
        atomicWrites: true
        // Flush synchronously so close/unload cannot strand a deferred write.
        blockWrites: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                var content = text();
                if (state.initialized && content === state.lastText) return;
                if (state.initialized && root.hasUnsavedChanges) {
                    state.writable = false;
                    root.failed("External changes conflict with local edits. Export your Roll, then reload to reconcile.");
                    return;
                }
                var result = Model.decodeWorkspace(content);
                state.initialized = true; state.lastText = content;
                state.writable = true;
                root.workspaceLoaded(result.workspace, result.needsSave);
            } catch (e) {
                state.writable = false;
                root.failed("Could not read the outline. The original file is preserved: " + e.message);
            }
        }
        onLoadFailed: function(error) {
            if (error === FileViewError.FileNotFound) {
                if (state.initialized) {
                    state.writable = false;
                    root.failed("Workspace disappeared. Saving is paused to preserve local edits.");
                    return;
                }
                state.initialized = true; state.writable = true;
                root.workspaceLoaded(Model.initialWorkspace(), true);
            } else {
                state.writable = false;
                root.failed("Could not load: " + error);
            }
        }
        onSaved: root.saved()
        onSaveFailed: function(error) { root.failed("Could not save: " + error); }
    }
}
