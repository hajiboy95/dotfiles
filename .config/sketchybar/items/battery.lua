local battery = SBAR.add("item", "battery", {
	position = "right",
	update_freq = 120,
	icon = {
		font = {
			family = "Hack Nerd Font",
			style = "Regular",
		},
	},
	label = { drawing = false }, -- Hidden by default
})

local function battery_update()
	SBAR.exec("pmset -g batt", function(batt_info)
		local found, _, charge = batt_info:find("(%d+)%%")

		if found then
			local charge_num = tonumber(charge)
			local is_charging = batt_info:find("AC Power")

			-- 1. COLOR & LABEL LOGIC
			local color = COLORS.accent_color
			local should_draw_label = false

			if charge_num < 10 then
				color = COLORS.red
				should_draw_label = true
			elseif charge_num < 30 then
				color = COLORS.orange
				should_draw_label = true
			end

			-- 2. ICON LOGIC
			local icon
			if is_charging then
				icon = ""
				color = COLORS.charging
				should_draw_label = false
			else
				if charge_num > 90 then
					icon = ""
				elseif charge_num > 60 then
					icon = ""
				elseif charge_num > 40 then
					icon = ""
				elseif charge_num > 10 then
					icon = ""
				else
					icon = ""
				end
			end

			-- Apply the updates
			battery:set({
				icon = { string = icon, color = color },
				label = { string = charge .. "%", color = color, drawing = should_draw_label },
			})
		end
	end)
end

-- 3. INTERACTION
-- Show percentage when hovering, hide when leaving (unless battery is low)
battery:subscribe("mouse.entered", function()
	battery:set({ label = { drawing = true } })
end)

battery:subscribe("mouse.exited", function()
	-- Re-run the update logic to decide if label should hide or stay (based on low battery)
	battery_update()
end)

battery:subscribe({ "routine", "power_source_change", "system_woke" }, battery_update)
