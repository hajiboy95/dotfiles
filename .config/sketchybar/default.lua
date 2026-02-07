local border_width = 1
local corner_raduis = 15
local item_padding = 8
local height = 24
local size = 15.0
-- Define default item properties
local default_item = {
	-- always the left object
	icon = {
		font = {
			family = "Hack Nerd Font",
			-- style = "Bold",
			size = size,
		},
		color = COLORS.accent_color,
		padding_left = item_padding,
		padding_right = item_padding,
		y_offset = 1,
	},
	-- always the right object
	label = {
		font = {
			-- family = "Hack Nerd Font",
			family = "SF Pro",
			style = "Semibold",
			size = size,
		},
		color = COLORS.accent_color,
		padding_right = item_padding,
		y_offset = 1,
	},
	background = {
		color = COLORS.background,
		border_color = COLORS.background_border,
		border_width = border_width,
		corner_radius = corner_raduis,
		height = height,
	},
	popup = {
		background = {
			corner_radius = corner_raduis,
			color = COLORS.popup_background,
			border_width = border_width,
			border_color = COLORS.popup_border,
		},
	},
}

SBAR.default(default_item)
SBAR.default({ background = { drawing = false } })
-- Add Bar
SBAR.bar({
	-- position = "top",
	height = height,
	blur_radius = 30,
})

return default_item
