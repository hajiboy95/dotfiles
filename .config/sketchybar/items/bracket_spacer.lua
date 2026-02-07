local M = {}

function M.create(name, width, position)
	local spacer = SBAR.add("item", name or "spacer", {
		position = position or "right",
		width = width,
		label = { drawing = false },
		icon = { drawing = false },
	})

	return spacer
end

return M
