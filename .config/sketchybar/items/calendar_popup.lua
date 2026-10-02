-- ==========================================================
-- MONTH VIEW (popup on the clock)
-- ==========================================================
-- Title "October 2026", a Mo–Su header and up to six week rows in
-- Hack (equal-width digits keep the columns). Scroll over it to move
-- through months, Shift- or Option-scroll through years; click the
-- title to come back to today. A label has one colour per row, so
-- today is marked by shape, a circled number, not by colour.

local months = {
	"January",
	"February",
	"March",
	"April",
	"May",
	"June",
	"July",
	"August",
	"September",
	"October",
	"November",
	"December",
}

return function(anchor)
	anchor:set({ popup = { align = "right" } })
	local popup = "popup." .. anchor.name
	local mono = { family = LOOK.icon_font, style = "Regular", size = 13.5 }

	-- A fixed width: the popup otherwise sized narrower than its rows
	-- and clipped the last column.
	local function row(name, font)
		return SBAR.add("item", "cal.view." .. name, {
			position = popup,
			width = 196, -- 21 Hack cells (~171 pt at 13.5) + 2 × 12 padding
			icon = { drawing = false },
			label = {
				string = "",
				font = font,
				padding_left = 12,
				padding_right = 12,
			},
		})
	end

	local title = THEME.track_word(row("title", LOOK.word_font()))
	-- Centred between its arrows.
	title:set({ label = { width = 196, align = "center", padding_left = 0, padding_right = 0 } })
	local header = row("header", mono)
	local weeks = {}
	for i = 1, 6 do
		weeks[i] = row("week" .. i, mono)
	end

	local offset = 0 -- months from the current one

	local function render()
		local now = os.date("*t")
		local year, month = now.year, now.month + offset
		year = year + math.floor((month - 1) / 12)
		month = (month - 1) % 12 + 1

		local first = os.date("*t", os.time({ year = year, month = month, day = 1, hour = 12 }))
		local lead = (first.wday + 5) % 7 -- Monday-first blanks before day 1
		local days = os.date("*t", os.time({ year = year, month = month + 1, day = 0, hour = 12 })).day
		local is_this_month = year == now.year and month == now.month

		title:set({
			label = {
				string = "‹  " .. months[month] .. " " .. year .. "  ›",
				color = offset == 0 and COLORS.text_color or COLORS.accent_color,
			},
		})
		header:set({ label = { string = " Mo Tu We Th Fr Sa Su", color = COLORS.disabled_color } })

		local day = 1 - lead
		for i = 1, 6 do
			if day > days then
				weeks[i]:set({ drawing = false })
			else
				-- Each cell is three Hack characters wide, so columns never
				-- shift.
				local cells = {}
				for _ = 1, 7 do
					local today = is_this_month and day == now.day
					local cell
					if day < 1 or day > days then
						cell = "   "
					elseif today then
						-- Today circled: ① to ⑳ (U+2460…), ㉑ to ㉛ (U+3251…). The
						-- glyph comes from a fallback font yet spans two Hack
						-- cells, so the columns hold.
						cell = " " .. utf8.char(day <= 20 and (0x245F + day) or (0x3250 + day - 20))
					else
						cell = string.format(" %2d", day)
					end
					table.insert(cells, cell)
					day = day + 1
				end
				weeks[i]:set({
					drawing = true,
					label = {
						string = table.concat(cells),
						color = COLORS.text_color,
					},
				})
			end
		end
	end

	local function set_open(open)
		if open then
			offset = 0
			render()
		end
		anchor:set({ popup = { drawing = open } })
	end

	-- Scroll: a month per step; with Shift or Option, a year. Shift
	-- works on a trackpad; a wheel's Shift-scroll turns horizontal,
	-- which sketchybar does not read, so Option covers the wheel.
	local function scroll(env)
		local delta = tonumber(env.SCROLL_DELTA) or 0
		if delta ~= 0 then
			local by_year = env.MODIFIER == "shift" or env.MODIFIER == "alt"
			local step = by_year and 12 or 1
			offset = offset + (delta > 0 and -step or step)
			render()
		end
	end
	for _, item in ipairs({ title, header, table.unpack(weeks) }) do
		item:subscribe("mouse.scrolled", scroll)
	end
	title:subscribe("mouse.clicked", function()
		offset = 0
		render()
	end)
	anchor:subscribe("mouse.exited.global", function()
		set_open(false)
	end)
	THEME.on_change(render)
	render()

	return {
		toggle = function()
			set_open(anchor:query().popup.drawing ~= "on")
		end,
	}
end
