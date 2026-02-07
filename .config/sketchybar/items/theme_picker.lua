local config_dir = os.getenv("CONFIG_DIR")
local theme_file = config_dir .. "/helpers/active_theme.txt"

-- 1. The Trigger Item (The anchor for the popup)
local picker_trigger = SBAR.add("item", "theme_picker", {
	position = "right",
	icon = {
		string = "󰏘",
		font = { size = 18.0 },
	},
	label = { drawing = false },
})

-- 2. Alphabetical Sorting Logic
local sorted_scheme_names = {}
for name, _ in pairs(COLORS.all_schemes) do
	table.insert(sorted_scheme_names, name)
end
table.sort(sorted_scheme_names) -- Sorts the table A-Z

-- 3. Create the Popup Content
-- We iterate through all schemes and add them as popup items
for _, scheme_name in ipairs(sorted_scheme_names) do
	local scheme = COLORS.all_schemes[scheme_name]
	local is_active = (COLORS.active_scheme_name == scheme_name) -- Check if this is the current theme
	-- Define the click script ONLY if it's not the active one
	local script
	if not is_active then
		script = "echo '" .. scheme_name .. "' > " .. theme_file .. " && sketchybar --reload"
	else
		-- If already active, just close the popup when clicked
		script = "sketchybar --set " .. picker_trigger.name .. " popup.drawing=off"
	end
	local dot = SBAR.add("item", "theme.dot." .. scheme_name, {
		position = "popup." .. picker_trigger.name,
		icon = {
			string = is_active and "􀃳" or "􀀁", -- Checkmark circle vs solid circle
			color = scheme.accent_color,
		},
		label = {
			string = scheme_name:gsub("_", " "):gsub("^%l", string.upper), -- Capitalize name
			color = is_active and COLORS.accent_color or COLORS.disabled_color,
			font = { style = is_active and "Bold" or "Regular" },
		},
		click_script = script,
	})

	-- Hover effect for the popup items
	dot:subscribe("mouse.entered", function()
		dot:set({
			label = { color = COLORS.accent_color },
		})
	end)
	dot:subscribe("mouse.exited", function()
		dot:set({
			label = { color = is_active and COLORS.accent_color or COLORS.disabled_color },
		})
	end)
end

-- 3. Toggle Logic
-- Clicking the trigger shows/hides the popup
picker_trigger:subscribe("mouse.clicked", function()
	local current_state = picker_trigger:query().popup.drawing
	picker_trigger:set({ popup = { drawing = (current_state == "off") } })
end)

-- Optional: Close popup if mouse leaves the area
picker_trigger:subscribe("mouse.exited.global", function()
	picker_trigger:set({ popup = { drawing = false } })
end)
