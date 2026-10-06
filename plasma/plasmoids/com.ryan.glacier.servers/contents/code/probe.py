#!/usr/bin/env python3
"""Probes the servers listed in ~/.config/glacier/servers.json and prints
their status as JSON. Minecraft servers are asked with the game's own
status ping, which needs no login."""
import json
import socket
import struct
import subprocess
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

CONFIG = Path.home() / ".config/glacier/servers.json"
TIMEOUT = 3


def varint(n):
    out = b""
    while True:
        b = n & 0x7F
        n >>= 7
        out += bytes([b | (0x80 if n else 0)])
        if not n:
            return out


def read_varint(sock):
    n = shift = 0
    while True:
        b = sock.recv(1)
        if not b:
            raise ConnectionError("closed")
        n |= (b[0] & 0x7F) << shift
        shift += 7
        if not b[0] & 0x80:
            return n


def minecraft(host, port):
    t0 = time.monotonic()
    with socket.create_connection((host, port), timeout=TIMEOUT) as s:
        s.settimeout(TIMEOUT)
        hb = host.encode()
        hs = varint(0) + varint(767) + varint(len(hb)) + hb + struct.pack(">H", port) + varint(1)
        s.sendall(varint(len(hs)) + hs + b"\x01\x00")
        read_varint(s)
        read_varint(s)
        ln = read_varint(s)
        data = b""
        while len(data) < ln:
            chunk = s.recv(ln - len(data))
            if not chunk:
                break
            data += chunk
    latency = round((time.monotonic() - t0) * 1000)
    j = json.loads(data)
    players = j.get("players", {})
    return {
        "up": True,
        "online": players.get("online", 0),
        "max": players.get("max", 0),
        "players": sorted(p.get("name", "") for p in players.get("sample", []) if p.get("name")),
        "version": j.get("version", {}).get("name", ""),
        "latency_ms": latency,
    }


def tcp(host, port):
    t0 = time.monotonic()
    with socket.create_connection((host, port), timeout=TIMEOUT):
        pass
    return {"up": True, "latency_ms": round((time.monotonic() - t0) * 1000)}


def ping(host):
    r = subprocess.run(["ping", "-c", "1", "-W", str(TIMEOUT), host], capture_output=True, text=True)
    if r.returncode != 0:
        raise ConnectionError("no reply")
    ms = None
    for part in r.stdout.split():
        if part.startswith("time="):
            ms = round(float(part[5:]))
    return {"up": True, "latency_ms": ms}


def probe(entry):
    kind = entry.get("type", "minecraft")
    host = entry.get("host", "")
    port = int(entry.get("port", 25565))
    result = {"name": entry.get("name", host), "type": kind, "host": host, "up": False}
    try:
        if kind == "minecraft":
            result.update(minecraft(host, port))
        elif kind == "tcp":
            result.update(tcp(host, port))
        elif kind == "ping":
            result.update(ping(host))
        else:
            result["error"] = f"unknown type {kind}"
    except Exception as e:  # noqa: BLE001 - any failure means "down"
        result["error"] = str(e)
    return result


def main():
    try:
        entries = json.loads(CONFIG.read_text())
    except Exception as e:  # noqa: BLE001
        print(json.dumps([{"name": "servers.json", "up": False, "error": str(e)}]))
        return
    with ThreadPoolExecutor(max_workers=8) as pool:
        print(json.dumps(list(pool.map(probe, entries))))


if __name__ == "__main__":
    main()
