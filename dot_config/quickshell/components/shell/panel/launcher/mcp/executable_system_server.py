#!/usr/bin/env python3
import sys
import json
import subprocess
import os

# Configuration
ALLOWED_COMMANDS = {
    "whoami": ["whoami"],
    "date": ["date"],
    "uptime": ["uptime", "-p"],
}

def send_response(request_id, result=None, error=None):
    response = {
        "jsonrpc": "2.0",
        "id": request_id
    }
    if error:
        response["error"] = error
    else:
        response["result"] = result
    
    sys.stdout.write(json.dumps(response) + "\n")
    sys.stdout.flush()

def handle_list_tools():
    return [
        {
            "name": "notify",
            "description": "Send a system notification",
            "parameters": {
                "type": "object",
                "properties": {
                    "title": {"type": "string"},
                    "message": {"type": "string"}
                },
                "required": ["message"]
            }
        },
        {
            "name": "run_command",
            "description": "Run a safe system command",
            "parameters": {
                "type": "object",
                "properties": {
                    "command": {
                        "type": "string",
                        "enum": list(ALLOWED_COMMANDS.keys())
                    }
                },
                "required": ["command"]
            }
        },
        {
            "name": "open_url",
            "description": "Open a URL in the default browser",
            "parameters": {
                "type": "object",
                "properties": {
                    "url": {"type": "string"}
                },
                "required": ["url"]
            }
        }
    ]

def handle_call_tool(name, arguments):
    if name == "notify":
        title = arguments.get("title", "Quickshell")
        message = arguments.get("message", "")
        subprocess.run(["notify-send", title, message])
        return "Notification sent"
    
    elif name == "run_command":
        cmd_key = arguments.get("command")
        if cmd_key in ALLOWED_COMMANDS:
            cmd = ALLOWED_COMMANDS[cmd_key]
            result = subprocess.run(cmd, capture_output=True, text=True)
            return result.stdout.strip()
        else:
            raise ValueError(f"Command '{cmd_key}' is not allowed")
            
    elif name == "open_url":
        url = arguments.get("url")
        if url:
            subprocess.run(["xdg-open", url])
            return f"Opened {url}"
        return "No URL provided"
    
    else:
        raise ValueError(f"Unknown tool: {name}")

def main():
    while True:
        try:
            line = sys.stdin.readline()
            if not line:
                break
            
            request = json.loads(line)
            req_id = request.get("id")
            method = request.get("method")
            params = request.get("params", {})
            
            try:
                if method == "tools/list":
                    result = {"tools": handle_list_tools()}
                    send_response(req_id, result)
                    
                elif method == "tools/call":
                    name = params.get("name")
                    args = params.get("arguments", {})
                    result = {"content": [{"type": "text", "text": handle_call_tool(name, args)}]}
                    send_response(req_id, result)
                    
                elif method == "ping":
                    send_response(req_id, "pong")
                    
                else:
                    # Ignore other MCP methods for this simple demo
                    pass
                    
            except Exception as e:
                send_response(req_id, error={"code": -32000, "message": str(e)})
                
        except json.JSONDecodeError:
            continue
        except Exception as e:
            sys.stderr.write(f"Critical error: {e}\n")
            sys.stderr.flush()

if __name__ == "__main__":
    main()
