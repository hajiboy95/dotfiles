local M = {}

function M.create(name)
	-- We add the item using the name passed in, or default to "separator"
	local separator = SBAR.add("item", name or "separator", {
		position = "left",
		label = {
			string = "|",
			y_offset = 2,
			padding_left = DEFAULT_ITEM.icon.padding_right,
		},
		icon = { drawing = false },
		background = { drawing = false, padding_left = 0, padding_right = 0 },
	})

	return separator
end

return M
