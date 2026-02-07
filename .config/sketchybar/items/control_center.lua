local config_dir = os.getenv("CONFIG_DIR")
local menu_bin = config_dir .. "/helpers/menus/bin/menus"
SBAR.add("item", "control_center", {
	position = "right",
	icon = "􀜊",
	label = { drawing = false },
	click_script = menu_bin .. " -s 'Kontrollzentrum,BentoBox-0'",
})
