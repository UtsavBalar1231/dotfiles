#!/usr/bin/env python3
"""org.freedesktop.Notifications server for the eww shell.

  notifd.py         run the daemon (D-Bus activated via ~/.local/share/dbus-1/services)
  notifd.py watch   stream the daemon state as JSON lines, for `deflisten`

Control methods live on the dev.eww.Notifd interface, e.g.
  busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications \
      dev.eww.Notifd Dismiss u 12
Actions are invoked by index (InvokeIndex) so app-chosen action keys never reach a shell.
"""
import html
import json
import os
import re
import sys
import time

import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

BUS = "org.freedesktop.Notifications"
PATH = "/org/freedesktop/Notifications"
CTL = "dev.eww.Notifd"
CACHE = os.path.join(os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "eww", "notifd")
HISTORY = os.path.join(CACHE, "history.json")

POPUP_MS = {0: 3000, 1: 5000, 2: 8000}  # by urgency: low, normal, critical
LEAVE_MS = 260  # a little longer than the 200ms notif-out keyframes in scss/_components.scss
FRESH_S = 0.5
MAX_POPUPS = 4
MAX_HISTORY = 60
BODY_LIMIT = 600

CLOSE_EXPIRED, CLOSE_DISMISSED, CLOSE_CALL = 1, 2, 3


def plain(text: str) -> str:
    text = re.sub(r"<br\s*/?>", "\n", text or "", flags=re.I)
    text = html.unescape(re.sub(r"<[^>]+>", "", text))
    return text.strip()[:BODY_LIMIT]


class Daemon(dbus.service.Object):
    def __init__(self, bus):
        name = dbus.service.BusName(BUS, bus, allow_replacement=True, replace_existing=True, do_not_queue=True)
        super().__init__(name, PATH)
        os.makedirs(CACHE, exist_ok=True)
        self.items: dict[int, dict] = {}
        self.timers: dict[int, int] = {}
        self.dnd = False
        self._save_pending = False
        self._load()
        self.next_id = max(self.items, default=0) + 1

    def _load(self):
        try:
            with open(HISTORY) as f:
                data = json.load(f)
        except (OSError, ValueError):
            return
        self.dnd = bool(data.get("dnd", False))
        for n in data.get("history", []):
            n.update(popup=False, leaving=False)
            self.items[int(n["id"])] = n

    def _save(self):
        self._save_pending = False
        keep = [n for n in self.items.values() if not n.get("transient")][-MAX_HISTORY:]
        tmp = HISTORY + ".tmp"
        with open(tmp, "w") as f:
            json.dump({"dnd": self.dnd, "history": keep}, f)
        os.replace(tmp, HISTORY)
        live = {n["image"] for n in self.items.values() if n.get("image", "").startswith(CACHE)}
        for fname in os.listdir(CACHE):
            p = os.path.join(CACHE, fname)
            if fname.endswith(".png") and p not in live:
                os.unlink(p)
        return False

    def state(self) -> str:
        now = time.time()
        ordered = sorted(self.items.values(), key=lambda n: n["time"])
        view = lambda n: {**n, "fresh": now - n["time"] < FRESH_S}  # noqa: E731
        popups = [view(n) for n in ordered if n.get("popup")][-MAX_POPUPS:]
        history = [view(n) for n in reversed(ordered)]
        return json.dumps({"dnd": self.dnd, "count": len(history), "popups": popups, "history": history},
                          separators=(",", ":"))

    def changed(self):
        self._prune()  # here, not only on Notify: items become prunable later, when their popup ends
        self.StateChanged(self.state())
        if not self._save_pending:
            self._save_pending = True
            GLib.timeout_add(800, self._save)

    def _cancel_timer(self, nid: int):
        if (src := self.timers.pop(nid, None)) is not None:
            GLib.source_remove(src)

    def _arm(self, nid: int, ms: int):
        self._cancel_timer(nid)
        if ms > 0:
            self.timers[nid] = GLib.timeout_add(ms, self._expire, nid)

    def _expire(self, nid: int):
        self.timers.pop(nid, None)
        self._hide_popup(nid)
        return False

    def _hide_popup(self, nid: int):
        n = self.items.get(nid)
        if not n or not n.get("popup") or n.get("leaving"):
            return
        n["leaving"] = True
        self.changed()
        GLib.timeout_add(LEAVE_MS, self._finish_hide, nid)

    def _finish_hide(self, nid: int):
        n = self.items.get(nid)
        if n and n.get("leaving"):  # a replacement that arrived meanwhile is not leaving
            n.update(popup=False, leaving=False)
            if n.get("transient"):
                self._remove(nid, CLOSE_EXPIRED, notify=False)
            self.changed()
        return False

    def _remove(self, nid: int, reason: int, notify: bool = True):
        self._cancel_timer(nid)
        if self.items.pop(nid, None) is not None:
            self.NotificationClosed(dbus.UInt32(nid), dbus.UInt32(reason))
            if notify:
                self.changed()

    def _prune(self):
        """Keep memory bounded like the on-disk history: drop the oldest items not on screen."""
        excess = len(self.items) - MAX_HISTORY
        if excess <= 0:
            return
        idle = sorted((n for n in self.items.values() if not n.get("popup")), key=lambda n: n["time"])
        for n in idle[:excess]:
            self._remove(n["id"], CLOSE_EXPIRED, notify=False)

    def _image(self, nid: int, hints) -> str:
        raw = hints.get("image-data") or hints.get("image_data") or hints.get("icon_data")
        if raw is not None:
            try:
                from gi.repository import GdkPixbuf

                w, h, stride, alpha, bps, _ch, data = raw
                pix = GdkPixbuf.Pixbuf.new_from_bytes(GLib.Bytes.new(bytes(data)), GdkPixbuf.Colorspace.RGB,
                                                      bool(alpha), int(bps), int(w), int(h), int(stride))
                if pix is None:
                    raise ValueError("inconsistent image-data dimensions")
                path = os.path.join(CACHE, f"{nid}-{int(time.time() * 1000)}.png")
                pix.savev(path, "png", [], [])
                return path
            except (GLib.Error, ValueError, TypeError) as e:
                print(f"notifd: bad image-data: {e}", file=sys.stderr)
        path = str(hints.get("image-path") or hints.get("image_path") or "")
        if path.startswith("file://"):
            path = path[7:]
        return path if path.startswith("/") and os.path.exists(path) else ""

    def _sync_target(self, hints) -> int | None:
        key = str(hints.get("x-canonical-private-synchronous") or hints.get("synchronous") or "")
        if not key:
            return None
        return next((nid for nid, n in self.items.items() if n.get("sync") == key), None)

    @dbus.service.method(BUS, in_signature="", out_signature="as")
    def GetCapabilities(self):
        return ["body", "actions", "icon-static", "persistence", "x-canonical-private-synchronous"]

    @dbus.service.method(BUS, in_signature="", out_signature="ssss")
    def GetServerInformation(self):
        return ("eww-notifd", "eww", "1.0", "1.2")

    @dbus.service.method(BUS, in_signature="susssasa{sv}i", out_signature="u", byte_arrays=True)
    def Notify(self, app_name, replaces_id, app_icon, summary, body, actions, hints, expire_timeout):
        nid = int(replaces_id) or self._sync_target(hints) or 0
        if not nid:
            nid, self.next_id = self.next_id, self.next_id + 1
        urgency = int(hints.get("urgency", 1))
        value = hints.get("value")
        n = {
            "id": nid,
            "app": str(app_name or ""),
            "summary": plain(str(summary)),
            "body": plain(str(body)),
            "icon": str(app_icon or ""),
            "desktop": str(hints.get("desktop-entry", "") or ""),
            "image": self._image(nid, hints),
            "urgency": urgency,
            "actions": [{"key": str(k), "label": str(v)} for k, v in zip(actions[::2], actions[1::2])],
            "resident": bool(hints.get("resident", False)),
            "transient": bool(hints.get("transient", False)),
            "sync": str(hints.get("x-canonical-private-synchronous") or hints.get("synchronous") or ""),
            "progress": int(value) if value is not None else -1,
            "time": time.time(),
            "popup": not self.dnd or urgency == 2,
            "leaving": False,
        }
        self.items[nid] = n
        if n["popup"]:
            ms = POPUP_MS.get(urgency, 5000) if expire_timeout < 0 else int(expire_timeout)
            self._arm(nid, ms)
        self.changed()
        return dbus.UInt32(nid)

    @dbus.service.method(BUS, in_signature="u", out_signature="")
    def CloseNotification(self, nid):
        self._remove(int(nid), CLOSE_CALL)

    @dbus.service.signal(BUS, signature="uu")
    def NotificationClosed(self, nid, reason):
        pass

    @dbus.service.signal(BUS, signature="us")
    def ActionInvoked(self, nid, action_key):
        pass

    @dbus.service.method(CTL, in_signature="", out_signature="s")
    def GetState(self):
        return self.state()

    @dbus.service.signal(CTL, signature="s")
    def StateChanged(self, state):
        pass

    @dbus.service.method(CTL, in_signature="u", out_signature="")
    def Dismiss(self, nid):
        self._remove(int(nid), CLOSE_DISMISSED)

    @dbus.service.method(CTL, in_signature="u", out_signature="")
    def HidePopup(self, nid):
        self._cancel_timer(int(nid))
        self._hide_popup(int(nid))

    @dbus.service.method(CTL, in_signature="us", out_signature="")
    def Invoke(self, nid, key):
        nid = int(nid)
        n = self.items.get(nid)
        if not n:
            return
        self.ActionInvoked(dbus.UInt32(nid), str(key))
        if n.get("resident"):
            self.HidePopup(nid)
        else:
            self._remove(nid, CLOSE_DISMISSED)

    @dbus.service.method(CTL, in_signature="uu", out_signature="")
    def InvokeIndex(self, nid, index):
        n = self.items.get(int(nid))
        if n and int(index) < len(n["actions"]):
            self.Invoke(nid, n["actions"][int(index)]["key"])

    @dbus.service.method(CTL, in_signature="", out_signature="")
    def ClearAll(self):
        for nid in list(self.items):
            self._remove(nid, CLOSE_DISMISSED, notify=False)
        self.changed()

    @dbus.service.method(CTL, in_signature="", out_signature="")
    def ToggleDnd(self):
        self.dnd = not self.dnd
        if self.dnd:
            for n in self.items.values():
                if n.get("popup") and n["urgency"] < 2:
                    self._cancel_timer(n["id"])
                    n.update(popup=False, leaving=False)
        self.changed()


def watch():
    """Print the state on start and on every change; survives daemon restarts."""
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from xdgicons import app_icon, icon_path

    empty = json.dumps({"dnd": False, "count": 0, "popups": [], "history": []})

    def decorate(n: dict) -> dict:
        icon = (icon_path(n.get("icon", ""), 64, False) or app_icon(n.get("desktop", ""), 64, False)
                or app_icon(n.get("app", ""), 64, False) or icon_path("dialog-information", 64))
        # eww runs label :text through unescape, so backslashes must survive it.
        esc = lambda s: s.replace("\\", "\\\\")  # noqa: E731
        # Buttons carry only the action's index; its key (chosen by the sending app) stays in the daemon.
        actions = [{"i": i, "label": esc(a["label"])} for i, a in enumerate(n["actions"]) if a["key"] != "default"]
        image_css = n.get("image", "").replace("\\", "\\\\").replace("'", "\\'")
        return {**n, "icon": icon, "summary": esc(n["summary"]), "body": esc(n["body"]),
                "app": esc(n.get("app", "")), "actions": actions,
                "has_default": any(a["key"] == "default" for a in n["actions"]),
                "image_css": image_css, "ts": int(n["time"])}

    def show(raw: str):
        st = json.loads(raw)
        st["popups"] = [decorate(n) for n in st["popups"]]
        st["history"] = [decorate(n) for n in st["history"]]
        print(json.dumps(st, separators=(",", ":")), flush=True)

    DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()

    def fetch():
        try:
            show(bus.get_object(BUS, PATH).GetState(dbus_interface=CTL))
        except dbus.DBusException as e:
            print(f"notifd watch: {e.get_dbus_name()}; retrying", file=sys.stderr)
            print(empty, flush=True)
            GLib.timeout_add_seconds(3, fetch)
        return False

    bus.add_signal_receiver(lambda s: show(str(s)), signal_name="StateChanged", dbus_interface=CTL, path=PATH)
    bus.add_signal_receiver(lambda *_: GLib.timeout_add(300, fetch), signal_name="NameOwnerChanged",
                            dbus_interface="org.freedesktop.DBus", arg0=BUS)
    GLib.idle_add(fetch)
    GLib.MainLoop().run()


def main():
    if sys.argv[1:] == ["watch"]:
        watch()
        return
    DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    Daemon(bus)
    loop = GLib.MainLoop()
    bus.add_signal_receiver(lambda *_: loop.quit(), signal_name="NameLost", dbus_interface="org.freedesktop.DBus")
    loop.run()


if __name__ == "__main__":
    main()
