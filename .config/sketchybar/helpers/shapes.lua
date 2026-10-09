-- Looks: everything of a theme but its colours (looks.lua holds those)
-- — shape, size, gaps, font and Liquid Glass. Picking a look also
-- wears its own palette; a colour picked afterwards changes colours
-- only. A look writes EVERY key below, so nothing of the previous one
-- lingers (a colour-only palette that bundled a glow could never
-- switch it off again: KiwiDesk #578; its bundled looks are total
-- the same way). Sizes follow KiwiDesk's bundled looks. Never
-- written: edges.
local M = {}

M.order = { "glass", "strip", "tiler", "neon", "retro", "kiwidesk" }

-- Hack Nerd Font (Material Design) glyphs for the picker.
M.glyphs = {
	glass = "󰖌",
	strip = "󰍴",
	tiler = "󰋁",
	neon = "󰉁",
	retro = "󰄱",
	kiwidesk = "󰋜",
}

-- Each look's own palette (looks.lua scheme), worn when the look is
-- picked, as KiwiDesk's bundled looks name theirs. A colour picked
-- afterwards changes the colours only.
M.palettes = {
	glass = "liquid_glass",
	strip = "teal", -- the one bright hue: reads as colour at 25%
	tiler = "blacknwhite",
	neon = "purple",
	retro = "gruvbox",
	kiwidesk = "kiwidesk",
}

M.labels = {
	glass = "Glass",
	strip = "Strip",
	tiler = "Tiler",
	neon = "Neon",
	retro = "Retro",
	kiwidesk = "KiwiDesk",
}

-- kiwi: KiwiDesk's look. sb: sketchybar's pills (radius = roundness% x
-- 15, the pill being 30 pt tall), popup alpha (a non-glass popup needs
-- more cover: no blur hides a busy window behind it). strip: one bar
-- instead of pills. accent_border: pills outlined in the accent.
-- tint: without glass, the scheme's hue at 25% all the same, flat on
-- both bars (KiwiDesk's fill takes the same see-through colour, no
-- blur). A look never alters a palette's character.
M.presets = {
	glass = {
		kiwi = {
			font = "SF Pro Rounded",
			font_weight = 500,
			thickness = 44,
			outer_margin = 10,
			gap = 16,
			item_gap = 10,
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
			font = "SF Pro",
			font_weight = 500,
			thickness = 32, -- one band with sketchybar's 32 pt bar
			gap = 8,
			item_gap = 6,
			style = "plain",
			fit = "full",
			roundness = 0, -- flush on the edge: no corners to round
			outer_margin = 0,
			shelf_border = false,
			shelf_border_width = 1,
			highlight = 2,
			glass = false, -- sketchybar cannot draw real glass: both bars paint one flat tint instead
			ring = 3,
			corners = "rounded",
			glow = false,
			glow_size = 0,
			sheen = 0.3,
			app_indicator = "edge_mark",
			space_indicator = "edge_mark",
		},
		sb = { radius = 0, border = 0, blur = 30, height = 30, popup_alpha = 0x99, strip = true, tint = true },
	},
	tiler = {
		kiwi = {
			font = "System Monospaced", -- sketchybar: Hack, monospaced too
			font_weight = 500,
			thickness = 30, -- level with sketchybar's 30 pt pills
			outer_margin = 4,
			gap = 4,
			item_gap = 4,
			style = "plain",
			fit = "hug",
			roundness = 0,
			shelf_border = true,
			shelf_border_width = 1,
			highlight = 2,
			glass = false,
			ring = 4,
			corners = "square",
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
			font = "Avenir Next",
			font_weight = 500,
			thickness = 40,
			outer_margin = 8,
			gap = 16, -- the glow's bloom needs the room
			item_gap = 8,
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
			font = "Charter",
			font_weight = 500,
			thickness = 28, -- level with its 28 pt pills
			outer_margin = 6,
			gap = 8,
			item_gap = 6,
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
-- set_gap_global takes a number); nil leaves gaps alone rather than
-- flatten uneven ones.
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

-- "KiwiDesk": the KiwiDesk profile's own look (set by looks.lua from
-- the profile file; live CLI writes do not save into it) with the
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
	M.presets.kiwidesk = {
		kiwi = {
			font = s["kiwishelf.font_family"],
			font_weight = s["kiwishelf.font_weight"],
			thickness = pick("kiwishelf.thickness", glass.thickness),
			outer_margin = pick("kiwishelf.outer_margin", glass.outer_margin),
			inner_margin = pick("kiwishelf.inner_margin", 0),
			gap = uniform_gap(s),
			item_gap = pick("kiwishelf.item_gap", glass.item_gap),
			glyph_size = pick("kiwishelf.glyph_size", 0),
			font_size = pick("kiwishelf.font_size", 0),
			glyph_gap = pick("space_bar.glyph_gap", 0),
			style = pick("kiwishelf.background_style", glass.style),
			fit = pick("kiwishelf.background_fit", glass.fit),
			roundness = pick("kiwishelf.corner_roundness", glass.roundness),
			shelf_border = pick("kiwishelf.border", glass.shelf_border),
			shelf_border_width = pick("kiwishelf.border_width", glass.shelf_border_width),
			highlight = pick("kiwishelf.highlight_width", glass.highlight),
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

-- The font sketchybar's words wear under a look.
function M.font(name)
	return M.get(name).kiwi.font
end

-- What KiwiDesk last got from us, per verb: an unchanged size or gap
-- is not re-sent, as each one retiles every Space.
local applied = {}

-- One shell command setting KiwiDesk's whole look, each verb run even
-- if another is refused; silent and harmless without the CLI. `force`
-- re-sends every verb (the active look picked again).
function M.kiwidesk_command(name, force)
	local k = M.get(name).kiwi
	local function either(value, fallback)
		if value == nil then
			return fallback
		end
		return value
	end
	local verbs = {
		{ "kiwishelf.set_font_family", k.font },
		{ "kiwishelf.set_font_weight", k.font_weight },
		{ "kiwishelf.set_background_style", k.style },
		{ "kiwishelf.set_background_fit", k.fit },
		{ "kiwishelf.set_corner_roundness", k.roundness },
		{ "kiwishelf.set_border", k.shelf_border },
		{ "kiwishelf.set_border_width", k.shelf_border_width },
		{ "kiwishelf.set_highlight_width", k.highlight },
		{ "kiwishelf.set_item_gap", k.item_gap },
		{ "kiwishelf.set_glyph_size", either(k.glyph_size, 0) },
		{ "kiwishelf.set_font_size", either(k.font_size, 0) },
		{ "space_bar.set_glyph_gap", either(k.glyph_gap, 0) },
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
		-- Sizes last: each retiles.
		{ "kiwishelf.set_thickness", k.thickness },
		{ "kiwishelf.set_outer_margin", either(k.outer_margin, 0) },
		{ "kiwishelf.set_inner_margin", either(k.inner_margin, 0) },
		{ "set_gap_global", k.gap },
	}
	local parts = {}
	for _, verb in ipairs(verbs) do
		local value = verb[2]
		if value ~= nil and (force or applied[verb[1]] ~= value) then
			applied[verb[1]] = value
			local arg = type(value) == "string" and "'" .. value:gsub("'", "") .. "'" or tostring(value)
			table.insert(parts, "kiwidesk " .. verb[1] .. " " .. arg)
		end
	end
	if #parts == 0 then
		return "true"
	end
	return "{ command -v kiwidesk >/dev/null 2>&1 && " .. table.concat(parts, "; ") .. "; } >/dev/null 2>&1"
end

return M
