#!/usr/bin/env python3
"""Wallpaper manager behind the eww picker: library scan, thumbnails, awww, slideshow.

  wall.py daemon        run the manager (launch.sh and `watch` start it on demand)
  wall.py watch MODE    stream state as JSON lines: `grid` (deflisten walls), `status` (wallstat) or
                        `colors` (the current wallpaper's sampled colours), or plain lines with
                        the wrapper's theme classes: `theme` (see theme.py)
  wall.py CMD [ARG]     send one command (a final `-` argument is read from stdin):
    tab static|gif|fav    q TEXT        qs SEQ TEXT   page next|prev|up|down   pick IDX   fav IDX
    accept    random      next          back       restore       rescan        ping
    slideshow on|off|toggle   every MINUTES   source static|gif|all|fav
    shuffle on|off|toggle     transition NAME
    accent N|default          use matched colour N of the current wallpaper as the accent, or Gruvbox
"""
import glob
import hashlib
import json
import math
import os
import random
import socket
import subprocess
import sys
import threading
import time
import fcntl
from concurrent.futures import ThreadPoolExecutor

RUNTIME = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
SOCK = os.path.join(RUNTIME, "eww-wall.sock")
STATE = os.path.expanduser("~/.local/state/eww/wallpapers.json")
THUMBS = os.path.join(os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "eww", "wall-thumbs")
LIBRARY = [os.path.expanduser("~/Pictures/wallpapers")]

STATIC_EXT = {".jpg", ".jpeg", ".png", ".webp"}
ANIMATED_EXT = {".gif"}
TW, TH, RADIUS = 448, 252, 14  # thumbnail size must equal the yuck image size: eww cannot scale GIFs
THUMB_VERSION = 1  # bump to invalidate every cached thumbnail
COLS, ROWS = 6, 3
INTERVALS = [1, 5, 15, 30, 60]
SOURCES = ["static", "gif", "all", "fav"]
TRANSITIONS = ["fade", "wipe", "grow", "wave", "outer", "random"]
HISTORY = 30

# Grid fields go to `walls`, everything else to `wallstat`: eww rebuilds every tile whenever
# the variable a `for` reads changes, so status ticks must not touch the grid's variable.
GRID_KEYS = ("tab", "query", "page", "pages", "count", "rows", "counts")

DEFAULTS = {
    "tab": "static", "page": 0, "current": "", "history": [], "favourites": [],
    "slideshow": {"on": False, "every": 15, "source": "all", "shuffle": True},
    "transition": "grow",
    "accents": {},  # wallpaper path -> chosen sampled colour (-1: Gruvbox); absent means the strongest
}


def label_safe(s: str) -> str:
    """eww runs label :text through unescape, so a lone backslash must be doubled to survive."""
    return s.replace("\\", "\\\\")


def kind_of(path: str) -> str:
    return "gif" if os.path.splitext(path)[1].lower() in ANIMATED_EXT else "static"


def thumb_for(path: str) -> str:
    st = os.stat(path)
    key = hashlib.sha1(f"{path}:{st.st_mtime_ns}:{st.st_size}:{THUMB_VERSION}".encode()).hexdigest()
    return os.path.join(THUMBS, key + (".gif" if kind_of(path) == "gif" else ".png"))


def rounded_mask():
    from PIL import Image, ImageDraw

    mask = Image.new("L", (TW, TH), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, TW - 1, TH - 1), RADIUS, fill=255)
    return mask


def make_static_thumb(src: str, dst: str):
    from PIL import Image, ImageOps

    with Image.open(src) as img:
        img.draft("RGB", (TW * 2, TH * 2))
        thumb = ImageOps.fit(img.convert("RGB"), (TW, TH), Image.Resampling.LANCZOS)
    thumb.putalpha(rounded_mask())
    thumb.save(dst + ".part.png")
    os.replace(dst + ".part.png", dst)


def make_gif_thumb(src: str, dst: str, mask: str):
    # First 4s at 10 fps keeps the per-tile animation light; the alpha mask rounds the corners.
    # The mask input must be finite (-t) and alphamerge must stop with the GIF, or palettegen,
    # which only emits at end of stream, waits forever.
    graph = (f"[0:v]fps=10,scale={TW}:{TH}:force_original_aspect_ratio=increase:flags=lanczos,"
             f"crop={TW}:{TH}[v];[1:v]format=gray[m];[v][m]alphamerge=shortest=1,split[a][b];"
             "[a]palettegen=reserve_transparent=1:stats_mode=diff[p];"
             "[b][p]paletteuse=alpha_threshold=128:dither=bayer:bayer_scale=3")
    tmp = dst + ".part.gif"
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-t", "4", "-i", src, "-loop", "1", "-t", "4", "-i", mask,
                    "-filter_complex", graph, "-loop", "0", tmp],
                   check=True, timeout=60, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
    os.replace(tmp, dst)


def awww(*args: str, wait: bool = False):
    proc = subprocess.Popen(["awww", *args], stdin=subprocess.DEVNULL,
                            stdout=subprocess.PIPE if wait else subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if not wait:
        return ""
    try:
        return proc.communicate(timeout=5)[0].decode()
    except subprocess.TimeoutExpired:  # a wedged awww-daemon must not take a daemon thread with it
        proc.kill()
        proc.communicate()
        return ""


AWWW_CACHE = os.path.join(os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "awww")
CACHE_BROKEN = b"failed to load cached animation frames"


def purge_anim_cache(path: str, since: float = 0.0):
    """awww writes a GIF's resized frames to its cache in place and trusts that file on every later
    apply, so an awww killed mid-write leaves the GIF stuck on its first frame until the entry goes."""
    for f in glob.glob(os.path.join(AWWW_CACHE, "*", glob.escape(path.replace("/", "_")) + "__*")):
        try:
            if os.path.getmtime(f) >= since:
                os.remove(f)
        except OSError:
            pass


def ensure_awww():
    if subprocess.run(["awww", "query"], capture_output=True).returncode == 0:
        return
    subprocess.Popen(["awww-daemon"], start_new_session=True, stdin=subprocess.DEVNULL,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(40):
        time.sleep(0.1)
        if subprocess.run(["awww", "query"], capture_output=True).returncode == 0:
            return


class Manager:
    def __init__(self):
        self.lock = threading.RLock()
        self.cfg = json.loads(json.dumps(DEFAULTS))
        self.load()
        self.query = ""
        self.qseq = 0.0  # newest keystroke timestamp applied; older `qs` arrivals are stale
        self.library: dict[str, list[str]] = {"static": [], "gif": []}
        self.thumbs: dict[str, str] = {}
        self.queued = 0
        self.done = 0
        self.next_at = 0.0
        self.watchers: dict[socket.socket, dict] = {}  # conn -> {"mode", "last"}
        self.scan_lock = threading.Lock()
        self.proc: subprocess.Popen | None = None
        self.theme = ""  # class of the palette matching the current wallpaper
        self.applied: str | None = None  # theme last handed to `theme.py apply` (None: not yet)
        self.colours: dict[str, list[str]] = {}  # wallpaper path -> matched colour ids (theme.match)
        self.swatches: list[dict] = []  # the current wallpaper's colours, for the picker
        self.dirty = threading.Event()
        self.wake = threading.Event()
        self.pool = ThreadPoolExecutor(max_workers=4)

    def load(self):
        try:
            with open(STATE) as f:
                saved = json.load(f)
        except (OSError, ValueError):
            return
        for k, v in saved.items():
            if isinstance(v, dict) and isinstance(self.cfg.get(k), dict):
                self.cfg[k].update(v)
            elif k in self.cfg:
                self.cfg[k] = v

    def save(self):
        os.makedirs(os.path.dirname(STATE), exist_ok=True)
        with open(STATE + ".tmp", "w") as f:
            json.dump(self.cfg, f, indent=1)
        os.replace(STATE + ".tmp", STATE)

    def scan(self):
        if not self.scan_lock.acquire(blocking=False):
            return  # a scan is already running; its result is just as fresh
        try:
            self._scan()
        finally:
            self.scan_lock.release()

    def _scan(self):
        found = {"static": [], "gif": []}
        for root in LIBRARY:
            for dirpath, dirs, files in os.walk(root):
                dirs[:] = [d for d in dirs if not d.startswith(".")]
                for f in files:
                    ext = os.path.splitext(f)[1].lower()
                    if not f.startswith(".") and ext in STATIC_EXT | ANIMATED_EXT:
                        p = os.path.join(dirpath, f)
                        found[kind_of(p)].append(p)
        for k in found:
            found[k].sort(key=lambda p: os.path.basename(p).lower())
        with self.lock:
            self.library = found
            self.cfg["favourites"] = [p for p in self.cfg["favourites"] if os.path.exists(p)]
        self.queue_thumbnails()
        self.changed()

    def queue_thumbnails(self):
        os.makedirs(THUMBS, exist_ok=True)
        mask = os.path.join(THUMBS, f"mask-{TW}x{TH}-r{RADIUS}.png")
        if not os.path.exists(mask):
            rounded_mask().save(mask)
        keep = {os.path.basename(mask)}
        todo = []
        with self.lock:
            for path in self.library["static"] + self.library["gif"]:
                try:
                    dst = thumb_for(path)
                except OSError:
                    continue
                keep.add(os.path.basename(dst))
                if os.path.exists(dst):
                    self.thumbs[path] = dst
                elif path not in self.thumbs:
                    todo.append((path, dst))
            self.queued, self.done = len(todo), 0
        for f in os.listdir(THUMBS):
            if f not in keep:
                os.unlink(os.path.join(THUMBS, f))
        for path, dst in todo:
            self.pool.submit(self.build_thumb, path, dst, mask)

    def build_thumb(self, path: str, dst: str, mask: str):
        try:
            if kind_of(path) == "gif":
                make_gif_thumb(path, dst, mask)
            else:
                make_static_thumb(path, dst)
            with self.lock:
                self.thumbs[path] = dst
        except Exception as e:  # one unreadable file must not stop the rest of the library
            print(f"wall: thumbnail failed for {path}: {e}", file=sys.stderr)
        with self.lock:
            self.done += 1
        self.changed()

    def pool_for(self, source: str) -> list[str]:
        lib = self.library
        if source == "fav":
            return [p for p in lib["static"] + lib["gif"] if p in self.cfg["favourites"]]
        if source == "all":
            return lib["static"] + lib["gif"]
        return lib.get(source, [])

    def filtered(self) -> list[str]:
        q = self.query.lower()
        return [p for p in self.pool_for(self.cfg["tab"]) if q in os.path.splitext(os.path.basename(p))[0].lower()]

    def view(self) -> dict:
        with self.lock:
            items = self.filtered()
            per = COLS * ROWS
            pages = max(1, math.ceil(len(items) / per))
            page = min(self.cfg["page"], pages - 1)
            cur, favs = self.cfg["current"], set(self.cfg["favourites"])
            tiles = [{"idx": i, "path": p, "name": label_safe(os.path.splitext(os.path.basename(p))[0]), "kind": kind_of(p),
                      "thumb": self.thumbs.get(p, ""), "current": p == cur, "fav": p in favs}
                     for i, p in enumerate(items) if page * per <= i < (page + 1) * per]
            rows = [tiles[i:i + COLS] for i in range(0, len(tiles), COLS)]
            if rows:
                rows[-1] += [{"idx": -1, "path": "", "name": "", "kind": "", "thumb": "", "current": False,
                              "fav": False}] * (COLS - len(rows[-1]))
            ss = dict(self.cfg["slideshow"])
            ss["next_at"] = int(self.next_at)
            return {
                "tab": self.cfg["tab"], "query": label_safe(self.query), "page": page + 1, "pages": pages,
                "count": len(items), "rows": rows,
                "counts": {"static": len(self.library["static"]), "gif": len(self.library["gif"]),
                           "fav": len(self.pool_for("fav"))},
                "current": {"path": cur, "name": label_safe(os.path.splitext(os.path.basename(cur))[0]) if cur else "",
                            "kind": kind_of(cur) if cur else ""},
                "slideshow": ss, "transition": self.cfg["transition"],
                "intervals": INTERVALS, "transitions": TRANSITIONS,
                "progress": {"done": self.done, "total": self.queued},
                "applying": bool(self.proc and self.proc.poll() is None),
            }

    def changed(self, persist: bool = False):
        if persist:
            with self.lock:
                self.save()
        self.dirty.set()

    def broadcaster(self):
        while True:
            self.dirty.wait()
            self.dirty.clear()
            v = self.view()
            parts = {"grid": {k: v[k] for k in GRID_KEYS},
                     "status": {k: x for k, x in v.items() if k not in GRID_KEYS}, "all": v}
            lines = {m: (json.dumps(p, separators=(",", ":")) + "\n").encode() for m, p in parts.items()}
            lines["theme"] = (self.theme + "\n").encode()
            lines["colors"] = (json.dumps(self.swatches, separators=(",", ":")) + "\n").encode()
            with self.lock:
                targets = list(self.watchers.items())
            dead = []
            # Sends happen outside the lock (sockets have a 1s timeout) so a stalled reader
            # cannot freeze commands or the slideshow; unchanged parts are not re-sent.
            for conn, w in targets:
                line = lines[w["mode"]]
                if line == w["last"]:
                    continue
                try:
                    conn.sendall(line)
                    w["last"] = line
                except OSError:
                    dead.append(conn)
            if dead:
                with self.lock:
                    for conn in dead:
                        self.watchers.pop(conn, None)
                        conn.close()
            time.sleep(0.25)  # coalesce bursts (thumbnail completions, rapid paging)

    def apply(self, path: str, transition: str | None = None, record: bool = True, retry: bool = True):
        if not path or not os.path.exists(path):
            return
        ensure_awww()
        t = transition or self.cfg["transition"]
        args = ["img", path, "--transition-type", t, "--transition-fps", "120", "--transition-duration", "1.2"]
        if t in ("wipe", "wave"):
            args += ["--transition-angle", "30"]
        # A GIF takes seconds to resize; cancel any apply still running so the last pick wins.
        started = time.time()
        with self.lock:
            if self.proc and self.proc.poll() is None:
                self.proc.terminate()
            self.proc = proc = subprocess.Popen(["awww", *args], stdin=subprocess.DEVNULL,
                                                stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
        threading.Thread(target=self.settle, args=(proc, path, started, retry), daemon=True).start()
        with self.lock:
            prev = self.cfg["current"]
            if record and prev and prev != path:
                self.cfg["history"] = ([prev] + [h for h in self.cfg["history"] if h != prev])[:HISTORY]
            self.cfg["current"] = path
        self.changed(persist=True)
        self.retheme(path)

    def retheme(self, path: str):
        """Sample `path`'s colours and pick the shell's theme on a worker thread: it decodes images."""
        def work():
            import theme
            ids = self.colours.get(path)
            if ids is None:
                try:
                    thumb = thumb_for(path)
                    ids = theme.match(theme.samples(thumb if os.path.exists(thumb) else path))
                except (OSError, ValueError):
                    ids = []
                self.colours[path] = ids
            with self.lock:
                if self.cfg["current"] != path:  # a newer wallpaper has its own retheme coming
                    return
                pick = self.cfg["accents"].get(path, 0)
                pick = -1 if pick < 0 or not ids else pick if pick < len(ids) else 0
                cls = theme.classes(ids, pick)
                self.swatches = [{"key": str(i), "hex": theme.COLORS[cid]["hex"], "on": i == pick,
                                  "tip": theme.COLORS[cid]["label"]} for i, cid in enumerate(ids)]
                self.swatches.append({"key": "default", "hex": theme.DEFAULT["accent"], "on": pick < 0,
                                      "tip": "Gruvbox Orange (ignore the wallpaper)"})
                self.theme = cls
                fresh = cls != self.applied
                self.applied = cls
            self.changed()
            if fresh:  # recolour niri, kitty, GTK, Qt and swaylock too (see theme.py)
                log = open(os.path.join(os.path.dirname(STATE), "theme.log"), "a")
                subprocess.Popen([os.path.join(os.path.dirname(os.path.abspath(__file__)), "theme.py"),
                                  "apply", cls, f"{time.time():.6f}"], start_new_session=True,
                                 stdin=subprocess.DEVNULL, stdout=log, stderr=log)
                log.close()
        if path:  # not self.pool: a fresh library scan can queue hundreds of thumbnails there
            threading.Thread(target=work, daemon=True).start()

    def settle(self, proc: subprocess.Popen, path: str, started: float, retry: bool):
        err = proc.communicate()[1]
        if proc.returncode < 0:  # killed for a newer pick, maybe mid cache write
            purge_anim_cache(path, since=started)
        elif CACHE_BROKEN in err and retry:
            purge_anim_cache(path)
            with self.lock:
                if self.proc is proc:
                    self.apply(path, transition="none", record=False, retry=False)
                    return
        self.changed()

    def advance(self):
        with self.lock:
            ss = self.cfg["slideshow"]
            pool = self.pool_for(ss["source"]) or self.pool_for("all")
            cur = self.cfg["current"]
            if not pool:
                return
            if ss["shuffle"]:
                choices = [p for p in pool if p != cur] or pool
                nxt = random.choice(choices)
            else:
                nxt = pool[(pool.index(cur) + 1) % len(pool)] if cur in pool else pool[0]
        self.apply(nxt)

    def reset_timer(self):
        with self.lock:
            ss = self.cfg["slideshow"]
            self.next_at = time.time() + ss["every"] * 60 if ss["on"] else 0.0
        self.wake.set()
        self.changed()

    def slideshow(self):
        while True:
            with self.lock:
                wait = self.next_at - time.time() if self.next_at else None
            if wait is not None and wait <= 0:
                self.advance()
                self.reset_timer()
                continue
            self.wake.wait(wait)
            self.wake.clear()

    def restore(self):
        cur = self.cfg["current"]
        if not cur or not os.path.exists(cur):
            return
        ensure_awww()
        if cur not in awww("query", wait=True):
            self.apply(cur, transition="none", record=False)

    def command(self, cmd: str, arg: str):
        if cmd == "ping":
            return
        with self.lock:
            cfg, ss = self.cfg, self.cfg["slideshow"]
            items = self.filtered()
            per = COLS * ROWS
            pages = max(1, math.ceil(len(items) / per))
            if cmd == "tab" and arg in ("static", "gif", "fav"):
                cfg["tab"], cfg["page"] = arg, 0
            elif cmd == "q":
                self.query, cfg["page"], self.qseq = arg, 0, time.time()
            elif cmd == "qs":
                seq, _, text = arg.partition(" ")
                try:
                    stale = float(seq) < self.qseq
                except ValueError:
                    stale = True
                if stale:
                    return
                self.qseq, self.query, cfg["page"] = float(seq), text, 0
            elif cmd == "page":
                step = {"next": 1, "down": 1, "prev": -1, "up": -1}.get(arg)
                cfg["page"] = (cfg["page"] + step) % pages if step else max(0, min(int(arg or 1) - 1, pages - 1))
            elif cmd == "slideshow":
                ss["on"] = (not ss["on"]) if arg == "toggle" else arg == "on"
            elif cmd == "every" and arg.isdigit() and int(arg) > 0:
                ss["every"] = int(arg)
            elif cmd == "source" and arg in SOURCES:
                ss["source"] = arg
            elif cmd == "shuffle":
                ss["shuffle"] = (not ss["shuffle"]) if arg == "toggle" else arg == "on"
            elif cmd == "transition" and arg in TRANSITIONS:
                cfg["transition"] = arg
            elif cmd == "accent" and cfg["current"] and (arg == "default" or arg.isdigit()):
                if arg == "0":
                    cfg["accents"].pop(cfg["current"], None)
                else:
                    cfg["accents"][cfg["current"]] = -1 if arg == "default" else int(arg)
            elif cmd == "fav" and arg.lstrip("-").isdigit() and 0 <= int(arg) < len(items):
                p = items[int(arg)]
                favs = cfg["favourites"]
                favs.remove(p) if p in favs else favs.append(p)
        target = None
        if cmd == "pick" and arg.isdigit() and int(arg) < len(items):
            target = items[int(arg)]
        elif cmd == "accept" and items:
            target = items[0]
        elif cmd == "random" and items:
            target = random.choice([p for p in items if p != self.cfg["current"]] or items)
        elif cmd == "back" and self.cfg["history"]:
            with self.lock:
                target = self.cfg["history"].pop(0)
            self.apply(target, record=False)
            target = None
        elif cmd == "next":
            self.advance()
        elif cmd == "restore":
            self.restore()
        elif cmd == "rescan":
            threading.Thread(target=self.scan, daemon=True).start()
        elif cmd == "accent":
            self.retheme(self.cfg["current"])
        if target:
            self.apply(target)
        if cmd in ("slideshow", "every", "next", "pick", "accept", "random", "back"):
            self.reset_timer()
        self.changed(persist=cmd not in ("q", "qs", "page"))

    def handle(self, conn: socket.socket):
        line = conn.makefile("r").readline().strip()
        if line.split(" ")[0] == "watch":
            mode = line.partition(" ")[2] or "all"
            conn.settimeout(1.0)
            with self.lock:
                self.watchers[conn] = {"mode": mode if mode in ("grid", "status", "theme", "colors") else "all", "last": b""}
            self.dirty.set()
            return
        cmd, _, arg = line.partition(" ")
        try:
            self.command(cmd, arg)
        finally:
            conn.close()

    def startup(self):
        try:
            self.scan()
            self.restore()
            self.retheme(self.cfg["current"])
        except Exception as e:  # never leave the slideshow unarmed because startup hit a snag
            print(f"wall: startup: {e}", file=sys.stderr)
        finally:
            self.reset_timer()

    def serve(self):
        # One daemon per session: the lock is held for the process lifetime, so a second
        # instance (two clients racing to spawn one) exits here instead of stealing the socket.
        self.lock_fd = os.open(SOCK + ".lock", os.O_RDWR | os.O_CREAT, 0o600)
        try:
            fcntl.flock(self.lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            return
        try:
            os.unlink(SOCK)
        except FileNotFoundError:
            pass
        srv = socket.socket(socket.AF_UNIX)
        srv.bind(SOCK)
        srv.listen(16)
        threading.Thread(target=self.broadcaster, daemon=True).start()
        threading.Thread(target=self.slideshow, daemon=True).start()
        threading.Thread(target=self.startup, daemon=True).start()
        while True:
            conn, _ = srv.accept()
            threading.Thread(target=self.handle, args=(conn,), daemon=True).start()


def connect(start: bool = True) -> socket.socket:
    for attempt in range(50):
        s = socket.socket(socket.AF_UNIX)
        try:
            s.connect(SOCK)
            return s
        except OSError:
            s.close()
            if attempt == 0 and start:
                subprocess.Popen([os.path.abspath(__file__), "daemon"], start_new_session=True,
                                 stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
            time.sleep(0.1)
    raise SystemExit("wall: daemon did not come up")


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__, file=sys.stderr)
        sys.exit(1)
    if args[0] == "daemon":
        Manager().serve()
    elif args[0] == "watch":
        mode = args[1] if len(args) > 1 else "all"
        while True:
            s = connect()
            s.sendall(f"watch {mode}\n".encode())
            for line in s.makefile("r"):
                print(line, end="", flush=True)
            time.sleep(0.5)  # daemon restarted; reconnect
    else:
        if args[-1] == "-":
            args = args[:-1] + [sys.stdin.read().rstrip("\n")]
        if args[0] == "qs" and len(args) == 2:  # the shell had no $EPOCHREALTIME; stamp it here
            args = ["qs", f"{time.time():.6f}", args[1]]
        s = connect()
        s.sendall((" ".join(args).replace("\n", " ") + "\n").encode())
        s.close()


if __name__ == "__main__":
    main()
