import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Path to the python script
    property string scriptPath: "" 
    property var pendingRequests: ({})
    property int nextId: 1
    property bool ready: false
    property var availableTools: []

    signal toolResult(int id, var result, var error)
    signal toolsLoaded(var tools)

    Process {
        id: proc
        // Assume python3 is in path. Adjust if needed.
        command: ["python3", root.scriptPath]
        running: root.scriptPath !== ""
        
        property string buffer: ""

        onStdout: (data) => {
            buffer += data;
            var newlineIdx = buffer.indexOf("\n");
            while (newlineIdx !== -1) {
                var line = buffer.substring(0, newlineIdx);
                buffer = buffer.substring(newlineIdx + 1);
                root.handleMessage(line);
                newlineIdx = buffer.indexOf("\n");
            }
        }
        
        onStderr: (data) => console.error("MCP Server Error:", data)
        
        onExited: (code) => console.log("MCP Server exited with code:", code)
    }

    function handleMessage(line) {
        if (!line.trim()) return;
        try {
            var msg = JSON.parse(line);
            if (msg.id !== undefined) {
                if (root.pendingRequests[msg.id]) {
                    var cb = root.pendingRequests[msg.id];
                    delete root.pendingRequests[msg.id];
                    if (cb) cb(msg.result, msg.error);
                }
            }
        } catch (e) {
            console.error("MCP Client JSON Error:", e, "Line:", line);
        }
    }

    function sendRequest(method, params, callback) {
        var id = root.nextId++;
        if (callback) root.pendingRequests[id] = callback;
        
        var req = {
            jsonrpc: "2.0",
            id: id,
            method: method,
            params: params || {}
        };
        
        if (proc.running) {
            proc.write(JSON.stringify(req) + "\n");
        } else {
            console.error("MCP Server not running");
            if (callback) callback(null, {message: "Server not running"});
        }
    }

    function listTools() {
        sendRequest("tools/list", {}, function(result, error) {
            if (!error && result.tools) {
                root.availableTools = result.tools;
                root.toolsLoaded(result.tools);
                console.log("MCP Tools loaded:", result.tools.length);
            } else {
                console.error("Failed to list tools:", error ? error.message : "Unknown error");
            }
        });
    }

    function callTool(name, args, callback) {
        sendRequest("tools/call", {
            name: name,
            arguments: args
        }, callback);
    }

    Component.onCompleted: {
        // Resolve script path relative to this file
        // Qt.resolvedUrl returns file:///... we need /...
        var url = Qt.resolvedUrl("system_server.py");
        if (url.startsWith("file://")) {
            root.scriptPath = url.substring(7);
        } else {
            root.scriptPath = url;
        }
        
        // Wait a bit for process to start then list tools
        Qt.callLater(function() {
            if (proc.running) listTools();
        });
    }
}
