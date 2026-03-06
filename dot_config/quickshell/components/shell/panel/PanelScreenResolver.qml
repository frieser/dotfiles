import QtQuick
import Quickshell
import "../../config"

QtObject {
    id: root

    readonly property string mode: Config.panelsScreen
    readonly property var targetScreens: {
        if (mode === "all") {
            return Quickshell.screens;
        }

        if (mode === "active" || mode === "") {
            return Quickshell.screens.length > 0 ? [Quickshell.screens[0]] : [];
        }

        for (let i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === mode) {
                return [Quickshell.screens[i]];
            }
        }

        return Quickshell.screens.length > 0 ? [Quickshell.screens[0]] : [];
    }
}
