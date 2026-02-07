local icon_map = require("helpers.icon_map")
local separator_module = require("items.separator")
local spaces_store = {}
SBAR.add("event", "aerospace_workspace_change")
SBAR.add("event", "aerospace_mode_change")

-- ==========================================================
-- 1. AEROSPACE MODE INDICATOR
-- ==========================================================
local mode_indicator = SBAR.add("item", "aerospace_mode", {
	position = "left",
	icon = {
		string = "",
		padding_right = 0,
	},
	drawing = false,
})

-- Helper to update the UI based on mode string
local function update_mode_display(mode)
	local should_draw = (mode ~= "main" and mode ~= "")
	mode_indicator:set({
		drawing = should_draw,
		label = { drawing = should_draw },
	})
end

-- Subscription for changes
mode_indicator:subscribe("aerospace_mode_change", function(env)
	update_mode_display(env.INFO or "")
end)

-- ==========================================================
-- 2. WORKSPACE UPDATER LOGIC
-- ==========================================================
local function update_space(item, workspace_id, focused_workspace, should_animate)
	if not APPLICATION_MENU_COLLAPSED then
		return
	end

	-- TODO: WE KNOW WE'LL GET FOCUSED_WORKSPACE ON WORKSPACE CHANGE. IF WE DON'T,
	-- WE DON'T NEED TO ASK FOR IT AGAIN, PROBLEM: DOUBLE TRIGGER WORKSPACE AND FOCUS CHANGE
	-- 1. Fetch focus if missing
	if not focused_workspace then
		SBAR.exec("aerospace list-workspaces --focused", function(res)
			update_space(item, workspace_id, res:gsub("\n", ""), should_animate)
		end)
		return
	end

	local is_focused = (focused_workspace == workspace_id)

	-- 2. Get Windows
	local cmd = "aerospace list-windows --workspace "
		.. workspace_id
		.. " --format '%{app-name}|%{monitor-appkit-nsscreen-screens-id}'"

	SBAR.exec(cmd, function(windows)
		local icon_strip = ""
		local monitor_id = "1"

		for line in windows:gmatch("[^\r\n]+") do
			local app, mid = line:match("^(.*)|(.-)$")
			if app and app ~= "" then
				local lookup = icon_map[app] or icon_map["Default"] or "􀔆"
				icon_strip = icon_strip .. lookup .. "  "
				if mid and mid ~= "" then
					monitor_id = mid
				end
			end
		end

		if is_focused and icon_strip == "" then
			icon_strip = "􀍼"
		end

		-- 3. DETERMINE VISIBILITY
		local has_content = (icon_strip ~= "")
		local should_show = has_content or is_focused

		-- 4. STATE CHECK (Avoid redundant updates)
		local state = spaces_store[workspace_id]
		if
			state
			and state.icon_strip == icon_strip
			and state.is_focused == is_focused
			and state.monitor_id == monitor_id
			and not should_animate
		then
			return
		end

		-- Update cache
		if state then
			state.should_show = should_show
			state.icon_strip = icon_strip
			state.is_focused = is_focused
			state.monitor_id = monitor_id
		end

		if not should_show then
			item:set({ drawing = false })
			return
		end

		-- 5. Animation (Bounce)
		if is_focused and should_animate then
			SBAR.animate("sin", 10, function()
				item:set({ y_offset = 6 })
				SBAR.animate("sin", 10, function()
					item:set({ y_offset = 0 })
				end)
			end)
		else
			item:set({ y_offset = 0 })
		end

		-- 6. Draw the Item
		item:set({
			display = monitor_id,
			drawing = true,
			icon = {
				string = workspace_id,
				color = is_focused and COLORS.accent_color or COLORS.disabled_color,
			},
			label = {
				string = icon_strip,
				color = is_focused and COLORS.accent_color or COLORS.disabled_color,
				drawing = true,
				font = { family = "sketchybar-app-font", style = "Regular", size = 16.0 },
			},
		})
	end)
end

-- ==========================================================
-- 3. CREATE WORKSPACE ITEMS
-- ==========================================================

local handle = io.popen("aerospace list-workspaces --all")

if handle then
	local workspaces = handle:read("*a")
	handle:close()

	for workspace_id in workspaces:gmatch("[^\r\n]+") do
		local space = SBAR.add("item", "space." .. workspace_id, {
			position = "left",
			icon = { string = workspace_id },
			drawing = false,
		})

		spaces_store[workspace_id] = {
			item = space,
			should_show = false,
			icon_strip = "",
			is_focused = false,
			monitor_id = "1",
		}

		local space_events = {
			"aerospace_workspace_change",
			"space_windows_change",
			"front_app_switched",
			"display_change",
		}

		local debounce_timer = nil

		space:subscribe(space_events, function(env)
			local event_name = env.SENDER

			-- 2. Determine focus and animation
			local focused = env.FOCUSED_WORKSPACE
			local should_animate = (event_name == "aerospace_workspace_change" or event_name == "mouse.clicked")

			-- 3. Debounce Logic
			if event_name == "aerospace_workspace_change" then
				-- Immediate update for critical events
				if debounce_timer then
					SBAR.delay_cancel(debounce_timer)
					debounce_timer = nil
				end
				update_space(space, workspace_id, focused, should_animate)
			else
				-- Debounced update for frequent events
				if debounce_timer then
					SBAR.delay_cancel(debounce_timer)
				end
				debounce_timer = SBAR.delay(0.5, function()
					debounce_timer = nil
					update_space(space, workspace_id, focused, should_animate)
				end)
			end
		end)

		space:subscribe("mouse.clicked", function()
			SBAR.exec("aerospace workspace " .. workspace_id)
		end)

		space:subscribe({ "mouse.entered", "mouse.exited" }, function(env)
			if not APPLICATION_MENU_COLLAPSED then
				return
			end

			local is_entering = (env.SENDER == "mouse.entered")

			SBAR.exec("aerospace list-workspaces --focused", function(focused)
				local workspace_is_focused = (focused:gsub("\n", "") == workspace_id)

				if not workspace_is_focused then
					if is_entering then
						-- HIGHLIGHT (Hover-Farben an, Hintergrund an)
						space:set({
							icon = { color = COLORS.accent_color },
							label = { color = COLORS.accent_color },
						})
					else
						-- RESET (Zurück zum Standard für inaktive Spaces)
						space:set({
							icon = { color = COLORS.disabled_color },
							label = { color = COLORS.disabled_color },
						})
					end
				end
			end)
		end)

		-- Initial Update
		update_space(space, workspace_id)
	end
end

local space_separator = separator_module.create("space_separator")

-- ==========================================================
-- 4. SWAP CONTROLLER (Curtain Effect)
-- ==========================================================
local swap_manager = SBAR.add("item", { drawing = false })

-- Register explicit events
SBAR.add("event", "fade_in_spaces")
SBAR.add("event", "fade_out_spaces")

-- === FADE IN LOGIC (SHOW SPACES) ===
swap_manager:subscribe("fade_in_spaces", function()
	SBAR.exec("aerospace list-workspaces --focused", function(focused_name)
		focused_name = focused_name:gsub("\n", "")

		-- 1. Setup: Reset width to 0
		for _, data in pairs(spaces_store) do
			if data.should_show then
				data.item:set({
					width = 0,
					icon = { color = 0x00000000 },
					label = { color = 0x00000000 },
					background = { color = 0x00000000 },
				})
			end
		end

		-- 2. Animate: Grow width and fade in color
		SBAR.animate("tanh", APPLICATION_MENU_TRANSITION_FRAMES, function()
			for id, data in pairs(spaces_store) do
				if data.should_show then
					local is_focused = (id == focused_name)
					local text_color = is_focused and COLORS.accent_color or COLORS.disabled_color
					local bg_color = is_focused and COLORS.background or COLORS.transparent

					data.item:set({
						width = "dynamic",
						icon = { color = text_color },
						label = { color = text_color },
						background = { color = bg_color },
					})
				end
			end
			space_separator:set({ drawing = true })
		end)
	end)
end)

-- === FADE OUT LOGIC (HIDE SPACES) ===
swap_manager:subscribe("fade_out_spaces", function()
	-- Animate: Shrink width to 0 and transparent color
	SBAR.animate("tanh", APPLICATION_MENU_TRANSITION_FRAMES, function()
		for _, data in pairs(spaces_store) do
			if data.should_show then
				data.item:set({
					width = 0,
					icon = { color = COLORS.transparent },
					label = { color = COLORS.transparent },
					background = { color = COLORS.transparent },
				})
			end
			space_separator:set({ drawing = false })
		end
	end)
end)
