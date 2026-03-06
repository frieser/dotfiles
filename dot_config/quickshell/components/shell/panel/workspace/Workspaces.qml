import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../ui/panel"
import "../../../config"

Panel {
    id: root

    position: "left"

    // Niri object passed from shell.qml
    required property var niri

    property bool showByChange: false
    // Track which workspace is currently being renamed (by ID)
    property var renamingWorkspaceId: null
    property bool isRenaming: renamingWorkspaceId !== null

    OverviewManager {
        id: overviewManager
        onIsOverviewOpenChanged: {
            if (isOverviewOpen) {
                root.revealed = true
            } else {
                if (!root.isHovered && !isRenaming && !showByChange) {
                    root.revealed = false
                }
            }
        }
    }

    // Prevent auto-hide when renaming or when shown by workspace change or in overview
    preventAutoHide: showByChange || isRenaming || overviewManager.isOverviewOpen
    
    // Request exclusive keyboard focus when renaming so typing works
    wantsFocus: isRenaming

    onShowByChangeChanged: {
        if (showByChange) {
            root.revealed = true
        } else {
            if (!root.isHovered && !isRenaming && !overviewManager.isOverviewOpen) {
                root.revealed = false
            }
        }
    }

    // Reset renaming state when panel hides
    onRevealedChanged: {
        if (!revealed) {
            renamingWorkspaceId = null
        }
    }

    IpcHandler {
        target: "ui.panel.workspaces"
        function rename() {
            // Iterate visible items to find the active one
            for (var i = 0; i < repeater.count; i++) {
                var item = repeater.itemAt(i);
                if (item && item.isActive) {
                    root.renamingWorkspaceId = item.workspaceId;
                    root.revealed = true;
                    // No need to force focus here manually, the Popup's onVisibleChanged handles it
                    Qt.callLater(() => {
                        item.forceRenameFocus();
                    });
                    return;
                }
            }
        }
        
        function clearName() {
            console.log("IPC clearName called")
            clearNameProc.running = true
        }
    }
    
    Process {
        id: clearNameProc
        command: ["niri", "msg", "action", "unset-workspace-name"]
        
        onExited: (code) => {
             console.log("Clear name process exited: " + code)
        }
    }
    Process {
        id: renameProc
        property string newName: ""
        // If newName is empty string, we pass it as a single empty argument
        // If we want to unset, niri action set-workspace-name "" works.
        // QProcess handling of empty strings in arrays can be tricky.
        // Let's use 'sh -c' to be absolutely sure the empty string argument is passed correctly.
        command: ["sh", "-c", "niri msg action set-workspace-name \"" + newName + "\""]
        
        onExited: (code) => {
            if (code === 0) {
                root.renamingWorkspaceId = null
            }
        }
    }

    // Process to execute the rename command

    property real verticalPadding: Config.padding
    property real horizontalPadding: Config.padding - 2

    contentWidth: workspacesLayout.implicitWidth + horizontalPadding * 2
    contentHeight: workspacesLayout.implicitHeight + verticalPadding * 2
    contentPadding: 0

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.showByChange = false
    }

    ColumnLayout {
        id: workspacesLayout
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: root.horizontalPadding
        Layout.topMargin: root.verticalPadding
        Layout.bottomMargin: root.verticalPadding
        spacing: Config.spacing

        Repeater {
            id: repeater
            // Use the real Niri workspaces model
            model: root.niri.workspaces

            Rectangle {
                id: workspaceItem
                // Niri model properties: id, name, idx, isActive, isFocused, etc.
                property bool isActive: model.isActive
                property var workspaceId: model.id
                property bool hasName: model.name && model.name.length > 0 && isNaN(model.name)
                property bool hovered: mouseArea.containsMouse
                property bool isBeingRenamed: root.renamingWorkspaceId === workspaceId
                
                // function forceRenameFocus() removed as logic is now in Popup

                // Trigger to show OSD when this workspace becomes active
                onIsActiveChanged: {
                    if (isActive) {
                        root.showByChange = true;
                        hideTimer.restart();
                        if (hasName && !hovered && !isBeingRenamed) nameTooltip.open();
                    } else {
                        // Close tooltip immediately when leaving this workspace
                        nameTooltip.close();
                        // Cancel rename if we switch away
                        if (isBeingRenamed) root.renamingWorkspaceId = null;
                    }
                }

                onHoveredChanged: {
                    if (hovered) nameTooltip.close();
                }

                ToolTip {
                    id: nameTooltip
                    visible: overviewManager.isOverviewOpen && isActive && hasName && !isBeingRenamed
                    timeout: overviewManager.isOverviewOpen ? -1 : 1200 
                    x: 0
                    y: 0
                    padding: 0
                    topPadding: 0
                    bottomPadding: 0
                    leftPadding: 0
                    rightPadding: 0
                    height: 24
                    
                    contentItem: Item {
                        Text {
                            anchors.centerIn: parent
                            text: model.name || ""
                            color: Config.background
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                    
                    background: Rectangle {
                        color: Config.foreground
                        radius: Config.itemRadius
                    }
                    
                    width: nameMetrics.width + 16
                    enter: Transition {
                        NumberAnimation {
                            property: "width"
                            from: 24
                            duration: Config.animationDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Layout.alignment: Qt.AlignLeft
                
                TextMetrics {
                    id: nameMetrics
                    text: model.name || ""
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                }
                
                TextMetrics {
                    id: inputMetrics
                    text: nameInput.text || ""
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                }

                // Layout properties to keep the panel width constant
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                z: isBeingRenamed ? 99 : 0 // Bring to front when renaming

                // Visual width: expands when renaming without affecting layout
                width: isBeingRenamed ? Math.max(60, inputMetrics.width + 24) : 24
                height: 24
                radius: Config.itemRadius

                Behavior on width {
                    NumberAnimation {
                        duration: Config.animationDuration
                        easing.type: Easing.OutCubic
                    }
                }

                // Renaming Input Field (Inside the item)
                TextInput {
                    id: nameInput
                    anchors.centerIn: parent
                    width: parent.width - 10
                    visible: parent.isBeingRenamed
                    
                    text: model.name || ""
                    color: Config.background
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    
                    selectByMouse: true
                    selectionColor: Qt.alpha(Config.background, 0.3)
                    selectedTextColor: Config.background
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    clip: true
                    
                    focus: true
                    
                    onAccepted: {
                        renameProc.newName = text
                        renameProc.running = true
                        root.renamingWorkspaceId = null
                    }
                    
                    Keys.onEscapePressed: {
                        root.renamingWorkspaceId = null
                    }
                    
                    // Aggressive focus grabbing
                    Timer {
                        interval: 50
                        running: parent.visible && !nameInput.activeFocus
                        repeat: true
                        onTriggered: {
                            nameInput.forceActiveFocus()
                            nameInput.selectAll()
                        }
                    }
                }
                
                function forceRenameFocus() {
                    nameInput.forceActiveFocus()
                    nameInput.selectAll()
                }

                // Background: 
                // - Renaming: Accent
                // - Active: Foreground
                // - Inactive: Dimmed
                color: isBeingRenamed ? Config.accent :
                       isActive ? Config.foreground : Qt.alpha(Config.foreground, 0.1)

                // Normal Text Label (Single Letter)
                Text {
                    anchors.centerIn: parent
                    text: parent.hasName ? (parent.hovered ? "" : model.name.charAt(0).toUpperCase()) : ""
                    color: isActive ? Config.background : Config.foreground
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    opacity: isActive ? 0.9 : 0.4
                    visible: !parent.isBeingRenamed
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: Config.animationDuration
                        }
                    }
                }

                // Smooth color animation
                Behavior on color {
                    ColorAnimation {
                        duration: Config.animationDuration
                    }
                }

                // Click to change workspace (disabled when renaming)
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !parent.isBeingRenamed
                    onClicked: root.niri.focusWorkspaceById(parent.workspaceId)
                }
            }
        }
    }
}
