var defaults = [
    {name: "Meeting notes", title: "Meeting notes", items: [
        [1,"Date"], [1,"Participants"], [1,"Agenda"], [2,"Topic"],
        [1,"Decisions"], [1,"Action items"], [2,"[ ] Next action"]
    ]},
    {name: "Daily review", title: "Daily review", items: [
        [1,"Today's focus"], [2,"[ ] Most important outcome"], [1,"Notes and discoveries"],
        [1,"What went well?"], [1,"What could improve?"], [1,"Tomorrow's first step"], [2,"[ ] Start here"]
    ]},
    {name: "Project plan", title: "Project plan", items: [
        [1,"Goal"], [1,"Success criteria"], [1,"Milestones"], [2,"[ ] First milestone"],
        [1,"Resources"], [1,"Risks and open questions"], [1,"Next actions"], [2,"[ ] First small step"]
    ]}
];
function normalize(value) {
    if (!Array.isArray(value) || value.length > 50) throw new Error("Invalid templates");
    return value.map(function(t,index) {
        if (!t || typeof t.name !== "string" || !t.name.trim() || t.name.length > 200 || typeof t.title !== "string" || !t.title.trim() || t.title.length > 200 || !Array.isArray(t.items) || t.items.length > 500) throw new Error("Invalid templates");
        var previous=0;
        t.items.forEach(function(item) {
            if (!Array.isArray(item) || item.length !== 2 || !Number.isInteger(item[0]) || item[0] < 1 || item[0] > previous+1 || typeof item[1] !== "string" || item[1].length > 2000 || /[\r\n]/.test(item[1])) throw new Error("Invalid templates");
            previous=item[0];
        });
        return JSON.parse(JSON.stringify(t));
    });
}
function toText(template) { return template.items.map(function(item) { return "  ".repeat(item[0]-1)+item[1]; }).join("\n"); }
function fromText(name, text) {
    var lines=text.replace(/\r\n?/g,"\n").split("\n");
    if (lines.length===1 && !lines[0]) lines=[];
    var items=lines.map(function(line) {
        var prefix=(/^\s*/.exec(line)||[""])[0];
        var spaces=prefix.replace(/\t/g,"  ").length;
        if (spaces%2) throw new Error("Use two spaces per indentation level");
        return [1+spaces/2,line.slice(prefix.length)];
    });
    return normalize([{name:name.trim(),title:name.trim(),items:items}])[0];
}
