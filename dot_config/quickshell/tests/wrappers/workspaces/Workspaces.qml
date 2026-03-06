import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../base"
import ".."

Panel {
    id: root

    position: "left"

    // Niri object passed from shell.qml
    required property var niri

    property bool showByChange: false

    preventAutoHide: showByChange

    onShowByChangeChanged: {
        if (showByChange) {
            root.revealed = true
        } else {
            if (!root.isHovered) {
                root.revealed = false
            }
        }
    }

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
            // Use the real Niri workspaces model
            model: root.niri.workspaces

            Rectangle {
                id: workspaceItem
                // Niri model properties: id, name, idx, isActive, isFocused, etc.
                property bool isActive: modelData.isActive
                property var workspaceId: modelData.id
                property bool hasName: model.name && model.name.length > 0 && isNaN(model.name)
                property bool hovered: mouseArea.containsMouse

                // Trigger to show OSD when this workspace becomes active
                onIsActiveChanged: {
                    if (isActive) {
                        root.showByChange = true;
                        hideTimer.restart();
                        if (hasName && !hovered) nameTooltip.open();
                    } else {
                        // Close tooltip immediately when leaving this workspace
                        nameTooltip.close();
                    }
                }

                onHoveredChanged: {
                    if (hovered) nameTooltip.close();
                }

                ToolTip {
                    id: nameTooltip
                    visible: false
                    timeout: 1200 // Reduced from 2000 for snappier feel
                    
                    // Overlay exactly on top of the item
                    x: 0
                    y: 0
                    
                    // Remove padding to match the underlying rectangle size exactly
                    padding: 0
                    topPadding: 0
                    bottomPadding: 0
                    leftPadding: 0
                    rightPadding: 0
                    
                    // Match height
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
                    
                    // Animate width from 24px (collapsed) to full size
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

                width: (hovered && hasName) ? (nameMetrics.width + 16) : 24
                height: 24
                radius: Config.itemRadius // Unified with volume bar (4px)

                Behavior on width {
                    NumberAnimation {
                        duration: Config.animationDuration
                        easing.type: Easing.OutCubic
                    }
                }

                // Background: Config.foreground if active, very dimmed otherwise (placeholder)
                color: isActive ? Config.foreground : Qt.alpha(Config.foreground, 0.08)

                Text {
                    anchors.centerIn: parent
                    text: parent.hasName ? (parent.hovered ? model.name : model.name.charAt(0).toUpperCase()) : ""
                    color: isActive ? Config.background : Config.foreground
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    opacity: isActive ? 0.9 : 0.4
                    
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

                // Click to change workspace
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.niri.focusWorkspaceById(parent.workspaceId)
                }
            }
        }
    }
}
