local M = {}

function M.create(name)
	local separator = SBAR.add("item", name or "separator", {
		position = "left",
		icon = { drawing = false },
	})

	return separator
end

return M
