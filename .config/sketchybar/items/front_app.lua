local icon_map = require("helpers.icon_map")

local front_app = SBAR.add("item", "front_app", {
	position = "left",
	icon = {
		font = { family = "sketchybar-app-font", style = "Regular" },
	},
})

local function update_front_app()
	SBAR.exec("aerospace list-windows --focused --format '%{app-name}'", function(app_name)
		local app_name_trimmed = app_name:gsub("\n", "")
		if app_name_trimmed ~= "" then
			local icon = icon_map[app_name_trimmed] or icon_map["Default"] or "APP"
			front_app:set({
				drawing = true,
				icon = { string = icon },
				label = { string = app_name_trimmed },
			})
		else
			front_app:set({ drawing = false })
		end
	end)
end

-- 3. Subscribe
front_app:subscribe({ "space_windows_change", "front_app_switched" }, function()
	SBAR.delay(0.5, update_front_app)
end)

update_front_app()
