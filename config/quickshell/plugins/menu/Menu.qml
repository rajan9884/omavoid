import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons as Commons
import qs.Ui as Ui

Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null

  property bool showing: false
  property string query: ""
  property int selected: 0

  readonly property color bg: Commons.Color.menu.background
  readonly property color fg: Commons.Color.menu.text
  readonly property color borderCol: Commons.Color.menu.border
  readonly property color scrimCol: Commons.Color.menu.scrim
  readonly property color selectedBg: Commons.Color.menu.selectedBackground
  readonly property color selectedFg: Commons.Color.menu.selectedText
  readonly property color faintFg: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.6)
  readonly property int cornerRadius: Commons.Style.cornerRadius
  readonly property string fontFamily: Commons.Style.font.menuFamily

  function open(payloadJson) {
    root.query = ""
    root.selected = 0
    root.showing = true
    Qt.callLater(function() {
      if (searchInput) {
        searchInput.text = ""
        searchInput.forceActiveFocus()
      }
    })
  }

  function close() {
    root.showing = false
    root.query = ""
    root.selected = 0
  }

  function toggle(payloadJson) {
    if (root.showing) root.close()
    else root.open(payloadJson)
  }

  function refresh() { return "ok" }
  function ping() { return "ok" }

  function fuzzyScore(name, q) {
    name = name.toLowerCase()
    q = q.toLowerCase()
    if (q.length === 0) return 1
    if (name.indexOf(q) === 0) return 1000 - name.length
    var si = 0, score = 0, consec = 0
    for (var i = 0; i < name.length && si < q.length; i++) {
      if (name[i] === q[si]) {
        score += 10 + consec * 5
        if (i === 0 || name[i-1] === " " || name[i-1] === "-" || name[i-1] === "_") score += 8
        consec++
        si++
      } else {
        consec = 0
      }
    }
    if (si < q.length) return -1
    return score - name.length * 0.1
  }

  readonly property var allApps: {
    if (!DesktopEntries || !DesktopEntries.applications) return []
    return DesktopEntries.applications.values.filter(function(a) {
      return a && !a.noDisplay && !a.hidden && a.name
    })
  }

  readonly property var filteredApps: {
    var q = root.query.trim()
    var apps = root.allApps
    if (apps.length === 0) return []

    var scored = []
    for (var i = 0; i < apps.length; i++) {
      var app = apps[i]
      var searchTarget = (app.name || "") + " " + (app.genericName || "") + " " + (app.comment || "") + " " + (app.execString || "")
      var s = root.fuzzyScore(searchTarget, q)
      if (s >= 0) scored.push({ app: app, score: s })
    }

    var byName = function(a, b) {
      return (a.app.name || "").toLowerCase().localeCompare((b.app.name || "").toLowerCase())
    }

    if (q.length === 0) {
      scored.sort(byName)
    } else {
      scored.sort(function(a, b) {
        return b.score - a.score || byName(a, b)
      })
    }

    return scored.slice(0, 40).map(function(x) { return x.app })
  }

  onFilteredAppsChanged: {
    if (root.selected >= root.filteredApps.length) {
      root.selected = Math.max(0, root.filteredApps.length - 1)
    }
  }

  function launchCurrent() {
    if (root.filteredApps.length === 0) return
    var idx = Math.min(Math.max(0, root.selected), root.filteredApps.length - 1)
    var app = root.filteredApps[idx]
    if (app && typeof app.execute === "function") {
      root.close()
      app.execute()
    }
  }

  Ui.OverlayWindow {
    id: overlay
    shown: root.showing
    WlrLayershell.namespace: "omarchy-menu"

    Rectangle {
      anchors.fill: parent
      color: root.scrimCol

      MouseArea {
        anchors.fill: parent
        onClicked: root.close()
      }
    }

    Rectangle {
      id: card
      anchors.centerIn: parent
      width: Math.min(680, overlay.width - 40)
      height: Math.min(520, overlay.height - 80)
      radius: root.cornerRadius
      color: root.bg
      border.color: root.borderCol
      border.width: 1
      clip: true

      MouseArea {
        anchors.fill: parent
        // Prevent clicks inside card from dismissing the overlay
      }

      Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Search Bar Row
        Rectangle {
          width: parent.width
          height: 44
          radius: Math.max(6, root.cornerRadius - 4)
          color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.06)
          border.color: searchInput.activeFocus ? root.selectedBg : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.15)
          border.width: 1

          Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: ""
              font.family: root.fontFamily
              font.pixelSize: 15
              color: root.faintFg
            }

            TextInput {
              id: searchInput
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - 32
              text: root.query
              font.family: root.fontFamily
              font.pixelSize: 14
              color: root.fg
              clip: true
              selectByMouse: true

              Text {
                anchors.fill: parent
                text: "Search applications..."
                font.family: parent.font.family
                font.pixelSize: parent.font.pixelSize
                color: root.faintFg
                visible: !searchInput.text && !searchInput.inputMethodComposing
              }

              onTextChanged: {
                if (root.query !== text) {
                  root.query = text
                  root.selected = 0
                }
              }

              Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                  root.close()
                  event.accepted = true
                } else if (event.key === Qt.Key_Down) {
                  if (root.filteredApps.length > 0) {
                    root.selected = (root.selected + 1) % root.filteredApps.length
                    appListView.positionViewAtIndex(root.selected, ListView.Contain)
                  }
                  event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                  if (root.filteredApps.length > 0) {
                    root.selected = (root.selected - 1 + root.filteredApps.length) % root.filteredApps.length
                    appListView.positionViewAtIndex(root.selected, ListView.Contain)
                  }
                  event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                  root.launchCurrent()
                  event.accepted = true
                } else if (event.key === Qt.Key_PageDown) {
                  if (root.filteredApps.length > 0) {
                    root.selected = Math.min(root.selected + 6, root.filteredApps.length - 1)
                    appListView.positionViewAtIndex(root.selected, ListView.Contain)
                  }
                  event.accepted = true
                } else if (event.key === Qt.Key_PageUp) {
                  if (root.filteredApps.length > 0) {
                    root.selected = Math.max(root.selected - 6, 0)
                    appListView.positionViewAtIndex(root.selected, ListView.Contain)
                  }
                  event.accepted = true
                }
              }
            }
          }
        }

        // Application List
        ListView {
          id: appListView
          width: parent.width
          height: parent.height - 44 - 12 - footerRow.height - 12
          clip: true
          model: root.filteredApps
          currentIndex: root.selected
          spacing: 2
          boundsBehavior: Flickable.StopAtBounds

          onCurrentIndexChanged: {
            if (currentIndex >= 0 && currentIndex < count) {
              positionViewAtIndex(currentIndex, ListView.Contain)
            }
          }

          delegate: Rectangle {
            required property var modelData
            required property int index

            readonly property bool isSelected: index === root.selected

            width: appListView.width
            height: 48
            radius: Math.max(4, root.cornerRadius - 6)
            color: isSelected ? root.selectedBg : "transparent"

            Row {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 12

              // Icon or Letter Fallback
              Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30

                Image {
                  id: iconImg
                  anchors.fill: parent
                  sourceSize: Qt.size(30, 30)
                  source: (modelData && modelData.icon) ? Quickshell.iconPath(modelData.icon, true) : ""
                  visible: status === Image.Ready
                  fillMode: Image.PreserveAspectFit
                }

                Rectangle {
                  anchors.fill: parent
                  radius: 6
                  color: isSelected ? Qt.rgba(root.selectedFg.r, root.selectedFg.g, root.selectedFg.b, 0.2) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1)
                  visible: !iconImg.visible

                  Text {
                    anchors.centerIn: parent
                    text: (modelData && modelData.name && modelData.name.length > 0) ? modelData.name.charAt(0).toUpperCase() : "?"
                    color: isSelected ? root.selectedFg : root.fg
                    font.family: root.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                  }
                }
              }

              // Text Labels
              Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 42
                spacing: 2

                Text {
                  width: parent.width
                  text: (modelData && modelData.name) ? modelData.name : ""
                  color: isSelected ? root.selectedFg : root.fg
                  font.family: root.fontFamily
                  font.pixelSize: 13
                  font.bold: isSelected
                  elide: Text.ElideRight
                }

                Text {
                  width: parent.width
                  visible: !!(modelData && (modelData.genericName || modelData.comment))
                  text: (modelData && (modelData.genericName || modelData.comment)) ? (modelData.genericName || modelData.comment) : ""
                  color: isSelected ? Qt.rgba(root.selectedFg.r, root.selectedFg.g, root.selectedFg.b, 0.75) : root.faintFg
                  font.family: root.fontFamily
                  font.pixelSize: 10
                  elide: Text.ElideRight
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onEntered: root.selected = index
              onClicked: {
                root.selected = index
                root.launchCurrent()
              }
            }
          }
        }

        // Footer Row
        Row {
          id: footerRow
          width: parent.width
          height: 18
          spacing: 16

          Text {
            text: "↑↓ Navigate"
            font.family: root.fontFamily
            font.pixelSize: 10
            color: root.faintFg
          }

          Text {
            text: "↵ Launch"
            font.family: root.fontFamily
            font.pixelSize: 10
            color: root.faintFg
          }

          Text {
            text: "Esc Close"
            font.family: root.fontFamily
            font.pixelSize: 10
            color: root.faintFg
          }
        }
      }
    }
  }
}
