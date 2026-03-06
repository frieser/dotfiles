import QtQuick
import Quickshell

Item {
    id: root

    property alias model: clipboardModel
    property var clipboardEntries: []    // Array of {content: string, timestamp: Date}
    property int maxHistory: 100
    property string lastClipboard: ""

    signal clipboardItemSelected(string content)

    ListModel { id: clipboardModel }

    // Poll clipboard every second
    Timer {
        id: clipboardWatcher
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            var current = Quickshell.clipboardText;
            if (current && current.length > 0 && current !== root.lastClipboard) {
                root.lastClipboard = current;
                root.addEntry(current);
            }
        }
    }

    function addEntry(content) {
        // Remove duplicate if exists
        var entries = root.clipboardEntries.slice();
        for (var i = entries.length - 1; i >= 0; i--) {
            if (entries[i].content === content) {
                entries.splice(i, 1);
            }
        }

        // Add to front
        entries.unshift({ "content": content });

        // Trim to max
        if (entries.length > root.maxHistory) {
            entries = entries.slice(0, root.maxHistory);
        }

        root.clipboardEntries = entries;
    }

    function truncateContent(content) {
        if (!content) return "";
        // Replace newlines with spaces for display
        var clean = content.replace(/\n/g, " ").replace(/\s+/g, " ").trim();
        return clean.length > 80 ? clean.substring(0, 80) + "..." : clean;
    }

    function load() {
        filter("");
    }

    function filter(text) {
        clipboardModel.clear();
        var searchLower = text.toLowerCase();

        for (var i = 0; i < clipboardEntries.length; i++) {
            var entry = clipboardEntries[i];
            if (searchLower === "" || entry.content.toLowerCase().indexOf(searchLower) !== -1) {
                clipboardModel.append({
                    "name": truncateContent(entry.content),
                    "icon": "󰅍",
                    "desc": entry.content.length + " characters",
                    "action": "clip:" + i,
                    "identifier": i.toString(),
                    "provider": "clipboard"
                });
            }
        }

        // Show empty state if no entries
        if (clipboardModel.count === 0 && searchLower === "") {
            clipboardModel.append({
                "name": "No clipboard history yet",
                "icon": "󰅍",
                "desc": "Copy something to start tracking",
                "action": "error",
                "identifier": "empty",
                "provider": "clipboard"
            });
        }
    }

    function activate(item) {
        if (!item || item.action === "error") return true;
        
        var idx = parseInt(item.identifier);
        if (idx >= 0 && idx < clipboardEntries.length) {
            var content = clipboardEntries[idx].content;
            Quickshell.clipboardText = content;
            root.lastClipboard = content;  // Prevent re-adding from watcher
            root.clipboardItemSelected(content);
        }
        return true;
    }

    function goBack() {
        return false;
    }

    Component.onCompleted: {
        // Capture current clipboard as first entry
        var current = Quickshell.clipboardText;
        if (current && current.length > 0) {
            root.lastClipboard = current;
            addEntry(current);
        }
    }
}
