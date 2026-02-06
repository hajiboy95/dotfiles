#!/usr/bin/env python3
import json
import subprocess
import os
import sys


def add_clipboard(clipboard_file, max_items):
    clipboard_file = os.path.expanduser(clipboard_file)
    try:
        with open(clipboard_file, "r") as f:
            data = json.load(f)
    except Exception:
        data = {"clipboard": []}

    clip = subprocess.check_output("pbpaste").decode("utf-8")
    if clip and clip not in data["clipboard"]:
        data["clipboard"].append(clip)
        data["clipboard"] = data["clipboard"][-max_items:]
        with open(clipboard_file, "w") as f:
            json.dump(data, f, indent=4)
        sys.exit(0)  # Clipboard changed
    sys.exit(1)  # No change


def print_clipboard(clipboard_file):
    clipboard_file = os.path.expanduser(clipboard_file)
    try:
        with open(clipboard_file, "r") as f:
            data = json.load(f)
    except Exception:
        data = {"clipboard": []}
    for entry in data["clipboard"]:
        # Print each entry followed by a NUL char
        print(entry, end="\0")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: clipboard_json.py /path/to/clipboard.json MAX_ITEMS [--print]")
        sys.exit(2)
    clipboard_file = sys.argv[1]
    try:
        max_items = int(sys.argv[2])
    except ValueError:
        print("MAX_ITEMS must be an integer.")
        sys.exit(2)
    if len(sys.argv) > 3 and sys.argv[3] == "--print":
        print_clipboard(clipboard_file)
    else:
        add_clipboard(clipboard_file, max_items)
