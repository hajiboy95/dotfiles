local battery = SBAR.add("item", "battery", {
	position = "right",
	update_freq = 120,
	label = { drawing = true },
})

local function battery_update()
	SBAR.exec("pmset -g batt", function(batt_info)
		local icon
		local found, _, charge = batt_info:find("(%d+)%%")

		if found then
			local charge_num = tonumber(charge)
			local found_ac = batt_info:find("AC Power")

			-- LOGIC CHANGE: Check for AC first
			if found_ac then
				icon = ""
			else
				-- Only check discharge levels if we are NOT charging
				if charge_num > 90 then
					icon = ""
				elseif charge_num > 60 then
					icon = ""
				elseif charge_num > 30 then
					icon = ""
				elseif charge_num > 10 then
					icon = ""
				else
					icon = ""
				end
			end

			battery:set({
				icon = icon,
				label = charge .. "%",
			})
		end
	end)
end

battery:subscribe({ "routine", "power_source_change" }, battery_update)
