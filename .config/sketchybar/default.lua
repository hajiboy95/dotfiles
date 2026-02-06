local border_width = 1
local corner_raduis = 15
local item_padding = 6
-- Define default item properties
local default_item = {
	-- always the left object
	icon = {
		font = {
			family = "Hack Nerd Font",
			-- style = "Bold",
			size = 15.0,
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
			size = 14.0,
		},
		color = COLORS.accent_color,
		padding_right = item_padding,
	},
	background = {
		color = COLORS.background,
		border_color = COLORS.background_border,
		border_width = border_width,
		corner_radius = corner_raduis,
		height = 24,
		padding_left = item_padding / 2,
		padding_right = item_padding / 2,
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

-- Add Bar
SBAR.bar({
	-- position = "top",
	height = 32,
	color = COLORS.bar_color,
	blur_radius = 30,
})

return default_item
