-- 1. The Trigger Item (The anchor for the popup)
local picker_trigger = SBAR.add("item", "theme_picker", {
	position = "right",
	icon = {
		string = "󰏘",
		font = { size = DEFAULT_ITEM.icon.font.size * 1.2 },
	},
	label = { drawing = false },
	popup = { align = "right" },
})

-- 2. Alphabetical Sorting Logic
local sorted_scheme_names = {}
for name, _ in pairs(COLORS.all_schemes) do
	table.insert(sorted_scheme_names, name)
end
table.sort(sorted_scheme_names) -- Sorts the table A-Z

-- 3. Create the Popup Content. A pick switches live (helpers/theme):
-- COLORS swap in place and every item recolours, no reload.
local dots = {}

local function is_active(name)
	return COLORS.active_scheme_name == name
end

local function paint_dot(name)
	local active = is_active(name)
	dots[name]:set({
		icon = { string = active and "􀃳" or "􀀁", color = COLORS.all_schemes[name].accent_color },
		-- The tick and the colour mark the active theme (a custom font
		-- may have no bold).
		label = { color = active and COLORS.accent_color or COLORS.disabled_color },
	})
end

for _, scheme_name in ipairs(sorted_scheme_names) do
	local scheme = COLORS.all_schemes[scheme_name]
	local dot = SBAR.add("item", "theme.dot." .. scheme_name, {
		position = "popup." .. picker_trigger.name,
		label = {
			string = scheme.label or scheme_name:gsub("_", " "):gsub("^%l", string.upper),
			font = LOOK.word_font(),
		},
	})
	dots[scheme_name] = THEME.track_word(dot)
	paint_dot(scheme_name)

	-- Picking the active theme re-sends it to KiwiDesk (e.g. after
	-- KiwiDesk's own colours were changed).
	dot:subscribe("mouse.clicked", function()
		picker_trigger:set({ popup = { drawing = false } })
		THEME.apply(scheme_name)
	end)
	dot:subscribe("mouse.entered", function()
		dot:set({ label = { color = COLORS.accent_color }, background = { drawing = true } })
	end)
	dot:subscribe("mouse.exited", function()
		dot:set({
			label = { color = is_active(scheme_name) and COLORS.accent_color or COLORS.disabled_color },
			background = { drawing = false },
		})
	end)
end

-- Scriptable too: `sketchybar --trigger theme_set THEME=<name>`.
SBAR.add("event", "theme_set")
picker_trigger:subscribe("theme_set", function(env)
	if env.THEME and COLORS.all_schemes[env.THEME] then
		THEME.apply(env.THEME)
	end
end)

THEME.on_change(function()
	for name in pairs(dots) do
		paint_dot(name)
	end
end)

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
