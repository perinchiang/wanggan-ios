"""Work around WebKit bug 293831 in Xcode 16.4 / iOS 18.4-18.5 simulators.

Apple's workaround links the runtime's Swift overlay into the build products
directory. This affects simulator testing only; no library goes into the IPA.
https://developer.apple.com/forums/thread/785964
"""
import argparse
import json
from pathlib import Path
import subprocess


def prepare(device_id, products, devices, runtimes, xcode_version):
    runtime_id = next((key for key, entries in devices.items()
                       if any(device["udid"] == device_id for device in entries)), None)
    runtime = next((entry for entry in runtimes if entry["identifier"] == runtime_id), None)
    if runtime is None:
        raise RuntimeError("Selected simulator runtime was not found")
    if xcode_version.splitlines()[0] != "Xcode 16.4" or runtime["version"] not in {"18.4", "18.5"}:
        print("Selected toolchain/runtime does not require the WebKit 293831 workaround")
        return
    library = (Path(runtime["bundlePath"]) / "Contents/Resources/RuntimeRoot"
               / "System/Cryptexes/OS/usr/lib/swift/libswiftWebKit.dylib")
    if not library.is_file():
        raise RuntimeError(f"WebKit workaround library is missing: {library}")
    products = Path(products)
    products.mkdir(parents=True, exist_ok=True)
    link = products / library.name
    if link.is_symlink():
        link.unlink()
    elif link.exists():
        raise RuntimeError("Refusing to replace an existing build product")
    link.symlink_to(library)
    print(f"Simulator-only WebKit overlay: {link} -> {library}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--device", required=True)
    parser.add_argument("--products", required=True)
    args = parser.parse_args()
    devices = json.loads(subprocess.check_output(
        ["xcrun", "simctl", "list", "devices", "--json"]))["devices"]
    runtimes = json.loads(subprocess.check_output(
        ["xcrun", "simctl", "list", "runtimes", "--json"]))["runtimes"]
    xcode_version = subprocess.check_output(["xcodebuild", "-version"], text=True)
    prepare(args.device, args.products, devices, runtimes, xcode_version)
