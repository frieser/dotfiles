import QtQuick
import Quickshell
import Quickshell.Io
import "../../../config"

Item {
    id: root

    // Property to store the target output name found from workspaces
    property string targetOutputName: ""
    property string bufferWorkspaces: ""
    property string bufferOutputs: ""

    IpcHandler {
        target: "ui.window.pip"

        function enable() {
            // Start the chain: Get workspaces -> Find Output -> Get Output Dims -> Apply
            bufferWorkspaces = "";
            getWorkspacesProcess.running = true;
        }

        function toggle() {
            enable();
        }

        function disable() {
            disablePipProcess.running = true;
        }
    }

    Process {
        id: disablePipProcess
        command: ["niri", "msg", "action", "move-window-to-tiling"]
    }

    // Step 1: Get Workspaces to find focused output
    Process {
        id: getWorkspacesProcess
        command: ["niri", "msg", "-j", "workspaces"]
        
        stdout: SplitParser {
            onRead: data => root.bufferWorkspaces += data
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                console.error("PipMode: Failed to get workspaces");
                return;
            }
            try {
                var workspaces = JSON.parse(root.bufferWorkspaces);
                var focused = workspaces.find(w => w.is_focused);
                if (focused && focused.output) {
                    root.targetOutputName = focused.output;
                    root.bufferOutputs = "";
                    getOutputsProcess.running = true;
                } else {
                    console.error("PipMode: No focused workspace or output found");
                }
            } catch (e) {
                console.error("PipMode: Error parsing workspaces JSON", e);
            }
        }
    }

    // Step 2: Get Outputs to determine screen dimensions
    Process {
        id: getOutputsProcess
        command: ["niri", "msg", "-j", "outputs"]

        stdout: SplitParser {
            onRead: data => root.bufferOutputs += data
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                console.error("PipMode: Failed to get outputs");
                return;
            }
            try {
                var outputs = JSON.parse(root.bufferOutputs);
                var target = outputs[root.targetOutputName];
                
                if (!target) {
                    console.error("PipMode: Target output not found in outputs list");
                    return;
                }

                // Determine dimensions
                var width = 0;
                var height = 0;

                if (target.logical) {
                    width = target.logical.width;
                    height = target.logical.height;
                } else if (target.modes && target.modes.length > 0) {
                    // Fallback to modes
                    var mode = target.modes.find(m => m.is_preferred) || target.modes[0];
                    if (target.current_mode !== null && typeof target.current_mode === 'number') {
                         // If current_mode is an index
                         if (target.modes[target.current_mode]) {
                             mode = target.modes[target.current_mode];
                         }
                    }
                    width = mode.width;
                    height = mode.height;
                }

                if (width > 0 && height > 0) {
                    applySmartPip(width, height);
                } else {
                    console.error("PipMode: Could not determine valid screen dimensions");
                }
            } catch (e) {
                console.error("PipMode: Error parsing outputs JSON", e);
            }
        }
    }

    // Step 3: Apply PIP Logic
    function applySmartPip(screenW, screenH) {
        // Requirement: "calcular el cuarto que sea el alto" (Height driven)
        // Height = 1/4 of Screen Height
        var targetH = screenH * 0.25;
        
        // Requirement: "ancho proporcional al alto para que este en 16:9"
        // Width = Height * (16/9)
        var targetW = targetH * (16.0 / 9.0);
        
        // Position: Bottom Right (Flush / Pegado)
        // Taking into account screenBorderSize from Config
        // Adjusted per user feedback: "todavia un poco mas arriba"
        // We increase the vertical offset significantly to ensure the window sits ABOVE the screen border.
        
        var borderThickness = Config.screenBorderSize;
        if (borderThickness === undefined) {
             borderThickness = 4; // Default fallback
        }
        
        // Extra offset to clear the border completely (4px right margin, +24px bottom safety)
        var extraOffsetX = 4;
        var extraOffsetY = 24;
        
        var targetX = screenW - targetW - borderThickness - extraOffsetX;
        var targetY = screenH - targetH - borderThickness - extraOffsetY;

        console.log("PipMode: Applying PIP. Screen:", screenW, "x", screenH, 
                    "Target:", Math.floor(targetW), "x", Math.floor(targetH), 
                    "Border:", borderThickness, "OffsetX:", extraOffsetX, "OffsetY:", extraOffsetY,
                    "at", Math.floor(targetX), ",", Math.floor(targetY));

        // Construct command chain
        // Note: Using 'Math.floor' ensures integer values
        var w = Math.floor(targetW);
        var h = Math.floor(targetH);
        var x = Math.floor(targetX);
        var y = Math.floor(targetY);

        var cmds = [
            "niri msg action move-window-to-floating",
            "niri msg action set-window-width " + w,
            "niri msg action set-window-height " + h,
            "niri msg action move-floating-window --x -10000 --y -10000", 
            "niri msg action move-floating-window --x " + x + " --y " + y
        ];

        applyProcess.command = ["sh", "-c", cmds.join(" && ")];
        applyProcess.running = true;
    }

    Process {
        id: applyProcess
        onExited: exitCode => {
            if (exitCode === 0) {
                console.log("PipMode: Successfully applied smart PIP");
            } else {
                console.error("PipMode: Failed to apply PIP actions");
            }
        }
    }
}
