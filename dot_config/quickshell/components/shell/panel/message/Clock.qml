import QtQuick
import QtQuick.Layouts
import "../../../config"

// Clock display component
Item {
    id: root

    property bool forceShown: false
    property bool showDate: false

    function updateTime() {
        let currentTime = new Date();
        timeText.text = Qt.formatDateTime(currentTime, "HH:mm");
        if (root.showDate) {
            dateText.text = Qt.formatDateTime(currentTime, Config.clockDateFormat);
        } else {
            dateText.text = "";
        }
        return currentTime;
    }

    // Clock Timer
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            let currentTime = root.updateTime();
            if (currentTime.getSeconds() === 0 && (currentTime.getMinutes() === 0 || currentTime.getMinutes() === 30)) {
                showBriefly();
            }
        }
    }

    onShowDateChanged: updateTime()

    Timer {
        id: hideTimer
        interval: 5000
        onTriggered: root.forceShown = false
    }

    function showBriefly() {
        root.forceShown = true;
        hideTimer.restart();
    }

    function toggle() {
        root.forceShown = !root.forceShown;
        if (root.forceShown) {
            hideTimer.restart();
        }
    }

    // Initialize clock
    Component.onCompleted: {
        root.updateTime();
    }

    implicitWidth: mainLayout.implicitWidth
    implicitHeight: mainLayout.implicitHeight

    RowLayout {
        id: mainLayout
        spacing: 6

        Text {
            id: timeText
            Layout.alignment: Qt.AlignVCenter
            color: Config.foreground
            font.family: Config.fontFamily
            font.pixelSize: 16
            font.bold: true
        }

        Text {
            id: dateText
            visible: text !== ""
            Layout.alignment: Qt.AlignVCenter
            color: Config.dimmed
            font.family: Config.fontFamily
            font.pixelSize: 11
            font.bold: false
        }
    }
}
