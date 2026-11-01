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
  property bool opened: showing
  property string query: ""
  property int selected: 0
  property string currentMode: "apps" // "apps", "system", "select"
  property string dmenuPrompt: ""
  property var dmenuOptions: []
  property string selectionFile: ""
  property string doneFile: ""
  property int menuWidth: 460

  readonly property color bg: Commons.Color.menu.background
  readonly property color fg: Commons.Color.menu.text
  readonly property color borderCol: Commons.Color.menu.border
  readonly property color selectedBg: Commons.Color.menu.selectedBackground
  readonly property color selectedFg: Commons.Color.menu.selectedText
  readonly property color faintFg: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.6)
  readonly property int cornerRadius: Commons.Style.cornerRadius
  readonly property string fontFamily: Commons.Style.font.menuFamily

  readonly property var systemMenuItems: [
    { name: "Install Packages", iconGlyph: "󰉉", comment: "Search & install Void packages", cmd: "void-launch-floating-terminal-with-presentation void-pkg-install" },
    { name: "Remove Packages", iconGlyph: "󰭌", comment: "Search & remove installed packages", cmd: "void-launch-floating-terminal-with-presentation void-pkg-remove" },
    { name: "Lock System", iconGlyph: "󰌾", comment: "Lock display immediately", cmd: "void-system-lock" },
    { name: "Screensaver", iconGlyph: "󰍹", comment: "Run ttfx screensaver", cmd: "void-toggle-screensaver" },
    { name: "Suspend", iconGlyph: "󰤄", comment: "Sleep system", cmd: "loginctl suspend 2>/dev/null || zzz" },
    { name: "Hibernate", iconGlyph: "󰋊", comment: "Hibernate system", cmd: "loginctl hibernate 2>/dev/null || ZZZ" },
    { name: "Logout", iconGlyph: "󰍃", comment: "Exit Hyprland session", cmd: "hyprctl dispatch exit" },
    { name: "Reboot", iconGlyph: "󰜉", comment: "Restart computer", cmd: "sudo reboot 2>/dev/null || loginctl reboot" },
    { name: "Shutdown", iconGlyph: "󰐥", comment: "Power off computer", cmd: "sudo poweroff 2>/dev/null || loginctl poweroff" }
  ]

  function open(payloadJson) {
    var payload = {}
    try { payload = JSON.parse(payloadJson || "{}") } catch (e) { payload = {} }

    root.query = ""
    root.selected = 0
    root.selectionFile = payload.selectionFile || ""
    root.doneFile = payload.doneFile || ""

    if (payload.mode === "select") {
      root.currentMode = "select"
      root.dmenuPrompt = payload.prompt || "Select"
      root.dmenuOptions = payload.options || []
      root.menuWidth = payload.width ? Math.max(380, payload.width) : 560
    } else if (payload.menu === "system" || payload.initialMenu === "system") {
      root.currentMode = "system"
      root.menuWidth = 440
    } else {
      root.currentMode = "apps"
      root.menuWidth = 460
      if (root.shell && root.shell.appLibrary && typeof root.shell.appLibrary.refreshIcons === "function") {
        root.shell.appLibrary.refreshIcons()
      }
    }

    root.showing = true
    root.opened = true
    Qt.callLater(function() {
      if (searchInput) {
        searchInput.text = ""
        searchInput.forceActiveFocus()
      }
    })
  }

  function close() {
    if (root.currentMode === "select" && root.doneFile) {
      Quickshell.execDetached(["touch", root.doneFile])
    }
    root.showing = false
    root.opened = false
    root.query = ""
    root.selected = 0
    root.selectionFile = ""
    root.doneFile = ""
    if (root.shell && typeof root.shell.hide === "function") {
      root.shell.hide("omarchy.menu")
    }
  }

  function toggle(payloadJson) {
    if (root.showing) root.close()
    else root.open(payloadJson)
  }

  function refresh() { return "ok" }
  function ping() { return "ok" }

  function fuzzyScore(name, q) {
    name = (name || "").toLowerCase()
    q = (q || "").toLowerCase()
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

  function scoreApp(app, q) {
    if (!app || !q) return 1
    var qLower = q.toLowerCase()
    var name = (app.name || "").toLowerCase()
    var exec = (app.execString || "").toLowerCase()
    var generic = (app.genericName || "").toLowerCase()
    var comment = (app.comment || "").toLowerCase()

    // 1. Exact name match
    if (name === qLower) return 100000

    // 2. Name starts with query
    if (name.indexOf(qLower) === 0) return 50000 - name.length * 10

    // 3. Word in name starts with query
    var words = name.split(/[\s\-_]+/)
    for (var w = 0; w < words.length; w++) {
      if (words[w].indexOf(qLower) === 0) {
        return 40000 - name.length * 10
      }
    }

    // 4. Executable binary starts with query
    var execBin = exec.split(" ")[0].split("/").pop()
    if (execBin.indexOf(qLower) === 0) return 35000 - execBin.length * 10

    // 5. Name contains query
    var nameIdx = name.indexOf(qLower)
    if (nameIdx !== -1) return 30000 - nameIdx * 100 - name.length * 10

    // 6. Generic name starts with or contains query
    if (generic.indexOf(qLower) === 0) return 20000 - generic.length * 10
    if (generic.indexOf(qLower) !== -1) return 15000 - generic.length * 10

    // 7. Fuzzy match on app name
    var fn = root.fuzzyScore(name, qLower)
    if (fn >= 0) return 10000 + fn

    // 8. Exec contains query
    if (exec.indexOf(qLower) !== -1) return 5000

    // 9. Comment contains query
    if (comment.indexOf(qLower) !== -1) return 2000

    // 10. Fuzzy match on generic name or exec
    var fg = root.fuzzyScore(generic + " " + execBin, qLower)
    if (fg >= 0) return 1000 + fg

    // 11. Fuzzy match on entire metadata
    var ft = root.fuzzyScore(name + " " + generic + " " + comment + " " + exec, qLower)
    if (ft >= 0) return 100 + ft

    return -1
  }

  function scoreSystem(item, q) {
    if (!item || !q) return 1
    var qLower = q.toLowerCase()
    var name = (item.name || "").toLowerCase()
    var comment = (item.comment || "").toLowerCase()

    if (name === qLower) return 100000
    if (name.indexOf(qLower) === 0) return 50000 - name.length * 10
    var nameIdx = name.indexOf(qLower)
    if (nameIdx !== -1) return 30000 - nameIdx * 100
    if (comment.indexOf(qLower) !== -1) return 10000
    var f = root.fuzzyScore(name + " " + comment, qLower)
    return f >= 0 ? 1000 + f : -1
  }

  function scoreSelect(label, subtext, q) {
    if (!q) return 1
    var qLower = q.toLowerCase()
    var l = (label || "").toLowerCase()
    var st = (subtext || "").toLowerCase()

    if (l === qLower) return 100000
    if (l.indexOf(qLower) === 0) return 50000 - l.length * 10
    var lIdx = l.indexOf(qLower)
    if (lIdx !== -1) return 30000 - lIdx * 100
    if (st.indexOf(qLower) !== -1) return 10000
    var f = root.fuzzyScore(l + " " + st, qLower)
    return f >= 0 ? 1000 + f : -1
  }

  function getIconSource(iconName) {
    var val = String(iconName || "").trim()
    if (!val) return ""
    if (root.shell && root.shell.appLibrary && typeof root.shell.appLibrary.iconSource === "function") {
      var s = root.shell.appLibrary.iconSource(val)
      if (s) return s
    }
    if (val.indexOf("file://") === 0) return val
    if (val.charAt(0) === "/") return "file://" + val
    var p = Quickshell.iconPath(val, true)
    if (p) return p
    return ""
  }

  readonly property var allApps: {
    if (!DesktopEntries || !DesktopEntries.applications) return []
    var list = DesktopEntries.applications.values.filter(function(a) {
      return a && !a.noDisplay && !a.hidden && a.name
    })
    var seen = {}
    var deduped = []
    for (var i = 0; i < list.length; i++) {
      var app = list[i]
      var normName = (app.name || "").trim().toLowerCase()
      var execBin = (app.execString || "").trim().split(" ")[0].split("/").pop().toLowerCase()
      var key = normName + "::" + execBin
      if (seen[key]) continue
      seen[key] = true
      deduped.push(app)
    }
    return deduped
  }

  readonly property var filteredItems: {
    var q = root.query.trim()
    var scored = []

    if (root.currentMode === "apps") {
      var apps = root.allApps
      if (apps.length === 0) return []
      for (var i = 0; i < apps.length; i++) {
        var app = apps[i]
        var s = q.length === 0 ? 1 : root.scoreApp(app, q)
        if (s >= 0) scored.push({ item: app, score: s })
      }
      if (q.length === 0) {
        scored.sort(function(a, b) {
          return (a.item.name || "").toLowerCase().localeCompare((b.item.name || "").toLowerCase())
        })
      } else {
        scored.sort(function(a, b) { return b.score - a.score })
      }
      return scored.map(function(s) { return s.item })

    } else if (root.currentMode === "system") {
      var items = root.systemMenuItems
      for (var j = 0; j < items.length; j++) {
        var item = items[j]
        var s2 = q.length === 0 ? 1 : root.scoreSystem(item, q)
        if (s2 >= 0) scored.push({ item: item, score: s2 })
      }
      if (q.length > 0) scored.sort(function(a, b) { return b.score - a.score })
      return scored.map(function(s) { return s.item })

    } else if (root.currentMode === "select") {
      var rawOptions = root.dmenuOptions
      for (var k = 0; k < rawOptions.length; k++) {
        var raw = String(rawOptions[k] || "")
        var parts = raw.split("\t")
        var glyph = parts.length > 2 ? parts[0] : ""
        var label = parts.length > 2 ? parts[1] : (parts.length > 1 ? parts[0] : raw)
        var subtext = parts.length > 2 ? parts[2] : (parts.length > 1 ? parts[1] : "")
        var obj = { raw: raw, glyph: glyph, label: label, subtext: subtext }
        var s3 = q.length === 0 ? 1 : root.scoreSelect(label, subtext, q)
        if (s3 >= 0) scored.push({ item: obj, score: s3 })
      }
      if (q.length > 0) scored.sort(function(a, b) { return b.score - a.score })
      return scored.map(function(s) { return s.item })
    }

    return []
  }

  onFilteredItemsChanged: {
    root.selected = 0
    if (itemListView) {
      itemListView.positionViewAtIndex(0, ListView.Beginning)
    }
  }

  function launchCurrent() {
    if (root.filteredItems.length === 0) return
    var cur = root.filteredItems[root.selected]
    if (!cur) return

    if (root.currentMode === "apps") {
      var appId = cur.id || ""
      var appName = cur.name || ""
      root.showing = false
      if (root.shell && root.shell.appLibrary && typeof root.shell.appLibrary.launch === "function") {
        root.shell.appLibrary.launch(appId, appName)
      } else {
        Quickshell.execDetached(cur.execString)
      }
      root.close()

    } else if (root.currentMode === "system") {
      var cmd = cur.cmd || ""
      root.showing = false
      if (cmd) Quickshell.execDetached(["bash", "-c", cmd])
      root.close()

    } else if (root.currentMode === "select") {
      var val = cur.raw || cur.label || ""
      root.showing = false
      if (root.selectionFile && root.doneFile) {
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" > \"$2\"; touch \"$3\"", "_", val, root.selectionFile, root.doneFile])
      }
      root.close()
    }
  }

  PanelWindow {
    id: window
    visible: root.showing
    width: Screen.width
    height: Screen.height

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "omarchy-menu"

    color: "transparent"

    onVisibleChanged: {
      if (visible && searchInput) {
        Qt.callLater(function() {
          searchInput.forceActiveFocus()
        })
      }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.close()
    }

    Rectangle {
      id: menuBox
      anchors.centerIn: parent
      width: root.menuWidth
      radius: root.cornerRadius
      color: root.bg
      border.color: root.borderCol
      border.width: 1

      readonly property int maxVisibleCount: root.currentMode === "select" ? 10 : 8
      readonly property int itemRowHeight: root.currentMode === "select" ? 40 : 48
      readonly property int currentItemCount: root.filteredItems ? root.filteredItems.length : 0
      readonly property int displayCount: Math.min(currentItemCount, maxVisibleCount)
      readonly property int listContentHeight: currentItemCount === 0 ? (root.query.length > 0 ? 44 : 0) : (displayCount * itemRowHeight)
      readonly property int calculatedHeight: 110 + listContentHeight

      height: calculatedHeight

      Behavior on height {
        enabled: root.showing
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: function(mouse) { mouse.accepted = true }
      }

      Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Search Bar Container
        Rectangle {
          width: parent.width
          height: 44
          radius: Math.max(4, root.cornerRadius - 4)
          color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.05)
          border.color: searchInput.activeFocus ? root.selectedBg : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)
          border.width: 1

          Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: root.currentMode === "system" ? "󰐥" : (root.currentMode === "select" ? "󰘔" : "󰍉")
              font.family: root.fontFamily
              font.pixelSize: 16
              color: root.faintFg
            }

            TextInput {
              id: searchInput
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - 32
              clip: true
              color: root.fg
              font.family: root.fontFamily
              font.pixelSize: 14
              selectionColor: root.selectedBg
              selectedTextColor: root.selectedFg
              focus: true

              Text {
                text: root.currentMode === "system" ? "System actions..." : (root.currentMode === "select" ? (root.dmenuPrompt + "...") : "Type to search...")
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
                  if (root.filteredItems.length > 0) {
                    root.selected = (root.selected + 1) % root.filteredItems.length
                    itemListView.positionViewAtIndex(root.selected, ListView.Contain)
                  }
                  event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                  if (root.filteredItems.length > 0) {
                    root.selected = (root.selected - 1 + root.filteredItems.length) % root.filteredItems.length
                    itemListView.positionViewAtIndex(root.selected, ListView.Contain)
                  }
                  event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                  root.launchCurrent()
                  event.accepted = true
                } else if (event.key === Qt.Key_PageDown) {
                  if (root.filteredItems.length > 0) {
                    root.selected = Math.min(root.selected + 6, root.filteredItems.length - 1)
                    itemListView.positionViewAtIndex(root.selected, ListView.Contain)
                  }
                  event.accepted = true
                } else if (event.key === Qt.Key_PageUp) {
                  if (root.filteredItems.length > 0) {
                    root.selected = Math.max(root.selected - 6, 0)
                    itemListView.positionViewAtIndex(root.selected, ListView.Contain)
                  }
                  event.accepted = true
                }
              }
            }
          }
        }

        // List View
        ListView {
          id: itemListView
          width: parent.width
          height: Math.max(0, menuBox.height - 110)
          clip: true
          model: root.filteredItems
          currentIndex: root.selected
          spacing: 2
          boundsBehavior: Flickable.StopAtBounds

          Text {
            anchors.centerIn: parent
            text: "No matching results"
            font.family: root.fontFamily
            font.pixelSize: 13
            color: root.faintFg
            visible: root.filteredItems.length === 0 && root.query.length > 0
          }

          onCurrentIndexChanged: {
            if (currentIndex >= 0 && currentIndex < count) {
              positionViewAtIndex(currentIndex, ListView.Contain)
            }
          }

          delegate: Rectangle {
            required property var modelData
            required property int index

            readonly property bool isSelected: index === root.selected

            width: itemListView.width
            height: root.currentMode === "select" ? 38 : 46
            radius: Math.max(4, root.cornerRadius - 6)
            color: isSelected ? root.selectedBg : "transparent"

            Row {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 12

              // Icon Column
              Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28

                // For Applications
                Image {
                  id: appIconImg
                  anchors.fill: parent
                  sourceSize: Qt.size(28, 28)
                  source: root.currentMode === "apps" ? root.getIconSource(modelData ? modelData.icon : "") : ""
                  visible: root.currentMode === "apps" && status === Image.Ready
                  fillMode: Image.PreserveAspectFit
                }

                // Fallback glyph/letter or System/Select glyph
                Rectangle {
                  anchors.fill: parent
                  radius: 6
                  color: isSelected ? Qt.rgba(root.selectedFg.r, root.selectedFg.g, root.selectedFg.b, 0.2) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08)
                  visible: !appIconImg.visible

                  Text {
                    anchors.centerIn: parent
                    text: {
                      if (root.currentMode === "system") return modelData.iconGlyph || "󰐥"
                      if (root.currentMode === "select") return modelData.glyph || "󰘔"
                      return (modelData && modelData.name && modelData.name.length > 0) ? modelData.name.charAt(0).toUpperCase() : "?"
                    }
                    color: isSelected ? root.selectedFg : root.fg
                    font.family: root.fontFamily
                    font.pixelSize: (root.currentMode === "system" || root.currentMode === "select") ? 16 : 13
                    font.bold: true
                  }
                }
              }

              // Text Labels
              Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 40
                spacing: 2

                Text {
                  width: parent.width
                  text: {
                    if (root.currentMode === "system") return modelData.name || ""
                    if (root.currentMode === "select") return modelData.label || ""
                    return (modelData && modelData.name) ? modelData.name : ""
                  }
                  color: isSelected ? root.selectedFg : root.fg
                  font.family: root.fontFamily
                  font.pixelSize: 13
                  font.bold: isSelected
                  elide: Text.ElideRight
                }

                Text {
                  width: parent.width
                  visible: {
                    if (root.currentMode === "system") return !!modelData.comment
                    if (root.currentMode === "select") return !!modelData.subtext
                    return !!(modelData && (modelData.genericName || modelData.comment))
                  }
                  text: {
                    if (root.currentMode === "system") return modelData.comment || ""
                    if (root.currentMode === "select") return modelData.subtext || ""
                    return (modelData && (modelData.genericName || modelData.comment)) ? (modelData.genericName || modelData.comment) : ""
                  }
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
              property int lastX: -1
              property int lastY: -1
              onPositionChanged: function(mouse) {
                if (lastX >= 0 && (Math.abs(mouse.x - lastX) > 4 || Math.abs(mouse.y - lastY) > 4)) {
                  root.selected = index
                }
                lastX = mouse.x
                lastY = mouse.y
              }
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
            text: "↵ Select / Launch"
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
