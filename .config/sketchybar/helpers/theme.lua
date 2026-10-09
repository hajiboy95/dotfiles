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
		drawing = not shape.strip,
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
	end
	SBAR.bar({
		color = shape.strip and COLORS.background or 0x00000000,
		border_color = COLORS.background_border,
		border_width = 0,
		corner_radius = shape.strip and shape.radius or 0,
		blur_radius = shape.strip and shape.blur or 0,
	})
end

-- KiwiDesk keeps its profile's look until one is PICKED; after that a
-- colour pick re-sends the look only when the effective one changed.
local pushed_look = nil

local function render(name, push_look)
	if not COLORS.use(name) then
		return
	end
	write(COLORS.theme_file, name)
	write(COLORS.look_file, COLORS.look_pin or "auto")
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
	M.apply_shape()
	for _, w in ipairs(M.words) do
		w.item:set({ label = { font = LOOK.word_font(w.scale) } })
	end
	for _, fn in ipairs(M.hooks) do
		fn()
	end
	-- KiwiDesk follows in the background: the shape first, then the
	-- colours (the glass tint depends on the look).
	local command = COLORS.kiwidesk_command(COLORS)
	if push_look or (pushed_look and pushed_look ~= COLORS.look) then
		command = COLORS.shapes.kiwidesk_command(COLORS.look) .. "; " .. command
		pushed_look = COLORS.look
	end
	SBAR.exec(command)
end

-- Picks a colour scheme; its default look follows unless one is pinned.
function M.apply(name)
	render(name, false)
end

-- Picks a look by name (pinned), or "auto" for the scheme's default.
function M.apply_look(look)
	if look == "auto" then
		COLORS.look_pin = nil
	elseif COLORS.shapes.presets[look] then
		COLORS.look_pin = look
	else
		return
	end
	render(COLORS.active_scheme_name, true)
end

return M
