SBAR.add("event", "after_unlock", "com.apple.screenIsUnlocked")
local unlock_handler = SBAR.add("item", { drawing = false })

unlock_handler:subscribe("after_unlock", function()
	SBAR.exec([[
        # 1. Kill and wait for death (prevent overlap)
        pkill -9 AeroSpace
        while pgrep -x AeroSpace >/dev/null; do sleep 0.1; done

        # 2. Launch AeroSpace
        open -a AeroSpace

        # 3. Wait for life (prevent Sketchybar from loading too early)
        # We try to list workspaces. This fails until AeroSpace is ready.
        until aerospace list-workspaces >/dev/null 2>&1; do sleep 0.1; done

        # 4. Finally reload UI
        sketchybar --reload
    ]])
end)
