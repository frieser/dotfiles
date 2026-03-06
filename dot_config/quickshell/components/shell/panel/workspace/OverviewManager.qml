import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property bool isOverviewOpen: false

    Process {
        id: eventStreamProc
        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (!data || data.trim() === "") return;
                try {
                    var event = JSON.parse(data);
                    // Check for OverviewOpenedOrClosed event
                    if (event && event.OverviewOpenedOrClosed) {
                        root.isOverviewOpen = event.OverviewOpenedOrClosed.is_open;
                    }
                } catch (e) {
                    console.log("OverviewManager: Parse error: " + e);
                }
            }
        }
        
        onExited: (code) => {
            console.log("OverviewManager: Event stream exited with code " + code + ". Restarting...");
            restartTimer.start();
        }
    }
    
    Timer {
        id: restartTimer
        interval: 2000
        repeat: false
        onTriggered: eventStreamProc.running = true
    }

    // Initial check
    Process {
        id: initialCheckProc
        command: ["niri", "msg", "--json", "overview-state"]
        running: true
        
        stdout: SplitParser {
            onRead: data => {
                if (!data) return;
                try {
                    var state = JSON.parse(data);
                    if (state && state.is_open !== undefined) {
                        root.isOverviewOpen = state.is_open;
                    }
                } catch (e) {
                    console.log("OverviewManager: Initial check parse error: " + e);
                }
            }
        }
    }
}
