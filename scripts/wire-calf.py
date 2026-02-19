#!/usr/bin/env python3
"""
Wire up all Calf plugins in JACK in series (stereo-aware)
"""

import jack
import re

def get_calf_ports(client):
    """
    Return a list of Calf plugin clients in order, each with their input/output ports.
    Returns: [{'name': client_name, 'inputs': [Port,...], 'outputs':[Port,...]}, ...]
    """
    all_ports = client.get_ports()
    clients = {}

    port_regex = re.compile(r"^(.*) (In|Out) #(\d+)$")  # Capture: plugin, In/Out, channel

    for port in all_ports:
        pname = port.name
        if "Calf" not in pname:
            continue  # adjust for your installed plugins

        m = port_regex.match(pname)
        if not m:
            continue

        plugin_name, io_type, channel = m.groups()
        channel = int(channel)

        clients.setdefault(plugin_name, {"inputs": [], "outputs": []})
        if io_type == "In":
            clients[plugin_name]["inputs"].append((channel, port))
        else:
            clients[plugin_name]["outputs"].append((channel, port))

    for c in clients.values():
        c["inputs"].sort(key=lambda x: x[0])
        c["outputs"].sort(key=lambda x: x[0])
        c["inputs"] = [p for _, p in c["inputs"]]
        c["outputs"] = [p for _, p in c["outputs"]]

    return [{"name": k, **v} for k, v in clients.items()]

def wire_calf_series(client):
    calf_clients = get_calf_ports(client)
    if not calf_clients:
        print("No Calf clients found in JACK.")
        return

    print("Found Calf clients (in order):")
    for c in calf_clients:
        print(" ", c["name"])

    for i in range(len(calf_clients) - 1):
        src = calf_clients[i]["outputs"]
        dst = calf_clients[i + 1]["inputs"]

        for o, d in zip(src, dst):
            try:
                client.connect(o, d)
                print(f"Connected {o} → {d}")
            except jack.JackError as e:
                print(f"Failed to connect {o} → {d}: {e}")

    print("Done wiring Calf plugins in series.")
    print("First input and last output remain unconnected.")

def main():
    with jack.Client("calf_wirer") as client:
        wire_calf_series(client)

if __name__ == "__main__":
    main()
