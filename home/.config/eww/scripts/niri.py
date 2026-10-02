#!/usr/bin/env python3
"""niri event-stream -> one JSON line per state change.

  niri.py ws    {"ws": {output: [workspace...]}}       for `deflisten niri` (workspace buttons)
  niri.py win   {"win": {output: window|null}}         for `deflisten niriwin` (window title)
The `ws` instance also records when each app's window first opens (OPENED), so the launcher's
"Recent" sort reflects apps opened any way, not only from the launcher.
Separate streams because eww rebuilds every workspace button whenever the variable its `for`
reads changes, and window titles (terminal spinners, browser tabs) change many times a second.
"""
import json
import os
import socket
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from xdgicons import app_for_id, app_icon, app_name  # noqa: E402

OPENED = os.path.expanduser("~/.local/state/eww/apps-opened.json")

workspaces: dict[int, dict] = {}
windows: dict[int, dict] = {}
MODE = sys.argv[1] if len(sys.argv) > 1 else "ws"
last = None


def record_open(app_id: str):
    info = app_for_id(app_id or "")
    if info is None:
        return
    try:
        with open(OPENED) as f:
            opened = json.load(f)
    except (OSError, ValueError):
        opened = {}
    opened[info.get_id()] = time.time()
    os.makedirs(os.path.dirname(OPENED), exist_ok=True)
    with open(OPENED + ".tmp", "w") as f:
        json.dump(opened, f)
    os.replace(OPENED + ".tmp", OPENED)


def label_safe(s: str) -> str:
    """eww runs label :text through unescape, so a lone backslash must be doubled to survive."""
    return s.replace("\\", "\\\\")


def window_view(w: dict | None) -> dict | None:
    if not w:
        return None
    app_id = w.get("app_id") or ""
    return {
        "id": w["id"],
        "title": label_safe(w.get("title") or ""),
        "app_id": app_id,
        "app": label_safe(app_name(app_id)),
        "icon": app_icon(app_id, 48),
        "floating": w.get("is_floating", False),
    }


def snapshot() -> dict:
    per_output: dict[str, list] = {}
    counts: dict[int, int] = {}
    urgent_ws: set[int] = set()
    for w in windows.values():
        wid = w.get("workspace_id")
        if wid is not None:
            counts[wid] = counts.get(wid, 0) + 1
            if w.get("is_urgent"):
                urgent_ws.add(wid)
    focused_win = {}
    for ws in sorted(workspaces.values(), key=lambda x: (x.get("output") or "", x["idx"])):
        out = ws.get("output") or ""
        per_output.setdefault(out, []).append({
            "id": ws["id"],
            "idx": ws["idx"],
            "name": ws.get("name") or "",
            "active": ws["is_active"],
            "focused": ws["is_focused"],
            "urgent": ws.get("is_urgent", False) or ws["id"] in urgent_ws,
            "wins": counts.get(ws["id"], 0),
        })
        if ws["is_active"]:
            focused_win[out] = window_view(windows.get(ws.get("active_window_id")))
    return {"ws": per_output} if MODE == "ws" else {"win": focused_win}


def emit():
    global last
    line = json.dumps(snapshot(), separators=(",", ":"))
    if line != last:
        last = line
        print(line, flush=True)


def apply(name: str, ev: dict):
    if name == "WorkspacesChanged":
        workspaces.clear()
        workspaces.update({w["id"]: w for w in ev["workspaces"]})
    elif name == "WorkspaceActivated":
        target = workspaces.get(ev["id"])
        if target is None:
            return
        for w in workspaces.values():
            if w.get("output") == target.get("output"):
                w["is_active"] = w["id"] == ev["id"]
            if ev["focused"]:
                w["is_focused"] = w["id"] == ev["id"]
    elif name == "WorkspaceActiveWindowChanged":
        if ev["workspace_id"] in workspaces:
            workspaces[ev["workspace_id"]]["active_window_id"] = ev["active_window_id"]
    elif name == "WorkspaceUrgencyChanged":
        if ev["id"] in workspaces:
            workspaces[ev["id"]]["is_urgent"] = ev["urgent"]
    elif name == "WindowsChanged":
        windows.clear()
        windows.update({w["id"]: w for w in ev["windows"]})
        if MODE == "ws" and not os.path.exists(OPENED):  # first run: seed with what is open now
            for w in ev["windows"]:
                record_open(w.get("app_id") or "")
    elif name == "WindowOpenedOrChanged":
        w = ev["window"]
        # Windows present at startup arrive via WindowsChanged, so only real opens land here as new ids.
        if MODE == "ws" and w["id"] not in windows:
            record_open(w.get("app_id") or "")
        if w.get("is_focused"):
            for other in windows.values():
                other["is_focused"] = False
        windows[w["id"]] = w
    elif name == "WindowClosed":
        windows.pop(ev["id"], None)
    elif name == "WindowFocusChanged":
        for w in windows.values():
            w["is_focused"] = w["id"] == ev["id"]
    elif name == "WindowUrgencyChanged":
        if ev["id"] in windows:
            windows[ev["id"]]["is_urgent"] = ev["urgent"]
    else:
        return
    emit()


def main():
    sock = socket.socket(socket.AF_UNIX)
    sock.connect(os.environ["NIRI_SOCKET"])
    stream = sock.makefile("rw")
    stream.write('"EventStream"\n')
    stream.flush()
    stream.readline()  # {"Ok":"Handled"}
    for line in stream:
        (name, payload), = json.loads(line).items()
        apply(name, payload)


if __name__ == "__main__":
    main()
