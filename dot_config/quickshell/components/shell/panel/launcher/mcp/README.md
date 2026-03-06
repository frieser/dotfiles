# MCP System Integration for Quickshell Launcher

## Overview
This design enables the Quickshell Launcher Chat to execute local system actions (notifications, volume control, app launching) by integrating a standard Model Context Protocol (MCP) server via `stdio`.

## Architecture

```
[ LLM (OpenCode) ]  <-- HTTP -->  [ ChatProvider.qml ]  <-- QProcess (stdio) -->  [ system_server.py ]
       ^                                  |                                             |
       |                                  |                                             |
   Decides to                        Orchestrates                               Executes
   call tool                         flow                                       Command
```

## Components

1.  **`system_server.py`** (Created)
    *   A lightweight Python script implementing the MCP protocol.
    *   Exposes tools: `notify`, `run_command`, `open_url`.
    *   **Security**: Uses an allowlist for commands (`ALLOWED_COMMANDS`) to prevent arbitrary code execution.

2.  **`McpClient.qml`** (Created)
    *   Wraps `Quickshell.Io.Process`.
    *   Handles JSON-RPC 2.0 communication over stdin/stdout.
    *   Provides signals: `toolsLoaded`, `toolResult`.
    *   Methods: `listTools()`, `callTool()`.

3.  **`ChatProvider.qml` Integration** (Proposed)
    *   Needs to act as the "MCP Host".
    *   Injects available tools into the LLM context.
    *   Intercepts tool calls from the LLM, forwards them to `McpClient`, and returns the output to the LLM.

## How to Integrate

### 1. Import the Client
In `ChatProvider.qml`:
```qml
import "./mcp" // Adjust path to where you placed McpClient.qml
```

### 2. Instantiate the Client
Inside `Item { id: root ... }`:
```qml
    McpClient {
        id: mcp
        onToolsLoaded: (tools) => {
            console.log("System tools ready:", tools.length)
            // Optional: Update a property to show "Tools Active" in UI
        }
        onToolResult: (id, result, error) => {
            // Handle the result of a tool execution
            // You typically send this back to the LLM as a new message
            // role: "tool", content: result
        }
    }
```

### 3. Inject Tools into Conversation
When sending a message (or creating a session), include the tool definitions. Since OpenCode's API might vary, the most robust way is adding them to the System Prompt or the first User Message:

```javascript
// Function to format tools for the LLM
function getSystemPromptWithTools() {
    var toolDesc = JSON.stringify(mcp.availableTools);
    return "You are a helpful assistant. You have access to the following tools on the user's system:\n" +
           toolDesc + "\n" +
           "To use a tool, respond ONLY with a JSON object: {\"tool\": \"name\", \"args\": {...}}";
}
```

### 4. Handle Tool Calls
In `handleMessagePart` or `handleMessageUpdate` (where you parse the AI response):

```javascript
// Pseudo-code for handling response
if (responseIsJsonToolCall(content)) {
    var call = JSON.parse(content);
    mcp.callTool(call.tool, call.args, function(result, error) {
        // Send result back to LLM automatically
        sendMessage("Tool output: " + (result || error.message));
    });
}
```

## Security Considerations
*   **Whitelisting**: The `system_server.py` strictly limits what commands can be run. Do not expose `os.system` or `subprocess.run` with arbitrary user input.
*   **Confirmation**: For sensitive actions (like "shut down"), you might want to add a UI popup in QML asking the user to confirm the action before calling `mcp.callTool`.
