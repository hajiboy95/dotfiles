local M = {}

function M.create(name, position)
	local separator = SBAR.add("item", name or "separator", {
		position = position or "left",
		icon = { drawing = false },
	})

	return separator
end

return M
