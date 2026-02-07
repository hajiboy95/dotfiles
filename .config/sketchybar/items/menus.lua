-- CONFIGURATION
local max_items = 15
local animation_seconds = (APPLICATION_MENU_TRANSITION_FRAMES / 60)

-- Detect Menu Binary Path
local config_dir = os.getenv("CONFIG_DIR")
local menu_bin = config_dir .. "/helpers/menus/bin/menus"

-- STATE VARIABLES
local mouse_on_menu = false
local is_sticky_open = false -- Flag to keep menu open after right-click

-- 1. Create the Trigger Icon
local menu_item = SBAR.add("item", "menu_trigger", {
	position = "left",
	icon = { font = { size = 22.0 }, string = "", y_offset = 1 },
	label = { drawing = false },
})

-- 2. Create the Menu Items Pool
local menu_items = {}
for i = 1, max_items do
	menu_items[i] = SBAR.add("item", "menu." .. i, {
		position = "left",
		drawing = false,
		width = 0,
		icon = { drawing = false },
		label = {
			font = { style = "Semibold", size = 13.5 },
			padding_left = DEFAULT_ITEM.icon.padding_left,
		},
		background = {
			corner_radius = 5,
		},
		click_script = menu_bin .. " -s " .. i,
	})
end

-- 3. Logic: Update Visuals
local function update_menus_visuals(menus_string)
	local idx = 1
	for menu_text in string.gmatch(menus_string, "[^\r\n]+") do
		if idx <= max_items then
			menu_items[idx]:set({
				label = { string = menu_text, drawing = true },
				drawing = not APPLICATION_MENU_COLLAPSED,
			})
			idx = idx + 1
		end
	end

	for i = idx, max_items do
		menu_items[i]:set({ drawing = false, width = 0 })
	end
end

-- 4. Logic: Animate & Open
local function open_menu()
	if APPLICATION_MENU_COLLAPSED == false then
		return
	end
	APPLICATION_MENU_COLLAPSED = false

	SBAR.trigger("fade_out_spaces")

	SBAR.exec(menu_bin .. " -l", function(result)
		if APPLICATION_MENU_COLLAPSED then
			return
		end
		update_menus_visuals(result)
		SBAR.animate("tanh", APPLICATION_MENU_TRANSITION_FRAMES, function()
			SBAR.set("/menu\\..*/", {
				width = "dynamic",
				label = { drawing = true, color = COLORS.disabled_color },
			})
		end)
	end)
end

local function close_menu()
	if APPLICATION_MENU_COLLAPSED then
		return
	end
	APPLICATION_MENU_COLLAPSED = true

	SBAR.animate("tanh", APPLICATION_MENU_TRANSITION_FRAMES, function()
		SBAR.set("/menu\\..*/", {
			width = 0,
			label = { color = 0x00000000 },
		})
	end)

	SBAR.trigger("fade_in_spaces")

	SBAR.delay(animation_seconds, function()
		if APPLICATION_MENU_COLLAPSED then
			SBAR.set("/menu\\..*/", { drawing = false })
		end
	end)
end

-- 5. Logic: Update State
local function update_state()
	-- Stay open if hovering OR if locked open by right-click
	if mouse_on_menu or is_sticky_open then
		open_menu()
	else
		-- Small delay to prevent accidental closing during fast mouse movements
		SBAR.delay(0.2, function()
			if not mouse_on_menu and not is_sticky_open then
				close_menu()
			end
		end)
	end
end

-- 6. Bindings
menu_item:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		-- Native Apple Menu (Index 0)
		SBAR.exec(menu_bin .. " -s 0")
		-- Close the sticky animation if it was open
		is_sticky_open = false
		update_state()
	else
		-- Toggle sticky expansion
		is_sticky_open = not is_sticky_open
		update_state()
	end
end)

menu_item:subscribe("mouse.exited", function()
	update_state()
end)

-- Global Exit: Collapse everything when mouse leaves the bar
menu_item:subscribe("mouse.exited", function()
	is_sticky_open = false
	mouse_on_menu = false
	update_state()
end)

for i = 1, max_items do
	menu_items[i]:subscribe("mouse.entered", function()
		mouse_on_menu = true
		menu_items[i]:set({
			label = { font = { style = "Bold" }, color = COLORS.accent_color },
		})
		update_state()
	end)

	menu_items[i]:subscribe("mouse.exited", function()
		mouse_on_menu = false
		menu_items[i]:set({
			label = { font = { style = "Semibold" }, color = COLORS.disabled_color },
		})
		update_state()
	end)

	-- Left clicking a menu item also resets the sticky state
	menu_items[i]:subscribe("mouse.clicked", function()
		is_sticky_open = false
		update_state()
	end)
end

-- -- 6. Watcher (Update menus when app switches), disabled since on focus change moves mouse to middle of foxus window
-- local menu_watcher = SBAR.add("item", { drawing = false })
-- menu_watcher:subscribe("front_app_switched", function()
--     SBAR.exec(menu_bin .. " -l", function(result)
--         update_menus_visuals(result)
--     end)
-- end)
