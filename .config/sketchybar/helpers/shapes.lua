-- Looks: the shape half of a theme, apart from its colours. Each
-- colour scheme names a default look (looks.lua); a look picked in
-- the theme picker pins over it. A look writes EVERY key below, so
-- nothing of the previous one lingers (a colour-only palette that
-- bundled a glow could never switch it off again: KiwiDesk #578).
-- Never written: edges and thickness. Two keys move windows and are
-- set only by the look that wants them, every other look giving the
-- profile's own value back: the shelf's outer margin (Strip: 0,
-- flush with the screen edge and sketchybar's strip) and the layout
-- gaps (Tiler: just clear of the ring, as a classic tiler).
local M = {}

M.order = { "glass", "strip", "tiler", "neon", "retro", "own" }

-- Hack Nerd Font (Material Design) glyphs for the picker.
M.glyphs = {
	auto = "󰁨",
	glass = "󰖌",
	strip = "󰍴",
	tiler = "󰋁",
	neon = "󰉁",
	retro = "󰄱",
	own = "󰋜",
}

M.labels = {
	glass = "Glass",
	strip = "Strip",
	tiler = "Tiler",
	neon = "Neon",
	retro = "Retro",
	own = "Own",
}

-- kiwi: KiwiDesk's look. sb: sketchybar's pills (radius = roundness% x
-- 15, the pill being 30 pt tall), popup alpha (a non-glass popup needs
-- more cover: no blur hides a busy window behind it). strip: one bar
-- instead of pills. accent_border: pills outlined in the accent.
M.presets = {
	glass = {
		kiwi = {
			style = "boxed",
			fit = "hug",
			roundness = 100,
			shelf_border = true,
			shelf_border_width = 1,
			highlight = 3,
			glass = true,
			ring = 5,
			corners = "rounded",
			glow = true,
			glow_size = 0,
			sheen = 0.5,
			app_indicator = "edge_mark",
			space_indicator = "outline",
		},
		sb = { radius = 15, border = 1, blur = 60, height = 30, popup_alpha = 0x80 },
	},
	strip = {
		kiwi = {
			style = "plain",
			fit = "full",
			roundness = 0, -- flush on the edge: no corners to round
			outer_margin = 0,
			shelf_border = false,
			shelf_border_width = 1,
			highlight = 2,
			glass = true,
			ring = 3,
			corners = "rounded",
			glow = false,
			glow_size = 0,
			sheen = 0.3,
			app_indicator = "edge_mark",
			space_indicator = "edge_mark",
		},
		sb = { radius = 0, border = 0, blur = 30, height = 30, popup_alpha = 0x99, strip = true },
	},
	tiler = {
		kiwi = {
			style = "plain",
			fit = "hug",
			roundness = 0,
			shelf_border = true,
			shelf_border_width = 1,
			highlight = 2,
			glass = false,
			ring = 2,
			corners = "square",
			fit_gaps = true, -- gaps = the ring's width, no whitespace
			glow = false,
			glow_size = 0,
			sheen = 0,
			app_indicator = "edge_mark",
			space_indicator = "edge_mark",
		},
		sb = { radius = 2, border = 1, blur = 0, height = 30, popup_alpha = 0xe6 },
	},
	neon = {
		kiwi = {
			style = "boxed",
			fit = "hug",
			roundness = 60,
			shelf_border = true,
			shelf_border_width = 2,
			highlight = 4,
			glass = false,
			ring = 6,
			corners = "rounded",
			glow = true,
			glow_size = 0,
			sheen = 0.2,
			app_indicator = "outline",
			space_indicator = "outline",
		},
		sb = { radius = 9, border = 2, blur = 20, height = 30, popup_alpha = 0xd9, accent_border = true },
	},
	retro = {
		kiwi = {
			style = "boxed",
			fit = "hug",
			roundness = 25,
			shelf_border = true,
			shelf_border_width = 2,
			highlight = 3,
			glass = false,
			ring = 3,
			corners = "rounded",
			glow = false,
			glow_size = 0,
			sheen = -0.3,
			app_indicator = "outline",
			space_indicator = "edge_mark",
		},
		sb = { radius = 4, border = 2, blur = 0, height = 28, popup_alpha = 0xf2 },
	},
}

-- The profile's global gap when one number says it (the CLI's
-- set_gap_global takes a number); nil leaves gaps alone.
local gap_paths = {
	"gap.global.inner.horizontal",
	"gap.global.inner.vertical",
	"gap.global.outer.top",
	"gap.global.outer.bottom",
	"gap.global.outer.left",
	"gap.global.outer.right",
}
local function uniform_gap(style)
	local value = nil
	for _, path in ipairs(gap_paths) do
		local v = style[path]
		if type(v) ~= "number" or (value and v ~= value) then
			return nil
		end
		value = v
	end
	return value
end

-- "Own": the KiwiDesk profile's own shape (set by looks.lua from the
-- profile file; live CLI writes do not save into it) with the
-- sketchybar pills of Glass.
function M.set_own(style)
	local s = style or {}
	local function pick(key, fallback)
		if s[key] == nil then
			return fallback
		end
		return s[key]
	end
	local glass = M.presets.glass.kiwi
	M.presets.own = {
		kiwi = {
			style = pick("kiwishelf.background_style", glass.style),
			fit = pick("kiwishelf.background_fit", glass.fit),
			roundness = pick("kiwishelf.corner_roundness", glass.roundness),
			shelf_border = pick("kiwishelf.border", glass.shelf_border),
			shelf_border_width = pick("kiwishelf.border_width", glass.shelf_border_width),
			highlight = pick("kiwishelf.highlight_width", glass.highlight),
			outer_margin = pick("kiwishelf.outer_margin", 10),
			gap = uniform_gap(s),
			glass = pick("kiwishelf.liquid_glass", glass.glass),
			drag_glass = s["drag.liquid_glass"],
			sticky_glass = s["sticky.liquid_glass"],
			panel_glass = s["shortcut_panel.liquid_glass"],
			ring = pick("border.width", glass.ring),
			corners = pick("border.corner_style", glass.corners),
			glow = pick("border.glow", glass.glow),
			glow_size = pick("border.glow_size", glass.glow_size),
			sheen = pick("border.sheen", glass.sheen),
			app_indicator = pick("app_bar.active_indicator", glass.app_indicator),
			space_indicator = pick("space_bar.active_indicator", glass.space_indicator),
			monocle_indicator = s["monocle.app_bar_active_indicator"],
			scroll_indicator = s["scroll.app_bar_active_indicator"],
		},
		sb = M.presets.glass.sb,
	}
end
M.set_own(nil)

function M.get(name)
	return M.presets[name] or M.presets.glass
end

-- One shell command setting KiwiDesk's whole look, each verb run even
-- if another is refused; silent and harmless without the CLI.
function M.kiwidesk_command(name)
	local k = M.get(name).kiwi
	local function either(value, fallback)
		if value == nil then
			return fallback
		end
		return value
	end
	local verbs = {
		{ "kiwishelf.set_background_style", k.style },
		{ "kiwishelf.set_background_fit", k.fit },
		{ "kiwishelf.set_corner_roundness", k.roundness },
		{ "kiwishelf.set_border", k.shelf_border },
		{ "kiwishelf.set_border_width", k.shelf_border_width },
		{ "kiwishelf.set_highlight_width", k.highlight },
		{ "kiwishelf.set_outer_margin", either(k.outer_margin, M.presets.own.kiwi.outer_margin) },
		-- Liquid Glass is one switch: every surface follows the shelf.
		{ "kiwishelf.set_liquid_glass", k.glass },
		{ "drag.set_liquid_glass", either(k.drag_glass, k.glass) },
		{ "sticky.set_liquid_glass", either(k.sticky_glass, k.glass) },
		{ "set_shortcut_panel_liquid_glass", either(k.panel_glass, k.glass) },
		{ "border.set_width", k.ring },
		{ "border.set_corner_style", k.corners },
		{ "border.set_glow", k.glow },
		{ "border.set_glow_size", k.glow_size },
		{ "border.set_sheen", k.sheen },
		{ "app_bar.set_active_indicator", k.app_indicator },
		{ "space_bar.set_active_indicator", k.space_indicator },
		{ "monocle.set_app_bar_active_indicator", either(k.monocle_indicator, k.app_indicator) },
		{ "scroll.set_app_bar_active_indicator", either(k.scroll_indicator, k.app_indicator) },
	}
	-- After the ring's verbs: fit_gaps measures the ring as now set.
	if k.fit_gaps then
		table.insert(verbs, { "border.fit_gaps", 0 })
	elseif M.presets.own.kiwi.gap then
		table.insert(verbs, { "set_gap_global", M.presets.own.kiwi.gap })
	end
	local parts = {}
	for _, verb in ipairs(verbs) do
		table.insert(parts, "kiwidesk " .. verb[1] .. " " .. tostring(verb[2]))
	end
	return "{ command -v kiwidesk >/dev/null 2>&1 && " .. table.concat(parts, "; ") .. "; } >/dev/null 2>&1"
end

return M
