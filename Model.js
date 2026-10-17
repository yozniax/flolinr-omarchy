.import "StarterContent.js" as StarterContent

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
            attachment: nodes[i].attachment || null,
            color: nodes[i].color || "default", collapsed: nodes[i].collapsed, children: endOf(nodes, i) > i + 1 || !!nodes[i].attachment});
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
// Insert on the next visible row. Expanded children keep their original parent.
function splitNode(nodes, i, start, end, zoomed) {
    if (i < 0 || i >= nodes.length) throw new Error("Item not found");
    var original = nodes[i], text = original.text;
    if (!Number.isInteger(start) || !Number.isInteger(end) || start < 0 || end < start || end > text.length)
        throw new Error("Invalid split position");
    var branchEnd = endOf(nodes, i);
    var insertChild = branchEnd > i + 1 && (!original.collapsed || zoomed);
    var next = node(text.slice(end), original.depth + (insertChild ? 1 : 0));
    next.color = original.color || "default";
    var prefix = text.slice(0, start);
    if (original.text !== prefix) { original.text = prefix; touch([original]); }
    nodes.splice(insertChild ? i + 1 : branchEnd, 0, next);
    return next.id;
}
// Join a visible predecessor, preserving and reparenting the removed item's children.
function mergeNode(nodes, i, previousId) {
    var p = indexOf(nodes, previousId);
    if (i <= 0 || i >= nodes.length || p < 0 || p >= i) return null;
    for (var j = p + 1; j < i; j++) if (nodes[j].depth <= nodes[p].depth) return null;
    var current = nodes[i], previous = nodes[p], position = previous.text.length;
    if (current.attachment || previous.attachment) return null;
    var end = endOf(nodes, i), delta = previous.depth - current.depth;
    var descendants = nodes.slice(i + 1, end);
    descendants.forEach(function(n) { n.depth += delta; });
    previous.text += current.text;
    previous.collapsed = false;
    touch([previous].concat(descendants));
    nodes.splice(i, 1);
    return {id: previous.id, position: position};
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
        if (n.attachment !== undefined) validateAttachment(n.attachment);
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
    return {id: node("", 0).id, name: name.trim() || "Untitled Roll", icon: "🧾", archived: false, nodes: nodes || []};
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
    var rolls = StarterContent.rolls.map(function(template) {
        var nodes = template.nodes.map(function(item) {
            // Every fresh workspace owns its IDs, timestamps and nested attachments.
            return Object.assign(node(item.text, item.depth), JSON.parse(JSON.stringify(item)));
        });
        var roll = createRoll(template.name, nodes);
        roll.icon = template.icon;
        return roll;
    });
    return workspace({version: 2, activeRollId: rolls[0].id, rolls: rolls});
}

function searchWorkspace(rolls, query) {
    var needle = query.trim().toLocaleLowerCase(), hits = [];
    if (!needle) return hits;
    rolls.forEach(function(roll) {
        var ancestors = [];
        roll.nodes.forEach(function(n) {
            ancestors.length = n.depth;
            if (n.text.toLocaleLowerCase().indexOf(needle) >= 0)
                hits.push({rollId: roll.id, nodeId: n.id, text: n.text, rollName: roll.memopadDate ? "Today's Memo · " + roll.memopadDate : roll.name,
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
function parseCaptureOutline(text, checklist) {
    if (typeof text !== "string") throw new Error("Add at least one item");
    var result = [], previousDepth = -1;
    text.split(/\r?\n/).forEach(function(line) {
        if (!line.trim()) return;
        var indent = (line.match(/^[\t ]*/) || [""])[0];
        var requestedDepth = (indent.match(/\t/g) || []).length + Math.floor(indent.replace(/\t/g, "").length / 2);
        var value = line.slice(indent.length).trim();
        if (!value) return;
        var depth = previousDepth < 0 ? 0 : Math.min(requestedDepth, previousDepth + 1);
        previousDepth = depth;
        if (checklist && !/^\[[ xX]\]\s/.test(value)) value = "[ ] " + value;
        result.push({text: value, depth: depth});
    });
    if (!result.length) throw new Error("Add at least one item");
    return result;
}
function markdownNodes(nodes, base) {
    return nodes.map(function(n) {
        var prefix = "  ".repeat(n.depth - (base || 0));
        var lines = n.text.split("\n");
        var value = prefix + "- " + lines[0] + lines.slice(1).map(function(line) { return "\n" + prefix + "  " + line.replace(/\\/g, "\\\\").replace(/^( *)([-+*]|\d+[.)])(?= |$)/, "$1\\$2"); }).join("");
        if (n.attachment) {
            var body = attachmentMarkdown(n.attachment), token;
            do { token = node("", 0).id; } while (body.indexOf(token) >= 0);
            var block = "<!-- flolinr-attachment:" + encodeURIComponent(JSON.stringify({attachment: n.attachment, end: token})) + " -->\n" + body + "\n<!-- flolinr-end:" + token + " -->";
            value += "\n" + block.split("\n").map(function(line) { return prefix + "  " + line; }).join("\n");
        }
        return value;
    }).join("\n");
}
function exportMarkdown(roll) {
    return "# " + roll.name.replace(/[\r\n]/g, " ") + "\n\n" + markdownNodes(roll.nodes, 0) + "\n";
}
function importMarkdown(text, fallbackName) {
    if (typeof text !== "string" || text.length > 32000000) throw new Error("Markdown exceeds 32 MB");
    var lines = text.replace(/^\uFEFF/, "").replace(/\r\n?/g, "\n").split("\n");
    if (lines[lines.length - 1] === "") lines.pop();
    var name = fallbackName || "Imported Roll", result = [], titleSeen = false, skipAttachment = "";
    lines.forEach(function(line) {
        if (skipAttachment) { if (line.trim() === "<!-- flolinr-end:" + skipAttachment + " -->") skipAttachment = ""; return; }
        var metadata = /^\s*<!-- flolinr-attachment:(\S+) -->$/.exec(line);
        if (metadata && result.length) {
            var payload = JSON.parse(decodeURIComponent(metadata[1]));
            validateAttachment(payload.attachment);
            if (payload.end !== undefined && !/^[a-z0-9]+$/.test(payload.end)) throw new Error("Invalid attachment boundary");
            result[result.length - 1].attachment = payload.attachment;
            skipAttachment = payload.end || "";
            return;
        }
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
    if (skipAttachment) throw new Error("Incomplete attachment block");
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
    if (JSON.parse(before).some(function(n) { return !!n.attachment; })) throw new Error("Protected attachments require a new AI preview");
    var parsed = importMarkdown(replacement, "AI preview").nodes;
    if (parsed.some(function(n) { return !!n.attachment; })) throw new Error("AI cannot create attachments");
    if (!parsed.length || parsed.filter(function(n) { return n.depth === 0; }).length !== 1) throw new Error("AI preview must contain one root bullet and its children");
    var depth = nodes[i].depth;
    parsed.forEach(function(n) { n.depth += depth; });
    // Keep the focused root identity for navigation; descendants receive fresh IDs.
    parsed[0].id = nodes[i].id; parsed[0].createdAt = nodes[i].createdAt;
    var result = nodes.slice(0, i).concat(parsed, nodes.slice(endOf(nodes, i)));
    validate({version: 1, nodes: result});
    return result;
}

// AI follows the right-hand body: current Roll, or the entire zoomed branch.
function scopeSnapshot(nodes, zoom) {
    return zoom ? branchSnapshot(nodes, zoom) : JSON.stringify(nodes);
}
function applyScope(nodes, zoom, before, replacement, protection) {
    if (scopeSnapshot(nodes, zoom) !== before) throw new Error("The displayed outline changed. Generate a new preview.");
    if (protection && protection.items.length) return applyProtectedScope(nodes, zoom, replacement, protection);
    if (JSON.parse(before).some(function(n) { return !!n.attachment; })) throw new Error("Protected attachments require a new AI preview");
    if (zoom) return applyBranch(nodes, zoom, before, replacement);
    var parsed = importMarkdown(replacement, "AI preview").nodes;
    if (parsed.some(function(n) { return !!n.attachment; })) throw new Error("AI cannot create attachments");
    if (!parsed.length) throw new Error("AI preview must contain at least one bullet item");
    validate({version: 1, nodes: parsed});
    return parsed;
}

function importOutline(items, name) {
    if (!Array.isArray(items)) throw new Error("Invalid imported outline");
    var nodes = items.map(function(item) {
        if (!item || typeof item.text !== "string" || !Number.isInteger(item.depth)) throw new Error("Invalid imported item");
        var decoded = decodeInterchangeText(item.text), value = node(decoded.text, item.depth);
        if (decoded.attachment) value.attachment = decoded.attachment;
        return value;
    });
    validate({version: 1, nodes: nodes});
    return createRoll(name || "Imported Roll", nodes);
}

// Embedded data stays in the workspace, independently of the source file.
function validateAttachment(a) {
    if (!a || ["image", "file", "text", "code"].indexOf(a.kind) < 0 ||
        typeof a.name !== "string" || !a.name || a.name.length > 255 || /[\r\n]/.test(a.name) ||
        typeof a.mime !== "string" || !/^[a-z0-9.+-]+\/[a-z0-9.+-]+$/i.test(a.mime) ||
        typeof a.content !== "string" || a.content.length > 2800000 ||
        typeof a.language !== "string" || !/^[a-zA-Z0-9_+-]{0,32}$/.test(a.language)) throw new Error("Invalid attachment");
    if (a.kind === "image" && ["image/png", "image/jpeg", "image/gif", "image/webp", "image/bmp"].indexOf(a.mime) < 0)
        throw new Error("Unsupported image preview");
    if ((a.kind === "image" || a.kind === "file") &&
        ((a.kind === "image" && !a.content) || a.content.length % 4 || !/^[A-Za-z0-9+/]*={0,2}$/.test(a.content))) throw new Error("Invalid attachment encoding");
    var bytes = a.kind === "image" || a.kind === "file" ? a.content.length / 4 * 3 - (a.content.endsWith("==") ? 2 : a.content.endsWith("=") ? 1 : 0)
        : encodeURIComponent(a.content).replace(/%[0-9A-F]{2}/g, "x").length;
    if (bytes > 2000000) throw new Error("Inserted files must be 2 MB or smaller");
    return a;
}
function insertAttachment(nodes, parentId, attachment) {
    validateAttachment(attachment);
    var p = indexOf(nodes, parentId);
    if (parentId && p < 0) throw new Error("The insertion target changed");
    var value = node("", p < 0 ? 0 : nodes[p].depth + 1);
    value.attachment = JSON.parse(JSON.stringify(attachment));
    if (p >= 0) nodes[p].collapsed = false;
    nodes.splice(p < 0 ? nodes.length : endOf(nodes, p), 0, value);
    return value.id;
}
function replaceWithAttachment(nodes, id, attachment, expectedText) {
    validateAttachment(attachment);
    var i = indexOf(nodes, id);
    if (i < 0 || nodes[i].attachment || nodes[i].text !== expectedText || !/^\/[a-z]*$/i.test(nodes[i].text.trim()))
        throw new Error("The insertion target changed");
    nodes[i].text = "";
    nodes[i].attachment = JSON.parse(JSON.stringify(attachment));
    nodes[i].collapsed = false;
    touch([nodes[i]]);
    return id;
}
function attachmentMarkdown(a) {
    validateAttachment(a);
    var name = a.name.replace(/[\\\[\]()*_`<>]/g, "\\$&");
    if (a.kind === "image" || a.kind === "file")
        return (a.kind === "image" ? "!" : "") + "[" + name + "](data:" + a.mime + ";base64," + a.content + ")";
    var fence = "```";
    while (a.content.indexOf(fence) >= 0) fence += "`";
    return "**" + name + "**\n\n" + fence + (a.language || "text") + "\n" + a.content + (a.content.endsWith("\n") ? "" : "\n") + fence;
}
function interchangeText(n) {
    return n.text + (n.attachment ? "\n<!-- flolinr-attachment:" + encodeURIComponent(JSON.stringify({attachment: n.attachment})) + " -->" : "");
}
function decodeInterchangeText(text) {
    var match = /\n<!-- flolinr-attachment:(\S+) -->$/.exec(text);
    if (!match) return {text: text};
    var payload = JSON.parse(decodeURIComponent(match[1]));
    return {text: text.slice(0, match.index), attachment: validateAttachment(payload.attachment)};
}
function createAiScope(nodes, zoom) {
    var snapshot = scopeSnapshot(nodes, zoom), scope = JSON.parse(snapshot), items = [], nonce = node("", 0).id;
    var base = scope.length ? scope[0].depth : 0;
    scope.forEach(function(n, i) {
        if (!n.attachment) return;
        var token = "[FLOLINR_PROTECTED_" + nonce + "_" + i + "]";
        items.push({token: token, node: JSON.parse(JSON.stringify(n))});
        n.text = token;
        delete n.attachment;
    });
    return {snapshot: snapshot, text: markdownNodes(scope, base), base: base, items: items};
}
function verifyProtectedTokens(text, protection) {
    var expected = protection.items.map(function(item) { return item.token; });
    var found = text.match(/\[FLOLINR_PROTECTED_[a-z0-9_]+\]/g) || [];
    if (found.length !== expected.length || expected.some(function(token) { return found.filter(function(s) { return s === token; }).length !== 1; }))
        throw new Error("AI changed a protected attachment marker. Generate a new preview.");
}
function applyProtectedScope(nodes, zoom, replacement, protection) {
    verifyProtectedTokens(replacement, protection);
    var parsed = importMarkdown(replacement, "AI preview").nodes;
    if (!parsed.length || (zoom && parsed.filter(function(n) { return n.depth === 0; }).length !== 1)) throw new Error("Invalid AI outline");
    parsed.forEach(function(n) { if (n.attachment) throw new Error("AI cannot create attachments"); });
    var base = zoom ? nodes[indexOf(nodes, zoom)].depth : 0;
    protection.items.forEach(function(item) {
        var matches = parsed.filter(function(n) { return n.text === item.token; });
        if (matches.length !== 1 || matches[0].depth + base !== item.node.depth)
            throw new Error("AI changed a protected attachment's indentation. Generate a new preview.");
        var i = parsed.indexOf(matches[0]);
        parsed[i] = JSON.parse(JSON.stringify(item.node));
        parsed[i].depth -= base;
    });
    var start = zoom ? indexOf(nodes, zoom) : 0, end = zoom ? endOf(nodes, start) : nodes.length;
    parsed.forEach(function(n) { n.depth += base; });
    if (zoom) { parsed[0].id = nodes[start].id; parsed[0].createdAt = nodes[start].createdAt; }
    var next = nodes.slice(0, start).concat(parsed, nodes.slice(end));
    validate({version: 1, nodes: next});
    return next;
}
function restoreMarkdownAttachments(text, protection) {
    verifyProtectedTokens(text, protection);
    protection.items.forEach(function(item) {
        var lines = text.split("\n"), matches = [];
        lines.forEach(function(line, i) { if (line.trim() === item.token) matches.push(i); });
        if (matches.length !== 1) throw new Error("AI changed a protected attachment marker. Generate a new preview.");
        lines[matches[0]] = attachmentMarkdown(item.node.attachment);
        text = lines.join("\n");
    });
    return text;
}

// Prefer filename extensions; pasted content is inspected without executing it.
function detectAttachmentFormat(name, content) {
    var extension = (name.trim().toLowerCase().match(/\.([a-z0-9]+)$/) || [])[1];
    var formats = {html:"html",htm:"html",css:"css",json:"json",md:"markdown",markdown:"markdown",txt:"text",text:"text",js:"javascript",mjs:"javascript",ts:"typescript",tsx:"tsx",jsx:"jsx",py:"python",sh:"sh",bash:"bash",yaml:"yaml",yml:"yaml",xml:"xml",svg:"xml",toml:"toml",sql:"sql",c:"c",h:"c",cpp:"cpp",rs:"rust",go:"go",java:"java",rb:"ruby",qml:"qml",csv:"csv",log:"text"};
    if (formats[extension]) return formats[extension];
    var text = content.trim();
    if (/^[\[{]/.test(text)) { try { JSON.parse(text); return "json"; } catch (e) {} }
    if (/^<\?xml\b/i.test(text) || /^<svg\b/i.test(text)) return "xml";
    if (/^<!doctype html\b/i.test(text) || /<\/?(?:html|head|body|div|span|p|script|style|section|h[1-6])\b/i.test(text)) return "html";
    if (/^[^{}]+\{\s*[\w-]+\s*:[^{}]+[;}]/.test(text)) return "css";
    if (/^(?:#{1,6}\s|```|~~~|[-*+]\s|\d+\.\s|>\s)/m.test(text) || /\[[^\]]+\]\([^)]+\)/.test(text)) return "markdown";
    if (/^(?:def |class |from \w+ import |import \w+|#!.*python)/m.test(text)) return "python";
    if (/^(?:const |let |var |function |export |import .* from )/m.test(text)) return "javascript";
    return "text";
}

// Move within the same sidebar section; daily notes keep their workspace slots.
function reorderRolls(rolls, sourceId, targetId, after) {
    var source = indexOf(rolls, sourceId), target = indexOf(rolls, targetId);
    if (source < 0 || target < 0 || source === target) return null;
    if (rolls[source].memopadDate || rolls[target].memopadDate || !!rolls[source].archived !== !!rolls[target].archived) return null;
    var order = rolls.filter(function(r) { return !r.memopadDate && !!r.archived === !!rolls[source].archived; });
    var moved = order.splice(indexOf(order, sourceId), 1)[0];
    order.splice(indexOf(order, targetId) + (after ? 1 : 0), 0, moved);
    var next = 0;
    var result = rolls.map(function(r) { return !r.memopadDate && !!r.archived === !!moved.archived ? order[next++] : r; });
    return result.every(function(r, i) { return r === rolls[i]; }) ? null : result;
}
