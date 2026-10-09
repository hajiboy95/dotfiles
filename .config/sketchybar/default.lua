-- Pill shape comes from the active look (helpers/shapes.lua).
local shape = COLORS.shape
local border_width = shape.border
local corner_raduis = shape.radius
local item_padding = 10
-- The bar matches the menu bar under the notch (32 pt on this
-- MacBook, NSScreen.safeAreaInsets.top) so it covers it fully; the
-- pills take nearly all of it, so they end level with the notch.
local bar_height = 32
local height = shape.height -- item pill height
local size = 13.5
-- Define default item properties
local default_item = {
	-- always the left object
	icon = {
		font = {
			family = "Hack Nerd Font",
			size = size,
		},
		color = COLORS.text_color,
		padding_left = item_padding,
		padding_right = item_padding,
		y_offset = 1,
	},
	-- always the right object
	label = {
		font = {
			family = "Hack Nerd Font",
			style = "Semibold",
			size = size,
		},
		color = COLORS.text_color,
		padding_right = item_padding,
	},
	background = {
		color = COLORS.background,
		border_color = COLORS.background_border,
		border_width = border_width,
		corner_radius = corner_raduis,
		height = height,
	},
	-- Popups wear the pills' border and a strong blur, over the theme's
	-- dark base at 50%: the pill colour alone (0x20 white in Liquid
	-- Glass) leaves white text unreadable over a white window.
	popup = {
		blur_radius = shape.blur,
		background = {
			corner_radius = corner_raduis,
			color = LOOK.with_alpha(COLORS.popup_background, shape.popup_alpha),
			border_width = border_width,
			border_color = COLORS.background_border,
		},
	},
}

SBAR.default(default_item)
SBAR.default({ background = { drawing = false } })
-- Add Bar
SBAR.bar({
	-- position = "top",
	height = bar_height,
	-- Transparent: only the item pills draw; the wallpaper shows
	-- between them.
	color = 0x00000000,
	blur_radius = 0,
})


return default_item
