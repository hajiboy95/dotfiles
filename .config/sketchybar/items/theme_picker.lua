-- THEME PICKER: one popup, two pages (a native submenu).
--   Colour page: every colour scheme, then a "Look" row naming the
--   look worn; scrolling over that row steps through the looks.
--   Look page: back to Colour, Auto (the scheme's own look), the looks.
-- A pick applies live (helpers/theme) and the popup stays open, so
-- combinations can be tried. Active rows differ in shape, not only
-- colour (􀃳 vs 􀀁, ✓), for red-green colour vision.
local shapes = COLORS.shapes
local row_label_width = 130 -- equal rows: the hover highlight spans the menu

local picker_trigger = SBAR.add("item", "theme_picker", {
	position = "right",
	icon = {
		string = "󰏘",
		font = { size = DEFAULT_ITEM.icon.font.size * 1.2 },
	},
	label = { drawing = false },
	popup = { align = "right", height = 24 },
})

local sorted_scheme_names = {}
for name, _ in pairs(COLORS.all_schemes) do
	table.insert(sorted_scheme_names, name)
end
table.sort(sorted_scheme_names)

local function scheme_label(name)
	local scheme = COLORS.all_schemes[name]
	return scheme.label or name:gsub("_", " "):gsub("^%l", string.upper)
end

local function look_label(name)
	return shapes.labels[name] or name
end

local function hover_color()
	return LOOK.with_alpha(COLORS.text_color, 0x22)
end

-- A clickable row: glyph slot plus a fixed-width label.
local function row(name, page_items)
	local item = SBAR.add("item", "theme." .. name, {
		position = "popup." .. picker_trigger.name,
		icon = { width = 22, padding_left = DEFAULT_ITEM.icon.padding_left, padding_right = 0 },
		label = {
			font = LOOK.word_font(),
			width = row_label_width,
			padding_left = 4,
			padding_right = DEFAULT_ITEM.icon.padding_right,
		},
	})
	THEME.track_word(item)
	item:subscribe("mouse.entered", function()
		item:set({ background = { drawing = true, color = hover_color() } })
	end)
	item:subscribe("mouse.exited", function()
		item:set({ background = { drawing = false } })
	end)
	table.insert(page_items, item)
	return item
end

-- Section caption: no hover, no click. Every popup row is one
-- height, so a 1 pt divider would still leave a blank row; a caption
-- puts that row to use (as tailscale's EXIT NODE).
local function caption(name, text, page_items)
	local item = SBAR.add("item", "theme." .. name, {
		position = "popup." .. picker_trigger.name,
		icon = { drawing = false },
		label = {
			string = text,
			font = LOOK.word_font(0.75),
			padding_left = DEFAULT_ITEM.icon.padding_left,
		},
	})
	THEME.track_word(item, 0.75)
	table.insert(page_items, item)
	return item
end

local colour_page, look_page = {}, {}
local captions = {}

-- Colour page
local dots = {}
for _, scheme_name in ipairs(sorted_scheme_names) do
	dots[scheme_name] = row("dot." .. scheme_name, colour_page)
end
table.insert(captions, caption("look_caption", "LOOK", colour_page))
local look_row = row("look_row", colour_page)

-- Look page
local back_row = row("back", look_page)
local auto_row = row("look.auto", look_page)
local look_rows = {}
for _, name in ipairs(shapes.order) do
	look_rows[name] = row("look." .. name, look_page)
end

local function paint()
	local active_scheme = COLORS.active_scheme_name
	for name, dot in pairs(dots) do
		local active = name == active_scheme
		-- The dot wears the scheme as it would look now (teal's glass
		-- variant differs from its opaque one).
		local resolved = LOOK.resolve(name)
		dot:set({
			icon = { string = active and "􀃳" or "􀀁", color = resolved.accent_color },
			label = {
				string = scheme_label(name),
				color = active and COLORS.accent_color or COLORS.disabled_color,
			},
		})
	end
	for _, item in ipairs(captions) do
		item:set({ label = { color = COLORS.disabled_color } })
	end

	local pinned = COLORS.look_pin
	look_row:set({
		icon = { string = shapes.glyphs[COLORS.look], color = COLORS.accent_color },
		label = {
			string = look_label(COLORS.look) .. (pinned and "" or " · Auto") .. "  ›",
			color = COLORS.text_color,
		},
	})
	back_row:set({
		icon = { string = "󰁍", color = COLORS.disabled_color },
		label = { string = "Colour · " .. scheme_label(active_scheme), color = COLORS.text_color },
	})
	local default_look = COLORS.all_schemes[active_scheme].look or "glass"
	auto_row:set({
		icon = { string = shapes.glyphs.auto, color = pinned and COLORS.disabled_color or COLORS.accent_color },
		label = {
			string = "Auto · " .. look_label(default_look) .. (pinned and "" or "  ✓"),
			color = pinned and COLORS.disabled_color or COLORS.accent_color,
		},
	})
	for name, item in pairs(look_rows) do
		local active = pinned == name
		item:set({
			icon = { string = shapes.glyphs[name], color = active and COLORS.accent_color or COLORS.disabled_color },
			label = {
				string = look_label(name) .. (active and "  ✓" or ""),
				color = active and COLORS.accent_color or COLORS.disabled_color,
			},
		})
	end
end

-- Page switch: rows vanish under the cursor, which can read as the
-- mouse leaving; ignore exits briefly.
local ignore_exit = false
local function set_page(page)
	ignore_exit = true
	SBAR.delay(0.25, function()
		ignore_exit = false
	end)
	for _, item in ipairs(colour_page) do
		item:set({ drawing = page == "colour", background = { drawing = false } })
	end
	for _, item in ipairs(look_page) do
		item:set({ drawing = page == "look", background = { drawing = false } })
	end
end
set_page("colour")
ignore_exit = false

local function close()
	picker_trigger:set({ popup = { drawing = false } })
	set_page("colour")
end

-- Clicks. Picking the active entry re-sends it to KiwiDesk (e.g.
-- after KiwiDesk's own colours were changed).
for name, dot in pairs(dots) do
	dot:subscribe("mouse.clicked", function()
		THEME.apply(name)
	end)
end
look_row:subscribe("mouse.clicked", function()
	set_page("look")
end)
back_row:subscribe("mouse.clicked", function()
	set_page("colour")
end)
auto_row:subscribe("mouse.clicked", function()
	THEME.apply_look("auto")
end)
for name, item in pairs(look_rows) do
	item:subscribe("mouse.clicked", function()
		THEME.apply_look(name)
	end)
end

-- Scroll over the Look row: Auto, then each look, a step per notch.
local cycle = { "auto" }
for _, name in ipairs(shapes.order) do
	table.insert(cycle, name)
end
look_row:subscribe("mouse.scrolled", function(env)
	local delta = tonumber(env.SCROLL_DELTA) or 0
	if delta == 0 then
		return
	end
	local current = COLORS.look_pin or "auto"
	local index = 1
	for i, name in ipairs(cycle) do
		if name == current then
			index = i
		end
	end
	index = (index - 1 + (delta > 0 and -1 or 1)) % #cycle + 1
	THEME.apply_look(cycle[index])
end)

-- Scriptable too: `sketchybar --trigger theme_set THEME=<name>`,
-- `sketchybar --trigger look_set LOOK=<name|auto>`.
SBAR.add("event", "theme_set")
SBAR.add("event", "look_set")
picker_trigger:subscribe("theme_set", function(env)
	if env.THEME and COLORS.all_schemes[env.THEME] then
		THEME.apply(env.THEME)
	end
end)
picker_trigger:subscribe("look_set", function(env)
	if env.LOOK then
		THEME.apply_look(env.LOOK)
	end
end)

THEME.on_change(paint)
paint()

picker_trigger:subscribe("mouse.clicked", function()
	if picker_trigger:query().popup.drawing == "off" then
		picker_trigger:set({ popup = { drawing = true } })
	else
		close()
	end
end)

picker_trigger:subscribe("mouse.exited.global", function()
	if not ignore_exit then
		close()
	end
end)
