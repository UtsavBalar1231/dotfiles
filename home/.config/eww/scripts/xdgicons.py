"""Shared desktop-entry and icon-theme lookups for the eww helper scripts."""
import functools
import os

import gi

os.environ.setdefault("NO_AT_BRIDGE", "1")  # headless helpers: skip the accessibility bus (log noise)
gi.require_version("Gtk", "3.0")
from gi.repository import Gio, Gtk  # noqa: E402

try:
    gi.require_version("GioUnix", "2.0")
    from gi.repository import GioUnix  # noqa: E402

    DesktopAppInfo = GioUnix.DesktopAppInfo
except (ImportError, ValueError):
    DesktopAppInfo = Gio.DesktopAppInfo

FALLBACK = "application-x-executable"


@functools.lru_cache(maxsize=512)
def icon_path(name: str, size: int = 64, fallback: bool = True) -> str:
    """Resolve an icon name or path to a file; with fallback=False, '' when nothing matches."""
    theme = Gtk.IconTheme.get_default()
    if name.startswith("file://"):
        name = name[7:]
    if name.startswith("/") and os.path.exists(name):
        return name
    candidates = [name, name.lower()] if name and not name.startswith("/") else []
    for candidate in candidates + ([FALLBACK] if fallback else []):
        info = theme.lookup_icon(candidate, size, Gtk.IconLookupFlags.FORCE_SIZE)
        if info and info.get_filename():
            return info.get_filename()
    return ""


def gicon_name(gicon) -> str:
    return gicon.to_string() if gicon else ""


@functools.lru_cache(maxsize=1)
def _apps():
    return [a for a in Gio.AppInfo.get_all() if isinstance(a, DesktopAppInfo)]


@functools.lru_cache(maxsize=256)
def app_for_id(app_id: str):
    """Best-effort Wayland app_id -> DesktopAppInfo (exact id, reverse-DNS tail, WMClass, name)."""
    if not app_id:
        return None
    for cand in (app_id, app_id.lower(), app_id.split(".")[-1].lower()):
        try:
            info = DesktopAppInfo.new(f"{cand}.desktop")
        except TypeError:
            info = None
        if info:
            return info
    low = app_id.lower()
    for a in _apps():
        wm = (a.get_startup_wm_class() or "").lower()
        did = (a.get_id() or "").removesuffix(".desktop").lower()
        if low in (wm, did, did.split(".")[-1], (a.get_name() or "").lower()):
            return a
    return None


def app_icon(app_id: str, size: int = 64, fallback: bool = True) -> str:
    info = app_for_id(app_id)
    return icon_path(gicon_name(info.get_icon()) if info else app_id, size, fallback)


def app_name(app_id: str) -> str:
    info = app_for_id(app_id)
    return info.get_name() if info else (app_id or "")
