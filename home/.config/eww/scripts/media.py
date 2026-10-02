#!/usr/bin/env python3
"""MPRIS state for `deflisten media`, via playerctl's GObject API: one JSON line per change."""
import base64
import hashlib
import json
import os
import threading
import urllib.parse
import urllib.request

import gi

gi.require_version("Playerctl", "2.0")
from gi.repository import GLib, Playerctl  # noqa: E402

ART_DIR = os.path.join(os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "eww", "art")
ART_KEEP = 50  # newest cover images kept on disk

manager = Playerctl.PlayerManager()
last = None
fetching: set[str] = set()


def label_safe(s: str) -> str:
    """eww runs label :text through unescape, so a lone backslash must be doubled to survive."""
    return s.replace("\\", "\\\\")


def css_url(path: str) -> str:
    """Make a path safe inside CSS `url('...')`."""
    return path.replace("\\", "\\\\").replace("'", "\\'")


def prune_art():
    files = sorted((os.path.join(ART_DIR, f) for f in os.listdir(ART_DIR)), key=os.path.getmtime, reverse=True)
    for f in files[ART_KEEP:]:
        os.unlink(f)


def fetch_art(url: str, path: str):
    try:
        with urllib.request.urlopen(url, timeout=4) as r, open(path + ".part", "wb") as f:
            f.write(r.read())
        os.replace(path + ".part", path)
        prune_art()
    except OSError:
        pass
    finally:
        fetching.discard(url)
        GLib.idle_add(emit)


def art_path(url: str) -> str:
    """Local file for an MPRIS artUrl; remote art is fetched in the background ("" until ready)."""
    if not url:
        return ""
    if url.startswith("file://"):
        path = urllib.parse.unquote(url[7:])
        return path if os.path.exists(path) else ""
    os.makedirs(ART_DIR, exist_ok=True)
    path = os.path.join(ART_DIR, hashlib.sha1(url.encode()).hexdigest())
    if os.path.exists(path):
        return path
    if url.startswith("data:image/") and ";base64," in url:
        try:
            with open(path, "wb") as f:
                f.write(base64.b64decode(url.split(",", 1)[1]))
            return path
        except (OSError, ValueError):
            return ""
    if url.startswith(("http://", "https://")) and url not in fetching:
        fetching.add(url)
        threading.Thread(target=fetch_art, args=(url, path), daemon=True).start()
    return ""


def pick():
    players = manager.props.players
    playing = [p for p in players if p.props.playback_status == Playerctl.PlaybackStatus.PLAYING]
    return (playing or players or [None])[0]


def emit(*_):
    global last
    p = pick()
    if p is None:
        state = {"available": False}
    else:
        meta = p.props.metadata.unpack() if p.props.metadata else {}
        art = art_path(str(meta.get("mpris:artUrl", "")))
        state = {
            "available": True,
            "player": p.props.player_instance or p.props.player_name or "",
            "status": p.props.playback_status.value_nick.capitalize(),
            "title": label_safe(p.get_title() or "Unknown"),
            "artist": label_safe(p.get_artist() or ""),
            "art": art,
            "art_css": css_url(art),
        }
    line = json.dumps(state, separators=(",", ":"))
    if line != last:
        last = line
        print(line, flush=True)
    return False


def manage(name):
    player = Playerctl.Player.new_from_name(name)
    player.connect("metadata", emit)
    player.connect("playback-status", emit)
    manager.manage_player(player)


def main():
    manager.connect("name-appeared", lambda _m, name: (manage(name), emit()))
    manager.connect("player-vanished", lambda *_: GLib.idle_add(emit))
    for name in manager.props.player_names:
        manage(name)
    emit()
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
