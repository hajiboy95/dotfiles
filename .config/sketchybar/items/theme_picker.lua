-- THEME PICKER: one popup, two pages (a native submenu).
--   Colour page: a "Look" row naming the look worn (scrolling over it
--   steps through the looks), then every colour scheme.
--   Look page: back to Colour, then the looks.
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

-- A-Z, but KiwiDesk first: the one that is not ours (the profile's
-- own colours, the profile's own look).
local function kiwidesk_first(label_of)
	return function(a, b)
		if (a == "kiwidesk") ~= (b == "kiwidesk") then
			return a == "kiwidesk"
		end
		return label_of(a) < label_of(b)
	end
end

local sorted_scheme_names = {}
for name, _ in pairs(COLORS.all_schemes) do
	table.insert(sorted_scheme_names, name)
end

local function scheme_label(name)
	local scheme = COLORS.all_schemes[name]
	return scheme.label or name:gsub("_", " "):gsub("^%l", string.upper)
end

local function look_label(name)
	return shapes.labels[name] or name
end
table.sort(sorted_scheme_names, kiwidesk_first(scheme_label))

-- The hover box sits inside the popup's rounded frame: inset 4 pt,
-- a row's height less 2, corners concentric with the popup's, no
-- border (the default pill's border drew past the frame).
local row_inset = 4
local function hover()
	return {
		drawing = true,
		color = LOOK.with_alpha(COLORS.text_color, 0x22),
		height = 22,
		corner_radius = math.max(COLORS.shape.radius - row_inset, 0),
		border_width = 0,
	}
end

-- A clickable row: glyph slot plus a fixed-width label.
local function row(name, page_items)
	local item = SBAR.add("item", "theme." .. name, {
		position = "popup." .. picker_trigger.name,
		padding_left = row_inset,
		padding_right = row_inset,
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
		item:set({ background = hover() })
	end)
	item:subscribe("mouse.exited", function()
		item:set({ background = { drawing = false } })
	end)
	table.insert(page_items, item)
	return item
end

local colour_page, look_page = {}, {}

-- The page switch sits in the first row of both pages, so clicking
-- the same spot flips back and forth.
local look_row = row("look_row", colour_page)
local back_row = row("back", look_page)

-- Colour page
local dots = {}
for _, scheme_name in ipairs(sorted_scheme_names) do
	dots[scheme_name] = row("dot." .. scheme_name, colour_page)
end

-- Look page, ordered like the colours.
local sorted_look_names = {}
for _, name in ipairs(shapes.order) do
	table.insert(sorted_look_names, name)
end
table.sort(sorted_look_names, kiwidesk_first(look_label))
local look_rows = {}
for _, name in ipairs(sorted_look_names) do
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
			icon = { string = active and "􀃳" or "􀀁", color = resolved.swatch or resolved.accent_color },
			label = {
				string = scheme_label(name),
				color = active and COLORS.accent_color or COLORS.disabled_color,
			},
		})
	end
	look_row:set({
		icon = { string = shapes.glyphs[COLORS.look], color = COLORS.accent_color },
		label = { string = "Look · " .. look_label(COLORS.look) .. "  ›", color = COLORS.text_color },
	})
	back_row:set({
		icon = { string = "󰁍", color = COLORS.disabled_color },
		label = { string = "Colour · " .. scheme_label(active_scheme), color = COLORS.text_color },
	})
	for name, item in pairs(look_rows) do
		local active = COLORS.look == name
		-- ✓ the look in its own palette, (✓) worn with another colour.
		local own_palette = shapes.palettes[name] == active_scheme
		local tick = active and (own_palette and "  ✓" or "  (✓)") or ""
		item:set({
			icon = { string = shapes.glyphs[name], color = active and COLORS.accent_color or COLORS.disabled_color },
			label = {
				string = look_label(name) .. tick,
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
-- The switch row of the new page lands under the cursor, which never
-- "entered" it: light it as hovered.
look_row:subscribe("mouse.clicked", function()
	set_page("look")
	back_row:set({ background = hover() })
end)
back_row:subscribe("mouse.clicked", function()
	set_page("colour")
	look_row:set({ background = hover() })
end)
for name, item in pairs(look_rows) do
	item:subscribe("mouse.clicked", function()
		THEME.apply_look(name)
	end)
end

-- Scroll over the Look row: a look per notch, in the page's order.
local cycle = sorted_look_names
look_row:subscribe("mouse.scrolled", function(env)
	local delta = tonumber(env.SCROLL_DELTA) or 0
	if delta == 0 then
		return
	end
	local current = COLORS.look
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
-- `sketchybar --trigger look_set LOOK=<name>`.
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
