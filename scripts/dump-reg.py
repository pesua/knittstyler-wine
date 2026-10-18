"""Dump registry subtrees from offline hives as JSON lines. Usage: dump-reg.py <hive> <key-path-substring>..."""
import sys, json
from regipy.registry import RegistryHive

hive = RegistryHive(sys.argv[1])
needles = [n.lower() for n in sys.argv[2:]]
for entry in hive.recurse_subkeys(as_json=True):
    if any(n in entry.path.lower() for n in needles):
        vals = {v["name"]: v["value"] for v in (entry.values or [])}
        print(json.dumps({"path": entry.path, "values": vals}, ensure_ascii=False, default=str))
