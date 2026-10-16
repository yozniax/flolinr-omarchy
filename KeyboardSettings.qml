import QtQuick
import Quickshell
import Quickshell.Io
import "Keybindings.js" as Bindings

// Settings are watched, never polled, and remain independent of user notes.
Item {
    id: root
    property string path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/flolinr/keybindings.json"
    readonly property var bindings: state.bindings
    readonly property string error: state.error

    function label(id) { return Bindings.label(bindings, id); }
    function load(text) {
        try {
            var next = Bindings.resolve(JSON.parse(text));
            state.bindings = next;
            state.error = "";
        } catch (e) {
            state.error = "Keybindings: " + e.message + ". Keeping the last valid settings.";
        }
    }
    QtObject {
        id: state
        property var bindings: Bindings.resolve({})
        property string error: ""
    }
    FileView {
        id: file
        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.load(text())
        onLoadFailed: function(error) {
            if (error === FileViewError.FileNotFound) {
                state.bindings = Bindings.resolve({});
                state.error = "";
            } else state.error = "Could not read keybindings: " + error;
        }
    }
}
