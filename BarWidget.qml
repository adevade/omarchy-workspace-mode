import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Ui
import "Model.js" as Model

// Workspace Mode: layout + focused-window codes for this monitor's workspace.
// The vocabulary (codes, words, priority) lives in Model.js; this file only
// wires Hyprland objects to it and paints the results.
// Two hover zones with their own tooltips; click either for the shortcut cheat sheet.
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

  // ---- State, via Model.js ----
  readonly property var layout: Model.layoutState(wsIpc.tiledLayout)
  readonly property var focusedTop: Model.pickFocusedWindow(ws, lastAddr)
  readonly property var win: Model.windowState(focusedTop && focusedTop.lastIpcObject ? focusedTop.lastIpcObject : null)
  readonly property bool hasWindow: win.code !== ""

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
      text: root.layout.code
      tooltipText: root.layout.word + " layout"
      onPressed: function(button) { root.togglePanel(button) }
    }

    // No `visible` override: empty text already auto-hides the button via
    // WidgetButton.hasVisualContent, which is exactly the empty-workspace case.
    WidgetButton {
      bar: root.bar
      text: root.win.code
      tooltipText: root.win.word
      onPressed: function(button) { root.togglePanel(button) }
    }
  }
}
