import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Ui

// Workspace Mode: layout + focused-window codes for this monitor's workspace.
// Layout: DWD / SCR. Window, top priority wins: FUL > MAX > TFS > PIN > FLT > TIL.
// Two hover zones with their own teaching tooltips. Display-only.
BarWidget {
  id: root
  moduleName: "io.github.adevade.workspace-mode"

  // Same faded look as an inactive workspace number (Workspaces.qml: 0.5).
  opacity: 0.5

  // ---- This monitor's workspace ----
  // This bar surface's monitor, so each screen reports its own workspace.
  readonly property var hostScreen: root.QsWindow.window ? root.QsWindow.window.screen : null
  readonly property var hyprMonitor: hostScreen ? Hyprland.monitorFor(hostScreen) : null
  readonly property var monitor: hyprMonitor ? hyprMonitor : Hyprland.focusedMonitor
  readonly property var ws: monitor ? monitor.activeWorkspace : Hyprland.focusedWorkspace

  readonly property var wsIpc: ws && ws.lastIpcObject ? ws.lastIpcObject : ({})
  readonly property string lastAddr: wsIpc.lastwindow ? String(wsIpc.lastwindow) : ""
  readonly property bool scrolling: wsIpc.tiledLayout ? String(wsIpc.tiledLayout).toLowerCase() !== "dwindle" : false
  readonly property string layoutCode: scrolling ? "SCR" : "DWD"
  readonly property string layoutWord: scrolling ? "Scrolling" : "Dwindle"

  function normAddr(a) {
    var s = String(a || "").toLowerCase()
    return s.indexOf("0x") === 0 ? s.slice(2) : s
  }

  // ---- Focused window on this workspace ----
  // The activated toplevel, else the workspace's lastwindow matched by address.
  readonly property var focusedTop: {
    if (!ws || !ws.toplevels || !ws.toplevels.values) return null
    var list = ws.toplevels.values
    var fallback = null
    var want = normAddr(lastAddr)
    for (var i = 0; i < list.length; i++) {
      var t = list[i]
      if (!t) continue
      if (t.activated === true) return t
      if (want !== "" && normAddr(t.address) === want) fallback = t
    }
    return fallback
  }

  readonly property var winIpc: focusedTop && focusedTop.lastIpcObject ? focusedTop.lastIpcObject : null

  // ponytail: Hyprland IPC (0.56.2) exposes no pseudo flag, so Super+P state stays invisible.
  readonly property string winCode: {
    if (!focusedTop || !winIpc) return ""
    var fs = Number(winIpc.fullscreen || 0)
    var fc = Number(winIpc.fullscreenClient || 0)
    if (fs >= 2) return "FUL"
    if (fs === 1) return "MAX"
    if (fc === 2) return "TFS"
    if (winIpc.pinned === true && winIpc.floating === true) return "PIN"
    if (winIpc.floating === true) return "FLT"
    return "TIL"
  }

  readonly property string winWord: {
    if (winCode === "MAX") return "Maximized (full-width)"
    if (winCode === "FUL") return "Fullscreen"
    if (winCode === "TFS") return "Tiled fullscreen"
    if (winCode === "FLT") return "Floating"
    if (winCode === "PIN") return "Popped out (pinned)"
    return "Tiled"
  }

  readonly property bool hasWindow: winCode !== ""

  // ---- Refresh ----
  // lastIpcObject only refreshes on explicit refresh; poke it on every
  // Hyprland event (debounced) plus a slow safety poll. Monitor IPC is never
  // read (only the activeWorkspace identity, which tracks events natively),
  // so it stays out of the hot path.
  function refreshIpc() {
    Hyprland.refreshWorkspaces()
    Hyprland.refreshToplevels()
  }

  Timer {
    id: refreshDebounce
    interval: 120
    repeat: false
    onTriggered: root.refreshIpc()
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: root.refreshIpc()
  }

  Connections {
    target: Hyprland
    function onRawEvent() { refreshDebounce.restart() }
  }

  Component.onCompleted: root.refreshIpc()

  // ---- Cheat-sheet panel. Shape contract for shell.summon/hide/toggle
  //      routing: Bar.findPanelWidget requires open/close/opened on the
  //      bar-widget root.
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  // Forwarded so this widget can stand in for the panel as the bar's popout
  // identity: Bar.requestPopout prefers closeForPopoutSwitch over close, and
  // KeyboardPanel reads popoutSwitchClosing back off its owner.
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("anchorItem" in target) target.anchorItem = grid
    if ("hostWidget" in target) target.hostWidget = root
  }

  function togglePanel(button) {
    if (button === Qt.LeftButton) root.toggle()
  }

  implicitWidth: grid.implicitWidth
  implicitHeight: grid.implicitHeight

  onBarChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  Grid {
    id: grid
    anchors.centerIn: parent
    columns: root.vertical ? 1 : 2
    rows: root.vertical ? (root.hasWindow ? 2 : 1) : 1

    WidgetButton {
      bar: root.bar
      text: root.layoutCode
      tooltipText: root.layoutWord + " layout"
      onPressed: function(button) { root.togglePanel(button) }
    }

    // No `visible` override: empty text already auto-hides the button via
    // WidgetButton.hasVisualContent, which is exactly the empty-workspace case.
    WidgetButton {
      bar: root.bar
      text: root.winCode
      tooltipText: root.winWord
      onPressed: function(button) { root.togglePanel(button) }
    }
  }
}
