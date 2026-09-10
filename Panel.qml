import QtQuick
import qs.Commons
import qs.Ui

// Cheat-sheet popup for the Workspace Mode widget: stock window-management
// shortcuts. Static by design — no runtime parsing, nothing to fail.
Panel {
  id: root
  moduleName: "io.github.adevade.workspace-mode"
  manageIpc: false

  property var anchorItem: null

  // The bar tracks the widget mounted in its slot — BarWidget.qml — not this
  // nested panel. Everything the bar identifies a panel by has to be that
  // widget: the popout coordinator compares against `slot.activeItem`, and
  // switchPanelFrom looks the slot up the same way.
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  // [keys, what] rows. Stock Omarchy defaults.
  readonly property var rows: [
    ["Super + F", "Fullscreen"],
    ["Super + Alt + F", "Full width (maximized)"],
    ["Super + Ctrl + F", "Tiled fullscreen"],
    ["Super + T", "Float / tile window"],
    ["Super + O", "Pop out (float + pin)"],
    ["Super + P", "Pseudo window"],
    ["Super + J", "Toggle split direction"],
    ["Super + L", "Workspace layout"],
    ["Super + G", "Group windows"],
    ["Super + Alt + G", "Move window out of group"],
    ["Super + Alt + Home", "Save window width"],
    ["Super + Home", "Restore window width"],
  ]

  function open() {
    root.controller.show()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(6)

        Text {
          textFormat: Text.PlainText
          text: "WINDOW SHORTCUTS"
          color: Qt.darker(root.contentForeground, 1.5)
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.caption
          font.letterSpacing: 1
          font.bold: true
        }

        Repeater {
          model: root.rows

          Row {
            required property var modelData
            spacing: Style.space(12)

            Text {
              textFormat: Text.PlainText
              width: Style.space(150)
              horizontalAlignment: Text.AlignRight
              text: modelData[0]
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }

            Text {
              textFormat: Text.PlainText
              text: modelData[1]
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
            }
          }
        }
      }
    }
  }
}
