import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarIndicator {
  id: root

  property bool recording: false

  active: recording
  activeText: "󰻂"
  inactiveText: "󰻂"
  activeTooltipText: I18n.t("bar.stopRecording")
  inactiveTooltipText: I18n.t("bar.screenRecording")
  useActiveColor: true
  activeColor: bar ? bar.urgent : Color.urgent

  function refresh() {
    if (!root.bar || statusProc.running) return
    statusProc.command = ["void-capture-screenrecording", "--status"]
    statusProc.running = true
  }

  onBarChanged: refresh()
  Component.onCompleted: refresh()

  Timer {
    running: root.recording
    interval: 2000
    repeat: true
    onTriggered: root.refresh()
  }

  Connections {
    target: root.indicatorHost
    ignoreUnknownSignals: true
    function onRefreshRequested() { root.refresh() }
  }

  Process {
    id: statusProc
    onExited: function(exitCode) {
      root.recording = exitCode === 0
    }
  }

  onPressed: function() {
    if (root.bar) {
      root.bar.run(root.recording ? "void-capture-screenrecording --stop-recording" : "void-menu toggle trigger.capture.screenrecord")
    }
  }
}
