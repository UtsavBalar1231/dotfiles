#!/usr/bin/env python3
"""BlueZ adapter/device state for `deflisten bt`, driven by D-Bus signals instead of polling."""
import json

import dbus
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

ICONS = {
    "audio-headphones": "󰋋", "audio-headset": "󰋎", "audio-card": "󰓃", "input-mouse": "󰍽",
    "input-keyboard": "󰌌", "input-gaming": "󰊗", "phone": "󰏲", "computer": "󰟀",
}

DBusGMainLoop(set_as_default=True)
bus = dbus.SystemBus()
last = None
pending = False


def snapshot() -> dict:
    objs = bus.get_object("org.bluez", "/").GetManagedObjects(dbus_interface="org.freedesktop.DBus.ObjectManager")
    powered, devices = False, []
    for path, ifaces in objs.items():
        if "org.bluez.Adapter1" in ifaces:
            powered = powered or bool(ifaces["org.bluez.Adapter1"].get("Powered", False))
        dev = ifaces.get("org.bluez.Device1")
        if dev and (dev.get("Paired") or dev.get("Connected")):
            battery = ifaces.get("org.bluez.Battery1", {}).get("Percentage")
            icon = str(dev.get("Icon", ""))
            devices.append({
                "mac": str(dev.get("Address", "")),
                # eww runs label :text through unescape, so a lone backslash must be doubled.
                "name": str(dev.get("Alias") or dev.get("Name") or dev.get("Address")).replace("\\", "\\\\"),
                "icon": ICONS.get(icon, "󰂯"),
                "connected": bool(dev.get("Connected", False)),
                "battery": int(battery) if battery is not None else -1,
            })
    devices.sort(key=lambda d: (not d["connected"], d["name"].lower()))
    connected = [d["name"] for d in devices if d["connected"]]
    return {"on": powered, "devices": devices, "connected": connected}


def emit():
    global last, pending
    pending = False
    try:
        state = snapshot()
    except dbus.DBusException:
        state = {"on": False, "devices": [], "connected": []}
    line = json.dumps(state, separators=(",", ":"))
    if line != last:
        last = line
        print(line, flush=True)
    return False


def schedule(*_args, **_kw):
    global pending
    if not pending:
        pending = True
        GLib.timeout_add(150, emit)


for sig, iface in (("PropertiesChanged", "org.freedesktop.DBus.Properties"),
                   ("InterfacesAdded", "org.freedesktop.DBus.ObjectManager"),
                   ("InterfacesRemoved", "org.freedesktop.DBus.ObjectManager")):
    bus.add_signal_receiver(schedule, signal_name=sig, dbus_interface=iface, bus_name="org.bluez")
bus.add_signal_receiver(schedule, signal_name="NameOwnerChanged", dbus_interface="org.freedesktop.DBus",
                        arg0="org.bluez")

emit()
GLib.MainLoop().run()
