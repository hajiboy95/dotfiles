#!/usr/bin/env python3
import sys
import json
import time
import subprocess

if len(sys.argv) < 3:
    sys.exit(1)

app, bundle = sys.argv[1], sys.argv[2]

res = subprocess.run(
    ["/opt/homebrew/bin/rift-cli", "query", "workspaces"],
    capture_output=True,
    text=True,
)
if res.returncode == 0:
    workspaces = json.loads(res.stdout)
    active_idx = next((ws["index"] for ws in workspaces if ws.get("is_active")), None)
    win_ids = [
        win["window_server_id"]
        for ws in workspaces
        for win in ws.get("windows", [])
        if app.lower() in win.get("app_name", "").lower()
        or bundle.lower() == win.get("bundle_id", "").lower()
    ]

    if win_ids and active_idx is not None:
        for win_id in win_ids:
            subprocess.run(
                [
                    "/opt/homebrew/bin/rift-cli",
                    "execute",
                    "workspace",
                    "move-window",
                    str(active_idx),
                    str(win_id),
                ]
            )
        time.sleep(0.05)
        subprocess.run(["osascript", "-e", f'tell application "{app}" to activate'])
        sys.exit(0)

subprocess.run(["open", "-a", app])
