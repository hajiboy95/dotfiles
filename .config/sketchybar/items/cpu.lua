-- 1. Get Core Count ONCE (Optimization)
-- Instead of running sysctl every 2 seconds, we run it once on startup.
local core_count = 1 -- fallback
local handle = io.popen("sysctl -n machdep.cpu.thread_count")
if handle then
	local result = handle:read("*a")
	core_count = tonumber(result) or 1
	handle:close()
end

-- 2. Create the Item
local cpu = SBAR.add("item", "cpu", {
	position = "right",
	update_freq = 2,
	icon = {
		string = "􀧓",
		y_offset = 1,
	},
})

-- 3. Update Function
local function cpu_update()
	SBAR.exec("ps -A -o %cpu | awk '{s+=$1} END {print s}'", function(total_load)
		local load = tonumber(total_load) or 0
		local percent = math.floor(load / core_count)

		cpu:set({
			label = percent .. "%",
		})
	end)
end

-- Subscribe
cpu:subscribe("routine", cpu_update)
