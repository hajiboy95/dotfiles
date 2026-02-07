SBAR.add("event", "after_unlock", "com.apple.screenIsUnlocked")
local unlock_handler = SBAR.add("item", { drawing = false })

unlock_handler:subscribe("after_unlock", function()
	SBAR.exec([[
        # 1. Kill and wait for death (prevent overlap)
        pkill -9 AeroSpace
        while pgrep -x AeroSpace >/dev/null; do sleep 0.1; done

        # 2. Open AeroSpace in the background (-g) so it doesn't steal focus/flicker
        open -g -a AeroSpace

        # 3. Wait for AeroSpace to be ready (Sequential wait)
        until aerospace list-workspaces >/dev/null 2>&1; do sleep 0.1; done

        # 4. Finally reload Sketchybar
        sketchybar --reload
    ]])
end)
