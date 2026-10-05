"""Stream a command's log and stop silent or stalled CI work before it burns quota."""
import argparse
import os
from pathlib import Path
import queue
import signal
import subprocess
import sys
import threading
import time

parser = argparse.ArgumentParser()
parser.add_argument("--log", required=True)
parser.add_argument("--idle-timeout", type=float, default=180)
parser.add_argument("--wall-timeout", type=float, default=1200)
parser.add_argument("command", nargs=argparse.REMAINDER)
args = parser.parse_args()
command = args.command[1:] if args.command[:1] == ["--"] else args.command
if not command:
    parser.error("a command is required")

process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                           text=True, bufsize=1, start_new_session=os.name != "nt")
lines = queue.Queue()

def read_output():
    for line in process.stdout:
        lines.put(line)
    lines.put(None)

threading.Thread(target=read_output, daemon=True).start()
started = last_output = time.monotonic()
timed_out = False
Path(args.log).parent.mkdir(parents=True, exist_ok=True)
with open(args.log, "w", encoding="utf-8") as log:
    while True:
        try:
            line = lines.get(timeout=0.25)
            if line is None:
                break
            log.write(line)
            log.flush()
            print(line, end="", flush=True)
            last_output = time.monotonic()
        except queue.Empty:
            pass
        now = time.monotonic()
        if now - last_output > args.idle_timeout or now - started > args.wall_timeout:
            reason = "no output" if now - last_output > args.idle_timeout else "wall time"
            message = f"\nCI watchdog stopped the command: {reason} limit exceeded.\n"
            log.write(message)
            print(message, flush=True)
            timed_out = True
            if os.name == "nt":
                process.terminate()
            else:
                os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                if os.name == "nt":
                    process.kill()
                else:
                    os.killpg(process.pid, signal.SIGKILL)
            break

sys.exit(124 if timed_out else process.wait())
