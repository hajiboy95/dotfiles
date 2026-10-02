-- The look: colours and fonts. Global LOOK (alias COLORS).
local colors = {}
local config_dir = os.getenv("CONFIG_DIR")
local theme_file = config_dir .. "/helpers/active_theme.txt"

-- Create the directory once when the script loads if not available yet
os.execute("mkdir -p " .. config_dir .. "/helpers")

-- 1. Define Common Colors
colors.white = 0xffffffff
colors.transparent = 0x00000000
colors.red = 0xffff4444
colors.orange = 0xffffa500
colors.charging = 0xffffd700

-- 2. Define Your Schemes
local schemes = {
	gruvbox = {
		font = "Charter", -- words (numbers and icons stay Hack)
		bar_color = 0x70282828,
		accent_color = 0xffd79921,
		secondary_accent = 0xfffabd2f,
		space_focused_window = 0xff83a598, -- Gruvbox aqua: separates from the yellow accent for red-green colour vision
		disabled_color = 0xffd3d3d3,
		background = 0xfa1e1e2e,
		background_border = 0xff45475a,
		popup_background = 0xff282828,
		popup_border = 0xffd79921,
	},
	teal = {
		font = "PT Sans", -- words (numbers and icons stay Hack)
		-- Its accent (#001F30) vanishes on KiwiDesk's shelf: KiwiDesk
		-- gets these instead.
		kiwi = {
			accent_color = 0xff2cf9ed,
			disabled_color = 0xff7fc4cc,
			space_focused_window = 0xffffb547,
		},
		bar_color = 0x40001f30,
		accent_color = 0xfa001f30,
		secondary_accent = 0xff397d89,
		space_focused_window = 0xff2cf9ed, -- Cyan/Teal highlight
		disabled_color = 0xff397d89,
		background = 0xff2cf9ed,
		background_border = 0xfa001f30,
		popup_background = 0xff2cf9ed,
		popup_border = 0xfa001f30,
	},
	blacknwhite = {
		font = "Helvetica Neue", -- words (numbers and icons stay Hack)
		bar_color = 0x40000000,
		accent_color = 0xffffffff,
		secondary_accent = 0xffa9cce3,
		space_focused_window = 0xff00d2ff, -- Electric blue highlight
		disabled_color = 0xffb0b0b0,
		background = 0xfa101314,
		background_border = 0xffffffff,
		popup_background = 0xff101314,
		popup_border = 0xffffffff,
	},
	purple = {
		font = "SF Pro Rounded", -- words (numbers and icons stay Hack)
		bar_color = 0x70140c42,
		accent_color = 0xffeb46f9,
		secondary_accent = 0xffa569bd,
		space_focused_window = 0xff00f3ff, -- Neon cyan highlight
		disabled_color = 0xffb8a1d9,
		background = 0xfa140c42,
		background_border = 0xff2e2a5a,
		popup_background = 0xff140c42,
		popup_border = 0xffeb46f9,
	},
	red = {
		font = "Trebuchet MS", -- words (numbers and icons stay Hack)
		bar_color = 0x7023090e,
		accent_color = 0xffff2453,
		secondary_accent = 0xffc0392b,
		space_focused_window = 0xfff7fc17, -- Neon yellow highlight
		disabled_color = 0xffe1a2a6,
		background = 0xfa23090e,
		background_border = 0xff3c1a22,
		popup_background = 0xff23090e,
		popup_border = 0xffff2453,
	},
	blue = {
		font = "Avenir Next", -- words (numbers and icons stay Hack)
		bar_color = 0x70021254,
		accent_color = 0xff15bdf9,
		secondary_accent = 0xff5dade2,
		space_focused_window = 0xffff7f00, -- Neon orange highlight
		disabled_color = 0xffaac5e0,
		background = 0xfa021254,
		background_border = 0xff223973,
		popup_background = 0xff021254,
		popup_border = 0xff15bdf9,
	},
	green = {
		font = "Gill Sans", -- words (numbers and icons stay Hack)
		bar_color = 0x70003315,
		accent_color = 0xff1dfca1,
		secondary_accent = 0xff52be80,
		space_focused_window = 0xff15bdf9, -- Electric blue highlight
		disabled_color = 0xffa1e0c0,
		background = 0xfa003315,
		background_border = 0xff0f4d2b,
		popup_background = 0xff003315,
		popup_border = 0xff1dfca1,
	},
	orange = {
		font = "Proxima Nova", -- words (numbers and icons stay Hack)
		bar_color = 0x70381c02,
		accent_color = 0xfff97716,
		secondary_accent = 0xffeb984e,
		space_focused_window = 0xff15bdf9, -- Electric cyan highlight
		disabled_color = 0xffe0bfa1,
		background = 0xfa381c02,
		background_border = 0xff4f2e11,
		popup_background = 0xff381c02,
		popup_border = 0xfff97716,
	},
	yellow = {
		font = "SF Compact Text", -- words (numbers and icons stay Hack)
		bar_color = 0x702d2b02,
		accent_color = 0xfff7fc17,
		secondary_accent = 0xfff4d03f,
		space_focused_window = 0xffeb46f9, -- Magenta highlight
		disabled_color = 0xffe9dea1,
		background = 0xfa2d2b02,
		background_border = 0xff4e4b13,
		popup_background = 0xff2d2b02,
		popup_border = 0xfff7fc17,
	},
	liquid_glass = {
		font = "SF Pro", -- words (numbers and icons stay Hack)
		bar_color = 0x00000000,
		-- Plain text white; "on" in True Dark's cyan, which reads on the
		-- glass (4.7:1) and stays apart from the orange front-app
		-- highlight and the attention colours for red-green vision.
		text_color = 0xffffffff,
		accent_color = 0xff64d2ff,
		secondary_accent = 0xffd6eaf8,
		space_focused_window = 0xffff9f0a, -- Apple orange: white vs cyan merged for red-green colour vision
		disabled_color = 0xffc7c7cc, -- light enough to read on glass
		background = 0x20ffffff,
		background_border = 0x40ffffff,
		popup_background = 0xee1a1d1e,
		popup_border = 0x80ffffff,
	},
}

-- 2b. The "kiwidesk" scheme: built at load from the active KiwiDesk
-- profile's own colours (a missing key falls back to gui.json's
-- shared look), so sketchybar and KiwiDesk wear one palette.
-- Picking it hands KiwiDesk its profile colours back.
local kiwi_paths = {
	{ "border.set_focused_color", "border.focused_color" },
	{ "border.set_unfocused_color", "border.unfocused_color" },
	{ "kiwishelf.set_fill_color", "kiwishelf.fill_color" },
	{ "kiwishelf.set_border_color", "kiwishelf.border_color" },
	{ "kiwishelf.set_item_color", "kiwishelf.item_color" },
	{ "kiwishelf.set_active_item_color", "kiwishelf.active_item_color" },
	{ "kiwishelf.set_highlight_color", "kiwishelf.highlight_color" },
	{ "kiwishelf.set_hover_item_color", "kiwishelf.hover_item_color" },
	{ "kiwishelf.set_hover_fill_color", "kiwishelf.hover_fill_color" },
	{ "kiwishelf.set_group_badge_color", "kiwishelf.group_badge_color" },
	{ "kiwishelf.set_group_badge_text_color", "kiwishelf.group_badge_text_color" },
	{ "space_bar.set_focused_item_color", "space_bar.focused_item_color" },
	{ "space_bar.set_focused_highlight_color", "space_bar.focused_highlight_color" },
	{ "drag.set_ghost_border_color", "drag.ghost.border_color" },
	{ "drag.set_ghost_fill_color", "drag.ghost.fill_color" },
	{ "drag.set_drop_zone_border_color", "drag.drop_zone.border_color" },
	{ "drag.set_drop_zone_fill_color", "drag.drop_zone.fill_color" },
}

-- Reads every path above; returns { [path] = "#hex" } or nil.
local function read_kiwidesk_profile()
	local wanted = {}
	for _, entry in ipairs(kiwi_paths) do
		table.insert(wanted, entry[2])
	end
	local handle = io.popen([[python3 - ']] .. table.concat(wanted, " ") .. [[' 2>/dev/null <<'PY'
import json, os, subprocess, sys
base = os.path.expanduser("~/.config/KiwiDesk")
try:
    status = subprocess.run(["kiwidesk", "get_profile_status"],
        capture_output=True, text=True, timeout=2).stdout
    name = json.loads(status).get("name") or "Starter"
except Exception:
    name = "Starter"
def load(path):
    try:
        with open(path) as f:
            return json.load(f).get("settings", {})
    except Exception:
        return {}
sources = [load(os.path.join(base, "profiles", name + ".json")),
           load(os.path.join(base, "gui.json"))]
for path in sys.argv[1].split():
    for src in sources:
        node = src
        for key in path.split("."):
            node = node.get(key) if isinstance(node, dict) else None
        if isinstance(node, str) and node.startswith("#"):
            print(path + "=" + node)
            break
glass = None
for src in sources:
    value = (src.get("kiwishelf") or {}).get("liquid_glass")
    if isinstance(value, bool):
        glass = value
        break
print("liquid_glass=" + ("on" if glass else "off"))
for src in sources:
    family = (src.get("kiwishelf") or {}).get("font_family")
    if isinstance(family, str) and family:
        print("font_family=" + family)
        break
PY]])
	if not handle then
		return nil
	end
	local out = handle:read("*a")
	handle:close()
	local values = {}
	for path, hex in out:gmatch("([%w%._]+)=(#%x+)") do
		values[path] = hex
	end
	values.liquid_glass = out:match("liquid_glass=on") ~= nil
	values.font_family = out:match("font_family=([^\n]+)")
	return next(values) and values or nil
end

-- "#RRGGBB" / "#RRGGBBAA" -> 0xAARRGGBB
local function argb(hex)
	local rgb = tonumber(hex:sub(2, 7), 16)
	local alpha = #hex >= 9 and tonumber(hex:sub(8, 9), 16) or 0xff
	return alpha * 0x1000000 + rgb
end

local function with_alpha(value, alpha)
	-- Plain arithmetic, not bitwise operators: stylua's parser in the
	-- pre-commit hook only knows Lua 5.1.
	return value % 0x1000000 + alpha * 0x1000000
end
colors.with_alpha = with_alpha

local kiwi_profile_values = read_kiwidesk_profile()
if kiwi_profile_values then
	local v = function(path, fallback)
		local hex = kiwi_profile_values[path]
		return hex and argb(hex) or fallback
	end
	local fill = v("kiwishelf.fill_color", 0xb31a1a2e)
	-- KiwiDesk's real Liquid Glass only TINTS with the fill, so it reads
	-- light and see-through; sketchybar paints it flat. With glass on,
	-- imitate it: the tint at 25% and a light glass rim.
	local glass = kiwi_profile_values.liquid_glass
	local pill = glass and with_alpha(fill, 0x40) or fill
	local rim = glass and 0x40ffffff or v("kiwishelf.border_color", 0x59e8eaf6)
	schemes.kiwidesk = {
		label = "KiwiDesk",
		is_kiwidesk_profile = true,
		font = kiwi_profile_values.font_family,
		bar_color = fill,
		-- Sketchybar draws text and icons in accent_color, so it takes
		-- the shelf's text colours, not the (darker) ring purple.
		accent_color = v("kiwishelf.active_item_color", 0xffb38ed9),
		text_color = v("kiwishelf.item_color", 0xffe8eaf6),
		secondary_accent = v("kiwishelf.item_color", 0xffe8eaf6),
		space_focused_window = v("space_bar.focused_item_color", 0xffb38ed9),
		-- Dim = the text colour at 50%: text_color is item_color too, so
		-- the bare value would make "off" look the same as "on".
		disabled_color = with_alpha(v("kiwishelf.item_color", 0xffe8eaf6), 0x80),
		background = pill,
		background_border = rim,
		popup_background = with_alpha(fill, 0xee),
		popup_border = v("kiwishelf.highlight_color", 0xff564ab6),
	}
end

-- 2c. While the KiwiDesk profile wears Liquid Glass, every scheme's
-- pills turn glass-like too: the theme's hue at most 25%, a light
-- rim. That pill colour is also what tints KiwiDesk's glass (kiwi_map),
-- and a near-opaque tint (Blue's 0xfa) would hide the glass entirely.
if kiwi_profile_values and kiwi_profile_values.liquid_glass then
	for name, scheme in pairs(schemes) do
		if name ~= "kiwidesk" and scheme.background then
			local alpha = math.floor(scheme.background / 0x1000000) % 0x100
			-- KiwiDesk's real glass keeps the theme's own tint (the owner
			-- prefers it as is); only sketchybar's painted pills drop to
			-- 25% to read as glass.
			scheme.glass_tint = scheme.background
			-- The glass draws its own light edge; an opaque theme border
			-- inside it reads as a second line, so the border is the
			-- same translucent rim the pills get.
			scheme.glass_border = 0x40ffffff
			scheme.background = with_alpha(scheme.background, math.min(alpha, 0x40))
			scheme.background_border = 0x40ffffff
		end
	end
end

-- 3. Select Active Scheme
local active_name
local first_available = next(schemes)

local f = io.open(theme_file, "r")
if f then
	local content = f:read("*all"):gsub("%s+", "")
	if schemes[content] then
		active_name = content
	end
	f:close()
end

active_name = active_name or (schemes.kiwidesk and "kiwidesk") or first_available
-- 4. Merge. `colors.use` swaps the active scheme IN PLACE (the same
-- table every module holds as COLORS), so a live theme switch needs
-- no reload: helpers/theme.lua re-applies the colours afterwards.
local scheme_keys = {}
function colors.use(name)
	local data = schemes[name]
	if not data then
		return false
	end
	for k in pairs(scheme_keys) do
		colors[k] = nil
	end
	scheme_keys = {}
	for k, v in pairs(data) do
		colors[k] = v
		scheme_keys[k] = true
	end
	-- Labels and icons read text_color; a scheme without one keeps its
	-- accent, as before.
	if not data.text_color then
		colors.text_color = colors.accent_color
		scheme_keys.text_color = true
	end
	colors.active_scheme_name = name
	if colors.resolve_font then
		colors.resolve_font(data.font)
	end
	return true
end

colors.use(active_name)
colors.all_schemes = schemes
colors.theme_file = theme_file

-- KiwiDesk colours per scheme key (replaces JankyBorders). Pushed
-- only when a theme is PICKED (items/theme_picker.lua), never at
-- load, so KiwiDesk keeps its profile's colours until you choose.
-- Live only (KiwiDesk does not save them). Anything not listed
-- keeps the profile's colour.
-- A source is a scheme key, or { key, alpha } for that colour at a
-- new alpha (0x00–0xff). Tints follow the profile's own alphas.
local kiwi_map = {
	-- Focus border
	{ "border.set_focused_color", "accent_color" },
	{ "border.set_unfocused_color", { "disabled_color", 0x40 } },
	-- KiwiShelf
	-- The pills' colour (KiwiDesk's glass tint), not bar_color: the
	-- bar strip itself is transparent.
	{ "kiwishelf.set_fill_color", "glass_tint" },
	{ "kiwishelf.set_border_color", "glass_border" },
	{ "kiwishelf.set_item_color", "disabled_color" },
	{ "kiwishelf.set_active_item_color", "accent_color" },
	{ "kiwishelf.set_highlight_color", "accent_color" },
	{ "kiwishelf.set_hover_item_color", "accent_color" },
	{ "kiwishelf.set_hover_fill_color", { "accent_color", 0x33 } },
	{ "kiwishelf.set_group_badge_color", "secondary_accent" },
	{ "kiwishelf.set_group_badge_text_color", "popup_background" },
	{ "space_bar.set_focused_item_color", "space_focused_window" },
	{ "space_bar.set_focused_highlight_color", "space_focused_window" },
	-- Dragging: the ghost in the accent, the drop zone in the
	-- theme's contrasting highlight.
	{ "drag.set_ghost_border_color", "accent_color" },
	{ "drag.set_ghost_fill_color", { "accent_color", 0x40 } },
	{ "drag.set_drop_zone_border_color", "space_focused_window" },
	{ "drag.set_drop_zone_fill_color", { "space_focused_window", 0x26 } },
}

-- 0xAARRGGBB -> "#RRGGBBAA"
local function kiwi_hex(value)
	return string.format("#%06X%02X", value % 0x1000000, math.floor(value / 0x1000000) % 0x100)
end

-- One shell command running each { verb, "#hex" }, every one even if
-- another is refused; "true" when empty or when the CLI is missing,
-- so a click never fails on it.
local function kiwi_shell(pairs_list)
	local parts = {}
	for _, entry in ipairs(pairs_list) do
		table.insert(parts, "kiwidesk " .. entry[1] .. " '" .. entry[2] .. "'")
	end
	if #parts == 0 then
		return "true"
	end
	return "{ command -v kiwidesk >/dev/null 2>&1 && " .. table.concat(parts, "; ") .. "; } >/dev/null 2>&1"
end

function colors.kiwidesk_command(scheme)
	-- The KiwiDesk scheme hands the profile's exact colours (and font)
	-- back.
	if scheme.is_kiwidesk_profile then
		local list = {}
		if scheme.font then
			table.insert(list, { "kiwishelf.set_font_family", scheme.font })
		end
		for _, entry in ipairs(kiwi_paths) do
			local hex = kiwi_profile_values and kiwi_profile_values[entry[2]]
			if hex then
				table.insert(list, { entry[1], hex })
			end
		end
		return kiwi_shell(list)
	end
	local list = {}
	if scheme.font then
		table.insert(list, { "kiwishelf.set_font_family", scheme.font })
	end
	for _, entry in ipairs(kiwi_map) do
		local source = entry[2]
		local key, alpha = source, nil
		if type(source) == "table" then
			key, alpha = source[1], source[2]
		end
		local value = (scheme.kiwi and scheme.kiwi[key]) or scheme[key]
		-- Glass off: KiwiDesk takes the pills' own colours.
		if key == "glass_tint" and not value then
			value = scheme.background
		elseif key == "glass_border" and not value then
			value = scheme.background_border
		end
		if value then
			if alpha then
				value = with_alpha(value, alpha)
			end
			table.insert(list, { entry[1], kiwi_hex(value) })
		end
	end
	return kiwi_shell(list)
end

-- Fonts. Words (titles, names, menu rows) wear the KiwiDesk shelf's
-- font so both bars share their handwriting; numbers and icons stay
-- Hack Nerd Font, whose equal-width digits keep readouts from
-- jittering and whose glyphs nothing else has.
colors.icon_font = "Hack Nerd Font"
colors.text_font = colors.icon_font
colors.text_style = "Semibold"

-- Style names vary per family (Apple Chancery's only one is
-- "Chancery", Charter's "Roman"), and sketchybar falls back to the
-- system font on a wrong one, so helpers/fontstyle asks macOS.
-- Nothing back = not installed: stay on Hack.
local fontstyle_dir = config_dir .. "/helpers/fontstyle"
os.execute("cd '" .. fontstyle_dir .. "' && make >/dev/null 2>&1")
local style_cache = {}
local function style_of(family)
	if style_cache[family] == nil then
		local handle = io.popen("'" .. fontstyle_dir .. "/bin/fontstyle' '" .. family:gsub("'", "") .. "' 2>/dev/null")
		local style = handle and handle:read("*l") or ""
		if handle then
			handle:close()
		end
		style_cache[family] = style or ""
	end
	return style_cache[family]
end

-- Sets the word font for the active scheme (called by colors.use).
function colors.resolve_font(family)
	local style = family and style_of(family) or ""
	if style ~= "" then
		colors.text_font, colors.text_style = family, style
	else
		colors.text_font, colors.text_style = colors.icon_font, "Semibold"
	end
end
colors.resolve_font(colors.font)

-- A label font table for words; `scale` multiplies the default size.
function colors.word_font(scale)
	return {
		family = colors.text_font,
		style = colors.text_style,
		size = 13.5 * (scale or 1),
	}
end

return colors
