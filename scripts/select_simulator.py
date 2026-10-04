"""Choose an installed iPhone; prefer the user's iPhone 15 Pro when available."""
import json
import subprocess

devices = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "--json"]))["devices"]
phones = [d for runtime, entries in devices.items() if "iOS" in runtime for d in entries if d["name"].startswith("iPhone")]
if not phones:
    raise SystemExit("No iOS simulator is installed in this runner image")
phone = next((d for d in phones if d["name"] == "iPhone 15 Pro"), phones[0])
print("id=" + phone["udid"])
print("name=" + phone["name"])
