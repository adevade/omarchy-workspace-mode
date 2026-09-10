// Vocabulary + IPC interpretation for the Workspace Mode widget.
//
// Everything the bar, tooltips, and panel can show is defined here, so a
// future state (or a renamed code) is a one-spot edit. The QML only wires
// Hyprland objects into these functions and paints the results.

// [layout] DWD = dwindle (the default), SCR = anything else (scrolling).
function layoutState(tiledLayout) {
  if (!!tiledLayout && String(tiledLayout).toLowerCase() !== "dwindle")
    return { code: "SCR", word: "Scrolling" };
  return { code: "DWD", word: "Dwindle" };
}

// [window] Top priority wins: FUL > MAX > TFS > PIN > FLT > TIL.
// A null ipc means no focused window: empty code, and the bar shows layout only.
// ponytail: Hyprland IPC (0.56.2) exposes no pseudo flag, so Super+P stays invisible.
function windowState(ipc) {
  if (!ipc) return { code: "", word: "" };
  var fs = Number(ipc.fullscreen || 0);
  var fc = Number(ipc.fullscreenClient || 0);
  if (fs >= 2) return { code: "FUL", word: "Fullscreen" };
  if (fs === 1) return { code: "MAX", word: "Maximized (full-width)" };
  if (fc === 2) return { code: "TFS", word: "Tiled fullscreen" };
  if (ipc.pinned === true && ipc.floating === true) return { code: "PIN", word: "Popped out (pinned)" };
  if (ipc.floating === true) return { code: "FLT", word: "Floating" };
  return { code: "TIL", word: "Tiled" };
}

// [focus] The activated toplevel on this workspace, else the workspace's
// lastwindow matched by address (Hyprland reports "0x…", Quickshell bare hex).
function pickFocusedWindow(ws, lastwindow) {
  var values = ws && ws.toplevels && ws.toplevels.values ? ws.toplevels.values : null;
  if (!values || !values.length) return null;
  var want = normAddr(lastwindow);
  var fallback = null;
  for (var i = 0; i < values.length; i++) {
    var t = values[i];
    if (!t) continue;
    if (t.activated === true) return t;
    if (want !== "" && normAddr(t.address) === want) fallback = t;
  }
  return fallback;
}

function normAddr(a) {
  var s = String(a || "").toLowerCase();
  return s.indexOf("0x") === 0 ? s.slice(2) : s;
}
