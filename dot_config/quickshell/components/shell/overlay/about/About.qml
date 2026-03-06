import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../ui/shell"
import "../../../config"

OverlayWindow {
    id: root
    active: false
    windowWidth: 900
    windowHeight: 520

    // Properties
    property string sysHostname: "..."
    property string sysOs: "..."
    property string sysKernel: "..."
    property string sysUptime: "..."
    property string sysCpu: "..."
    property string sysCores: "..."
    property string sysRam: "..."
    property string sysGpu: "..."
    property string sysDisk: "..."
    property string sysUser: "..."

    // --- SINGLE PROCESS ---
    // Moved to property to avoid default property conflicts and ensure visibility
    property var infoProcess: Process {
        id: infoProcessInternal
        
        // Single command that constructs the JSON directly
        // Escaping hell:
        // QML String -> Shell String -> Command execution
        // We use single quotes for the main shell string to minimize escaping needs
        command: ["/bin/sh", "-c", 
            "export LC_ALL=C; export PATH=$PATH:/usr/sbin:/sbin; " +
            "echo '{'; " +
            "echo '\"hostname\": \"'$(hostname 2>/dev/null)'\",'; " +
            "echo '\"os\": \"'$(grep -m1 PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '\"')'\",'; " +
            "echo '\"kernel\": \"'$(uname -r 2>/dev/null)'\",'; " +
            "echo '\"uptime\": \"'$(uptime -p 2>/dev/null | sed 's/up //')'\",'; " +
            "echo '\"cpu\": \"'$(lscpu 2>/dev/null | grep 'Model name' | cut -d: -f2 | xargs)'\",'; " +
            "echo '\"cores\": \"'$(nproc 2>/dev/null)'\",'; " +
            "echo '\"ram\": \"'$(free -h 2>/dev/null | awk '/Mem:/ {print $3 \" / \" $2}')'\",'; " +
            "echo '\"gpu\": \"'$(lspci 2>/dev/null | grep -i vga | cut -d: -f2 | head -c 40 | xargs)'\",'; " +
            "echo '\"disk\": \"'$(df -h / /var /home 2>/dev/null | sort -h -k 2 | tail -1 | awk '{print $3 \" / \" $2}')'\",'; " +
            "echo '\"user\": \"'$(whoami 2>/dev/null)'\"'; " +
            "echo '}'"
        ]
        
        onRunningChanged: {
            if (running) console.log("About: Running embedded sysinfo command")
        }
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    // console.log("About JSON: " + text) // Debug if needed
                    var data = JSON.parse(text);
                    root.sysHostname = data.hostname;
                    root.sysOs = data.os;
                    root.sysKernel = data.kernel;
                    root.sysUptime = data.uptime;
                    root.sysCpu = data.cpu;
                    root.sysCores = data.cores;
                    root.sysRam = data.ram;
                    root.sysGpu = data.gpu;
                    root.sysDisk = data.disk;
                    root.sysUser = data.user;
                } catch(e) {
                    console.error("About.qml: Failed to parse sysinfo JSON", e);
                    root.sysHostname = "Error";
                }
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    console.error("About.qml sysinfo error: " + text)
                }
            }
        }
    }

    // Trigger on open
    onActiveChanged: {
        if (active) {
            root.sysHostname = "Loading...";
            if (infoProcess) {
                infoProcess.running = false;
                infoProcess.running = true;
            }
        }
    }

    // UI
    view: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 20

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "󰋽"
            font.family: Config.iconFontFamily
            font.pixelSize: 48
            color: Config.accent
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.sysHostname
            font.family: Config.fontFamily
            font.pixelSize: 24
            font.bold: true
            color: Config.foreground
        }

        // DEBUG INFO
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Debug: " + (root.infoProcess ? root.infoProcess.command[0] : "Init...")
            font.pixelSize: 10
            color: Config.red
            visible: root.sysHostname === "Loading..." || root.sysHostname === "Error" || root.sysHostname === "..."
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.alpha(Config.foreground, 0.1)
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            rowSpacing: 12
            columnSpacing: 20

            InfoRow { icon: "󰣇"; label: "OS"; value: root.sysOs }
            InfoRow { icon: ""; label: "Kernel"; value: root.sysKernel }
            InfoRow { icon: "󰍛"; label: "CPU"; value: root.sysCpu }
            InfoRow { icon: "󰘚"; label: "Cores"; value: root.sysCores }
            InfoRow { icon: "󰑭"; label: "RAM"; value: root.sysRam }
            InfoRow { icon: "󰋩"; label: "GPU"; value: root.sysGpu }
            InfoRow { icon: "󰋊"; label: "Disk"; value: root.sysDisk }
            InfoRow { icon: "󰅐"; label: "Uptime"; value: root.sysUptime }
            InfoRow { icon: "󰖲"; label: "DE"; value: "Niri + Quickshell" }
            InfoRow { icon: "󰀄"; label: "User"; value: root.sysUser }
        }
    }

    component InfoRow: RowLayout {
        property string icon: ""
        property string label: ""
        property string value: ""

        Layout.fillWidth: true
        spacing: 10

        Text {
            text: icon
            font.family: Config.iconFontFamily
            font.pixelSize: 16
            color: Config.accent
            Layout.preferredWidth: 24
        }

        Text {
            text: label
            font.family: Config.fontFamily
            font.pixelSize: 13
            color: Config.dimmed
            Layout.preferredWidth: 60
        }

        Text {
            text: value
            font.family: Config.fontFamily
            font.pixelSize: 13
            color: Config.foreground
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }
}
