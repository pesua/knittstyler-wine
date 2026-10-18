"""Export registry subtrees from an offline hive to a .reg file (REGEDIT5, UTF-16LE).
Usage: hive-to-reg.py <hive> <root-name e.g. HKEY_CURRENT_USER> <out.reg> <key-path>...
"""
import sys
from regipy.registry import RegistryHive

hive_path, root, out_path, *wanted = sys.argv[1:]
hive = RegistryHive(hive_path)
wanted = [w.strip("\\").lower() for w in wanted]


def quote(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def hexlist(b):
    return ",".join(f"{x:02x}" for x in b)


def fmt(v):
    t, val = v["value_type"], v["value"]
    if t == "REG_SZ":
        return quote(val or "")
    if t == "REG_DWORD":
        return f"dword:{int(val) & 0xffffffff:08x}"
    raw = val if isinstance(val, (bytes, bytearray)) else bytes.fromhex(val)
    kind = {"REG_BINARY": "hex", "REG_EXPAND_SZ": "hex(2)", "REG_MULTI_SZ": "hex(7)"}.get(t, "hex(0)")
    return f"{kind}:{hexlist(raw)}"


lines = ["Windows Registry Editor Version 5.00", ""]
for entry in hive.recurse_subkeys(as_json=True):
    path = entry.path.strip("\\")
    if not any(path.lower() == w or path.lower().startswith(w + "\\") for w in wanted):
        continue
    lines.append(f"[{root}\\{path}]")
    for v in entry.values or []:
        name = "@" if v["name"] in ("", "(default)") else quote(v["name"])
        lines.append(f"{name}={fmt(v)}")
    lines.append("")
with open(out_path, "w", encoding="utf-16", newline="\r\n") as f:
    f.write("\n".join(lines) + "\n")
