import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "joma.mark-that"
    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    readonly property var helper: ["python3", decodeURIComponent(String(Qt.resolvedUrl("../marks.py")).replace(/^file:\/\//, ""))]
    property alias words: strings
    property alias anchorButton: icon
    property bool opened: false
    property bool browsing: false
    property bool failed: false
    property var snapshot: null
    property string note: ""
    property var marks: []
    property var selectedIds: []
    readonly property bool saving: writer.running
    readonly property bool listing: listingProcess.running

    function reveal(history) {
        browsing = history
        if (!panel.item) panel.setSource(Qt.resolvedUrl("MarkPanel.qml"), {host: root})
        opened = true
        if (panel.item) Qt.callLater(panel.item.focusPage)
    }

    function open() {
        if (opened || collector.running || saving) return
        failed = false
        snapshot = null
        note = ""
        collector.running = true
    }

    function close() {
        opened = false
    }

    function history() {
        if (collector.running || saving) return
        failed = false
        selectedIds = []
        marks = []
        reveal(true)
        listingProcess.running = true
    }

    function save() {
        if (!snapshot || saving) return
        failed = false
        writer.running = true
    }

    function selectMark(id) {
        selectedIds = selectedIds.includes(id) ? selectedIds.filter(item => item !== id) : selectedIds.concat([id])
    }

    function compare() {
        if (selectedIds.length < 2 || launcher.running) return
        failed = false
        launcher.command = helper.concat(["compare"], selectedIds)
        launcher.running = true
    }

    Translations { id: strings; directory: Qt.resolvedUrl("../i18n") }

    ShellIpc {
        target: "joma.mark-that"

        function toggleRecent(): void {
            const monitor = Hyprland.focusedMonitor
            const widgets = root.bar ? root.bar.moduleWidgets(root.moduleName) : []
            const widget = widgets.find(item => monitor && item.QsWindow.window?.screen?.name === monitor.name) || root
            if (widget.opened && widget.browsing) widget.close()
            else widget.history()
            console.debug("Mark that: Recent marks shortcut", widget.opened && widget.browsing ? "open" : "closed")
        }
    }

    WidgetButton {
        id: icon
        anchors.fill: parent
        bar: root.bar
        text: "⚑"
        tooltipText: strings.t("tooltip")
        onPressed: function(button) {
            if (button === Qt.RightButton) root.history()
            else if (root.opened) root.close()
            else root.open()
        }
    }

    Loader {
        id: panel
        onLoaded: if (root.opened) Qt.callLater(item.focusPage)
    }

    Process {
        id: collector
        command: root.helper.concat(["capture"])
        stdout: StdioCollector { id: captured; waitForEnd: true }
        onExited: function(code) {
            try {
                if (code === 0) root.snapshot = JSON.parse(captured.text)
            } catch (error) { root.snapshot = null }
            root.failed = !root.snapshot
            root.reveal(false)
        }
    }

    Process {
        id: writer
        command: root.helper.concat(["save"])
        stdinEnabled: true
        onStarted: write(JSON.stringify(Object.assign({}, root.snapshot, { note: root.note })) + "\n")
        onExited: function(code) {
            if (code !== 0) { root.failed = true; return }
            root.close()
            Quickshell.execDetached(["notify-send", "-a", strings.t("title"), strings.t("saved")])
        }
    }

    Process {
        id: listingProcess
        command: root.helper.concat(["recent"])
        stdout: StdioCollector { id: historyOutput; waitForEnd: true }
        onExited: function(code) {
            try {
                if (code !== 0) throw Error("list")
                root.marks = JSON.parse(historyOutput.text)
                root.selectedIds = root.marks.slice(0, 2).map(mark => mark.id)
            } catch (error) { root.failed = true }
        }
    }

    Process {
        id: launcher
        onExited: function(code) {
            if (code !== 0) root.failed = true
            else root.close()
        }
    }
}
