// User overrides are separate from outline data and plugin updates.
var defaults = {
    "undo": "Ctrl+Z",
    "redo": "Ctrl+Shift+Z",
    "search": "Ctrl+F",
    "save": "Ctrl+S",
    "help": "Ctrl+/",
    "color": "Ctrl+Shift+C",
    "newRoll": "Ctrl+Shift+N",
    "renameRoll": "Ctrl+Shift+R",
    "previousRoll": "Ctrl+PgUp",
    "nextRoll": "Ctrl+PgDown",
    "previousNode": "Ctrl+Up",
    "nextNode": "Ctrl+Down",
    "zoomIn": "Alt+Right",
    "zoomOut": "Alt+Left",
    "zoomHome": "Ctrl+Home",
    "fold": "Ctrl+Shift+Space",
    "addItem": "Ctrl+Shift+A",
    "calendar": "Ctrl+Shift+D",
    "timestamps": "Ctrl+I",
    "close": "Ctrl+W",
    "focusRolls": "F6",
    "emoji": "Ctrl+Shift+E",
    "today": "Ctrl+Shift+T",
    "archive": "Ctrl+Shift+H",
    "deleteRoll": "Ctrl+Shift+Delete",
    "focusCalendar": "Ctrl+Shift+L"
};
function resolve(value) {
    if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error("Expected a JSON object");
    var result = Object.assign({}, defaults);
    Object.keys(value).forEach(function(id) {
        if (!Object.prototype.hasOwnProperty.call(defaults, id)) throw new Error("Unknown action: " + id);
        var key = value[id];
        if (typeof key !== "string" || (key !== "" && !/^(?:(?:Ctrl|Alt|Shift|Meta)\+)*(?:[A-Z0-9/]|F(?:[1-9]|[12][0-9]|3[0-5])|Up|Down|Left|Right|Home|End|PgUp|PgDown|Space|Delete|Insert|Tab|Backspace|Return|Escape)$/.test(key)))
            throw new Error("Invalid shortcut for " + id);
        var parts = key.split("+");
        if (new Set(parts).size !== parts.length) throw new Error("Repeated modifier for " + id);
        result[id] = key;
    });
    var used = {};
    Object.keys(result).forEach(function(id) {
        var key = result[id];
        if (!key) return;
        var parts = key.split("+"), last = parts.pop();
        var canonical = parts.sort().join("+") + "+" + last;
        if (used[canonical]) throw new Error("Duplicate shortcut: " + key + " (" + used[canonical] + ", " + id + ")");
        used[canonical] = id;
    });
    return result;
}

// One action catalog drives documentation and shortcut help.
var descriptions = {
    "search": "Search all Rolls and daily notes",
    "newRoll": "Create a new Roll and start typing",
    "today": "Open today’s fixed memopad and start typing",
    "renameRoll": "Rename the current Roll",
    "archive": "Archive / restore the current Roll",
    "deleteRoll": "Confirm deletion of an archived Roll",
    "focusCalendar": "Focus the nested calendar list",
    "emoji": "Choose an emoji icon for this Roll",
    "focusRolls": "Switch focus between Rolls and editor",
    "zoomHome": "Return to the Roll root",
    "fold": "Collapse / expand the current item",
    "addItem": "Add an item at the end of this zoom",
    "calendar": "Open the activity calendar",
    "timestamps": "Show the current item's timestamps",
    "close": "Save and close Flolinr",
    "undo": "Undo",
    "redo": "Redo",
    "color": "Choose a color for the focused item",
    "save": "Save now (changes also save automatically)",
    "help": "Show or hide this help",
    "previousRoll": "Previous Roll",
    "nextRoll": "Next Roll",
    "previousNode": "Focus previous visible item",
    "nextNode": "Focus next visible item",
    "zoomIn": "Zoom into the focused item",
    "zoomOut": "Go to parent"
};

function label(bindings, id) { return bindings[id] || "Disabled"; }
function helpRows(bindings) {
    return Object.keys(defaults).map(function(id) { return [label(bindings, id), descriptions[id]]; });
}
