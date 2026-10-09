-- Live theme switching: a theme is a colour scheme (looks.lua) worn
-- in a look (helpers/shapes.lua). Swaps COLORS in place, reshapes and
-- recolours every item, pill and popup, then runs each module's hook
-- so items with colour logic of their own (state colours, graphs, the
-- picker's ticks) re-render. No `sketchybar --reload`, so no flash.
local M = {
	hooks = {},
	pills = { "menus.bracket", "right.bracket", "resources.bracket", "spotify.bracket" },
}

-- Items whose label is a WORD register here; a theme switch re-sets
-- their font (numbers and icons keep Hack and are not listed).
M.words = {}
function M.track_word(item, scale)
	table.insert(M.words, { item = item, scale = scale })
	return item
end

-- A module registers how it recolours itself.
function M.on_change(fn)
	table.insert(M.hooks, fn)
end

local function popup_color()
	return LOOK.with_alpha(COLORS.popup_background, COLORS.shape.popup_alpha)
end

local function write(path, text)
	local f = io.open(path, "w")
	if f then
		f:write(text .. "\n")
		f:close()
	end
end

-- The look's sketchybar half: pill shape, popup cover, and for a
-- strip look one painted bar instead of pills. Also run once at load
-- (init.lua), the pills existing only then.
function M.apply_shape()
	local shape = COLORS.shape
	local pill = {
		color = COLORS.background,
		border_color = shape.accent_border and COLORS.accent_color or COLORS.background_border,
		border_width = shape.border,
		corner_radius = shape.radius,
		height = shape.height,
	}
	DEFAULT_ITEM.background.border_width = shape.border
	DEFAULT_ITEM.background.corner_radius = shape.radius
	DEFAULT_ITEM.background.height = shape.height
	DEFAULT_ITEM.popup.blur_radius = shape.blur
	DEFAULT_ITEM.popup.background.corner_radius = shape.radius
	for _, name in ipairs(M.pills) do
		SBAR.set(name, { background = pill })
		-- Separately, after: setting a colour turns a background on.
		SBAR.set(name, { background = { drawing = not shape.strip } })
	end
	SBAR.bar({
		color = shape.strip and COLORS.background or 0x00000000,
		border_color = COLORS.background_border,
		border_width = 0,
		corner_radius = shape.strip and shape.radius or 0,
		-- No blur: KiwiDesk's flat fill has none, so the band matches.
		blur_radius = 0,
	})
end

-- KiwiDesk keeps its profile's look until one is PICKED.
local function render(name, push_look)
	if not COLORS.use(name) then
		return
	end
	write(COLORS.theme_file, name)
	write(COLORS.look_file, COLORS.look_pin)
	-- Modules read their defaults from DEFAULT_ITEM: keep it current.
	DEFAULT_ITEM.icon.color = COLORS.text_color
	DEFAULT_ITEM.label.color = COLORS.text_color
	DEFAULT_ITEM.background.color = COLORS.background
	DEFAULT_ITEM.background.border_color = COLORS.background_border
	DEFAULT_ITEM.popup.background.color = popup_color()
	DEFAULT_ITEM.popup.background.border_color = COLORS.background_border

	SBAR.set("/.*/", {
		icon = { color = COLORS.text_color },
		label = { color = COLORS.text_color },
		popup = {
			blur_radius = COLORS.shape.blur,
			background = {
				color = popup_color(),
				border_color = COLORS.background_border,
				corner_radius = COLORS.shape.radius,
			},
		},
	})
	for _, w in ipairs(M.words) do
		w.item:set({ label = { font = LOOK.word_font(w.scale) } })
	end
	for _, fn in ipairs(M.hooks) do
		fn()
	end
	-- After the hooks: one recolouring a pill would turn it back on.
	M.apply_shape()
	-- KiwiDesk follows in the background: the shape first, then the
	-- colours (the glass tint depends on the look).
	local command = COLORS.kiwidesk_command(COLORS)
	if push_look then
		command = COLORS.shapes.kiwidesk_command(COLORS.look, push_look == "force") .. "; " .. command
	end
	SBAR.exec(command)
end

-- Picks a colour scheme; the look stays.
function M.apply(name)
	render(name, false)
end

-- Picks a look with its own palette; a colour picked afterwards
-- changes the colours only.
function M.apply_look(look)
	if not COLORS.shapes.presets[look] then
		return
	end
	-- The active look picked again re-sends all of it (e.g. after
	-- KiwiDesk's own settings were changed).
	local again = look == COLORS.look
	COLORS.look_pin = look
	local scheme = COLORS.active_scheme_name
	local palette = COLORS.shapes.palettes[look]
	if palette and COLORS.all_schemes[palette] then
		scheme = palette
	end
	render(scheme, again and "force" or true)
end

return M
