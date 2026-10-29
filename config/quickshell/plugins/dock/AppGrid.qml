import QtQuick
import Quickshell
import "ui" as Ui

// Menu entry point: summonable launcher surface that replaces the old app grid.
Item {
  id: root
  width: 0
  height: 0

  property var appLibrary: null
  property var dock: null

  readonly property bool opened: window.opened
  readonly property var core: service

  function open(payloadJson) {
    service.onWindowOpened()
    var payload = {}
    try { payload = JSON.parse(payloadJson || "{}") || {} } catch (e) { payload = {} }
    window.summon(payload)
  }

  function close() {
    window.dismiss()
  }

  function dismiss() {
    window.opened = false
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open("{}")
  }

  Service {
    id: service
    appLibrary: root.appLibrary
    dock: root
  }

  Ui.LauncherWindow {
    id: window
    launcher: root
  }
}
