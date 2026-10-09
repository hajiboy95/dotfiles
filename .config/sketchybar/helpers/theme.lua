-- Live theme switching: swaps COLORS in place, recolours every item,
-- pill and popup, then runs each module's hook so items with colour
-- logic of their own (state colours, graphs, the picker's ticks)
-- re-render. No `sketchybar --reload`, so no flash.
local M = { hooks = {}, pills = { "menus.bracket", "right.bracket", "resources.bracket", "spotify.bracket" } }

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
	return LOOK.with_alpha(COLORS.popup_background, 0x80)
end

function M.apply(name)
	if not COLORS.use(name) then
		return
	end
	local f = io.open(COLORS.theme_file, "w")
	if f then
		f:write(name .. "\n")
		f:close()
	end
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
			background = { color = popup_color(), border_color = COLORS.background_border },
		},
	})
	-- Only the brackets that draw a pill: setting a background's colour
	-- also turns it on, so a regex would light up undrawn ones too.
	for _, pill in ipairs(M.pills) do
		SBAR.set(pill, {
			background = { color = COLORS.background, border_color = COLORS.background_border },
		})
	end
	for _, w in ipairs(M.words) do
		w.item:set({ label = { font = LOOK.word_font(w.scale) } })
	end
	for _, fn in ipairs(M.hooks) do
		fn()
	end
	-- KiwiDesk follows in the background.
	SBAR.exec(COLORS.kiwidesk_command(COLORS.all_schemes[name]))
end

return M
