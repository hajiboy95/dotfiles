-- An app's glyph from sketchybar-app-font (":tailscale:", ...), or a
-- Nerd Font fallback when that font is not installed.
local home = os.getenv("HOME")
local function installed()
	for _, dir in ipairs({ home .. "/Library/Fonts/", "/Library/Fonts/" }) do
		local f = io.open(dir .. "sketchybar-app-font.ttf", "r")
		if f then
			f:close()
			return true
		end
	end
	return false
end
local has_font = installed()

-- Returns the icon fields to merge into an item's `icon`.
return function(ligature, fallback, size)
	if has_font then
		return {
			string = ligature,
			font = { family = "sketchybar-app-font", style = "Regular", size = size },
		}
	end
	return { string = fallback }
end
