local icon_map = require("helpers.icon_map")

-- Set up rift.lua path
package.cpath = os.getenv("HOME") .. "/.config/sketchybar/rift-client/bin/?.so;" .. package.cpath
local rift = require("rift")

-- ==========================================================
-- CONFIG & LOGGING
-- ==========================================================
local DEBUG = false -- Set to true to enable logging to /tmp/rift.log

local function dump_table(t, prefix, file)
	prefix = prefix or ""
	if type(t) ~= "table" then
		file:write(prefix .. tostring(t) .. "\n")
		return
	end
	for k, v in pairs(t) do
		if type(v) == "table" then
			file:write(prefix .. tostring(k) .. ":\n")
			dump_table(v, prefix .. "  ", file)
		else
			file:write(prefix .. tostring(k) .. ": " .. tostring(v) .. "\n")
		end
	end
end

local function log_event(env)
	local f = io.open("/tmp/rift.log", "a")
	if f then
		f:write("--- EVENT: " .. tostring(env.EVENT) .. " ---\n")
		f:write("INFO: " .. tostring(env.INFO) .. "\n")
		if env.DATA then
			dump_table(env.DATA, "", f)
		end
		f:write("\n")
		f:close()
	end
end

-- ==========================================================
-- STATE
-- ==========================================================
local spaces_store = {}
local space_item_list = {}
local workspace_names = { "1", "2", "3", "4", "􀖇", "􀫀" }
local current_focused_workspace = "1"
local is_app_focused = false
local client = nil

-- Forward declaration of update_spaces and connect_client
local update_spaces
local connect_client

-- ==========================================================
-- INITIALIZE SPACES VISUALLY
-- ==========================================================
for _, workspace_id in ipairs(workspace_names) do
	local space = SBAR.add("item", "space." .. workspace_id, {
		position = "left",
		icon = { string = workspace_id, color = COLORS.disabled_color },
		label = {
			string = "",
			font = {
				family = "sketchybar-app-font",
				style = "Regular",
				size = 14.0,
			},
			drawing = true,
		},
		drawing = true,
	})

	table.insert(space_item_list, space.name)

	spaces_store[workspace_id] = {
		item = space,
	}

	space:subscribe("mouse.clicked", function()
		-- Dynamically determine 0-based index from our workspace list
		local idx = 0
		for i, name in ipairs(workspace_names) do
			if name == workspace_id then
				idx = i - 1
				break
			end
		end

		if not client and not connect_client() then
			return
		end

		local success = pcall(function()
			client:send_request('{"set_workspace":{"workspace":' .. idx .. "}}")
		end)
		if not success then
			client = nil
		end
	end)

	space:subscribe({ "mouse.entered", "mouse.exited" }, function(env)
		if not APPLICATION_MENU_COLLAPSED then
			return
		end
		local is_entering = (env.SENDER == "mouse.entered")
		local is_this_focused = (workspace_id == current_focused_workspace)
		if not is_this_focused then
			space:set({
				icon = { color = is_entering and COLORS.accent_color or COLORS.disabled_color },
				label = { color = is_entering and COLORS.accent_color or COLORS.disabled_color },
			})
		end
	end)
end

-- ==========================================================
-- SPACE SEPARATOR
-- ==========================================================
local space_separator = SBAR.add("item", "space_separator", {
	position = "left",
	label = { drawing = false },
	icon = {
		string = "|",
		padding_left = 0,
		padding_right = DEFAULT_ITEM.icon.padding_right,
	},
})

table.insert(space_item_list, space_separator.name)

-- ==========================================================
-- FRONT APP
-- ==========================================================
local front_app = SBAR.add("item", "front_app", {
	position = "left",
	icon = {
		font = { family = "sketchybar-app-font", style = "Regular", size = DEFAULT_ITEM.icon.font.size * 1.1 },
		padding_right = DEFAULT_ITEM.icon.padding_right * 0.5,
		padding_left = DEFAULT_ITEM.icon.padding_left * 0.5,
	},
	label = { font = { size = DEFAULT_ITEM.label.font.size * 1.1 } },
	drawing = false,
})

table.insert(space_item_list, front_app.name)

-- ==========================================================
-- BRACKET CREATION
-- ==========================================================
local spaces_bracket = SBAR.add("bracket", space_item_list, {
	background = { drawing = true },
})

-- ==========================================================
-- CONNECTION & UPDATE MANAGEMENT
-- ==========================================================
function connect_client()
	if client then
		return true
	end

	local new_client, err = rift.connect()
	if new_client then
		client = new_client
		client:subscribe({ "*" }, function(env)
			if DEBUG then
				log_event(env)
			end
			update_spaces()
		end)
		return true
	else
		if DEBUG then
			local f = io.open("/tmp/rift.log", "a")
			if f then
				f:write("Failed to connect to rift: " .. tostring(err) .. "\n")
				f:close()
			end
		end
		return false
	end
end

update_spaces = function()
	if not client and not connect_client() then
		return
	end

	local success, res = pcall(function()
		return client:send_request([[{"get_workspaces":{"space_id":null}}]])
	end)

	if not success or not res or res.error or not res.data then
		client = nil
		return
	end

	local active_app_name = nil

	for _, w in ipairs(res.data) do
		local ws_name = tostring(w.name)
		local is_focused = w.is_active

		if is_focused then
			current_focused_workspace = ws_name
		end

		-- Construct the icon strip of apps on this workspace
		local icon_strip = ""
		local seen_apps = {}
		if w.windows and #w.windows > 0 then
			for _, win in ipairs(w.windows) do
				local app = win.app_name
					or win.app
					or win.localized_name
					or (win.app_info and (win.app_info.localized_name or win.app_info.app_name or win.app_info.bundle_id))
					or win.bundle_id
				if app and not seen_apps[app] then
					seen_apps[app] = true
					local icon = icon_map[app] or icon_map["Default"] or ":default:"
					icon_strip = icon_strip .. " " .. icon
				end

				-- Capture the focused app's name dynamically from Rift's window focus info
				if win.is_focused then
					active_app_name = win.app_name or win.app or win.localized_name
				end
			end
		end

		local space_data = spaces_store[ws_name]
		if space_data then
			space_data.item:set({
				icon = { color = is_focused and COLORS.accent_color or COLORS.disabled_color },
				label = {
					string = icon_strip,
					color = is_focused and COLORS.accent_color or COLORS.disabled_color,
					drawing = (icon_strip ~= ""),
				},
			})
		end
	end

	-- Update front focused app
	is_app_focused = (active_app_name and active_app_name ~= "")
	if is_app_focused then
		front_app:set({
			drawing = APPLICATION_MENU_COLLAPSED,
			icon = { string = icon_map[active_app_name] or icon_map["Default"] or "APP" },
			label = { string = active_app_name },
		})
		if APPLICATION_MENU_COLLAPSED then
			space_separator:set({ drawing = true })
		end
	else
		front_app:set({ drawing = false })
		space_separator:set({ drawing = false })
	end
end

-- Try initial connection and render
connect_client()
update_spaces()

-- ==========================================================
-- SWAP CONTROLLER (Curtain / Fade Effect)
-- ==========================================================
local swap_manager = SBAR.add("item", { drawing = false })

SBAR.add("event", "fade_in_spaces")
SBAR.add("event", "fade_out_spaces")

swap_manager:subscribe("fade_in_spaces", function()
	-- Connect and get workspaces to know which one is focused
	if not client and not connect_client() then
		return
	end
	local res = client:send_request([[{"get_workspaces":{"space_id":null}}]])
	if not res or not res.data then
		return
	end

	local focused_name = "1"
	for _, w in ipairs(res.data) do
		if w.is_active then
			focused_name = tostring(w.name)
			break
		end
	end

	-- Reset widths/colors first to 0
	for _, data in pairs(spaces_store) do
		data.item:set({ width = 0, icon = { color = 0x00000000 }, label = { color = 0x00000000 } })
	end
	if is_app_focused then
		front_app:set({ width = 0, icon = { color = 0x00000000 }, label = { color = 0x00000000 } })
	end

	-- Animate in
	SBAR.animate("tanh", APPLICATION_MENU_TRANSITION_FRAMES, function()
		spaces_bracket:set({ background = { drawing = true } })

		for id, data in pairs(spaces_store) do
			local color = (id == focused_name) and COLORS.accent_color or COLORS.disabled_color
			data.item:set({ width = "dynamic", icon = { color = color }, label = { color = color } })
		end

		space_separator:set({ drawing = is_app_focused })

		if is_app_focused then
			front_app:set({ width = "dynamic", icon = { color = 0xffffffff }, label = { color = 0xffffffff } })
		end
	end)
end)

swap_manager:subscribe("fade_out_spaces", function()
	SBAR.animate("tanh", APPLICATION_MENU_TRANSITION_FRAMES, function()
		spaces_bracket:set({ background = { drawing = false } })

		for _, data in pairs(spaces_store) do
			data.item:set({
				width = 0,
				icon = { color = COLORS.transparent },
				label = { color = COLORS.transparent },
			})
		end

		space_separator:set({ drawing = false })
		front_app:set({ width = 0, icon = { color = COLORS.transparent }, label = { color = COLORS.transparent } })
	end)
end)
