"""Reuse a booted iPhone; otherwise prefer iPhone 15 Pro for the CI layout."""
import json
import subprocess

devices = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "--json"]))["devices"]
phones = [d for runtime, entries in devices.items() if "iOS" in runtime for d in entries if d["name"].startswith("iPhone")]
if not phones:
    raise SystemExit("No iOS simulator is installed in this runner image")
phone = next((d for d in phones if d["state"] == "Booted"), None)
if phone is None:
    phone = next((d for d in phones if d["name"] == "iPhone 15 Pro"), None)
if phone is None:
    device_types = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devicetypes", "--json"]))["devicetypes"]
    requested = next((d for d in device_types if d["name"] == "iPhone 15 Pro"), None)
    runtime = next((r for r, entries in devices.items() if "iOS" in r and any(d["name"].startswith("iPhone") for d in entries)), None)
    if requested and runtime:
        device_id = subprocess.check_output(["xcrun", "simctl", "create", "iPhone 15 Pro", requested["identifier"], runtime], text=True).strip()
        phone = {"name": "iPhone 15 Pro", "udid": device_id}
    else:
        phone = phones[0]
print("id=" + phone["udid"])
print("name=" + phone["name"])
