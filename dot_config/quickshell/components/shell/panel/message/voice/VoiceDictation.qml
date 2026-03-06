import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import "../../../../ui/panel"
import "../../../../config"

Item {
    id: root
    
    // --- Configuration ---
    // We are now inside a layout, so explicit size is handled by Layout properties
    implicitHeight: active ? 80 : 0
    implicitWidth: 300 // Will be stretched by parent
    
    Layout.fillWidth: true
    Layout.preferredHeight: active ? 80 : 0
    
    visible: active
    
    // Ensure we animate height when toggling
    Behavior on Layout.preferredHeight {
        NumberAnimation { duration: Config.animationDurationMedium; easing.type: Config.animEasingStandard }
    }
    
    // --- State ---
    property bool active: false
    property string state: "IDLE" // IDLE, RECORDING, PROCESSING, DOWNLOADING, THINKING
    property string statusText: "Ready"
    property string capturedText: ""
    property real downloadProgress: 0.0  // Progress for download animation (0.0 to 1.0)
    
    // Voxtype vs legacy mode
    property bool voxtypeAvailable: false
    property bool useVoxtype: false
    
    // Dependency tracking
    property bool wtypeAvailable: false
    property bool pwRecordAvailable: false
    property bool modelAvailable: false
    property bool dependenciesChecked: false
    readonly property string effectiveModel: {
        var lang = Config.voiceDictation.language || "en"
        if (lang === "en") return "base.en"
        return "base"
    }
    
    // Missing dependencies list for UI
    property var missingDependencies: {
        var missing = [];
        if (dependenciesChecked && state !== "DOWNLOADING") {
            if (useVoxtype && !modelAvailable) {
                missing.push("Voxtype model (will download on record)");
            } else if (!useVoxtype && !modelAvailable) {
                missing.push("Whisper model (~/.local/share/hyprflow/models/whisper-small.llamafile)");
            }
            if (!useVoxtype && !pwRecordAvailable) {
                missing.push("pw-record (pipewire)");
            }
        }
        return missing;
    }
    property bool canOperate: {
        if (!dependenciesChecked) return false;
        if (root.state === "DOWNLOADING") return false;
        if (useVoxtype) return voxtypeAvailable;  // Model will be downloaded on demand
        return modelAvailable && pwRecordAvailable;
    }
    
    // Paths
    property string modelDir: Quickshell.env("HOME") + "/.local/share/hyprflow/models"
    property string modelPath: modelDir + "/whisper-small.llamafile"
    property string audioPath: "/tmp/voice_dictation.wav"
    property string voiceSystemAudioPath: "/tmp/voice_system.wav"
    
    // Check dependencies at startup
    Component.onCompleted: {
        // Initialize bar heights array
        barHeights = new Array(30)
        for (var i = 0; i < 30; i++) {
            barHeights[i] = 0.1
        }
        
        console.log("VoiceDictation: Starting initialization...")
        console.log("VoiceDictation: Config model:", root.effectiveModel, "language:", Config.voiceDictation.language)
        
        // First check if voxtype is available
        voxtypeCheckProcess.running = true
    }
    
    // Update voxtype config with model and language from our config
    function updateVoxtypeConfig() {
        var configPath = Quickshell.env("HOME") + "/.config/voxtype/config.toml"
        
        // Use sed to update model and language in voxtype config
        var updateModelCmd = "sed -i 's/^\\s*model\\s*=.*/  model = \"" + root.effectiveModel + "\"/' " + configPath
        var updateLangCmd = "sed -i 's/^\\s*language\\s*=.*/  language = \"" + Config.voiceDictation.language + "\"/' " + configPath
        
        voxtypeConfigUpdateProcess.command = ["sh", "-c", updateModelCmd + " && " + updateLangCmd]
        voxtypeConfigUpdateProcess.running = true
    }
    
    Process {
        id: voxtypeConfigUpdateProcess
        command: ["true"]
        
        onExited: (code) => {
            if (code === 0) {
                console.log("Updated voxtype config with model:", root.effectiveModel, "and language:", Config.voiceDictation.language)
            } else {
                console.error("Failed to update voxtype config")
            }
        }
    }
    
    // --- IPC Handler ---
    IpcHandler {
        target: "ui.overlay.voice"
        
        function toggle() {
            console.log("=== VoiceDictation IPC toggle() called ===")
            console.log("  - Current state:", root.state)
            console.log("  - Active:", root.active)
            console.log("  - Model available:", root.modelAvailable)
            console.log("  - Use voxtype:", root.useVoxtype)
            
            // If recording, stop
            if (root.state === "RECORDING") {
                console.log("  → Stopping recording")
                root.stopRecording()
                return
            }
            
            // If downloading or processing, ignore
            if (root.state === "DOWNLOADING" || root.state === "PROCESSING") {
                console.log("  → Ignoring (already", root.state + ")")
                return
            }
            
            // Otherwise, start new recording
            console.log("  → Starting new session")
            root.active = true
            
            // Check if need to download model first
            if (root.useVoxtype && !root.modelAvailable) {
                console.log("  → Model missing, calling downloadModel()")
                root.downloadModel()
            } else {
                console.log("  → Model available, starting recording")
                root.startRecording()
            }
        }
        
        function open() {
            if (root.state !== "RECORDING" && root.state !== "DOWNLOADING" && root.state !== "PROCESSING") {
                root.active = true
                // Check if need to download model first
                if (root.useVoxtype && !root.modelAvailable) {
                    console.log("VoiceDictation IPC: Model missing, downloading...")
                    root.downloadModel()
                } else {
                    root.startRecording()
                }
            }
        }

        function close() {
            if (root.state === "RECORDING") {
                root.stopRecording()
            } else if (root.state !== "DOWNLOADING") {
                root.active = false
            }
        }
        
        function voiceSystem() {
            console.log("=== VoiceDictation IPC voiceSystem() called ===")
            console.log("  - Current state:", root.state)
            
            // If already recording for voice system, stop and process
            if (root.state === "RECORDING" && root.isVoiceSystemMode) {
                console.log("  → Stopping voice system recording")
                root.stopRecording()
                return
            }
            
            // If downloading or processing, ignore
            if (root.state === "DOWNLOADING" || root.state === "PROCESSING") {
                console.log("  → Ignoring (already", root.state + ")")
                return
            }
            
            // Otherwise, start new voice system recording
            console.log("  → Starting voice system session")
            root.isVoiceSystemMode = true
            root.active = true
            
            // Check if need to download model first
            if (root.useVoxtype && !root.modelAvailable) {
                console.log("  → Model missing, calling downloadModel()")
                root.downloadModel()
            } else {
                console.log("  → Model available, starting recording")
                root.startRecording()
            }
        }
        
        function responseComplete() {
            console.log("=== VoiceDictation IPC responseComplete() called ===")
            console.log("  - Current state:", root.state)
            
            if (root.state === "THINKING") {
                console.log("  → Response complete, closing widget")
                thinkingTimeoutTimer.stop()
                root.state = "IDLE"
                root.active = false
            }
        }
    }
    
    // Voice system mode flag
    property bool isVoiceSystemMode: false
    
    // --- Dependency Check ---
    
    // 0a. Check if voxtype is available
    Process {
        id: voxtypeCheckProcess
        command: ["which", "voxtype"]
        onExited: (code) => {
            root.voxtypeAvailable = (code === 0)
            root.useVoxtype = (code === 0)
            
            console.log("VoiceDictation: Voxtype available:", root.voxtypeAvailable)
            
            if (root.useVoxtype) {
                // Use voxtype - update config and check model
                root.updateVoxtypeConfig()
                console.log("VoiceDictation: Checking for model:", root.effectiveModel)
                voxtypeModelCheckProcess.running = true
            } else {
                console.log("VoiceDictation: Voxtype not found, using legacy mode")
                // Use legacy method - check all dependencies
                wtypeCheckProcess.running = true
                pwRecordCheckProcess.running = true
                modelCheckProcess.running = true
            }
        }
    }
    
    // 0b. Check if voxtype model is installed
    Process {
        id: voxtypeModelCheckProcess
        command: ["test", "-f", Quickshell.env("HOME") + "/.local/share/voxtype/models/ggml-" + root.effectiveModel + ".bin"]
        onExited: (code) => {
            var modelPath = Quickshell.env("HOME") + "/.local/share/voxtype/models/ggml-" + root.effectiveModel + ".bin"
            root.modelAvailable = (code === 0)
            console.log("VoiceDictation: Model check result for", modelPath, ":", root.modelAvailable ? "FOUND" : "NOT FOUND")
            
            // Don't auto-download on startup, wait for user to record
            root.dependenciesChecked = true
            if (root.modelAvailable) {
                console.log("Voxtype model found:", root.effectiveModel)
                console.log("VoiceDictation: Ready to operate")
                
                // If we just finished downloading, auto-start recording
                if (root.autoStartRecordingAfterDownload) {
                    root.autoStartRecordingAfterDownload = false
                    console.log("VoiceDictation: Auto-starting recording after download")
                    root.state = "IDLE"
                    root.startRecording()
                }
            } else {
                console.log("VoiceDictation: Model not found, will download on first record")
            }
        }
    }
    
    // Model download process
    Process {
        id: modelDownloadProcess
        command: ["voxtype", "--model", root.effectiveModel, "setup", "--download"]
        
        stdout: SplitParser {
            onRead: text => {
                // Ignore stdout, just show simple message
            }
        }
        
        stderr: SplitParser {
            onRead: text => {
                // Ignore stderr, just show simple message
            }
        }
        
        onRunningChanged: {
            if (running) {
                root.state = "DOWNLOADING"
                root.statusText = "Downloading model..."
                root.downloadProgress = 0.0  // Reset progress
                root.modelAvailable = false
                root.dependenciesChecked = false
            } else if (root.state === "DOWNLOADING") {
                // Download finished, check if successful
                console.log("Download process finished, checking if model installed...")
                // Wait a bit for file to be written
                modelCheckTimer.start()
            }
        }
        
        onExited: (code) => {
            console.log("Model download exited with code:", code)
            if (code !== 0) {
                console.error("Model download failed with code:", code)
                root.state = "IDLE"
                root.statusText = "Download failed"
                root.active = false
            }
        }
    }
    
    // Timer to wait before checking if model was downloaded
    Timer {
        id: modelCheckTimer
        interval: 1000
        repeat: false
        onTriggered: {
            // Restart voxtype daemon to pick up new model
            console.log("VoiceDictation: Restarting voxtype daemon to load new model...")
            restartVoxtypeDaemonProcess.running = true
        }
    }
    
    // Process to restart voxtype daemon after model download
    Process {
        id: restartVoxtypeDaemonProcess
        command: ["systemctl", "--user", "restart", "voxtype"]
        
        onExited: (code) => {
            console.log("VoiceDictation: Daemon restart exited with code:", code)
            if (code === 0) {
                console.log("VoiceDictation: Voxtype daemon restarted successfully")
            } else {
                console.error("VoiceDictation: Failed to restart voxtype daemon")
            }
            // Wait a bit for daemon to start, then check model again
            daemonRestartCheckTimer.start()
        }
    }
    
    // Timer to wait after daemon restart
    Timer {
        id: daemonRestartCheckTimer
        interval: 2000  // Wait 2 seconds for daemon to fully start
        repeat: false
        onTriggered: {
            console.log("VoiceDictation: Checking model after daemon restart...")
            voxtypeModelCheckProcess.running = true
        }
    }
    
    // Property to track if we should auto-start recording after download
    property bool autoStartRecordingAfterDownload: false
    
    function getModelNumber() {
        // Map model name to voxtype menu number
        var modelMap = {
            "tiny.en": "1",
            "base.en": "2",
            "small.en": "3",
            "medium.en": "4",
            "large-v3": "5",
            "large-v3-turbo": "6"
        };
        return modelMap[root.effectiveModel] || "2"; // Default to base.en
    }
    
    function downloadModel() {
        console.log("=== VoiceDictation: downloadModel() called ===")
        console.log("  - Model:", root.effectiveModel)
        console.log("  - Current state:", root.state)
        console.log("  - Active:", root.active)
        
        root.active = true  // Make sure UI is visible during download
        root.autoStartRecordingAfterDownload = true  // Auto-start recording after download
        
        console.log("  - Starting modelDownloadProcess...")
        modelDownloadProcess.running = true
    }
    
    // Legacy dependency checks
    Process {
        id: modelCheckProcess
        command: ["test", "-f", root.modelPath]
        onExited: (code) => {
            root.modelAvailable = (code === 0)
            root.updateDependencyStatus()
        }
    }
    
    function updateDependencyStatus() {
        // Check if all async checks are done
        if (modelCheckProcess.running === false && pwRecordCheckDone && wtypeCheckDone) {
            root.dependenciesChecked = true
        }
    }
    
    property bool pwRecordCheckDone: false
    property bool wtypeCheckDone: false
    
    // --- Processes ---
    
    // 0. Check if wtype is available
    Process {
        id: wtypeCheckProcess
        command: ["which", "wtype"]
        onExited: (code) => {
            root.wtypeAvailable = (code === 0)
            root.wtypeCheckDone = true
            console.log("VoiceDictation: wtype check - available:", root.wtypeAvailable)
            root.updateDependencyStatus()
        }
    }
    
    // 0b. Check if pw-record is available
    Process {
        id: pwRecordCheckProcess
        command: ["which", "pw-record"]
        onExited: (code) => {
            root.pwRecordAvailable = (code === 0)
            root.pwRecordCheckDone = true
            root.updateDependencyStatus()
        }
    }
    
    // --- Voice System Mode Processes (pw-record + voxtype transcribe) ---
    
    // Voice system recording with pw-record (no typing, full control)
    Process {
        id: voiceSystemRecordProcess
        command: ["pw-record", "--rate", "16000", "--channels", "1", root.voiceSystemAudioPath]
        
        onRunningChanged: {
            if (running) {
                root.state = "RECORDING"
                root.statusText = "Listening..."
                console.log("=== VoiceDictation: Voice system recording STARTED ===")
                console.log("  - Command:", voiceSystemRecordProcess.command)
                console.log("  - Audio path:", root.voiceSystemAudioPath)
            } else {
                console.log("=== VoiceDictation: Voice system recording STOPPED ===")
            }
        }
        
        onExited: (code) => {
            console.log("VoiceDictation: Voice system recording exited with code:", code)
        }
    }
    
    // Voice system transcription with voxtype transcribe
    Process {
        id: voiceSystemTranscribeProcess
        command: ["voxtype", "--quiet", "--model", root.effectiveModel, "transcribe", root.voiceSystemAudioPath]
        
        property string rawOutput: ""
        
        stdout: SplitParser {
            onRead: text => {
                console.log("VoiceDictation: voxtype stdout chunk:", text)
                voiceSystemTranscribeProcess.rawOutput += text
            }
        }
        
        stderr: SplitParser {
            onRead: text => {
                console.log("VoiceDictation: voxtype stderr:", text)
            }
        }
        
        onRunningChanged: {
            if (running) {
                root.state = "PROCESSING"
                root.statusText = "Processing..."
                root.capturedText = ""
                voiceSystemTranscribeProcess.rawOutput = ""
                console.log("=== VoiceDictation: Voice system transcription STARTED ===")
                console.log("  - Command:", voiceSystemTranscribeProcess.command)
                console.log("  - Audio file:", root.voiceSystemAudioPath)
            }
        }
        
        onExited: (code) => {
            console.log("=== VoiceDictation: Voice system transcription EXITED ===")
            console.log("  - Exit code:", code)
            console.log("  - Raw output length:", voiceSystemTranscribeProcess.rawOutput.length)
            console.log("  - Raw output:", voiceSystemTranscribeProcess.rawOutput)
            
            if (code === 0) {
                // The transcription is the LAST non-empty line
                var lines = voiceSystemTranscribeProcess.rawOutput.split('\n')
                console.log("  - Total lines:", lines.length)
                
                // Find the last non-empty line (that's the transcription)
                var transcription = ""
                for (var i = lines.length - 1; i >= 0; i--) {
                    var line = lines[i].trim()
                    if (line.length > 0) {
                        transcription = line
                        console.log("  - Found transcription at line", i, ":", transcription)
                        break
                    }
                }
                
                root.capturedText = transcription
                console.log("  - Final captured text:", root.capturedText)
                console.log("  - Final text length:", root.capturedText.length)
                root.finish()
            } else {
                console.error("VoiceDictation: Failed to transcribe voice system audio")
                root.state = "IDLE"
                root.active = false
                root.isVoiceSystemMode = false
            }
        }
    }
    
    // --- Voxtype Processes (Normal Mode) ---
    
    // Voxtype record start (sends signal to daemon)
    Process {
        id: voxtypeRecordStartProcess
        command: ["voxtype", "record", "start"]
        
        onExited: (code) => {
            console.log("VoiceDictation: voxtype record start exited with code:", code)
            if (code === 0) {
                root.state = "RECORDING"
                root.statusText = "Listening..."
            } else {
                console.error("VoiceDictation: Failed to start voxtype recording")
                root.state = "IDLE"
                root.active = false
            }
        }
    }
    
    // Voxtype record stop (sends signal to daemon, daemon handles transcription and typing)
    Process {
        id: voxtypeRecordStopProcess
        command: ["voxtype", "record", "stop"]
        
        onExited: (code) => {
            console.log("VoiceDictation: voxtype record stop exited with code:", code)
            if (code === 0) {
                // Voxtype daemon handles transcription and typing automatically
                // Just show processing state briefly then close
                root.state = "PROCESSING"
                root.statusText = "Processing..."
                // Close UI after a short delay (daemon is doing the work)
                closeAfterProcessingTimer.start()
            } else {
                console.error("VoiceDictation: Failed to stop voxtype recording")
                root.state = "IDLE"
                root.active = false
            }
        }
    }
    
    // Timer to close UI after voxtype daemon finishes
    Timer {
        id: closeAfterProcessingTimer
        interval: 2000  // Wait 2 seconds for daemon to finish
        repeat: false
        onTriggered: {
            root.state = "IDLE"
            root.statusText = "Ready"
            root.active = false
        }
    }
    
    // --- Legacy Processes ---
    
    // 1. Recording (legacy - not used with voxtype)
    Process {
        id: recordProcess
        command: ["pw-record", "--rate", "16000", "--channels", "1", root.audioPath]
        
        onRunningChanged: {
            if (running) {
                root.state = "RECORDING"
                root.statusText = "Listening..."
            }
        }
    }
    
    // 2. Transcribing (legacy)
    Process {
        id: transcribeProcess
        
        stdout: SplitParser {
            onRead: text => {
                root.capturedText += text
            }
        }
        
        onRunningChanged: {
            if (running) {
                root.state = "PROCESSING"
                root.statusText = "Processing..."
                root.capturedText = ""
            } else if (!running && root.state === "PROCESSING") {
                root.finish()
            }
        }
    }
    
    // 3. Typing Action (optional - requires wtype)
    Process {
        id: typeProcess
        command: ["true"] // Placeholder
        
        onRunningChanged: {
            if (running) {
                console.log("VoiceDictation: typeProcess started with command:", typeProcess.command)
            }
        }
        
        onExited: (code) => {
            console.log("VoiceDictation: typeProcess exited with code:", code)
            if (code !== 0) {
                console.error("VoiceDictation: wtype failed, showing notification")
                // wtype failed, show notification
                notifyProcess.running = true
            } else {
                console.log("VoiceDictation: wtype succeeded!")
            }
        }
    }
    
    // 4. Send notification (fallback when wtype not available)
    Process {
        id: notifyProcess
        command: ["notify-send", "-a", "Voice Dictation", "-i", "edit-paste", "Text copied to clipboard", root.capturedText]
    }
    
    // --- Logic ---
    
    function startRecording() {
        console.log("VoiceDictation: Starting recording (voxtype mode:", root.useVoxtype, ", voice system:", root.isVoiceSystemMode, ")")
        
        // Don't start if critical dependencies are missing
        if (!root.canOperate) {
            console.warn("VoiceDictation: Cannot operate - dependencies not met")
            console.warn("  - dependenciesChecked:", root.dependenciesChecked)
            console.warn("  - modelAvailable:", root.modelAvailable)
            console.warn("  - voxtypeAvailable:", root.voxtypeAvailable)
            console.warn("  - state:", root.state)
            return
        }
        
        console.log("VoiceDictation: Recording...")
        
        if (root.useVoxtype && !root.isVoiceSystemMode) {
            // Normal mode: Use voxtype daemon (will type automatically)
            voxtypeRecordStartProcess.running = true
        } else if (root.useVoxtype && root.isVoiceSystemMode) {
            // Voice system mode: Use pw-record directly to avoid typing
            console.log("VoiceDictation: Voice system mode - using pw-record")
            voiceSystemRecordProcess.running = true
        } else {
            // Legacy method (no voxtype)
            recordProcess.running = true
        }
    }
    
    function stopRecording() {
        console.log("VoiceDictation: Stopping recording...")
        
        if (root.useVoxtype && !root.isVoiceSystemMode) {
            // Normal mode: Use voxtype daemon (will type automatically)
            voxtypeRecordStopProcess.running = true
        } else if (root.useVoxtype && root.isVoiceSystemMode) {
            // Voice system mode: Stop pw-record and transcribe with voxtype
            console.log("VoiceDictation: Voice system mode - stopping pw-record")
            voiceSystemRecordProcess.running = false
            // Start transcription
            root.state = "PROCESSING"
            root.statusText = "Processing..."
            voiceSystemTranscribeProcess.running = true
        } else {
            // Legacy method
            recordProcess.running = false
            console.log("VoiceDictation: Using legacy transcribe")
            transcribeProcess.command = ["sh", root.modelPath, "-f", root.audioPath, "--no-timestamps", "--log-disable", "--language", Config.voiceDictation.language]
            transcribeProcess.running = true
        }
    }
    
    function finish() {
        root.state = "IDLE"
        root.statusText = "Done"
        
        console.log("=== VoiceDictation: finish() called ===")
        console.log("  - Captured text:", root.capturedText)
        console.log("  - Text length:", root.capturedText.length)
        console.log("  - Voice system mode:", root.isVoiceSystemMode)
        
        if (root.capturedText.trim() !== "") {
            root.capturedText = root.capturedText.trim()
            console.log("  - Trimmed text:", root.capturedText)
            
            if (root.isVoiceSystemMode) {
                // Voice system mode: copy to clipboard and send IPC signal
                console.log("  - Voice system mode: sending to chat")
                // Keep active and show thinking state
                root.state = "THINKING"
                root.statusText = "Thinking..."
                root.isVoiceSystemMode = false
                
                // Copy text to clipboard so the chat IPC can read it
                Quickshell.clipboardText = root.capturedText
                console.log("  - Copied to clipboard for voice system")
                
                // Send IPC signal to chat (no arguments, will read from clipboard)
                console.log("  - Calling IPC: qs ipc call ui.dialog.launcher.chat sendVoiceCommand")
                voiceSystemSendProcess.command = [
                    "qs", "ipc", "call", "ui.dialog.launcher.chat", "sendVoiceCommand"
                ]
                voiceSystemSendProcess.running = true
                
                // Auto-close after timeout (60 seconds)
                thinkingTimeoutTimer.start()
            } else {
                // Normal mode: copy to clipboard and optionally type
                root.active = false // Hide
                
                // Always copy to clipboard using native Quickshell API
                Quickshell.clipboardText = root.capturedText
                console.log("  - Copied to clipboard")
                
                if (root.wtypeAvailable) {
                    // Auto-type with wtype if available
                    console.log("  - wtype available, typing text...")
                    typeProcess.command = ["wtype", "-d", "2", root.capturedText]
                    typeProcess.running = true
                } else {
                    // No wtype, just notify user that text is in clipboard
                    console.log("  - wtype not available, showing notification")
                    notifyProcess.command = ["notify-send", "-a", "Voice Dictation", "-i", "edit-paste", "Text copied to clipboard", root.capturedText]
                    notifyProcess.running = true
                }
            }
        } else {
            console.log("  - No text captured (empty after trim)")
            console.log("  - WARNING: Transcription was filtered out or empty!")
            root.active = false
            root.isVoiceSystemMode = false
        }
    }
    
    // Timer to auto-close thinking state after timeout
    Timer {
        id: thinkingTimeoutTimer
        interval: 60000  // 60 seconds
        repeat: false
        onTriggered: {
            console.log("VoiceDictation: Thinking timeout, closing widget")
            root.state = "IDLE"
            root.active = false
        }
    }
    
    // Process to send voice command to chat
    Process {
        id: voiceSystemSendProcess
        command: ["true"] // Placeholder
        
        onRunningChanged: {
            if (running) {
                console.log("VoiceDictation: voiceSystemSendProcess running with command:", voiceSystemSendProcess.command)
            }
        }
        
        onExited: (code) => {
            console.log("VoiceDictation: voiceSystemSendProcess exited with code:", code)
            if (code === 0) {
                console.log("VoiceDictation: Voice command IPC sent successfully")
            } else {
                console.error("VoiceDictation: Failed to send voice command IPC, code:", code)
                // Fallback: show notification
                notifyProcess.command = ["notify-send", "-a", "Voice System", "-i", "dialog-error", "Failed to send to chat", root.capturedText]
                notifyProcess.running = true
            }
        }
    }
    
    property real animPhase: 0.0
    property var barHeights: []

    // --- Visualizer Timer ---
    Timer {
        id: vizTimer
        interval: 50
        repeat: true
        running: root.state === "RECORDING" || root.state === "PROCESSING" || root.state === "DOWNLOADING" || root.state === "THINKING"
        onTriggered: {
            var newHeights = []
            if (root.state === "RECORDING") {
                for (var i = 0; i < 30; i++) {
                    newHeights.push(Math.random())
                }
            } else if (root.state === "PROCESSING") {
                root.animPhase += 0.4
                for (var i = 0; i < 30; i++) {
                    // Sine Wave Computing Effect
                    var x = i * 0.3 + root.animPhase
                    var val = (Math.sin(x) + 1.0) / 2.0
                    newHeights.push(val)
                }
            } else if (root.state === "THINKING") {
                // Pulsing wave effect - slower and more meditative
                root.animPhase += 0.15
                for (var i = 0; i < 30; i++) {
                    // Breathing/pulsing effect from center
                    var distance = Math.abs(i - 15) / 15.0  // 0 at center, 1 at edges
                    var pulse = (Math.sin(root.animPhase - distance * 2) + 1.0) / 2.0
                    newHeights.push(pulse * 0.8 + 0.2)  // Keep minimum height
                }
            } else if (root.state === "DOWNLOADING") {
                // Progress bar effect - simulate incremental progress (faster)
                root.downloadProgress += 0.015  // Increased from 0.005 to make it faster
                if (root.downloadProgress > 0.95) {
                    root.downloadProgress = 0.2  // Loop back to keep it moving
                }
                
                for (var i = 0; i < 30; i++) {
                    // Progressive fill effect
                    var barPosition = i / 30.0
                    if (barPosition < root.downloadProgress) {
                        newHeights.push(1.0)  // Full height
                    } else {
                        newHeights.push(0.1)  // Minimal height
                    }
                }
            }
            root.barHeights = newHeights
        }
    }
    
    // --- Visuals ---
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.2)
        radius: Config.itemRadius
        
        // Missing dependencies view
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 5
            visible: !root.canOperate && root.dependenciesChecked && root.state !== "DOWNLOADING"
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "󰀦 Missing Dependencies"
                color: Config.red
                font.family: Config.fontFamily
                font.pixelSize: 14
                font.bold: true
            }
            
            Repeater {
                model: root.missingDependencies
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "• " + modelData
                    color: Config.dimmed
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    Layout.maximumWidth: root.width - 20
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: root.wtypeAvailable === false && root.wtypeCheckDone
                text: "(wtype optional - for auto-typing)"
                color: Config.dimmed
                font.family: Config.fontFamily
                font.pixelSize: 10
                font.italic: true
            }
        }
        
        // Downloading view
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 5
            visible: root.state === "DOWNLOADING"
            
            // Status Text
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.statusText
                color: Config.foreground
                font.family: Config.fontFamily
                font.pixelSize: 14
                font.bold: true
            }
            
            // Visualizer Container
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    
                    Repeater {
                        id: vizRepeater
                        model: 30 
                        
                        Rectangle {
                            id: bar
                            
                            Layout.preferredWidth: 4
                            // Use wave height for PROCESSING/DOWNLOADING too
                            Layout.preferredHeight: {
                                var height = root.barHeights[index] !== undefined ? root.barHeights[index] : 0.1
                                return 30 * (root.state === "IDLE" ? 0.1 : (0.2 + height * 0.8))
                            }
                            Layout.alignment: Qt.AlignVCenter
                            
                            color: {
                                if (root.state === "DOWNLOADING") return Config.yellow
                                if (root.state === "PROCESSING") return Config.cyan
                                if (root.state === "THINKING") return Config.purple
                                if (root.state === "RECORDING") return Config.accent
                                return Config.dimmed
                            }
                            radius: Config.itemRadius
                            
                            Behavior on Layout.preferredHeight {
                                NumberAnimation { duration: Config.animDurationFast }
                            }
                            
                            Behavior on color {
                                ColorAnimation { duration: Config.animDurationRegular }
                            }
                        }
                    }
                }
            }
        }
        
        // Normal operation view
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 5
            visible: (root.canOperate || !root.dependenciesChecked) && root.state !== "DOWNLOADING"
            
            // Status Text
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.statusText
                color: Config.foreground
                font.family: Config.fontFamily
                font.pixelSize: 14
                font.bold: true
            }
            
            // Visualizer Container
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    
                    Repeater {
                        model: 30 
                        
                        Rectangle {
                            id: bar2
                            
                            Layout.preferredWidth: 4
                            // Use wave height for PROCESSING too
                            Layout.preferredHeight: {
                                var height = root.barHeights[index] !== undefined ? root.barHeights[index] : 0.1
                                return 30 * (root.state === "IDLE" ? 0.1 : (0.2 + height * 0.8))
                            }
                            Layout.alignment: Qt.AlignVCenter
                            
                            color: root.state === "PROCESSING" ? Config.cyan : (root.state === "THINKING" ? Config.purple : (root.state === "RECORDING" ? Config.accent : Config.dimmed))
                            radius: Config.itemRadius
                            
                            Behavior on Layout.preferredHeight {
                                NumberAnimation { duration: Config.animDurationFast }
                            }
                            
                            Behavior on color {
                                ColorAnimation { duration: Config.animDurationRegular }
                            }
                        }
                    }
                }
            }
            
            // Hint
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.state === "RECORDING" ? "Click to Stop" : " "
                color: Config.dimmed
                font.family: Config.fontFamily
                font.pixelSize: 10
            }
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (root.state === "RECORDING") {
                    root.stopRecording()
                }
            }
        }
    }
}
