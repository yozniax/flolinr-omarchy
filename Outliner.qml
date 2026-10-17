pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons as Commons
import "Model.js" as Model
import "CommandActions.js" as Commands

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
        onResult: function(text) { if (featurePanel.opened) featurePanel.showResult(text); else root.status = text; }
        onFailure: function(text) { if (attachmentDialog.opened) attachmentDialog.failure(text); else if (featurePanel.opened) featurePanel.failure(text); else { root.status = text; transferNotice.show(I18n.t("Could not complete import / export"), text); } }
        onNotice: function(text) { transferNotice.show(I18n.t("Import completed"), text); }
        onDone: { featurePanel.close(); attachmentDialog.close(); }
        onAiStatus: function(text) { featurePanel.connectionStatus(text); }
        onAiSettingsNeeded: featurePanel.show("settings")
    }
    property string searchQuery: ""
    readonly property var searchHits: { var revision = root.revision; return Model.searchWorkspace(rolls, searchQuery); }
    property bool captureSaving: false
    property var captureNodeIds: []
    property string captureDay: ""
    property string captureTimestamp: ""
    function captureLine(payload) {
        if (!ready || captureSaving) return;
        try {
            var mode = typeof payload === "string" ? "memo" : payload.mode;
            var captureText = typeof payload === "string" ? payload : String(payload.text || "");
            var entries = mode === "memo" ? [{text: captureText.trim(), depth: 0}]
                : Model.parseCaptureOutline(captureText, mode === "checklist");
            entries = entries.filter(function(entry) { return !!entry.text; });
            if (!entries.length) throw new Error("Add at least one item");
            commitRoll();
            var active = activeRollId, before = JSON.stringify(nodes);
            if (!captureNodeIds.length) {
                captureDay = todayKey;
                var capturedAt = new Date();
                captureTimestamp = String(capturedAt.getHours()).padStart(2, "0") + ":" + String(capturedAt.getMinutes()).padStart(2, "0");
            }
            var target = Model.ensureMemopad(rolls, captureDay);
            if (captureNodeIds.length) {
                var pendingIds = captureNodeIds;
                target.nodes = target.nodes.filter(function(node) { return pendingIds.indexOf(node.id) < 0; });
            }
            captureNodeIds = [];
            var timestampNode = Model.node(captureTimestamp, 0);
            target.nodes.push(timestampNode);
            captureNodeIds.push(timestampNode.id);
            entries.forEach(function(entry) {
                var item = Model.node(entry.text, entry.depth + 1);
                target.nodes.push(item); captureNodeIds.push(item.id);
            });
            if (isMemopad && rolls[Model.indexOf(rolls, active)].memopadDate === captureDay) {
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
        onSubmitted: function(payload) { root.captureLine(payload); }
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
    }
    function addTodayNote() {
        if (!ready) return;
        openMemopad(todayKey);
        zoom = ""; search.text = ""; query = "";
        var last = nodes.length ? nodes[nodes.length - 1] : null;
        if (last && last.depth === 0 && !last.text) refresh(last.id, {position: 0});
        else addFirst();
    }
    property string deleteTarget: ""
    property string deleteName: ""
    readonly property bool archived: {
        var revision = root.revision;
        var i = Model.indexOf(rolls, activeRollId);
        return i >= 0 && rolls[i].archived === true;
    }
    readonly property var liveRolls: { var revision = root.revision; return rolls.filter(function(r) { return !r.archived && !r.memopadDate; }); }
    readonly property var archivedRolls: { var revision = root.revision; return rolls.filter(function(r) { return r.archived === true; }); }
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
    readonly property string rollIcon: {
        var revision = root.revision;
        var i = Model.indexOf(rolls, activeRollId);
        return i < 0 ? "🧾" : defaultRollIcon(rolls[i]);
    }
    function defaultRollIcon(roll) { return !roll.icon || roll.icon === "📄" ? "🧾" : roll.icon; }
    function reorderRoll(sourceId, targetId, after) {
        if (!ready || !workspaceStore.writable) return;
        var reordered = Model.reorderRolls(rolls, sourceId, targetId, after);
        if (!reordered) return;
        commitRoll(); rolls = reordered; changed(); save();
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
    readonly property bool editingAllowed: ready && !searchDialog.opened && !deleteDialog.opened && !helpDialog.opened && !rollDialog.opened && !calendarDialog.opened && !infoDialog.opened && !iconDialog.opened && !colorMenu.opened && !featurePanel.opened && !capture.opened && !fileTransfer.opened && !transferNotice.opened && !attachmentDialog.opened && !attachmentDialog.choosing && !commandDialog.opened && !templateManager.opened
    readonly property string zoomText: { var revision = root.revision; var i = Model.indexOf(nodes, zoom); return i < 0 ? "" : nodes[i].text; }
    readonly property var zoomAttachment: { var revision = root.revision; var i = Model.indexOf(nodes, zoom); return i < 0 ? null : nodes[i].attachment || null; }
    readonly property bool zoomAttachmentCollapsed: { var revision = root.revision; var i = Model.indexOf(nodes, zoom); return i >= 0 && nodes[i].collapsed; }
    readonly property var commandTemplates: appSettings.templates
    function restoreCommandFocus(id) {
        if (!id) return;
        Qt.callLater(function() {
            if (id === root.zoom) { zoomTitle.forceActiveFocus(); zoomTitle.cursorPosition = zoomTitle.length; }
            else root.focusNode(id);
        });
    }
    function openSlashCommand(id, command) {
        if (!ready || features.busy || Commands.commands.indexOf(command) < 0) return;
        var i = Model.indexOf(nodes, id);
        if (i < 0) return;
        try {
            Commands.target(nodes, id, nodes[i].text);
            if (command === "insert") attachmentDialog.showSlash(id, command);
            else if (["date", "link", "template"].indexOf(command) >= 0) commandDialog.show(id, command);
            else applySlashCommand(id, command, nodes[i].text, null);
        } catch (e) { transferNotice.show(I18n.t("Could not complete action"), I18n.t(e.message)); }
    }
    function applySlashCommand(id, command, expected, value) {
        Commands.target(nodes, id, expected);
        var text = "", focus = id;
        if (command === "date") text = Commands.dateText(value);
        else if (command === "link") {
            var r = Model.indexOf(rolls, value.rollId);
            if (r < 0) throw new Error("The linked item no longer exists");
            var item = value.nodeId ? rolls[r].nodes[Model.indexOf(rolls[r].nodes, value.nodeId)] : null;
            if (value.nodeId && !item) throw new Error("The linked item no longer exists");
            text = Commands.linkText(rolls[r], item);
        } else if (command !== "template") throw new Error("Unknown command");
        if (command === "template" && !commandTemplates[value]) throw new Error("Choose a template");
        snapshot();
        if (command === "template") focus = Commands.insertTemplate(nodes, id, expected, value, commandTemplates);
        else Commands.replace(nodes, id, expected, text);
        changed(); refresh(focus);
        restoreCommandFocus(focus);
        return focus;
    }

    function toggleTodo(id) {
        var i = Model.indexOf(nodes, id);
        if (!ready || i < 0 || Commands.todoState(nodes[i].text) === null) return;
        snapshot(); nodes[i].text = Commands.toggleTodo(nodes[i].text);
        Model.touch([nodes[i]]); changed(); refresh(id);
    }
    function clearTodo(id) {
        var i = Model.indexOf(nodes, id);
        if (!ready || i < 0 || Commands.todoState(nodes[i].text) === null) return;
        snapshot(); nodes[i].text = nodes[i].text.replace(/^\[[ xX]\]\s?/, "");
        Model.touch([nodes[i]]); changed(); refresh(id, {position: 0});
    }
    function followInternalLink(link) {
        if (!ready || !link) return;
        var r = Model.indexOf(rolls, link.rollId);
        if (r < 0 || (link.nodeId && Model.indexOf(rolls[r].nodes, link.nodeId) < 0)) {
            transferNotice.show(I18n.t("Link unavailable"), I18n.t("The linked item no longer exists")); return;
        }
        selectRoll(link.rollId, false); search.text = ""; query = ""; zoom = link.nodeId; refresh();
        if (zoom) Qt.callLater(function() { zoomTitle.forceActiveFocus(); });
    }
    function insertAttachment(attachment, parentId, replaceId, expectedText) {
        if (!ready) return;
        Model.validateAttachment(attachment);
        if (parentId && Model.indexOf(nodes, parentId) < 0) throw new Error("The insertion target changed");
        var target = replaceId ? Model.indexOf(nodes, replaceId) : -1;
        if (replaceId && (target < 0 || nodes[target].attachment || nodes[target].text !== expectedText)) throw new Error("The insertion target changed");
        snapshot();
        var id = replaceId ? Model.replaceWithAttachment(nodes, replaceId, attachment, expectedText) : Model.insertAttachment(nodes, parentId, attachment);
        changed(); refresh(id);
    }
    function updateAttachment(id, attachment) {
        var i = Model.indexOf(nodes, id);
        if (!ready || i < 0 || !nodes[i].attachment) throw new Error("The insertion target changed");
        Model.validateAttachment(attachment); snapshot();
        nodes[i].attachment = JSON.parse(JSON.stringify(attachment));
        Model.touch([nodes[i]]); changed(); refresh(id);
    }
    function removeAttachment(id) {
        var i = Model.indexOf(nodes, id);
        if (!ready || i < 0 || !nodes[i].attachment) return;
        snapshot();
        if (nodes[i].text === nodes[i].attachment.name) nodes[i].text = "";
        delete nodes[i].attachment; Model.touch([nodes[i]]); changed(); refresh(id);
    }
    function setAttachmentCollapsed(id, collapsed) {
        var i = Model.indexOf(nodes, id);
        if (!ready || i < 0 || !nodes[i].attachment || nodes[i].collapsed === collapsed) return;
        nodes[i].collapsed = collapsed; changed(); refresh(id);
    }
    function addAfterAttachment(id) {
        var i = Model.indexOf(nodes, id);
        if (!ready || i < 0) return;
        snapshot();
        var value = Model.node("", nodes[i].depth);
        nodes.splice(Model.endOf(nodes, i), 0, value); changed(); refresh(value.id);
    }
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
    function navigateFrom(id, direction, target) {
        var i = Model.indexOf(rows, id), next = i + direction;
        if (id === zoom && direction > 0 && rows.length) next = 0;
        else if (i < 0 || next >= rows.length) return false;
        if (next < 0) {
            if (!zoom) return false;
            zoomTitle.forceActiveFocus();
            if (target && target.x !== undefined) {
                var edge = zoomTitle.positionToRectangle(zoomTitle.length);
                zoomTitle.cursorPosition = zoomTitle.positionAt(target.x, edge.y + edge.height / 2);
            } else zoomTitle.cursorPosition = zoomTitle.length;
            return true;
        }
        refresh(rows[next].id, target);
        return true;
    }
    function mergeItem(id) {
        if (!ready || query) return;
        var rowIndex = Model.indexOf(rows, id);
        var previousId = rowIndex > 0 ? rows[rowIndex - 1].id : (rowIndex === 0 ? zoom : "");
        var i = Model.indexOf(nodes, id), p = Model.indexOf(nodes, previousId);
        if (i <= 0 || p < 0 || p >= i) return;
        snapshot();
        var joined = Model.mergeNode(nodes, i, previousId);
        if (!joined) { undoStack = undoStack.slice(0, -1); return; }
        changed();
        if (joined.id === zoom) {
            refresh();
            zoomTitle.forceActiveFocus(); zoomTitle.cursorPosition = joined.position;
        } else refresh(joined.id, {position: joined.position});
    }
    function splitItem(id, start, end) {
        if (!ready || query) return;
        var i = Model.indexOf(nodes, id);
        if (i < 0) return;
        snapshot();
        var parent = Model.parentOf(nodes, i);
        var nextId = Model.splitNode(nodes, i, start, end, id === zoom);
        if (id === zoom && nodes[Model.indexOf(nodes, nextId)].depth === nodes[i].depth) zoom = parent < 0 ? "" : nodes[parent].id;
        changed(); refresh(nextId, {position: 0});
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
    function timestampLabel(value) { return value ? new Date(value).toLocaleString(I18n.locale) : I18n.t("Unknown (created before timestamps were introduced)"); }
    function showInfo() {
        var i = Model.indexOf(nodes, focusedNode);
        if (i < 0) return;
        infoText.text = I18n.t("Created: {0}\nUpdated: {1}", [timestampLabel(nodes[i].createdAt), timestampLabel(nodes[i].updatedAt)]);
        infoDialog.open();
    }
    readonly property string rollName: {
        var revision = root.revision;
        var i = Model.indexOf(rolls, activeRollId);
        return i < 0 ? I18n.t("Home") : rolls[i].memopadDate ? I18n.t("Daily note") + " · " + rolls[i].memopadDate : rolls[i].name;
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
        if (!window.visible) {
            window.visible = true;
            if (ready) prepareInput();
        }
        if (payload.mode === "settings") Qt.callLater(function() { featurePanel.show("settings"); });
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
    function refresh(focusId, cursorTarget) {
        if (zoom && Model.indexOf(nodes, zoom) < 0) zoom = "";
        rows = Model.visible(nodes, zoom, query);
        if (focusId) {
            pendingFocus = focusId; pendingCursor = cursorTarget || null; focusAttempts = 0; focusRetry.restart();
        }
    }
    property string pendingFocus: ""
    property var pendingCursor: null
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
            if (item && window.visible && root.editingAllowed) { item.edit(root.pendingCursor); root.pendingFocus = ""; }
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
        else if (kind === "delete" && !nodes[i].attachment && !nodes[i].text && Model.endOf(nodes, i) === i + 1) {
            nodes.splice(i, 1); id = nodes[Math.max(0, i - 1)] ? nodes[Math.max(0, i - 1)].id : "";
        }
        refresh(id); changed();
    }
    function removeNode(id) {
        if (!ready || query) return;
        var i = Model.indexOf(nodes, id);
        if (i < 0) return;
        var end = Model.endOf(nodes, i);
        var focusId = nodes[end] ? nodes[end].id : (i > 0 ? nodes[i - 1].id : "");
        snapshot();
        nodes.splice(i, end - i);
        changed(); refresh(focusId);
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
            if (root.captureSaving) { root.captureSaving = false; root.captureNodeIds = []; root.captureDay = ""; root.captureTimestamp = ""; capture.saved(); }
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
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.focusRolls; enabled: root.editingAllowed; onActivated: { if (rollList.activeFocus) root.focusNode(root.focusedNode); else rollList.forceActiveFocus(); } }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.emoji; enabled: root.editingAllowed; onActivated: root.chooseIcon(); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.today; enabled: root.editingAllowed; onActivated: root.openMemopad(root.todayKey); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.archive; enabled: root.editingAllowed; onActivated: root.toggleArchive(); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.deleteRoll; enabled: root.editingAllowed && root.archived; onActivated: root.requestDelete(); }
        Shortcut { context: Qt.WindowShortcut; sequence: root.keybindings.focusCalendar; enabled: root.editingAllowed; onActivated: root.showCalendar(); }
        FeaturePanel { id: featurePanel; controller: features; onEditTemplatesRequested: templateManager.show() }
        FileTransfer { id: fileTransfer; controller: features }
        AttachmentDialog { id: attachmentDialog; controller: features }
        CommandDialog { id: commandDialog; controller: root }
        TemplateManager { id: templateManager; settings: appSettings }
        CompactDialog {
            id: transferNotice
            parent: Overlay.overlay
            anchors.centerIn: parent
            width: Math.min(460, window.width - 32)
            modal: true
            focus: true
            standardButtons: Dialog.NoButton
            property string message: ""
            onClosed: if (root.ready) root.focusNode(root.focusedNode || (root.nodes.length ? root.nodes[0].id : ""))
            function show(title, text) { transferNotice.title = "ℹ️ " + title; message = text; open(); }
            contentItem: Label { text: I18n.t(transferNotice.message); wrapMode: Text.WordWrap; }
            footer: ActionLink { text: I18n.t("Close · Esc"); onClicked: transferNotice.close(); }
        }
        CompactDialog {
            id: searchDialog
            parent: Overlay.overlay
            anchors.centerIn: parent
            width: Math.min(600, window.width - 32)
            height: Math.min(440, window.height - 32)
            title: "🔍 " + I18n.t("Search all Rolls and daily notes")
            modal: true; focus: true
            standardButtons: Dialog.NoButton
            onOpened: { root.commitRoll(); search.forceActiveFocus(); search.selectAll(); }
            onClosed: { root.searchQuery = ""; search.text = ""; }
            footer: ActionLink { text: I18n.t("Close · Esc"); onClicked: searchDialog.close(); }
            contentItem: ColumnLayout {
                TextField {
                    id: search
                    Layout.fillWidth: true
                    placeholderText: I18n.t("Search all content, including archived Rolls")
                    onTextChanged: { root.searchQuery = text; searchResults.currentIndex = 0; }
                    onAccepted: root.jumpToHit(root.searchHits[searchResults.currentIndex])
                    Keys.onDownPressed: searchResults.currentIndex = Math.min(searchResults.count - 1, searchResults.currentIndex + 1)
                    Keys.onUpPressed: searchResults.currentIndex = Math.max(0, searchResults.currentIndex - 1)
                }
                Label { text: I18n.t("{0} results · ↑↓ to select · Enter to zoom", [root.searchHits.length]); }
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
                        text: modelData.rollName + (modelData.archived ? I18n.t(" [Archived]") : "") + " / " + modelData.path + "  " + modelData.text
                        highlighted: ListView.isCurrentItem
                        onClicked: root.jumpToHit(modelData)
                    }
                }
            }
        }
        CompactDialog {
            id: deleteDialog
            parent: Overlay.overlay
            anchors.centerIn: parent
            width: Math.min(440, window.width - 32)
            title: "🗑️ " + I18n.t("Delete archived Roll?")
            modal: true; focus: true
            standardButtons: Dialog.NoButton
            contentItem: Column {
                spacing: 12
                Label { width: parent.width; text: I18n.t("Permanently delete “{0}” and all its items? This cannot be undone.", [root.deleteName]); wrapMode: Text.WordWrap; }
                Row {
                    spacing: 12
                    ActionLink { text: I18n.t("Cancel"); focus: true; onClicked: deleteDialog.close(); }
                    ActionLink { text: I18n.t("Delete Roll"); onClicked: root.deleteRoll(); }
                }
            }
        }
        CompactDialog {
            id: iconDialog
            parent: Overlay.overlay
            anchors.centerIn: parent
            width: Math.min(400, window.width - 32)
            height: Math.min(360, window.height - 32)
            title: "😀 " + I18n.t("Roll icon")
            modal: true; focus: true
            standardButtons: Dialog.NoButton
            footer: ActionLink { text: I18n.t("Close · Esc"); onClicked: iconDialog.reject(); }
            contentItem: Column {
                spacing: 12
                Label { text: I18n.t("Choose an emoji or enter your own"); opacity: 0.65; }
                GridView {
                    id: iconGrid
                    width: parent.width
                    height: 168
                    cellWidth: width / 6
                    cellHeight: 38
                    clip: true
                    currentIndex: 0
                    keyNavigationEnabled: true
                    ScrollBar.vertical: ScrollBar {}
                    model: ["🧾", "🗞️", "📥", "📓", "📚", "📝", "🗂️", "💡", "🎯", "🚀", "🧠", "🌱", "🏡", "💼", "🛠️", "💻", "🎨", "🎵", "📅", "✅", "⭐", "🔥", "🌊", "🌙", "🧭", "🌿", "🌳", "🍃", "🌸", "🌻", "🍀", "☀️", "☁️", "🌈", "❄️", "⚡", "✨", "🔖", "📌", "📎", "✏️", "🖋️", "📐", "🔬", "🔭", "🧪", "⚙️", "🔧", "🧩", "🎲", "🎮", "🎬", "📷", "🎧", "🎤", "🎹", "🏃", "🚲", "🏕️", "✈️", "🌍", "🗺️", "🏔️", "☕", "🍵", "🍎", "🥗", "🐈", "🐕", "🦉", "🦋", "🐝", "🐙", "💬", "💭", "❤️", "🧡", "💛", "💚", "💙", "💜", "🤍", "🖤", "🔴", "🟠", "🟡", "🟢", "🔵", "🟣", "🔶", "🔷", "🔹", "▪️", "◻️", "➰", "♾️", "🔗"]
                    Keys.onReturnPressed: root.setRollIcon(model[currentIndex])
                    Keys.onEnterPressed: root.setRollIcon(model[currentIndex])
                    delegate: ActionLink {
                        required property string modelData
                        width: iconGrid.cellWidth - 4
                        height: 34
                        text: modelData
                        font.family: "Noto Color Emoji"
                        font.pixelSize: 21
                        flat: true
                        highlighted: GridView.isCurrentItem && iconGrid.activeFocus
                        onClicked: root.setRollIcon(modelData)
                    }
                }
                Row {
                    spacing: 8
                    TextField { id: iconInput; width: 220; placeholderText: I18n.t("Custom emoji"); maximumLength: 32; onAccepted: root.setRollIcon(text); }
                    ActionLink { text: I18n.t("Apply"); enabled: iconInput.text.trim().length > 0; onClicked: root.setRollIcon(iconInput.text); }
                }
                Label { text: I18n.t("Arrow keys to choose · Enter to apply · Esc to close"); font.pixelSize: 11; opacity: 0.55; }
            }
        }
        CompactDialog {
            id: infoDialog
            parent: Overlay.overlay
            anchors.centerIn: parent
            width: Math.min(540, window.width - 32)
            title: "🕒 " + I18n.t("Node timestamps")
            modal: true; focus: true
            standardButtons: Dialog.NoButton
            footer: ActionLink { text: I18n.t("Close · Esc"); onClicked: infoDialog.reject(); }
            contentItem: Label { id: infoText; wrapMode: Text.WordWrap; }
        }
        CompactDialog {
            id: calendarDialog
            parent: Overlay.overlay
            anchors.centerIn: parent
            width: Math.min(400, window.width - 32)
            height: Math.min(460, window.height - 32)
            title: "📅 " + I18n.t("Calendar")
            modal: true; focus: true
            standardButtons: Dialog.NoButton
            footer: ActionLink { text: I18n.t("Close · Esc"); onClicked: calendarDialog.reject(); }
            contentItem: ScrollView {
                id: calendarScroll
                clip: true
            Column {
                id: calendarKeys
                width: calendarScroll.availableWidth
                spacing: 5
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
                    Label { text: root.calendarDate.toLocaleDateString(I18n.locale, "MMMM yyyy"); width: 132; height: 26; verticalAlignment: Text.AlignVCenter; }
                    ActionLink { text: "›"; onClicked: root.shiftDate(0, 1); }
                    ActionLink { text: I18n.t("Today"); onClicked: root.calendarDate = new Date(); }

                }
                Grid {
                    columns: 7
                    width: parent.width
                    Repeater {
                        model: [1, 2, 3, 4, 5, 6, 7].map(function(day) { return I18n.locale.dayName(day, Locale.ShortFormat); })
                        Label { required property string modelData; width: calendarKeys.width / 7; height: 18; text: modelData; horizontalAlignment: Text.AlignHCenter; }
                    }
                    Repeater {
                        model: Model.calendarDays(root.calendarDate.getFullYear(), root.calendarDate.getMonth())
                        ActionLink {
                            id: dayButton
                            required property var modelData
                            width: calendarKeys.width / 7
                            height: 24
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
                            ToolTip.text: I18n.t("{0} items", [activityCount])
                        }
                    }
                }
                Item { width: 1; height: 4; }
                ModalSection { title: "DAILY NOTE"; width: parent.width }
                ActionLink {
                    width: parent.width
                    text: "📝  " + I18n.t("Daily note") + " · " + root.selectedDay + (root.selectedMemopads.length ? "" : " · " + I18n.t("Create"))
                    flat: true
                    onClicked: { calendarDialog.close(); root.openMemopad(root.selectedDay); }
                }
                Item { width: 1; height: 4; }
                Label { text: I18n.t("ROLL ACTIVITY") + " · " + root.selectedDay + " · " + I18n.t("{0} items", [root.dayActivity.length]); font.pixelSize: 12; font.weight: Font.DemiBold; opacity: 0.82; }
                ListView {
                    id: activityList
                    width: parent.width
                    height: Math.min(72, Math.max(24, root.dayActivity.length * 24))
                    clip: true
                    model: root.dayActivity
                    currentIndex: count ? 0 : -1
                    ScrollBar.vertical: ScrollBar {}
                    delegate: ItemDelegate {
                        required property var modelData
                        width: ListView.view.width
                        height: 24
                        font.pixelSize: 11
                        font.weight: Font.Light
                        text: modelData.rollName + " / " + modelData.text
                        highlighted: ListView.isCurrentItem
                        onClicked: root.openActivity(modelData)
                    }
                    Label { anchors.centerIn: parent; visible: activityList.count === 0; text: I18n.t("No activity on this day"); opacity: 0.6; }
                }
                Label {
                    width: parent.width
                    text: I18n.t("Arrows: date · PgUp/PgDn: month · T: today\nCtrl+↑↓: activity · Enter: open · Esc: close")
                    wrapMode: Text.WordWrap
                    font.pixelSize: 10
                    opacity: 0.5
                }
            }
        }
        }
        CompactDialog {
            id: rollDialog
            onClosed: if (!root.editingRollId && root.nodes.length) root.focusNode(root.nodes[0].id)
            parent: Overlay.overlay
            anchors.centerIn: parent
            width: Math.min(400, window.width - 32)
            title: root.editingRollId ? "✏️ " + I18n.t("Rename Roll") : "🧾 " + I18n.t("New Roll")
            modal: true
            focus: true
            standardButtons: Dialog.NoButton
            contentItem: Column {
                spacing: 16
                TextField {
                    id: rollNameInput
                    width: parent.width
                    placeholderText: I18n.t("Roll name")
                    maximumLength: 100
                    onAccepted: root.submitRoll()
                }
                Row {
                    spacing: 4
                    ActionLink { text: I18n.t("Cancel"); onClicked: rollDialog.close(); }
                    ActionLink { text: root.editingRollId ? I18n.t("Rename") : I18n.t("Create"); enabled: rollNameInput.text.trim().length > 0; onClicked: root.submitRoll(); }
                }
            }
        }
        Menu {
            id: colorMenu
            title: "🎨 " + I18n.t("Node color")
            Instantiator {
                model: ["default", "blue", "green", "amber", "rose", "purple"]
                onObjectAdded: function(index, object) { colorMenu.insertItem(index, object); }
                onObjectRemoved: function(index, object) { colorMenu.removeItem(object); }
                delegate: MenuItem {
                    required property string modelData
                    text: I18n.t(modelData.charAt(0).toUpperCase() + modelData.slice(1))
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
                    RowLayout {
                        spacing: 8
                        Layout.preferredHeight: 40
                        FlolinrIcon { Layout.preferredWidth: 26; Layout.preferredHeight: 26; }
                        RowLayout {
                            spacing: 11
                            Layout.alignment: Qt.AlignVCenter
                            Row {
                                spacing: 0
                                Label { text: "Flolin"; color: Commons.Color.foreground; font.pixelSize: 18; font.bold: true; }
                                Label { text: "r"; color: "#78c58b"; font.pixelSize: 18; font.bold: true; }
                            }
                            Label {
                                objectName: "brandVersion"
                                text: root.manifest ? root.manifest.version : "0.24.0"
                                color: Commons.Color.foreground
                                opacity: 0.4
                                font.pixelSize: 9
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                        Item { Layout.fillWidth: true; }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        spacing: 2
                        ActionLink {
                            id: todayLink
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: "📝 " + I18n.t("Today's note")
                            enabled: root.ready
                            contentItem: Label { text: todayLink.text; color: Commons.Color.foreground; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight; }
                            onClicked: root.openMemopad(root.todayKey)
                        }
                        ActionLink {
                            text: "[+]"
                            enabled: root.ready
                            Accessible.name: I18n.t("Add today's note")
                            onClicked: root.addTodayNote()
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
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        spacing: 2
                        ActionLink {
                            id: rollsBranch
                            Layout.fillWidth: true
                            text: "🗞️ " + I18n.t("Rolls")
                            contentItem: Label { text: rollsBranch.text; color: Commons.Color.foreground; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter; }
                            onClicked: rollList.forceActiveFocus()
                        }
                        ActionLink {
                            id: addRollLink
                            text: "[+]"
                            enabled: root.ready
                            onClicked: root.editRoll(true)
                            Accessible.name: I18n.t("Add Roll")
                        }
                    }
                    ListView {
                        id: rollList
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
                        RollEntry {
                            width: ListView.view.width
                            controller: root
                        }
                    }

                    ActionLink {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        visible: root.archivedRolls.length > 0
                        id: archivedBranch
                        text: "📦 " + I18n.t("Archived")
                        flat: true
                        contentItem: Label { text: archivedBranch.text; color: Commons.Color.foreground; opacity: 0.65; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter; }
                        onClicked: archivedList.forceActiveFocus()
                    }
                    ListView {
                        id: archivedList
                        visible: root.archivedRolls.length > 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: count ? count * 28 : 24
                        interactive: false
                        clip: true
                        model: root.archivedRolls
                        Keys.onReturnPressed: { if (currentIndex >= 0) { root.selectRoll(model[currentIndex].id); } }
                        Keys.onEnterPressed: { if (currentIndex >= 0) { root.selectRoll(model[currentIndex].id); } }
                        delegate: rollDelegate
                        ScrollBar.vertical: ScrollBar {}
                        Label { visible: archivedList.count === 0; text: I18n.t("No archived Rolls"); color: Commons.Color.foreground; opacity: 0.35; font.pixelSize: 11; }
                    }

                        }
                    }

                    ActionLink { text: "📥 " + I18n.t("Import"); enabled: root.ready && !features.busy; onClicked: fileTransfer.open("import"); }
                    ActionLink { text: "📅 " + I18n.t("Calendar"); enabled: root.ready; onClicked: root.showCalendar(); }
                    ActionLink { text: "⚙️ " + I18n.t("Settings"); onClicked: featurePanel.show("settings"); }
                    Label { Layout.fillWidth: true; visible: !!appSettings.error; text: I18n.t(appSettings.error); wrapMode: Text.WordWrap; }
                    ActionLink {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        id: shortcutsLink
                        text: I18n.t("Shortcuts") + " · " + keyboardSettings.label("help")
                        font.pixelSize: 11
                        contentItem: Label { text: shortcutsLink.text; color: Commons.Color.foreground; opacity: 0.6; font.pixelSize: 11; horizontalAlignment: Text.AlignLeft; verticalAlignment: Text.AlignVCenter; }
                        flat: true
                        onClicked: helpDialog.open()


                    }
                    Label {
                        Layout.fillWidth: true
                        text: I18n.t(root.status)
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
                ActionLink { text: "✨ AI"; enabled: root.ready && root.nodes.length > 0 && !features.busy; onClicked: featurePanel.show("ai"); }
                ActionLink { text: "📤 " + I18n.t("Export"); enabled: root.ready && !features.busy; onClicked: fileTransfer.open("export"); }
                ActionLink { text: "✏️ " + I18n.t("Rename Roll"); flat: true; visible: !root.isMemopad; enabled: root.ready; onClicked: root.editRoll(false); }
                ActionLink { text: root.archived ? "♻️ " + I18n.t("Restore") : "📦 " + I18n.t("Archive"); flat: true; visible: !root.isMemopad; enabled: root.ready; onClicked: root.toggleArchive(); }
                ActionLink { text: "🗑️ " + I18n.t("Delete"); flat: true; visible: root.archived; onClicked: root.requestDelete(); }
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
                        while (i >= 0) { result.unshift({id: root.nodes[i].id, text: root.nodes[i].attachment ? root.nodes[i].attachment.language || root.nodes[i].attachment.kind : root.nodes[i].text || I18n.t("Untitled")}); i = Model.parentOf(root.nodes, i); }
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
                visible: !root.zoomAttachment
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(40, zoomTitle.contentHeight)
                spacing: 12
                ActionLink {
                    text: root.rollIcon
                    width: 40; height: 40
                    font.family: "Noto Color Emoji"
                    font.pixelSize: 28
                    flat: true
                    onClicked: root.chooseIcon()
                    ToolTip.visible: hovered
                    ToolTip.text: I18n.t("Change Roll icon ({0})", [keyboardSettings.label("emoji")])
                }
                TextArea {
                    id: zoomTitle
                    width: parent.width - 52
                    height: Math.max(40, contentHeight)
                    wrapMode: TextEdit.Wrap
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
                    onInputMethodComposingChanged: if (!inputMethodComposing) zoomSlashMenu.update()
                    Keys.priority: Keys.BeforeItem
                    Keys.onPressed: function(event) {
                        if (readOnly || inputMethodComposing || (event.modifiers & (Qt.ShiftModifier | Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) return;
                        if (zoomSlashMenu.handleKey(event)) return;
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            event.accepted = true;
                            root.splitItem(root.zoom, selectionStart, selectionEnd);
                        } else if (selectionStart === selectionEnd) {
                            var caret = positionToRectangle(cursorPosition);
                            if ((event.key === Qt.Key_Down && caret.y >= positionToRectangle(length).y - 1) || (event.key === Qt.Key_Right && cursorPosition === length)) {
                                var target = event.key === Qt.Key_Right ? {position: 0} : {x: caret.x, direction: 1};
                                if (root.navigateFrom(root.zoom, 1, target)) event.accepted = true;
                            }
                        }
                    }
                    onActiveFocusChanged: {
                        if (activeFocus && root.zoom) { root.focusedNode = root.zoom; zoomSlashMenu.update(); }
                        else { sessionRecorded = false; zoomSlashMenu.close(); }
                    }
                    onTextChanged: {
                        if (!activeFocus || readOnly) return;
                        var i = Model.indexOf(root.nodes, root.zoom);
                        if (i >= 0 && root.nodes[i].text !== text) {
                            if (!sessionRecorded) { root.snapshot(); sessionRecorded = true; }
                            root.nodes[i].text = text; Model.touch([root.nodes[i]]); root.changed();
                        }
                        zoomSlashMenu.update();
                    }
                    SlashMenu { id: zoomSlashMenu; editor: zoomTitle; controller: root; nodeId: root.zoom }
                }
            }
            RowLayout {
                visible: !!root.zoom && (Commands.todoState(root.zoomText) !== null || !!Commands.parseLink(root.zoomText) || Commands.hasUrl(root.zoomText))
                Layout.fillWidth: true
                ActionLink {
                    visible: Commands.todoState(root.zoomText) !== null
                    text: Commands.todoState(root.zoomText) === true ? "☑" : "☐"
                    Accessible.name: I18n.t("Task")
                    onClicked: root.toggleTodo(root.zoom)
                }
                ActionLink {
                    visible: !!Commands.parseLink(root.zoomText)
                    text: "🔗 " + (Commands.parseLink(root.zoomText) || {}).label
                    onClicked: root.followInternalLink(Commands.parseLink(root.zoomText))
                }
                Text {
                    visible: Commands.hasUrl(root.zoomText) && !Commands.parseLink(root.zoomText)
                    Layout.fillWidth: true
                    text: Commands.linkify(root.zoomText)
                    textFormat: Text.RichText
                    wrapMode: Text.Wrap
                    color: Commons.Color.foreground
                    linkColor: Commons.Color.accent
                    font.pixelSize: 13
                    onLinkActivated: function(link) { if (/^https?:\/\//i.test(link)) Qt.openUrlExternally(link); }
                }
            }
            ColumnLayout {
                visible: !!root.zoomAttachment
                Layout.fillWidth: true
                Layout.maximumWidth: 760
                Layout.alignment: Qt.AlignHCenter
                Loader {
                    id: zoomAttachmentBody
                    Layout.fillWidth: true
                    active: !!root.zoomAttachment
                    Layout.preferredHeight: item ? item.implicitHeight : 0
                    sourceComponent: AttachmentView {
                        width: zoomAttachmentBody.width
                        attachment: root.zoomAttachment
                        collapsed: root.zoomAttachmentCollapsed
                        onExpandRequested: root.setAttachmentCollapsed(root.zoom, false)
                        onCollapseRequested: root.setAttachmentCollapsed(root.zoom, true)
                        onEditRequested: attachmentDialog.showEdit(root.zoom)
                        onSaveRequested: attachmentDialog.saveFile(root.zoomAttachment)
                        onRemoveRequested: root.removeAttachment(root.zoom)
                    }
                }
            }
            OutlineList {
                id: list
                objectName: "outlineList"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.maximumWidth: 760
                Layout.alignment: Qt.AlignHCenter
                clip: true
                model: root.rows
                spacing: 0
                delegate: OutlineNode {
                    width: list.width
                    controller: root
                    onColorRequested: function(nodeId) { root.colorTarget = nodeId; colorMenu.popup(); }
                    onEditAttachmentRequested: function(nodeId) { attachmentDialog.showEdit(nodeId); }
                    onSaveAttachmentRequested: function(attachment) { attachmentDialog.saveFile(attachment); }
                    onRemoveAttachmentRequested: function(nodeId) { root.removeAttachment(nodeId); }
                }
                footer: ActionLink { text: "[+]"; Accessible.name: I18n.t("Add item"); flat: true; enabled: root.ready && !root.query; onClicked: root.addFirst(); }
            }
            ActionLink {
                objectName: "authorCredit"
                Layout.alignment: Qt.AlignRight
                text: "by DoYoBe"
                font.pixelSize: 9
                horizontalPadding: 0
                verticalPadding: 0
                implicitHeight: 14
                Accessible.name: "by DoYoBe — www.doyo.be"
                onClicked: Qt.openUrlExternally("https://www.doyo.be/")
            }
        }
        }
    }
}
