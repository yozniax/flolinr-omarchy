.pragma library
var providers = ["codex", "claude", "openai", "anthropic", "ollama", "compatible", "custom"];
var labels = ["Codex CLI", "Claude Code CLI", "OpenAI API", "Anthropic API", "Ollama", "OpenAI-compatible API", "Custom CLI"];
function defaults(provider, id) {
    return {id: id, name: labels[providers.indexOf(provider)] || provider, provider: provider,
        model: "", baseUrl: provider === "ollama" ? "http://localhost:11434" : "",
        executable: "", command: []};
}
function validate(value) {
    var connections = value.aiConnections || [];
    if (!Array.isArray(connections) || connections.length > 50) throw new Error("Invalid AI connections");
    var ids = {};
    connections = connections.map(function(p) {
        if (!p || providers.indexOf(p.provider) < 0 || typeof p.id !== "string" || !/^[a-zA-Z0-9_-]{1,80}$/.test(p.id) || ids[p.id]) throw new Error("Invalid or duplicate AI connection");
        ids[p.id] = true;
        var result = defaults(p.provider, p.id);
        ["name", "model", "baseUrl", "executable"].forEach(function(k) {
            if (p[k] !== undefined && typeof p[k] !== "string") throw new Error("Invalid connection " + k);
            result[k] = (p[k] === undefined ? result[k] : p[k]).trim();
        });
        if (!result.name) throw new Error("Enter a connection name");
        result.command = p.command || [];
        if (!Array.isArray(result.command) || !result.command.every(function(s) { return typeof s === "string"; })) throw new Error("CLI command must be a JSON argument array");
        if (p.provider === "custom" && !result.command.length) throw new Error("Enter a custom CLI command");
        if (["openai", "anthropic", "ollama", "compatible"].indexOf(p.provider) >= 0 && !result.model) throw new Error("Enter a model ID");
        if (["ollama", "compatible"].indexOf(p.provider) >= 0 && !/^https?:\/\//.test(result.baseUrl)) throw new Error("Enter an HTTP(S) base URL");
        if (["ollama", "compatible"].indexOf(p.provider) >= 0) {
            var url = /^(https?):\/\/([^/]+)(?:\/[^?#]*)?$/.exec(result.baseUrl);
            if (!url || url[2].indexOf("@") >= 0) throw new Error("Use a base URL without credentials, query or fragment");
            if (url[1] === "http" && !/^(localhost|127(?:\.[0-9]{1,3}){3}|\[::1\])(?::[0-9]+)?$/.test(url[2])) throw new Error("Remote servers require HTTPS");
        }
        return result;
    });
    var active = value.activeAiConnectionId || "";
    if (typeof active !== "string" || (active && !ids[active])) throw new Error("Choose an existing AI connection");
    return {aiConnections: connections, activeAiConnectionId: active};
}
function migrate(value) {
    if (value.aiConnections !== undefined) return validate(value);
    if (Array.isArray(value.aiCommand) && value.aiCommand.length) {
        var p = defaults("custom", "legacy-cli"); p.name = "Previous CLI"; p.command = value.aiCommand;
        return validate({aiConnections: [p], activeAiConnectionId: p.id});
    }
    return validate({});
}
function active(connections, id) {
    for (var i = 0; i < connections.length; i++) if (connections[i].id === id) return connections[i];
    return null;
}
