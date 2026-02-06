local max_items = 5
local history = {}

-- 1. Create the Main Item
local clipboard = SBAR.add("item", "clipboard", {
	position = "right",
	update_freq = 1,
	icon = {
		string = "􁕜",
		font = { size = 16.0 },
	},
	label = { drawing = false },
})

-- 2. Create the Popup Items (The list)
-- We create 5 hidden items upfront so we don't have to destroy/create them constantly.
local popup_items = {}
for i = 1, max_items do
	local item = SBAR.add("item", "clipboard.popup." .. i, {
		position = "popup." .. clipboard.name,
		click_script = "",
		icon = {
			string = "􀊄",
			font = { size = 12.0 },
		},

		label = {
			string = "",
			width = 150,
			align = "left",
		},

		background = {
			drawing = false,
			padding_left = 12,
			padding_right = 12,
			corner_radius = 12,
		},
	})
	table.insert(popup_items, item)
end

-- 3. Function to Copy back to Clipboard
-- This function generates the bash command to copy text back
local function generate_copy_script(text)
	-- Escape single quotes for Bash safety
	local escaped_text = text:gsub("'", "'\\''")
	return "echo -n '" .. escaped_text .. "' | pbcopy; sketchybar --set clipboard popup.drawing=off"
end

-- 4. Update Function (Runs every second)
local function clipboard_update()
	SBAR.exec("pbpaste", function(content)
		if content == nil or content == "" then
			return
		end

		-- Check if it's a new copy (compare with the latest entry)
		if history[1] ~= content then
			-- Add to history
			table.insert(history, 1, content)
			if #history > max_items then
				table.remove(history, max_items + 1)
			end

			-- Update the Popup Item
			for i, item in ipairs(popup_items) do
				local history_text = history[i]

				if history_text then
					-- Truncate label for display (first 20 chars)
					local display_label = history_text:gsub("\n", " "):sub(1, 20)

					item:set({
						label = display_label,
						click_script = generate_copy_script(history_text),
						drawing = true,
					})
				else
					-- If no history for this slot, hide the item
					item:set({ drawing = false })
				end
			end
		end
	end)
end

-- 5. Event Handling
clipboard:subscribe("routine", clipboard_update)

-- Show popup on hover
clipboard:subscribe("mouse.entered", function()
	clipboard:set({ popup = { drawing = true } })
end)

-- Hide popup when leaving (and global exit)
clipboard:subscribe({ "mouse.exited", "mouse.exited.global" }, function()
	clipboard:set({ popup = { drawing = false } })
end)
