pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons as Commons
import "Model.js" as Model

Item {
    id: root
    readonly property var keybindings: keyboardSettings.bindings
    readonly property string pluginId: manifest && manifest.id ? manifest.id : "yozniax.flolinr"
    KeyboardSettings { id: keyboardSettings }
    AppSettings { id: appSettings }
    FeatureController {
        id: features
        editor: root
        settings: appSettings
        onResult: function(text) { featurePanel.showResult(text); }
        onFailure: function(text) { featurePanel.failure(text); }
        onDone: featurePanel.close()
    }
    property string searchQuery: ""
    readonly property var searchHits: { var revision = root.revision; return Model.searchWorkspace(rolls, searchQuery); }
    property bool captureSaving: false
    property string captureNodeId: ""
    property string captureDay: ""
    function captureLine(text) {
        if (!ready || captureSaving) return;
        try {
            commitRoll();
            var active = activeRollId, before = JSON.stringify(nodes);
            if (captureNodeId) {
                var target = Model.ensureMemopad(rolls, captureDay), ni = Model.indexOf(target.nodes, captureNodeId);
                if (ni < 0) throw new Error("Pending note changed. Reopen quick capture to retry.");
                target.nodes[ni].text = text.trim(); Model.touch([target.nodes[ni]]);
            } else {
                captureDay = todayKey;
                captureNodeId = Model.appendCapture(rolls, captureDay, text);
            }
            if (isMemopad && rolls[Model.indexOf(rolls, active)].memopadDate === todayKey) {
                undoStack = undoStack.concat([before]).slice(-100); redoStack = [];
            }
            rolls = rolls.slice(); changed(); refresh();
            captureSaving = true; capture.saving = true; capture.error = "";
            save();
        } catch (e) { capture.error = e.message; captureSaving = false; capture.saving = false; }
    }
    QuickCapture {
        id: capture
        ready: root.ready
        onSubmitted: function(text) { root.captureLine(text); }
        onDismissed: if (!root.closingFromHost && !window.visible) root.requestClose()
    }
    property var shell: null
    property var manifest: null
    property bool closingFromHost: false
    readonly property bool opened: window.visible || capture.opened
    property var nodes: []
    property var rows: []
    property var rolls: []
    property string activeRollId: ""
    property var rollStates: ({})
    property string editingRollId: ""
    readonly property string todayKey: Model.dayKey(dailyClock.date)
    readonly property bool isMemopad: {
        var revision = root.revision;
        var i = Model.indexOf(rolls, activeRollId);
        return i >= 0 && !!rolls[i].memopadDate;
    }
    readonly property var selectedMemopads: {
        var revision = root.revision;
        return rolls.filter(function(r) { return r.memopadDate === root.selectedDay; });
    }
    function openMemopad(day) {
        if (!ready) return;
        calendarDate = new Date(day + "T12:00:00");
        commitRoll();
        var roll = Model.ensureMemopad(rolls, day);
        rolls = rolls.slice(); selectRoll(roll.id);
        navCalendarOpen = true;
    }
    property bool navRollsOpen: true
    property bool navActiveOpen: true
    property bool navArchivedOpen: true
    property bool navCalendarOpen: false
    property string deleteTarget: ""
    property string deleteName: ""
    property int calendarLimit: 14
    property var collapsedDates: ({})
    readonly property bool archived: {
        var revision = root.revision;
        var i = Model.indexOf(rolls, activeRollId);
        return i >= 0 && rolls[i].archived === true;
    }
    readonly property var liveRolls: { var revision = root.revision; return rolls.filter(function(r) { return !r.archived && !r.memopadDate; }); }
    readonly property var archivedRolls: { var revision = root.revision; return rolls.filter(function(r) { return r.archived === true; }); }
    readonly property var calendarTree: {
        var revision = root.revision;
        return Model.calendarTree(rolls, calendarLimit, collapsedDates, calendarMode, true);
    }
    function toggleArchive() {
        var i = Model.indexOf(rolls, activeRollId);
        if (!ready || i < 0 || rolls[i].memopadDate) return;
        rolls[i].archived = !rolls[i].archived; rolls = rolls.slice(); changed();
    }
    function requestDelete() {
        if (!ready || !archived) return;
        deleteTarget = activeRollId; deleteName = rollName; deleteDialog.open();
    }
    function deleteRoll() {
        var i = Model.indexOf(rolls, deleteTarget);
        if (!ready || i < 0 || !rolls[i].archived) return;
        commitRoll();
        var remaining = Model.removeArchived(rolls, deleteTarget);
        if (Model.indexOf(rolls, remaining[0].id) < 0) rolls = rolls.concat([remaining[0]]);
        if (activeRollId === deleteTarget) selectRoll(remaining[0].id);
        rolls = remaining;
        delete rollStates[deleteTarget]; deleteTarget = ""; changed(); save(); deleteDialog.close();
    }
    function activateDate(item) {
        if (!item) return;
        if (item.kind === "day") { calendarDate = new Date(item.key + "T12:00:00"); openMemopad(item.key); }
        else { var next = Object.assign({}, collapsedDates); next[item.key] = !item.closed; collapsedDates = next; }
    }
    readonly property string rollIcon: {
        var revision = root.revision;
        var i = Model.indexOf(rolls, activeRollId);
        return i < 0 ? "📄" : rolls[i].icon || (rolls[i].name === "Inbox" ? "📥" : "📄");
    }
    function chooseIcon() { iconInput.text = rollIcon; iconDialog.open(); Qt.callLater(function() { iconGrid.forceActiveFocus(); }); }
    function setRollIcon(value) {
        var i = Model.indexOf(rolls, activeRollId), icon = value.trim();
        if (!ready || i < 0 || !icon || icon.length > 32) return;
        rolls[i].icon = icon; rolls = rolls.slice(); changed(); iconDialog.close();
    }
    property date calendarDate: new Date()
    readonly property string calendarMode: "updated"
    readonly property string selectedDay: Model.dayKey(calendarDate)
    readonly property var dayActivity: {
        var revision = root.revision;
        return Model.activity(rolls, selectedDay, calendarMode);
    }
    readonly property bool editingAllowed: ready && !searchDialog.opened && !deleteDialog.opened && !helpDialog.opened && !rollDialog.opened && !calendarDialog.opened && !infoDialog.opened && !iconDialog.opened && !colorMenu.opened && !featurePanel.opened && !capture.opened
    function focusNode(id) { refresh(id || (rows.length ? rows[0].id : "")); }
    function prepareInput() {
        if (!ready) return;
        search.text = ""; query = ""; zoom = "";
        var before = JSON.stringify(nodes);
        var input = Model.ensureInput(nodes, "");
        if (input.created) { undoStack = undoStack.concat([before]).slice(-100); redoStack = []; changed(); }
        refresh(input.id);
    }
    function enterZoom(id) {
        if (!ready) return;
        search.text = ""; query = ""; zoom = id;
        refresh();
        if (!rows.length) {
            snapshot(); var input = Model.ensureInput(nodes, zoom); changed(); refresh(input.id);
        } else focusNode(rows[rows.length - 1].id);
    }
    function navigate(direction) {
        var i = Model.indexOf(rows, focusedNode);
        if (rows.length) focusNode(rows[Math.max(0, Math.min(rows.length - 1, i + direction))].id);
    }
    function cycleRoll(direction) {
        var options = liveRolls;
        if (!options.length) return;
        var i = Model.indexOf(options, activeRollId);
        var next = i < 0 ? (direction < 0 ? options.length - 1 : 0) : (i + direction + options.length) % options.length;
        selectRoll(options[next].id);
    }
    function zoomIn() { if (Model.indexOf(nodes, focusedNode) >= 0) enterZoom(focusedNode); }
    function zoomOut(home) {
        var id = zoom, i = Model.indexOf(nodes, zoom), parent = i < 0 ? -1 : Model.parentOf(nodes, i);
        zoom = home || parent < 0 ? "" : nodes[parent].id;
        refresh(); focusNode(id);
    }
    function showCalendar() { commitRoll(); calendarDialog.open(); Qt.callLater(function() { calendarKeys.forceActiveFocus(); }); }
    function shiftDate(days, months) {
        var d = calendarDate;
        if (months) {
            var last = new Date(d.getFullYear(), d.getMonth() + months + 1, 0).getDate();
            calendarDate = new Date(d.getFullYear(), d.getMonth() + months, Math.min(d.getDate(), last));
        } else calendarDate = new Date(d.getFullYear(), d.getMonth(), d.getDate() + days);
    }
    function openActivity(item) {
        calendarDialog.close(); selectRoll(item.rollId, false);
        search.text = ""; query = ""; zoom = "";
        var i = Model.indexOf(nodes, item.nodeId), p = i < 0 ? -1 : Model.parentOf(nodes, i);
        while (p >= 0) { nodes[p].collapsed = false; p = Model.parentOf(nodes, p); }
        refresh(item.nodeId); changed();
    }
    function jumpToHit(hit) {
        if (!hit) return;
        searchDialog.close();
        selectRoll(hit.rollId, false);
        query = ""; searchQuery = ""; search.text = "";
        zoom = hit.nodeId; focusedNode = hit.nodeId; refresh();
        Qt.callLater(function() { zoomTitle.forceActiveFocus(); });
    }
    function timestampLabel(value) { return value ? new Date(value).toLocaleString(Qt.locale("en_US")) : "Unknown (created before timestamps were introduced)"; }
    function showInfo() {
        var i = Model.indexOf(nodes, focusedNode);
        if (i < 0) return;
        infoText.text = "Created: " + timestampLabel(nodes[i].createdAt) + "\nUpdated: " + timestampLabel(nodes[i].updatedAt);
        infoDialog.open();
    }
    readonly property string rollName: {
        var revision = root.revision;
        var i = Model.indexOf(rolls, activeRollId);
        return i < 0 ? "Home" : rolls[i].memopadDate ? "Daily note · " + rolls[i].memopadDate : rolls[i].name;
    }
    function commitRoll() {
        var i = Model.indexOf(rolls, activeRollId);
        if (i >= 0) rolls[i].nodes = nodes;
    }
    function selectRoll(id, prepare) {
        if (!ready) return;
        if (id === activeRollId) { if (prepare !== false) prepareInput(); return; }
        var i = Model.indexOf(rolls, id);
        if (i < 0) return;
        workspaceArea.forceActiveFocus();
        commitRoll();
        rollStates[activeRollId] = {zoom: zoom, undo: undoStack, redo: redoStack};
        activeRollId = id;
        if (!rolls[i].memopadDate) {
            navRollsOpen = true;
            if (rolls[i].archived) navArchivedOpen = true; else navActiveOpen = true;
        }
        nodes = rolls[i].nodes;
        var state = rollStates[id] || {zoom: "", undo: [], redo: []};
        zoom = state.zoom; undoStack = state.undo; redoStack = state.redo;
        search.text = ""; query = ""; focusedNode = ""; colorTarget = "";
        list.contentY = 0; refresh(); changed();
        if (prepare !== false) prepareInput();
    }
    function editRoll(create) {
        if (!create && isMemopad) return;
        editingRollId = create ? "" : activeRollId;
        rollNameInput.text = create ? "" : rollName;
        rollDialog.open();
        rollNameInput.forceActiveFocus(); rollNameInput.selectAll();
    }
    function submitRoll() {
        var name = rollNameInput.text.trim();
        if (!ready || !name) return;
        if (editingRollId) {
            var i = Model.indexOf(rolls, editingRollId);
            if (i >= 0) { rolls[i].name = name; rolls = rolls.slice(); changed(); }
        } else {
            var roll = Model.createRoll(name, [Model.node("", 0)]);
            rolls = rolls.concat([roll]); selectRoll(roll.id);
        }
        var focusId = !editingRollId && nodes.length ? nodes[0].id : "";
        rollDialog.close();
        if (focusId) Qt.callLater(function() { root.focusNode(focusId); });
    }
    property string zoom: ""
    property string query: ""
    property string status: "Loading…"
    property bool ready: false
    property bool dirty: false
    property var undoStack: []
    property var redoStack: []
    property int revision: 0
    property string focusedNode: ""
    property string colorTarget: ""
    function nodeColor(name) {
        var light = Commons.Color.background.r * 0.299 + Commons.Color.background.g * 0.587 + Commons.Color.background.b * 0.114 > 0.55;
        var palette = light
            ? {blue: "#245eae", green: "#287747", amber: "#906000", rose: "#b52e50", purple: "#7e42b2"}
            : {blue: "#8ab4f8", green: "#a5d6a7", amber: "#f2cb77", rose: "#f497ac", purple: "#c6a0f6"};
        return palette[name] || Commons.Color.foreground;
    }
    function setNodeColor(name) {
        var i = Model.indexOf(nodes, colorTarget);
        if (!ready || i < 0 || (nodes[i].color || "default") === name) return;
        snapshot(); nodes[i].color = name; Model.touch([nodes[i]]); refresh(colorTarget); changed();
    }
    readonly property string dataPath: appSettings.dataPath

    function open(payloadJson) {
        var payload = {};
        try { payload = JSON.parse(payloadJson || "{}"); } catch (e) {}
        closingFromHost = false;
        if (payload.mode === "capture") { capture.open(); return; }
        if (window.visible) return;
        window.visible = true;
        if (ready) prepareInput();
    }
    function close() {
        closingFromHost = true;
        save();
        window.visible = false;
        capture.close();
        closingFromHost = false;
    }
    function requestClose() {
        if (shell && typeof shell.hide === "function") shell.hide(pluginId);
        else close();
    }
    function toggle() { if (opened) close(); else open(); }
    function refresh(focusId) {
        if (zoom && Model.indexOf(nodes, zoom) < 0) zoom = "";
        rows = Model.visible(nodes, zoom, query);
        if (focusId) {
            pendingFocus = focusId; focusAttempts = 0; focusRetry.restart();
        }
    }
    property string pendingFocus: ""
    property int focusAttempts: 0
    Timer {
        id: focusRetry
        interval: 40
        onTriggered: {
            var i = Model.indexOf(root.rows, root.pendingFocus);
            if (i < 0) { root.pendingFocus = ""; return; }
            list.currentIndex = i;
            list.positionViewAtIndex(i, ListView.Contain);
            list.forceLayout();
            var item = list.itemAtIndex(i);
            if (item && window.visible && root.editingAllowed) { item.edit(); root.pendingFocus = ""; }
            else if (++root.focusAttempts < 10) restart();
            else root.pendingFocus = "";
        }
    }
    SystemClock { id: dailyClock; precision: SystemClock.Minutes; }
    function snapshot() {
        undoStack = undoStack.concat([JSON.stringify(nodes)]).slice(-100);
        redoStack = [];
    }
    function changed() { commitRoll(); revision++; dirty = true; status = "Unsaved changes"; saver.restart(); }
    function history(redo) {
        var source = redo ? redoStack : undoStack;
        if (!source.length || !ready) return;
        var current = JSON.stringify(nodes), previous = source[source.length - 1];
        if (redo) { redoStack = source.slice(0, -1); undoStack = undoStack.concat([current]); }
        else { undoStack = source.slice(0, -1); redoStack = redoStack.concat([current]); }
        nodes = JSON.parse(previous); refresh(); changed();
    }
    function action(id, kind, direction) {
        if (!ready || query) return;
        var i = Model.indexOf(nodes, id);
        if (i < 0) return;
        snapshot();
        var branch = nodes.slice(i, Model.endOf(nodes, i));
        if (kind === "add") {
            var n = Model.node("", nodes[i].depth);
            nodes.splice(Model.endOf(nodes, i), 0, n); id = n.id;
        } else if (kind === "indent") {
            if (id === zoom || (direction < 0 && nodes[i].depth <= (zoom ? nodes[Model.indexOf(nodes, zoom)].depth + 1 : 0))) return;
            if (Model.indent(nodes, i, direction)) Model.touch(branch);
        } else if (kind === "move") { if (Model.move(nodes, i, direction)) Model.touch(branch); }
        else if (kind === "fold") nodes[i].collapsed = !nodes[i].collapsed;
        else if (kind === "delete" && !nodes[i].text && Model.endOf(nodes, i) === i + 1) {
            nodes.splice(i, 1); id = nodes[Math.max(0, i - 1)] ? nodes[Math.max(0, i - 1)].id : "";
        }
        refresh(id); changed();
    }
    function addFirst() {
        if (!ready || query) return;
        snapshot();
        var z = Model.indexOf(nodes, zoom), n = Model.node("", z < 0 ? 0 : nodes[z].depth + 1);
        nodes.splice(z < 0 ? nodes.length : Model.endOf(nodes, z), 0, n);
        refresh(n.id); changed();
    }
    function save() {
        if (!ready || !dirty) return;
        commitRoll();
        workspaceStore.write(activeRollId, rolls);
    }
    function applyWorkspace(workspace, needsSave) {
        rolls = workspace.rolls;
        activeRollId = workspace.activeRollId;
        nodes = rolls[Model.indexOf(rolls, activeRollId)].nodes;
        ready = true;
        status = "Saved";
        refresh();
        if (needsSave) changed();
        if (window.visible) prepareInput();
    }
    WorkspaceStore {
        id: workspaceStore
        path: root.dataPath
        active: appSettings.ready
        hasUnsavedChanges: root.dirty
        onWorkspaceLoaded: function(workspace, needsSave) { root.applyWorkspace(workspace, needsSave); }
        onSaved: {
            root.dirty = false; root.status = "Saved";
            if (root.captureSaving) { root.captureSaving = false; root.captureNodeId = ""; capture.saved(); }
        }
        onFailed: function(message) {
            root.status = message;
            if (root.captureSaving) { root.captureSaving = false; capture.saving = false; capture.error = message; }
        }
    }
    Timer { id: saver; interval: 400; onTriggered: root.save(); }
    Component.onDestruction: root.save()

    FloatingWindow {
        id: window
        title: "Flolinr"
        visible: false
        implicitWidth: 1040
        implicitHeight: 760
        minimumSize: Qt.size(720, 480)
        color: Commons.Color.background
        onVisibleChanged: if (!visible) {
            root.save();
            if (!root.closingFromHost && root.shell && typeof root.shell.hide === "function") root.shell.hide(root.pluginId);
        }
        Shortcut { context: Qt.WindowShortcut; enabled: root.editingAllowed; sequence: root.keybindings.undo; onActivated: root.history(false); }
        Shortcut { context: Qt.WindowShortcut; enabled: root.editingAllowed; sequence: root.keybindings.redo; onActivated: root.history(true); }
        Shortcut { context: Qt.WindowShortcut; enabled: root.editingAllowed; sequence: root.keybindings.search; onActivated: { searchDialog.open(); search.forceActiveFocus(); search.selectAll(); } }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.save; onActivated: root.save(); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.help; enabled: root.editingAllowed || helpDialog.opened; onActivated: helpDialog.opened ? helpDialog.close() : helpDialog.open(); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.color; enabled: root.editingAllowed && root.focusedNode !== ""; onActivated: { root.colorTarget = root.focusedNode; colorMenu.popup(); } }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.newRoll; enabled: root.editingAllowed; onActivated: root.editRoll(true); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.renameRoll; enabled: root.editingAllowed; onActivated: root.editRoll(false); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.previousRoll; enabled: root.editingAllowed; onActivated: root.cycleRoll(-1); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.nextRoll; enabled: root.editingAllowed; onActivated: root.cycleRoll(1); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.previousNode; enabled: root.editingAllowed; onActivated: root.navigate(-1); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.nextNode; enabled: root.editingAllowed; onActivated: root.navigate(1); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.zoomIn; enabled: root.editingAllowed; onActivated: root.zoomIn(); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.zoomOut; enabled: root.editingAllowed; onActivated: root.zoomOut(false); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.zoomHome; enabled: root.editingAllowed; onActivated: root.zoomOut(true); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.fold; enabled: root.editingAllowed; onActivated: root.action(root.focusedNode, "fold", 0); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.addItem; enabled: root.editingAllowed; onActivated: root.addFirst(); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.calendar; enabled: root.editingAllowed; onActivated: root.showCalendar(); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.timestamps; enabled: root.editingAllowed; onActivated: root.showInfo(); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.close; enabled: root.editingAllowed; onActivated: root.requestClose(); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.focusRolls; enabled: root.editingAllowed; onActivated: { if (rollList.activeFocus) root.focusNode(root.focusedNode); else { root.navRollsOpen = true; root.navActiveOpen = true; rollList.forceActiveFocus(); } } }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.emoji; enabled: root.editingAllowed; onActivated: root.chooseIcon(); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.today; enabled: root.editingAllowed; onActivated: root.openMemopad(root.todayKey); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.archive; enabled: root.editingAllowed; onActivated: root.toggleArchive(); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.deleteRoll; enabled: root.editingAllowed && root.archived; onActivated: root.requestDelete(); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.focusCalendar; enabled: root.editingAllowed; onActivated: { root.navCalendarOpen = true; dateList.forceActiveFocus(); } }
        FeaturePanel { id: featurePanel; controller: features }
        Dialog {
            id: searchDialog
            parent: Overlay.overlay
            anchors.centerIn: parent
            width: Math.min(720, window.width - 32)
            height: Math.min(570, window.height - 32)
            title: "Search all Rolls and daily notes"
            modal: true; focus: true
            standardButtons: Dialog.NoButton
            onOpened: { root.commitRoll(); search.forceActiveFocus(); search.selectAll(); }
            onClosed: { root.searchQuery = ""; search.text = ""; }
            footer: ActionLink { text: "Close · Esc"; onClicked: searchDialog.close(); }
            contentItem: ColumnLayout {
                TextField {
                    id: search
                    Layout.fillWidth: true
                    placeholderText: "Search all content, including archived Rolls"
                    onTextChanged: { root.searchQuery = text; searchResults.currentIndex = 0; }
                    onAccepted: root.jumpToHit(root.searchHits[searchResults.currentIndex])
                    Keys.onDownPressed: searchResults.currentIndex = Math.min(searchResults.count - 1, searchResults.currentIndex + 1)
                    Keys.onUpPressed: searchResults.currentIndex = Math.max(0, searchResults.currentIndex - 1)
                }
                Label { text: root.searchHits.length + " results · ↑↓ to select · Enter to zoom"; }
                ListView {
                    id: searchResults
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.searchHits
                    ScrollBar.vertical: ScrollBar {}
                    delegate: ItemDelegate {
                        required property var modelData
                        width: ListView.view.width
                        text: modelData.rollName + (modelData.archived ? " [Archived]" : "") + " / " + modelData.path + "  " + modelData.text
                        highlighted: ListView.isCurrentItem
                        onClicked: root.jumpToHit(modelData)
                    }
                }
            }
        }
        Dialog {
            id: deleteDialog
            parent: Overlay.overlay
            anchors.centerIn: parent
            width: Math.min(440, window.width - 32)
            title: "Delete archived Roll?"
            modal: true; focus: true
            standardButtons: Dialog.NoButton
            contentItem: Column {
                spacing: 18
                Label { width: parent.width; text: "Permanently delete “" + root.deleteName + "” and all its items? This cannot be undone."; wrapMode: Text.WordWrap; }
                Row {
                    spacing: 12
                    ActionLink { text: "Cancel"; focus: true; onClicked: deleteDialog.close(); }
                    ActionLink { text: "Delete Roll"; onClicked: root.deleteRoll(); }
                }
            }
        }
        Dialog {
            id: iconDialog
            parent: Overlay.overlay
            anchors.centerIn: parent
            width: Math.min(400, window.width - 32)
            height: Math.min(420, window.height - 32)
            title: "Roll icon"
            modal: true; focus: true
            standardButtons: Dialog.NoButton
            footer: ActionLink { text: "Close · Esc"; onClicked: iconDialog.reject(); }
            contentItem: Column {
                spacing: 12
                Label { text: "Choose an emoji or enter your own"; opacity: 0.65; }
                GridView {
                    id: iconGrid
                    width: parent.width
                    height: 204
                    cellWidth: width / 6
                    cellHeight: 48
                    clip: true
                    currentIndex: 0
                    keyNavigationEnabled: true
                    ScrollBar.vertical: ScrollBar {}
                    model: ["📄", "📥", "📓", "📚", "📝", "🗂️", "💡", "🎯", "🚀", "🧠", "🌱", "🏡", "💼", "🛠️", "💻", "🎨", "🎵", "📅", "✅", "⭐", "🔥", "🌊", "🌙", "🧭", "🌿", "🌳", "🍃", "🌸", "🌻", "🍀", "☀️", "☁️", "🌈", "❄️", "⚡", "✨", "🔖", "📌", "📎", "✏️", "🖋️", "📐", "🔬", "🔭", "🧪", "⚙️", "🔧", "🧩", "🎲", "🎮", "🎬", "📷", "🎧", "🎤", "🎹", "🏃", "🚲", "🏕️", "✈️", "🌍", "🗺️", "🏔️", "☕", "🍵", "🍎", "🥗", "🐈", "🐕", "🦉", "🦋", "🐝", "🐙", "💬", "💭", "❤️", "🧡", "💛", "💚", "💙", "💜", "🤍", "🖤", "🔴", "🟠", "🟡", "🟢", "🔵", "🟣", "🔶", "🔷", "🔹", "▪️", "◻️", "➰", "♾️", "🔗"]
                    Keys.onReturnPressed: root.setRollIcon(model[currentIndex])
                    Keys.onEnterPressed: root.setRollIcon(model[currentIndex])
                    delegate: ActionLink {
                        required property string modelData
                        width: iconGrid.cellWidth - 4
                        height: 44
                        text: modelData
                        font.family: "Noto Color Emoji"
                        font.pixelSize: 25
                        flat: true
                        highlighted: GridView.isCurrentItem && iconGrid.activeFocus
                        onClicked: root.setRollIcon(modelData)
                    }
                }
                Row {
                    spacing: 8
                    TextField { id: iconInput; width: 220; placeholderText: "Custom emoji"; maximumLength: 32; onAccepted: root.setRollIcon(text); }
                    ActionLink { text: "Apply"; enabled: iconInput.text.trim().length > 0; onClicked: root.setRollIcon(iconInput.text); }
                }
                Label { text: "Arrow keys to choose · Enter to apply · Esc to close"; font.pixelSize: 11; opacity: 0.55; }
            }
        }
        Dialog {
            id: infoDialog
            parent: Overlay.overlay
            anchors.centerIn: parent
            width: Math.min(540, window.width - 32)
            title: "Node timestamps"
            modal: true; focus: true
            standardButtons: Dialog.NoButton
            footer: ActionLink { text: "Close · Esc"; onClicked: infoDialog.reject(); }
            contentItem: Label { id: infoText; wrapMode: Text.WordWrap; }
        }
        Dialog {
            id: calendarDialog
            parent: Overlay.overlay
            anchors.centerIn: parent
            width: Math.min(660, window.width - 32)
            height: Math.min(720, window.height - 32)
            title: "Daily notes and Roll activity"
            modal: true; focus: true
            standardButtons: Dialog.NoButton
            footer: ActionLink { text: "Close · Esc"; onClicked: calendarDialog.reject(); }
            contentItem: ScrollView {
                id: calendarScroll
                clip: true
            Column {
                id: calendarKeys
                width: calendarScroll.availableWidth
                spacing: 8
                focus: true
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: function(event) {
                    var handled = true;
                    if (event.key === Qt.Key_Left) root.shiftDate(-1, 0);
                    else if (event.key === Qt.Key_Right) root.shiftDate(1, 0);
                    else if (event.key === Qt.Key_Up && !(event.modifiers & Qt.ControlModifier)) root.shiftDate(-7, 0);
                    else if (event.key === Qt.Key_Down && !(event.modifiers & Qt.ControlModifier)) root.shiftDate(7, 0);
                    else if (event.key === Qt.Key_PageUp) root.shiftDate(0, -1);
                    else if (event.key === Qt.Key_PageDown) root.shiftDate(0, 1);
                    else if (event.key === Qt.Key_T) root.calendarDate = new Date();
                    else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Down) activityList.currentIndex = Math.min(activityList.count - 1, activityList.currentIndex + 1);
                    else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Up) activityList.currentIndex = Math.max(0, activityList.currentIndex - 1);
                    else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && root.dayActivity.length) root.openActivity(root.dayActivity[Math.max(0, activityList.currentIndex)]);
                    else handled = false;
                    event.accepted = handled;
                }
                Row {
                    spacing: 4
                    ActionLink { text: "‹"; onClicked: root.shiftDate(0, -1); }
                    Label { text: Qt.formatDate(root.calendarDate, "MMMM yyyy"); width: 180; height: 36; verticalAlignment: Text.AlignVCenter; }
                    ActionLink { text: "›"; onClicked: root.shiftDate(0, 1); }
                    ActionLink { text: "Today"; onClicked: root.calendarDate = new Date(); }

                }
                Grid {
                    columns: 7
                    width: parent.width
                    Repeater {
                        model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                        Label { required property string modelData; width: calendarKeys.width / 7; height: 24; text: modelData; horizontalAlignment: Text.AlignHCenter; }
                    }
                    Repeater {
                        model: Model.calendarDays(root.calendarDate.getFullYear(), root.calendarDate.getMonth())
                        ActionLink {
                            id: dayButton
                            required property var modelData
                            width: calendarKeys.width / 7
                            height: 35
                            flat: true
                            highlighted: modelData.key === root.selectedDay
                            opacity: modelData.current ? 1 : 0.35
                            readonly property int activityCount: {
                                var revision = root.revision;
                                return Model.activity(root.rolls, modelData.key, root.calendarMode).length;
                            }
                            text: String(modelData.day) + (activityCount || root.rolls.some(function(r) { return r.memopadDate === dayButton.modelData.key; }) ? " ·" : "")
                            onClicked: { root.calendarDate = new Date(modelData.key + "T12:00:00"); calendarKeys.forceActiveFocus(); }
                            ToolTip.visible: hovered
                            ToolTip.text: activityCount + " items"
                        }
                    }
                }
                Label { text: "DAILY NOTE"; font.pixelSize: 11; opacity: 0.6; }
                ActionLink {
                    width: parent.width
                    text: "📝  Daily note · " + root.selectedDay + (root.selectedMemopads.length ? "" : " · Create")
                    flat: true
                    onClicked: { calendarDialog.close(); root.openMemopad(root.selectedDay); }
                }
                Label { text: "ROLL ACTIVITY · " + root.selectedDay + " · " + root.dayActivity.length + " items"; font.bold: true; }
                ListView {
                    id: activityList
                    width: parent.width
                    height: Math.max(90, calendarDialog.availableHeight - 510)
                    clip: true
                    model: root.dayActivity
                    currentIndex: count ? 0 : -1
                    ScrollBar.vertical: ScrollBar {}
                    delegate: ItemDelegate {
                        required property var modelData
                        width: ListView.view.width
                        text: modelData.rollName + " / " + modelData.text
                        highlighted: ListView.isCurrentItem
                        onClicked: root.openActivity(modelData)
                    }
                    Label { anchors.centerIn: parent; visible: activityList.count === 0; text: "No activity on this day"; opacity: 0.6; }
                }
                Label {
                    width: parent.width
                    text: "Arrows: date · PgUp/PgDn: month · T: today\nCtrl+↑↓: result · Enter: open · Esc: close\nUpdated shows each item's latest edit, not a full history. Older items may have no timestamp."
                    wrapMode: Text.WordWrap
                    font.pixelSize: 11
                    opacity: 0.65
                }
            }
        }
        }
        Dialog {
            id: rollDialog
            onClosed: if (!root.editingRollId && root.nodes.length) root.focusNode(root.nodes[0].id)
            parent: Overlay.overlay
            anchors.centerIn: parent
            width: Math.min(400, window.width - 32)
            title: root.editingRollId ? "Rename Roll" : "New Roll"
            modal: true
            focus: true
            standardButtons: Dialog.NoButton
            contentItem: Column {
                spacing: 16
                TextField {
                    id: rollNameInput
                    width: parent.width
                    placeholderText: "Roll name"
                    maximumLength: 100
                    onAccepted: root.submitRoll()
                }
                Row {
                    spacing: 4
                    ActionLink { text: "Cancel"; onClicked: rollDialog.close(); }
                    ActionLink { text: root.editingRollId ? "Rename" : "Create"; enabled: rollNameInput.text.trim().length > 0; onClicked: root.submitRoll(); }
                }
            }
        }
        Menu {
            id: colorMenu
            title: "Node color"
            Instantiator {
                model: ["default", "blue", "green", "amber", "rose", "purple"]
                onObjectAdded: function(index, object) { colorMenu.insertItem(index, object); }
                onObjectRemoved: function(index, object) { colorMenu.removeItem(object); }
                delegate: MenuItem {
                    required property string modelData
                    text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                    checkable: true
                    checked: {
                        var revision = root.revision;
                        var i = Model.indexOf(root.nodes, root.colorTarget);
                        return i >= 0 && (root.nodes[i].color || "default") === modelData;
                    }
                    onTriggered: root.setNodeColor(modelData)
                }
            }
        }
        ShortcutsDialog {
            id: helpDialog
            bindings: root.keybindings
            settingsPath: keyboardSettings.path
            settingsError: keyboardSettings.error
        }
        Item {
            id: workspaceArea
            anchors.fill: parent
            focus: true
            Rectangle {
                id: sidebar
                width: 210
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                color: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.035)
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6
                    Row {
                        spacing: 9
                        Layout.preferredHeight: 40
                        FlolinrIcon { width: 26; height: 26; }
                        Column {
                            spacing: 2
                            Row {
                                spacing: 0
                                Label { text: "Flolin"; color: Commons.Color.foreground; font.pixelSize: 18; font.bold: true; }
                                Label { text: "r"; color: "#78c58b"; font.pixelSize: 18; font.bold: true; }
                            }
                            Label { text: root.manifest ? root.manifest.version : "0.10.0"; color: Commons.Color.foreground; opacity: 0.4; font.pixelSize: 10; }
                        }
                    }


                    ScrollView {
                        id: navigationScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        ColumnLayout {
                            width: navigationScroll.availableWidth
                            spacing: 4
                    ActionLink {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        id: rollsBranch
                        text: (root.navRollsOpen ? "▾ " : "▸ ") + "Rolls"
                        flat: true
                        contentItem: Label { text: rollsBranch.text; color: Commons.Color.foreground; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter; }
                        onClicked: root.navRollsOpen = !root.navRollsOpen
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        visible: root.navRollsOpen
                        spacing: 2
                        ActionLink {
                            id: activeBranch
                            Layout.fillWidth: true
                            text: (root.navActiveOpen ? "▾ " : "▸ ") + "Active"
                            font.pixelSize: 12
                            onClicked: root.navActiveOpen = !root.navActiveOpen
                        }
                        ActionLink {
                            id: addRollLink
                            text: "[+]"
                            enabled: root.ready
                            onClicked: root.editRoll(true)
                            Accessible.name: "Add Roll"
                        }
                    }
                    ListView {
                        id: rollList
                        visible: root.navRollsOpen && root.navActiveOpen
                        Layout.leftMargin: 32
                        Layout.fillWidth: true
                        Layout.preferredHeight: count ? count * 31 - 3 : 24
                        interactive: false
                        keyNavigationEnabled: false
                        currentIndex: Model.indexOf(root.liveRolls, root.activeRollId)
                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) { root.cycleRoll(event.key === Qt.Key_Up ? -1 : 1); rollList.forceActiveFocus(); event.accepted = true; }
                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.prepareInput(); event.accepted = true; }
                        }
                        clip: true
                        model: root.liveRolls
                        spacing: 3
                        ScrollBar.vertical: ScrollBar {}
                        delegate: rollDelegate

                    }
                    Component {
                        id: rollDelegate
                        ItemDelegate {
                            id: rollItem
                            required property var modelData
                            width: ListView.view.width
                            text: (modelData.icon || (modelData.name === "Inbox" ? "📥" : "📄")) + "  " + modelData.name
                            height: 28
                            highlighted: modelData.id === root.activeRollId
                            onClicked: root.selectRoll(modelData.id)
                            onDoubleClicked: { root.selectRoll(modelData.id); root.editRoll(false); }
                            background: Rectangle {
                                radius: 8
                                color: rollItem.highlighted
                                    ? Qt.rgba(Commons.Color.accent.r, Commons.Color.accent.g, Commons.Color.accent.b, 0.14)
                                    : rollItem.hovered ? Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.055) : "transparent"
                                border.width: rollItem.activeFocus ? 1 : 0
                                border.color: Commons.Color.accent
                            }
                            contentItem: Label {
                                text: rollItem.text
                                color: Commons.Color.foreground
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.RightButton
                                onClicked: { root.selectRoll(rollItem.modelData.id); root.chooseIcon(); }
                            }

                        }
                    }
                    ActionLink {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.preferredHeight: 24
                        visible: root.navRollsOpen
                        id: archivedBranch
                        text: (root.navArchivedOpen ? "▾ " : "▸ ") + "Archived"
                        flat: true
                        contentItem: Label { text: archivedBranch.text; color: Commons.Color.foreground; opacity: 0.65; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter; }
                        onClicked: root.navArchivedOpen = !root.navArchivedOpen
                    }
                    ListView {
                        id: archivedList
                        visible: root.navRollsOpen && root.navArchivedOpen
                        Layout.leftMargin: 32
                        Layout.fillWidth: true
                        Layout.preferredHeight: count ? count * 28 : 24
                        interactive: false
                        clip: true
                        model: root.archivedRolls
                        Keys.onReturnPressed: { if (currentIndex >= 0) { root.selectRoll(model[currentIndex].id); } }
                        Keys.onEnterPressed: { if (currentIndex >= 0) { root.selectRoll(model[currentIndex].id); } }
                        delegate: rollDelegate
                        ScrollBar.vertical: ScrollBar {}
                        Label { visible: archivedList.count === 0; text: "No archived Rolls"; color: Commons.Color.foreground; opacity: 0.35; font.pixelSize: 11; }
                    }
                ActionLink {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    id: calendarBranch
                        text: (root.navCalendarOpen ? "▾ " : "▸ ") + "Calendar"
                    flat: true
                    contentItem: Label { text: calendarBranch.text; color: Commons.Color.foreground; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter; }
                    onClicked: root.navCalendarOpen = !root.navCalendarOpen
                }
                ActionLink {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    visible: root.navCalendarOpen
                    text: "📝  Today"
                    onClicked: root.openMemopad(root.todayKey)


                }
                ListView {
                    id: dateList
                    visible: root.navCalendarOpen
                    Layout.leftMargin: 16
                    Layout.minimumHeight: 80
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(300, Math.max(80, count * 30))
                    clip: true
                    model: root.calendarTree.rows
                    currentIndex: count ? 0 : -1
                    Keys.onReturnPressed: root.activateDate(model[currentIndex])
                    Keys.onEnterPressed: root.activateDate(model[currentIndex])
                    ScrollBar.vertical: ScrollBar {}
                    delegate: ItemDelegate {
                        required property var modelData
                        width: ListView.view.width
                        height: 30
                        leftPadding: modelData.depth * 12 + 4
                        text: (modelData.kind === "day" ? "" : modelData.closed ? "▸ " : "▾ ") + modelData.label
                        font.pixelSize: 12
                        highlighted: ListView.isCurrentItem && dateList.activeFocus
                        onClicked: root.activateDate(modelData)
                    }
                    Label { visible: dateList.count === 0; text: "No dated items yet"; color: Commons.Color.foreground; opacity: 0.4; font.pixelSize: 11; }
                }
                ActionLink { Layout.fillWidth: true; text: "More"; flat: true; visible: root.navCalendarOpen && root.calendarTree.total > root.calendarLimit; onClicked: root.calendarLimit += 14; }

                        }
                    }

                    ActionLink { text: "Import Markdown"; enabled: root.ready; onClicked: featurePanel.show("import"); }
                    ActionLink { text: "Export Markdown"; enabled: root.ready; onClicked: featurePanel.show("export"); }
                    ActionLink { text: "AI · selected branch"; enabled: root.ready && !!(root.focusedNode || root.zoom); onClicked: featurePanel.show("ai"); }
                    ActionLink { text: "Activity calendar"; enabled: root.ready; onClicked: root.showCalendar(); }
                    ActionLink { text: "Settings"; onClicked: featurePanel.show("settings"); }
                    Label { Layout.fillWidth: true; visible: !!appSettings.error; text: appSettings.error; wrapMode: Text.WordWrap; }
                    ActionLink {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        id: shortcutsLink
                        text: "Shortcuts · " + keyboardSettings.label("help")
                        font.pixelSize: 11
                        contentItem: Label { text: shortcutsLink.text; color: Commons.Color.foreground; opacity: 0.6; font.pixelSize: 11; horizontalAlignment: Text.AlignLeft; verticalAlignment: Text.AlignVCenter; }
                        flat: true
                        onClicked: helpDialog.open()


                    }
                    Label {
                        Layout.fillWidth: true
                        text: root.status
                        color: Commons.Color.foreground
                        opacity: 0.45
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                    }
                }
            }
        ColumnLayout {
            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 24
            spacing: 16
            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true; }
                ActionLink { text: "Rename Roll"; flat: true; visible: !root.isMemopad; enabled: root.ready; onClicked: root.editRoll(false); }
                ActionLink { text: root.archived ? "Restore" : "Archive"; flat: true; visible: !root.isMemopad; enabled: root.ready; onClicked: root.toggleArchive(); }
                ActionLink { text: "Delete"; flat: true; visible: root.archived; onClicked: root.requestDelete(); }
            }
            Row {
                id: crumbs
                Layout.fillWidth: true
                spacing: 12
                ActionLink { text: root.rollIcon + "  " + root.rollName; flat: true; onClicked: root.enterZoom("") }
                Repeater {
                    model: {
                        var revision = root.revision;
                        var result = [], i = Model.indexOf(root.nodes, root.zoom);
                        while (i >= 0) { result.unshift({id: root.nodes[i].id, text: root.nodes[i].text || "Untitled"}); i = Model.parentOf(root.nodes, i); }
                        return result;
                    }
                    ActionLink {
                        required property var modelData
                        text: "›  " + modelData.text.slice(0, 24)
                        flat: true
                        onClicked: root.enterZoom(modelData.id)
                    }
                }
            }
            Row {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                spacing: 12
                ActionLink {
                    text: root.rollIcon
                    width: 40; height: 40
                    font.family: "Noto Color Emoji"
                    font.pixelSize: 28
                    flat: true
                    onClicked: root.chooseIcon()
                    ToolTip.visible: hovered
                    ToolTip.text: "Change Roll icon (" + keyboardSettings.label("emoji") + ")"
                }
                TextArea {
                    id: zoomTitle
                    width: parent.width - 52
                    height: 40
                    readOnly: !root.zoom || !root.ready
                    text: { var revision = root.revision; var i = Model.indexOf(root.nodes, root.zoom); return i < 0 ? root.rollName : root.nodes[i].text; }
                    textFormat: TextEdit.PlainText
                    color: Commons.Color.foreground
                    font.pixelSize: 22
                    font.family: Commons.Style.fontFamily
                    font.bold: true
                    padding: 0
                    background: Item {}
                    property bool sessionRecorded: false
                    onActiveFocusChanged: {
                        if (activeFocus && root.zoom) root.focusedNode = root.zoom;
                        else sessionRecorded = false;
                    }
                    onTextChanged: {
                        if (!activeFocus || readOnly) return;
                        var i = Model.indexOf(root.nodes, root.zoom);
                        if (i >= 0 && root.nodes[i].text !== text) {
                            if (!sessionRecorded) { root.snapshot(); sessionRecorded = true; }
                            root.nodes[i].text = text; Model.touch([root.nodes[i]]); root.changed();
                        }
                    }
                }
            }
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.maximumWidth: 760
                Layout.alignment: Qt.AlignHCenter
                clip: true
                model: root.rows
                spacing: 0
                ScrollBar.vertical: ScrollBar {}
                delegate: OutlineNode {
                    width: list.width
                    controller: root
                    onColorRequested: function(nodeId) { root.colorTarget = nodeId; colorMenu.popup(); }
                }
                footer: ActionLink { text: "[+]"; Accessible.name: "Add item"; flat: true; enabled: root.ready && !root.query; onClicked: root.addFirst(); }
            }
        }
        }
    }
}
