SBAR.add("event", "after_unlock", "com.apple.screenIsUnlocked")
local unlock_handler = SBAR.add("item", { drawing = false })

unlock_handler:subscribe("after_unlock", function()
	SBAR.exec([[
        # 1. We MUST export PATH or 'sketchybar' and 'aerospace' commands won't be found
        export PATH=$PATH:/opt/homebrew/bin:/usr/local/bin

        # 2. Kill AeroSpace
        pkill AeroSpace

        # 3. Wait for it to die (Fixing your 'doner' typo here)
        while pgrep -x AeroSpace >/dev/null; do sleep 0.1; done

        # 4. Open AeroSpace in background
        open -g -a AeroSpace

        # 5. Reload SketchyBar to reconnect to the new AeroSpace instance
        sketchybar --reload
    ]])
end)
