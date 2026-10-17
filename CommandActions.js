.import "Model.js" as Model
.import "Templates.js" as Templates

var commands = ["insert", "date", "link", "template"];
var templates = Templates.defaults;

function target(nodes, id, expected) {
    var i = Model.indexOf(nodes, id);
    if (i < 0 || nodes[i].attachment || nodes[i].text !== expected || !/^\/[a-z]*$/i.test(expected.trim()))
        throw new Error("The insertion target changed");
    return i;
}
function replace(nodes, id, expected, text) {
    var i = target(nodes, id, expected);
    nodes[i].text = text; nodes[i].collapsed = false; Model.touch([nodes[i]]);
    return id;
}
function insertTemplate(nodes, id, expected, index, available) {
    var template = (available || templates)[index];
    if (!template) throw new Error("Choose a template");
    var i = target(nodes, id, expected), depth = nodes[i].depth;
    replace(nodes, id, expected, template.title);
    var additions = template.items.map(function(item) { return Model.node(item[1], depth + item[0]); });
    nodes.splice.apply(nodes, [i + 1, 0].concat(additions));
    return additions.length ? additions[0].id : id;
}
function dateText(value) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(value) || Model.dayKey(value + "T12:00:00") !== value)
        throw new Error("Choose a valid date");
    return value;
}
function encodeId(value) { return encodeURIComponent(value).replace(/[()]/g, function(c) { return "%" + c.charCodeAt(0).toString(16).toUpperCase(); }); }
function linkText(roll, item) {
    var label = (item ? item.text || "Untitled item" : roll.memopadDate ? "Today's Memo · " + roll.memopadDate : roll.name).replace(/[\[\]\r\n]/g, " ").trim();
    return "[" + label + "](flolinr://roll/" + encodeId(roll.id) + (item ? "/item/" + encodeId(item.id) : "") + ")";
}
function parseLink(text) {
    var match = /^\[([^\]\r\n]+)\]\(flolinr:\/\/roll\/([^/\s)]+)(?:\/item\/([^/\s)]+))?\)$/.exec(text);
    if (!match) return null;
    try { return {label:match[1], rollId:decodeURIComponent(match[2]), nodeId:match[3] ? decodeURIComponent(match[3]) : ""}; }
    catch (e) { return null; }
}
function linkTargets(rolls, query, currentRoll, currentNode) {
    var result = [], needle = query.trim().toLocaleLowerCase();
    rolls.forEach(function(roll) {
        var title = roll.memopadDate ? "Today's Memo · " + roll.memopadDate : roll.name;
        if (!needle || title.toLocaleLowerCase().indexOf(needle) >= 0)
            result.push({label:title + (roll.archived ? " · Archived" : ""),rollId:roll.id,nodeId:""});
        // Avoid building thousands of item choices before a search is typed.
        if (!needle) return;
        roll.nodes.forEach(function(item) {
            if ((roll.id !== currentRoll || item.id !== currentNode) && item.text.trim() && item.text.toLocaleLowerCase().indexOf(needle) >= 0 && !/^\/[a-z]*$/i.test(item.text.trim()))
                result.push({label:title + " › " + item.text,rollId:roll.id,nodeId:item.id});
        });
    });
    return result.slice(0, 150);
}
function todoState(text) {
    var match = /^\[([ xX])\](?:\s|$)/.exec(text);
    return match ? match[1].toLowerCase() === "x" : null;
}
function toggleTodo(text) {
    var checked = todoState(text);
    if (checked === null) return text;
    return "[" + (checked ? " " : "x") + "]" + text.slice(3);
}
function escapeHtml(text) { return text.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;"); }
function hasUrl(text) { return /https?:\/\/[^\s<>]+/i.test(text); }
function linkify(text) {
    var pattern=/https?:\/\/[^\s<>]+/gi, result="", last=0, match;
    while ((match=pattern.exec(text))!==null) {
        var url=match[0].replace(/[.,;!?]+$/,"");
        while (url.endsWith(")") && (url.match(/\)/g)||[]).length>(url.match(/\(/g)||[]).length) url=url.slice(0,-1);
        result+=escapeHtml(text.slice(last,match.index))+"<a href=\""+escapeHtml(url)+"\">"+escapeHtml(url)+"</a>";
        last=match.index+url.length;
    }
    return (result+escapeHtml(text.slice(last))).replace(/\n/g,"<br>");
}
