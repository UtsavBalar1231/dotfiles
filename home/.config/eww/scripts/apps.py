#!/usr/bin/env python3
"""App index for the launcher and the drawer.

`apps.py daemon` (deflisten) prints one JSON state line per change and reads commands
from a FIFO; `apps.py <cmd> [arg]` writes one command to it:
  q <text>        set the search query      reset    clear query, rescan apps
  qs <seq> <text> query stamped with the shell's $EPOCHREALTIME; older stamps are dropped
  accept          launch the top result     pick <i>   launch result i (what widgets send)
  launch <desktop-id>        sort recent|frequent|az|next|prev   order used for an empty query (persisted)
A final argument of `-` means "read the text from stdin" (how eww hands over typed text).
"""
import json
import math
import os
import subprocess
import sys
import time

FIFO = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "eww-apps.fifo")
STATE = os.path.expanduser("~/.local/state/eww/apps-frecency.json")
OPENED = os.path.expanduser("~/.local/state/eww/apps-opened.json")  # written by niri.py on window open
SETTINGS = os.path.expanduser("~/.local/state/eww/apps-ui.json")
SORTS = ("recent", "frequent", "az")
GRID_COLS = 6  # drawer grid width; eww has no flowbox, so rows are pre-chunked here
LIST_LIMIT = 8  # launcher result rows


def label_safe(s: str) -> str:
    """eww runs label :text through unescape, so a lone backslash must be doubled to survive."""
    return s.replace("\\", "\\\\")


def read_json(path: str, default):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def write_json(path: str, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path + ".tmp", "w") as f:
        json.dump(data, f)
    os.replace(path + ".tmp", path)


def ago(ts: float) -> str:
    s = time.time() - ts
    if s < 60:
        return "just now"
    for unit, size in (("d", 86400), ("h", 3600), ("m", 60)):
        if s >= size:
            return f"{int(s // size)}{unit} ago"
    return ""


def send(cmd: str, arg: str = ""):
    try:
        fd = os.open(FIFO, os.O_WRONLY | os.O_NONBLOCK)
    except OSError:
        return
    with os.fdopen(fd, "w") as f:
        f.write(f"{cmd} {arg}".replace("\n", " ").strip() + "\n")


class Index:
    def __init__(self):
        self.query = ""
        self.qseq = 0.0
        self.apps: list[dict] = []
        self.usage = self._load_usage()
        self.opened: dict[str, float] = read_json(OPENED, {})
        sort = read_json(SETTINGS, {}).get("sort")
        self.sort = sort if sort in SORTS else SORTS[0]
        self.results: list[dict] = []

    @staticmethod
    def _load_usage() -> dict:
        try:
            with open(STATE) as f:
                return json.load(f)
        except (OSError, ValueError):
            return {}

    def _save_usage(self):
        os.makedirs(os.path.dirname(STATE), exist_ok=True)
        tmp = STATE + ".tmp"
        with open(tmp, "w") as f:
            json.dump(self.usage, f)
        os.replace(tmp, STATE)

    def rescan(self):
        from gi.repository import Gio, GLib
        from xdgicons import DesktopAppInfo, gicon_name, icon_path

        # Gio notices new/removed .desktop files through file monitors that only fire when the
        # main context is iterated; this daemon has no main loop, so drain pending events here.
        ctx = GLib.MainContext.default()
        while ctx.pending():
            ctx.iteration(False)
        apps = []
        for a in Gio.AppInfo.get_all():
            if not a.should_show() or not isinstance(a, DesktopAppInfo):
                continue
            exe = os.path.basename((a.get_executable() or "").split()[0]) if a.get_executable() else ""
            name = a.get_name() or a.get_id()
            haystack = " ".join([
                a.get_id() or "", exe, a.get_generic_name() or "",
                " ".join(a.get_keywords() or []), a.get_description() or "",
            ]).lower()
            apps.append({
                "id": a.get_id(),
                "name": label_safe(name),
                "desc": label_safe(a.get_description() or a.get_generic_name() or ""),
                "icon": icon_path(gicon_name(a.get_icon()), 96),
                "_name": name.lower(),
                "_words": name.lower().replace("-", " ").split(),
                "_hay": haystack,
            })
        apps.sort(key=lambda x: x["_name"])
        self.apps = apps

    def frecency(self, app_id: str) -> float:
        u = self.usage.get(app_id)
        if not u:
            return 0.0
        age_days = (time.time() - u["last"]) / 86400
        return u["count"] * math.exp(-age_days / 14)

    def last_opened(self, app_id: str) -> float:
        """Latest of a launcher launch and a window of the app appearing (any launch path)."""
        return max(self.usage.get(app_id, {}).get("last", 0), self.opened.get(app_id, 0))

    def order_key(self, app: dict):
        if self.sort == "recent":
            return (-self.last_opened(app["id"]), app["_name"])
        if self.sort == "frequent":
            return (-self.frecency(app["id"]), app["_name"])
        return (app["_name"],)

    def match(self, app: dict, q: str) -> float | None:
        if not q:
            return 0.0
        name = app["_name"]
        if name.startswith(q):
            return 100.0
        if any(w.startswith(q) for w in app["_words"]):
            return 85.0
        if q in name:
            return 70.0
        if q in app["_hay"]:
            return 45.0
        it = iter(name)
        if all(ch in it for ch in q):
            return 20.0
        return None

    def compute(self):
        q = self.query.strip().lower()
        scored = []
        for app in self.apps:
            s = self.match(app, q)
            if s is None:
                continue
            bonus = 8 * math.log1p(self.frecency(app["id"]))
            # With a query, relevance leads and the chosen sort breaks ties; without one, the sort decides.
            scored.append(((-(s + bonus) if q else 0, self.order_key(app)), app))
        scored.sort(key=lambda t: t[0])
        self.results = [t[1] for t in scored]

    def emit(self):
        self.compute()
        public = lambda a: {k: v for k, v in a.items() if not k.startswith("_")}  # noqa: E731
        results = [public(a) | {"i": i, "ago": ago(t) if (t := self.last_opened(a["id"])) else ""}
                   for i, a in enumerate(self.results)]
        rows = [results[i:i + GRID_COLS] for i in range(0, len(results), GRID_COLS)]
        if rows:
            pad = {"id": "", "i": -1, "name": "", "desc": "", "icon": self.apps[0]["icon"] if self.apps else ""}
            rows[-1] += [pad] * (GRID_COLS - len(rows[-1]))
        print(json.dumps({
            "query": label_safe(self.query),
            "sort": self.sort,
            "count": len(self.results),
            "total": len(self.apps),
            "results": results[:LIST_LIMIT],
            "rows": rows,
        }, separators=(",", ":")), flush=True)

    def launch(self, app_id: str):
        if not app_id:
            return
        subprocess.Popen(["niri", "msg", "action", "spawn", "--", "gtk-launch", app_id],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        u = self.usage.setdefault(app_id, {"count": 0, "last": 0})
        u["count"] += 1
        u["last"] = time.time()
        self._save_usage()
        subprocess.Popen([os.path.join(os.path.dirname(__file__), "panel.sh"), "close"],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)


def daemon():
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    if not os.path.exists(FIFO):
        os.mkfifo(FIFO, 0o600)
    idx = Index()
    idx.rescan()
    idx.emit()
    with os.fdopen(os.open(FIFO, os.O_RDWR), "r") as fifo:
        for line in fifo:
            cmd, _, arg = line.rstrip("\n").partition(" ")
            if cmd == "q":
                idx.query, idx.qseq = arg, time.time()
            elif cmd == "qs":
                seq, _, text = arg.partition(" ")
                try:
                    if float(seq) < idx.qseq:
                        continue
                    idx.qseq, idx.query = float(seq), text
                except ValueError:
                    continue
            elif cmd == "reset":
                idx.query, idx.qseq = "", time.time()
                idx.usage = idx._load_usage()
                idx.opened = read_json(OPENED, {})
                idx.rescan()
            elif cmd == "accept":
                if idx.results:
                    idx.launch(idx.results[0]["id"])
                continue
            elif cmd == "launch":
                idx.launch(arg)
                continue
            elif cmd == "sort":
                if arg in ("next", "prev"):
                    arg = SORTS[(SORTS.index(idx.sort) + (1 if arg == "next" else -1)) % len(SORTS)]
                if arg not in SORTS:
                    continue
                idx.sort = arg
                write_json(SETTINGS, {"sort": arg})
            elif cmd == "pick":
                if arg.isdigit() and int(arg) < len(idx.results):
                    idx.launch(idx.results[int(arg)]["id"])
                continue
            else:
                continue
            idx.emit()


def cli(argv: list[str]):
    cmd, args = argv[0], argv[1:]
    if args and args[-1] == "-":
        args = args[:-1] + [sys.stdin.read().rstrip("\n")]
    if cmd == "qs" and len(args) == 1:  # the shell had no $EPOCHREALTIME; stamp it here
        args = [f"{time.time():.6f}"] + args
    send(cmd, " ".join(args))


if __name__ == "__main__":
    if sys.argv[1:2] == ["daemon"]:
        daemon()
    elif len(sys.argv) >= 2:
        cli(sys.argv[1:])
