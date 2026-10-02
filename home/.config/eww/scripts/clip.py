#!/usr/bin/env python3
"""cliphist-backed clipboard panel; every command pushes the `clip` var with `eww update`.

  clip.py refresh [FILTER] | search SEQ TEXT | filter all|text|image | copy ID | accept | delete ID | wipe

`wipe` must be issued twice within 3s. For `search`, a TEXT of `-` is read from stdin
(how eww hands over typed text) and a missing SEQ is stamped here.
"""
import json
import os
import re
import subprocess
import sys
import time

RUN = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "eww-clip.json")
THUMBS = os.path.join(os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "eww", "clip")
BINARY = re.compile(r"\[\[ binary data (?P<size>.+?) (?P<fmt>\w+) (?P<w>\d+)x(?P<h>\d+) \]\]")
LIMIT = 80
THUMB_H = 150
PANEL_W = 700


def load() -> dict:
    try:
        with open(RUN) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {"query": "", "filter": "all"}


def save(state: dict):
    # Concurrent keystrokes each run this script; a partially written file would read as "no state".
    with open(RUN + ".tmp", "w") as f:
        json.dump(state, f)
    os.replace(RUN + ".tmp", RUN)


def entries() -> list[tuple[str, str]]:
    out = subprocess.run(["cliphist", "list"], capture_output=True, text=True, errors="replace").stdout
    return [tuple(line.split("\t", 1)) for line in out.splitlines() if "\t" in line]


def thumb(cid: str, fmt: str) -> str:
    os.makedirs(THUMBS, exist_ok=True)
    path = os.path.join(THUMBS, f"{cid}.{fmt}")
    if not os.path.exists(path):
        with open(path, "wb") as f:
            subprocess.run(["cliphist", "decode", cid], stdout=f, stderr=subprocess.DEVNULL)
    return path


def prune_thumbs(live_ids: set[str]):
    """Drop decoded images for entries cliphist no longer has (its own max-items eviction)."""
    for f in os.listdir(THUMBS) if os.path.isdir(THUMBS) else []:
        if f.split(".")[0] not in live_ids:
            os.unlink(os.path.join(THUMBS, f))


def build(state: dict) -> dict:
    q = state["query"].lower()
    items, total = [], 0
    history = entries()
    prune_thumbs({cid for cid, _ in history})
    for cid, preview in history:
        total += 1
        m = BINARY.fullmatch(preview.strip())
        kind = "image" if m else "text"
        if state["filter"] != "all" and state["filter"] != kind:
            continue
        if q and q not in preview.lower():
            continue
        if len(items) >= LIMIT:
            continue
        item = {"id": cid, "kind": kind}
        if m:
            w, h = int(m["w"]), int(m["h"])
            item |= {"thumb": thumb(cid, m["fmt"]),
                     "text": f"{m['fmt'].upper()} · {w}×{h} · {m['size']}",
                     "height": max(48, min(THUMB_H, int(h * min(1.0, PANEL_W / max(w, 1)))))}
        else:
            text = " ".join(preview.split())
            item |= {"thumb": "", "height": 0, "text": text.replace("\\", "\\\\")}
        items.append(item)
    return {**state, "items": items, "count": len(items), "total": total}


def push(state: dict):
    save(state)
    built = build(state)
    if load().get("seq", 0) != state.get("seq", 0):
        return  # a newer keystroke started while this one was building; let it publish
    subprocess.run(["eww", "update", "clip=" + json.dumps(built, separators=(",", ":"))],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def copy(cid: str):
    subprocess.Popen(["sh", "-c", f"cliphist decode {int(cid)} | wl-copy"], start_new_session=True)
    subprocess.Popen([os.path.join(os.path.dirname(os.path.abspath(__file__)), "panel.sh"), "close"],
                     start_new_session=True)


def main():
    cmd, arg = (sys.argv[1:] + ["", ""])[:2]
    state = load()
    if cmd == "refresh":
        push({"query": "", "filter": arg or "all", "seq": time.time()})
    elif cmd == "search":
        words = sys.argv[2:]
        try:
            seq = float(words[0])
            words = words[1:]
        except (IndexError, ValueError):
            seq = time.time()  # the shell had no $EPOCHREALTIME
        query = sys.stdin.read().rstrip("\n") if words == ["-"] else " ".join(words)
        if seq < state.get("seq", 0):
            return  # an older keystroke arriving late
        push({**state, "query": query, "seq": seq})
    elif cmd == "filter":
        push({**state, "filter": arg or "all"})
    elif cmd == "copy" and arg.isdigit():
        copy(arg)
    elif cmd == "accept":
        items = build(state)["items"]
        if items:
            copy(items[0]["id"])
    elif cmd == "delete" and arg.isdigit():
        subprocess.run(["cliphist", "delete"], input=f"{arg}\t\n", text=True)
        for f in os.listdir(THUMBS) if os.path.isdir(THUMBS) else []:
            if f.split(".")[0] == arg:
                os.unlink(os.path.join(THUMBS, f))
        push(state)
    elif cmd == "wipe":
        armed = subprocess.run(["eww", "get", "clip_wipe"], capture_output=True, text=True).stdout.strip()
        if armed != "true":
            subprocess.run(["eww", "update", "clip_wipe=true"])
            subprocess.Popen(["sh", "-c", "sleep 3; eww update clip_wipe=false"], start_new_session=True)
            return
        subprocess.run(["eww", "update", "clip_wipe=false"])
        subprocess.run(["cliphist", "wipe"])
        subprocess.run(["rm", "-rf", THUMBS])
        push(state)
    else:
        print(__doc__, file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
