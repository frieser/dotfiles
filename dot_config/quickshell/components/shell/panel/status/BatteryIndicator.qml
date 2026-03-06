import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../../../ui/indicators" // BaseIndicator
import "../../../config"
import "../../../ui/panel"

BaseIndicator {
    id: root

    property int percentage: 0
    property bool charging: false

    // Power profile support (optional - only if PowerProfiles module is available)
    property bool powerProfilesAvailable: typeof PowerProfiles !== "undefined"
    property int powerProfile: powerProfilesAvailable ? PowerProfiles.profile : 0

    // Signal emitted when power state changes
    signal powerStateChanged()

    // Track previous state to detect changes
    property int previousState: UPower.displayDevice ? UPower.displayDevice.state : 0

    // Initialize and update battery state
    Component.onCompleted: updateBatteryState()

    function updateBatteryState() {
        if (!UPower.displayDevice) return;
        
        var newPercentage = Math.round(UPower.displayDevice.percentage * 100);
        var newCharging = UPower.displayDevice.state === UPowerDeviceState.Charging;
        
        console.log("Updating battery state - Percentage:", newPercentage, "Charging:", newCharging, "State:", UPower.displayDevice.state);
        
        root.percentage = newPercentage;
        root.charging = newCharging;
    }

    // Watch for state changes
    Connections {
        target: UPower.displayDevice
        function onStateChanged() {
            var currentState = UPower.displayDevice.state;
            console.log("Battery state changed from", root.previousState, "to", currentState);
            
            root.updateBatteryState();
            
            if (currentState !== root.previousState) {
                root.powerStateChanged();
                root.previousState = currentState;
            }
        }
        
        function onPercentageChanged() {
            if (UPower.displayDevice) {
                root.percentage = Math.round(UPower.displayDevice.percentage * 100);
            }
        }
    }

    // Monitor for suspend/resume events via UPower OnBattery changes
    Connections {
        target: UPower
        function onOnBatteryChanged() {
            console.log("Power source changed - OnBattery:", UPower.onBattery);
            root.updateBatteryState();
            root.powerStateChanged();
        }
    }

    function getBatteryColor() {
        if (root.percentage <= 10)
            return Config.statusCritical;
        if (root.percentage <= 20)
            return Config.statusWarning;
        if (root.percentage <= 50)
            return Config.statusMedium;
        return Config.accent;
    }

    function getBatteryIcon() {
        var p = root.percentage / 100.0;
        if (root.charging) {
            // Charging icons by level
            if (p <= 0.1) return "󰢜";
            if (p <= 0.2) return "󰂆";
            if (p <= 0.3) return "󰂇";
            if (p <= 0.4) return "󰂈";
            if (p <= 0.5) return "󰢝";
            if (p <= 0.6) return "󰂉";
            if (p <= 0.7) return "󰢞";
            if (p <= 0.8) return "󰂊";
            if (p <= 0.9) return "󰂋";
            return "󰂅";
        }
        // Discharging icons by level
        if (p <= 0.1) return "󰁺";
        if (p <= 0.2) return "󰁻";
        if (p <= 0.3) return "󰁼";
        if (p <= 0.4) return "󰁽";
        if (p <= 0.5) return "󰁾";
        if (p <= 0.6) return "󰁿";
        if (p <= 0.7) return "󰂀";
        if (p <= 0.8) return "󰂁";
        if (p <= 0.9) return "󰂂";
        return "󰁹";
    }

    // BaseIndicator config
    fillPercentage: root.percentage
    fillColor: root.charging ? Config.accent : getBatteryColor()
    icon: getBatteryIcon()
    iconPixelSize: 18
}
