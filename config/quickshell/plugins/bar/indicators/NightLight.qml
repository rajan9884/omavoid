import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarIndicator {
  id: root

  readonly property var nightlightService: bar?.shell?.firstPartyServiceFor("void.nightlight")

  active: nightlightService ? nightlightService.enabled : false
  activeText: "󰔎"
  inactiveText: "󰔎"
  activeTooltipText: I18n.t("bar.dayLight")
  inactiveTooltipText: I18n.t("bar.nightLight")
  useActiveColor: true
  activeColor: bar ? bar.accent : Color.accent

  function toggle() {
    if (root.nightlightService) {
      root.nightlightService.setNightlight(!root.active)
    } else {
      toggleProc.command = ["void-toggle-nightlight"]
      toggleProc.running = true
    }
  }

  onPressed: function() { root.toggle() }

  Process {
    id: toggleProc
  }

  Connections {
    target: root.indicatorHost
    ignoreUnknownSignals: true
    function onRefreshRequested() {
      if (root.nightlightService) root.nightlightService.refresh()
    }
  }
}
