function node(text, depth) {
    var now = new Date().toISOString();
    return {createdAt: now, updatedAt: now, id: Date.now().toString(36) + Math.random().toString(36).slice(2), text: text || "", depth: depth || 0, collapsed: false, color: "default"};
}
function endOf(nodes, i) {
    var end = i + 1;
    while (end < nodes.length && nodes[end].depth > nodes[i].depth) end++;
    return end;
}
function indexOf(nodes, id) { return nodes.findIndex(function(n) { return n.id === id; }); }
function parentOf(nodes, i) {
    for (var p = i - 1; p >= 0; p--) if (nodes[p].depth < nodes[i].depth) return p;
    return -1;
}
function visible(nodes, zoom, query) {
    var z = indexOf(nodes, zoom), start = z < 0 ? 0 : z + 1;
    var end = z < 0 ? nodes.length : endOf(nodes, z), result = [], hidden = -1;
    var base = z < 0 ? 0 : nodes[z].depth + 1;
    for (var i = start; i < end; i++) {
        if (query) {
            if (nodes[i].text.toLowerCase().indexOf(query.toLowerCase()) < 0) continue;
        } else {
            if (hidden >= 0 && nodes[i].depth > hidden) continue;
            hidden = nodes[i].collapsed ? nodes[i].depth : -1;
        }
        result.push({id: nodes[i].id, text: nodes[i].text, depth: query ? 0 : nodes[i].depth - base,
            color: nodes[i].color || "default", collapsed: nodes[i].collapsed, children: endOf(nodes, i) > i + 1});
    }
    return result;
}
function indent(nodes, i, direction) {
    if (i < 0) return false;
    var depth = nodes[i].depth, end = endOf(nodes, i);
    if (direction > 0) {
        var prev = i - 1;
        while (prev >= 0 && nodes[prev].depth > depth) prev--;
        if (prev < 0 || nodes[prev].depth !== depth) return false;
        nodes[prev].collapsed = false;
    } else if (depth === 0) return false;
    // Outdent after the parent's remaining children to preserve their parentage.
    var destination = direction < 0 ? endOf(nodes, parentOf(nodes, i)) : end;
    var branch = nodes.splice(i, end - i);
    branch.forEach(function(n) { n.depth += direction; });
    nodes.splice.apply(nodes, [direction < 0 ? destination - branch.length : i, 0].concat(branch));
    return true;
}
function move(nodes, i, direction) {
    if (i < 0) return false;
    var end = endOf(nodes, i), target;
    if (direction > 0) {
        if (end >= nodes.length || nodes[end].depth !== nodes[i].depth) return false;
        target = endOf(nodes, end);
    } else {
        target = i - 1;
        while (target >= 0 && nodes[target].depth > nodes[i].depth) target--;
        if (target < 0 || nodes[target].depth !== nodes[i].depth) return false;
    }
    var branch = nodes.splice(i, end - i);
    nodes.splice.apply(nodes, [direction > 0 ? target - branch.length : target, 0].concat(branch));
    return true;
}
function validate(data) {
    if (!data || data.version !== 1 || !Array.isArray(data.nodes)) throw new Error("Unsupported document");
    var ids = {};
    data.nodes.forEach(function(n, i) {
        if (!n || typeof n.id !== "string" || !n.id || ids[n.id] || typeof n.text !== "string" ||
            !Number.isInteger(n.depth) || n.depth < 0 || n.depth > (i ? data.nodes[i-1].depth + 1 : 0) ||
            typeof n.collapsed !== "boolean") throw new Error("Invalid outline");
        if (n.color !== undefined && ["default", "blue", "green", "amber", "rose", "purple"].indexOf(n.color) < 0)
            throw new Error("Invalid node color");
        ["createdAt", "updatedAt"].forEach(function(key) {
            if (n[key] !== undefined && n[key] !== null &&
                (typeof n[key] !== "string" || !Number.isFinite(new Date(n[key]).getTime())))
                throw new Error("Invalid timestamp");
        });
        ids[n.id] = true;
    });
    return data.nodes;
}

function createRoll(name, nodes) {
    return {id: node("", 0).id, name: name.trim() || "Untitled Roll", icon: "📄", archived: false, nodes: nodes || []};
}
function workspace(data) {
    if (data && data.version === 1) {
        var roll = createRoll("Inbox", validate(data));
        return {version: 2, activeRollId: roll.id, rolls: [roll]};
    }
    if (!data || data.version !== 2 || !Array.isArray(data.rolls) || !data.rolls.length)
        throw new Error("Invalid workspace");
    var ids = {};
    data.rolls.forEach(function(roll) {
        if (!roll || typeof roll.id !== "string" || !roll.id || ids[roll.id] ||
            typeof roll.name !== "string" || !roll.name.trim()) throw new Error("Invalid Roll");
        if (roll.archived !== undefined && typeof roll.archived !== "boolean") throw new Error("Invalid archive state");
        if (roll.memopadDate !== undefined &&
            (typeof roll.memopadDate !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(roll.memopadDate) ||
             dayKey(roll.memopadDate + "T12:00:00") !== roll.memopadDate || roll.archived === true ||
             roll.name !== "memopad(" + roll.memopadDate + ")")) throw new Error("Invalid memopad");
        if (roll.memopadDate && data.rolls.filter(function(r) { return r.memopadDate === roll.memopadDate; }).length !== 1)
            throw new Error("Duplicate memopad date");
        ids[roll.id] = true;
        if (roll.icon !== undefined && (typeof roll.icon !== "string" || roll.icon.length > 32))
            throw new Error("Invalid Roll icon");
        validate({version: 1, nodes: roll.nodes});
    });
    if (typeof data.activeRollId !== "string" || !Object.prototype.hasOwnProperty.call(ids, data.activeRollId))
        throw new Error("Active Roll not found");
    return data;
}

function touch(nodes, now) {
    var timestamp = now || new Date().toISOString();
    nodes.forEach(function(n) { n.updatedAt = timestamp; });
}
function dayKey(value) {
    if (!value) return "";
    var d = new Date(value);
    if (!Number.isFinite(d.getTime())) return "";
    return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0");
}
function calendarDays(year, month) {
    var first = new Date(year, month, 1), offset = (first.getDay() + 6) % 7, days = [];
    for (var i = 0; i < 42; i++) {
        var d = new Date(year, month, i - offset + 1);
        days.push({key: dayKey(d), day: d.getDate(), current: d.getMonth() === month});
    }
    return days;
}
function activity(rolls, day, mode) {
    var result = [];
    rolls.forEach(function(roll) {
        if (roll.memopadDate) return;
        roll.nodes.forEach(function(n) {
            var value = mode === "created" ? n.createdAt : n.updatedAt;
            if (dayKey(value) === day) result.push({rollId: roll.id, rollName: roll.name, nodeId: n.id, text: n.text || "Untitled", timestamp: value});
        });
    });
    result.sort(function(a, b) { return new Date(b.timestamp) - new Date(a.timestamp); });
    return result;
}

function calendarTree(rolls, limit, collapsed, mode, foldDefault) {
    function closed(key) { return collapsed[key] === undefined ? !!foldDefault : !!collapsed[key]; }
    var counts = {};
    rolls.forEach(function(r) {
        if (r.memopadDate) { counts[r.memopadDate] = counts[r.memopadDate] || 0; return; }
        r.nodes.forEach(function(n) {
        var day = dayKey(mode === 'created' ? n.createdAt : n.updatedAt);
        if (day) counts[day] = (counts[day] || 0) + 1;
    }); });
    var dates = Object.keys(counts).sort().reverse(), rows = [], year = '', month = '';
    dates.slice(0, limit).forEach(function(day) {
        var y = day.slice(0, 4), m = day.slice(0, 7);
        if (y !== year) { rows.push({key:y,kind:'year',depth:0,label:y,closed:closed(y)}); year=y; month=''; }
        if (closed(y)) return;
        if (m !== month) { rows.push({key:m,kind:'month',depth:1,label:m.slice(5),closed:closed(m)}); month=m; }
        if (!closed(m)) rows.push({key:day,kind:'day',depth:2,label:day.slice(8),count:counts[day]});
    });
    return {rows:rows,total:dates.length};
}
function removeArchived(rolls, id) {
    var i = indexOf(rolls, id);
    if (i < 0 || rolls[i].archived !== true || rolls[i].memopadDate) throw new Error('Only archived Rolls can be deleted');
    var result = rolls.filter(function(r) { return r.id !== id; });
    return result.length ? result : [createRoll('Inbox', [])];
}
function ensureMemopad(rolls, day) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(day) || dayKey(day + 'T12:00:00') !== day) throw new Error('Invalid memopad date');
    for (var i=0; i<rolls.length; i++) if (rolls[i].memopadDate === day) return rolls[i];
    var roll=createRoll('memopad(' + day + ')', [node('',0)]);
    roll.memopadDate=day; roll.icon='📝'; rolls.push(roll); return roll;
}
function ensureInput(nodes, zoom) {
    var z=indexOf(nodes,zoom), depth=z < 0 ? 0 : nodes[z].depth+1;
    var end=z < 0 ? nodes.length : endOf(nodes,z), last=end-1;
    if (last > z && last >= 0 && nodes[last].depth === depth && nodes[last].text === '')
        return {id:nodes[last].id,created:false};
    var n=node('',depth);nodes.splice(end,0,n);
    return {id:n.id,created:true};
}

// Persistence boundary: validate before exposing data or replacing a file.
function decodeWorkspace(text) {
    var data = JSON.parse(text);
    return {workspace: workspace(data), needsSave: data.version === 1};
}
function encodeWorkspace(activeRollId, rolls) {
    // Validation normalizes older optional fields; use a detached snapshot.
    var data = JSON.parse(JSON.stringify({version: 2, activeRollId: activeRollId, rolls: rolls}));
    return JSON.stringify(workspace(data), null, 2);
}
function initialWorkspace() {
    var roll = createRoll("Inbox", [
        node("Welcome to Flolinr", 0),
        node("Press Enter to add an item, Tab to indent", 1),
        node("Click a bullet to zoom into an item", 1)
    ]);
    return {version: 2, activeRollId: roll.id, rolls: [roll]};
}

function searchWorkspace(rolls, query) {
    var needle = query.trim().toLocaleLowerCase(), hits = [];
    if (!needle) return hits;
    rolls.forEach(function(roll) {
        var ancestors = [];
        roll.nodes.forEach(function(n) {
            ancestors.length = n.depth;
            if (n.text.toLocaleLowerCase().indexOf(needle) >= 0)
                hits.push({rollId: roll.id, nodeId: n.id, text: n.text, rollName: roll.memopadDate ? "Daily note · " + roll.memopadDate : roll.name,
                    path: ancestors.join(" / "), memopadDate: roll.memopadDate || "", archived: !!roll.archived});
            ancestors[n.depth] = n.text;
        });
    });
    return hits;
}
function appendCapture(rolls, day, text) {
    var value = text.trim();
    if (!value || /[\r\n]/.test(value)) throw new Error("Enter one non-empty line");
    var roll = ensureMemopad(rolls, day), last = roll.nodes[roll.nodes.length - 1];
    if (last && last.depth === 0 && last.text === "") { last.text = value; touch([last]); return last.id; }
    var item = node(value, 0); roll.nodes.push(item); return item.id;
}
function markdownNodes(nodes, base) {
    return nodes.map(function(n) {
        var prefix = "  ".repeat(n.depth - (base || 0));
        var lines = n.text.split("\n");
        return prefix + "- " + lines[0] + lines.slice(1).map(function(line) { return "\n" + prefix + "  " + line.replace(/\\/g, "\\\\").replace(/^( *)([-+*]|\d+[.)])(?= |$)/, "$1\\$2"); }).join("");
    }).join("\n");
}
function exportMarkdown(roll) {
    return "# " + roll.name.replace(/[\r\n]/g, " ") + "\n\n" + markdownNodes(roll.nodes, 0) + "\n";
}
function importMarkdown(text, fallbackName) {
    if (typeof text !== "string" || text.length > 2000000) throw new Error("Markdown exceeds 2 MB");
    var lines = text.replace(/^\uFEFF/, "").replace(/\r\n?/g, "\n").split("\n");
    if (lines[lines.length - 1] === "") lines.pop();
    var name = fallbackName || "Imported Roll", result = [], titleSeen = false;
    lines.forEach(function(line) {
        if (!titleSeen && !result.length && /^# /.test(line)) { name = line.slice(2).trim() || name; titleSeen = true; return; }
        var match = /^( *)(?:[-+*]|\d+[.)])(?: (.*)|$)/.exec(line);
        if (match) {
            if (match[1].length % 2) throw new Error("Use two spaces per outline level");
            var depth = match[1].length / 2;
            if ((!result.length && depth !== 0) || (result.length && depth > result[result.length - 1].depth + 1)) throw new Error("Invalid Markdown nesting");
            result.push(node(match[2] || "", depth));
        } else if (result.length && line.startsWith("  ".repeat(result[result.length - 1].depth + 1))) {
            result[result.length - 1].text += "\n" + line.slice((result[result.length - 1].depth + 1) * 2).replace(/^( *)\\([-+*]|\d+[.)])(?= |$)/, "$1$2").replace(/\\\\/g, "\\");
        } else if (line.trim()) result.push(node(line, 0));
    });
    return createRoll(name, result);
}
function branchSnapshot(nodes, id) {
    var i = indexOf(nodes, id);
    if (i < 0) throw new Error("Focus an item first");
    return JSON.stringify(nodes.slice(i, endOf(nodes, i)));
}
function applyBranch(nodes, id, before, replacement) {
    var i = indexOf(nodes, id);
    if (i < 0 || branchSnapshot(nodes, id) !== before) throw new Error("The branch changed. Generate a new preview.");
    var parsed = importMarkdown(replacement, "AI preview").nodes;
    if (!parsed.length || parsed.filter(function(n) { return n.depth === 0; }).length !== 1) throw new Error("AI preview must contain one root bullet and its children");
    var depth = nodes[i].depth;
    parsed.forEach(function(n) { n.depth += depth; });
    // Keep the focused root identity for navigation; descendants receive fresh IDs.
    parsed[0].id = nodes[i].id; parsed[0].createdAt = nodes[i].createdAt;
    var result = nodes.slice(0, i).concat(parsed, nodes.slice(endOf(nodes, i)));
    validate({version: 1, nodes: result});
    return result;
}
