import QtQuick
import Quickshell
import "lib/Score.js" as Score
import "lib/Frecency.js" as Frecency
import "lib/ViewModel.js" as VM
import "lib/Apps.js" as Apps

// Lightweight application launcher core. Exclusively indexes desktop apps.
Item {
  id: root
  width: 0
  height: 0
  visible: false

  property var appLibrary: null
  property var dock: null

  readonly property string home: Quickshell.env("HOME")
  readonly property string configDir: home + "/.config/omarchy-launcher"
  readonly property string stateDir: home + "/.local/state/omarchy-launcher"

  property var entries: []
  property var appEntries: []
  property int indexRevision: 0

  property var frecencyData: Frecency.empty()
  property var settings: ({ favoritesOrder: [] })
  property var searchHistoryList: []
  property bool windowOpen: false

  signal indexChanged()

  function now() { return Math.floor(Date.now() / 1000) }

  function favoritesOrder() {
    var l = root.settings && Array.isArray(root.settings.favoritesOrder) ? root.settings.favoritesOrder : []
    return l.map(String)
  }

  function setFavoritesOrder(list) {
    var next = Object.assign({}, root.settings)
    next.favoritesOrder = list
    root.settings = next
    root.rebuildIndex()
  }

  function toggleFavorite(entryId, win) {
    var l = root.favoritesOrder()
    var idx = l.indexOf(entryId)
    if (idx >= 0) l.splice(idx, 1)
    else l.unshift(entryId)
    root.setFavoritesOrder(l)
    if (win) win.onSearchEdited(win.searchTextValue())
  }

  function moveFavorite(entryId, delta) {
    var l = root.favoritesOrder()
    var idx = l.indexOf(entryId)
    if (idx < 0) return false
    var nidx = Math.max(0, Math.min(l.length - 1, idx + delta))
    if (nidx === idx) return false
    var item = l.splice(idx, 1)[0]
    l.splice(nidx, 0, item)
    root.setFavoritesOrder(l)
    return true
  }

  function rebuildIndex() {
    var favs = root.favoritesOrder()
    var favSet = {}
    for (var f = 0; f < favs.length; f++) favSet[favs[f]] = true
    for (var i = 0; i < root.appEntries.length; i++) {
      var e = root.appEntries[i]
      e.favorite = !!favSet[e.id]
      Score.prepare(e)
    }
    root.entries = root.appEntries
    root.indexRevision += 1
    root.indexChanged()
  }

  function entryById(id) {
    for (var i = 0; i < root.entries.length; i++) {
      if (root.entries[i].id === id) return root.entries[i]
    }
    return null
  }

  function entryRow(e) {
    var acc = []
    if (e.accessoryText) acc.push({ text: e.accessoryText })
    return {
      id: e.id,
      title: e.title,
      subtitle: e.subtitle,
      icon: e.icon,
      keywords: e.keywords,
      accessories: acc,
      data: { entryId: e.id }
    }
  }

  function rootView(query) {
    var sections = []
    var q = String(query || "").trim()

    if (!q) {
      var favs = []
      var rest = []
      for (var i = 0; i < root.entries.length; i++) {
        var app = root.entries[i]
        if (app.favorite) favs.push(root.entryRow(app))
        else rest.push(root.entryRow(app))
      }
      if (favs.length > 0) sections.push({ id: "favorites", title: "Favorites", items: favs })
      if (rest.length > 0) sections.push({ id: "apps", title: favs.length > 0 ? "Applications" : "", items: rest })
    } else {
      var scores = Frecency.scores(root.frecencyData, root.now())
      var ranked = Score.rank(root.entries, q, scores, 50)
      var rows = []
      for (var r = 0; r < ranked.length; r++) {
        rows.push(root.entryRow(ranked[r].entry))
      }
      if (rows.length > 0) sections.push({ id: "results", title: "", items: rows })
    }

    return VM.normalizeView({
      id: "root",
      type: "list",
      filtering: false,
      searchBarPlaceholder: "Search apps…",
      searchText: q,
      isLoading: false,
      sections: sections,
      emptyView: { icon: "󰍉", title: q ? "No apps found for “" + q + "”" : "No applications installed" }
    })
  }

  function activateEntry(entry, win) {
    if (!entry) return false
    root.recordUse(entry.id)
    if (typeof entry.run === "function") {
      entry.run(entry, win)
    }
    return true
  }

  function entryActions(entry) {
    var self = root
    var primary = {
      id: "primary",
      title: "Open",
      icon: "󰏌",
      run: function(item, win) { return !self.activateEntry(entry, win) }
    }
    var secondary = [
      {
        id: "favorite",
        title: entry.favorite ? "Remove from Favorites" : "Add to Favorites",
        icon: entry.favorite ? "󰓎" : "󰓒",
        shortcut: { modifiers: ["ctrl", "shift"], key: "f", label: "⌃⇧F" },
        run: function(item, win) { self.toggleFavorite(entry.id, win); return true }
      },
      {
        id: "copy-name",
        title: "Copy Application Name",
        icon: "󰆏",
        run: function() { Quickshell.execDetached(["wl-copy", "--", entry.title]); return false }
      }
    ]
    return { title: entry.title, sections: [{ actions: [primary].concat(secondary) }] }
  }

  function recordUse(id) {
    root.frecencyData = Frecency.record(root.frecencyData, id, root.now())
  }

  function launchApp(desktopId, title) {
    if (root.appLibrary && typeof root.appLibrary.launch === "function") {
      root.appLibrary.launch(desktopId, title)
    } else {
      Quickshell.execDetached(["gtk-launch", desktopId + ".desktop"])
    }
  }

  function iconSource(icon) {
    if (root.appLibrary && typeof root.appLibrary.iconSource === "function") {
      return root.appLibrary.iconSource(icon)
    }
    var value = String(icon || "")
    if (!value) return Quickshell.iconPath("application-x-executable", true)
    if (value.indexOf("file://") === 0 || value.indexOf("image://") === 0) return value
    if (value.charAt(0) === "/") return "file://" + value
    var themed = Quickshell.iconPath(value, true)
    return themed || Quickshell.iconPath("application-x-executable", true)
  }

  function onWindowOpened() {
    if (root.appEntries.length === 0) root.rebuildApps()
  }

  function onWindowClosed() {
  }

  function recordSearch(query) {
    var q = String(query || "").trim()
    if (!q) return
    var list = root.searchHistoryList.slice()
    var idx = list.indexOf(q)
    if (idx >= 0) list.splice(idx, 1)
    list.unshift(q)
    if (list.length > 50) list = list.slice(0, 50)
    root.searchHistoryList = list
  }

  function searchHistory() {
    return root.searchHistoryList
  }

  function rebuildApps() {
    var values = []
    try { values = DesktopEntries.applications.values || [] } catch (e) { values = [] }
    var out = []
    for (var i = 0; i < values.length; i++) {
      var app = values[i]
      if (!app || app.noDisplay) continue
      var id = Apps.normalizeDesktopId(app.id)
      if (!id) continue
      var name = String(app.name || id)
      var kw = Apps.listToArray(app.keywords)
      if (app.comment) kw.push(String(app.comment))
      if (app.genericName) kw.push(String(app.genericName))
      out.push({
        id: "app:" + id,
        kind: "app",
        title: name,
        subtitle: String(app.genericName || app.comment || ""),
        keywords: kw,
        aliases: [],
        baseAliases: [],
        icon: { kind: "app", value: String(app.icon || "") },
        accessoryText: "Application",
        enabled: true,
        favorite: false,
        primaryTitle: "Open",
        desktopId: id,
        run: function(e) { root.launchApp(e.desktopId, e.title) }
      })
    }
    out.sort(function(a, b) {
      return a.title.localeCompare(b.title, undefined, { sensitivity: "base" })
    })
    for (var j = 0; j < out.length; j++) {
      Score.prepare(out[j])
    }
    root.appEntries = out
    root.entries = out
    root.rebuildIndex()
  }

  Connections {
    target: DesktopEntries.applications
    ignoreUnknownSignals: true
    function onValuesChanged() { root.rebuildApps() }
  }

  Component.onCompleted: {
    root.rebuildApps()
  }
}
