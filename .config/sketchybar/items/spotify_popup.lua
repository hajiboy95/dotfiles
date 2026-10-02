-- ==========================================================
-- SPOTIFY MINI PLAYER (popup on right click)
-- ==========================================================
-- One row: the cover, title over "artist · elapsed / length", and
-- previous / play-pause / next. Everything comes from media-control
-- while Spotify is the now-playing source; the time ticks while the
-- popup is open, and the cover is re-read when the track changes.

local config_dir = os.getenv("CONFIG_DIR")
local cover_path = (os.getenv("TMPDIR") or "/tmp/") .. "sketchybar_spotify_cover.jpg"
local placeholder = config_dir .. "/data/album_placeholder.jpg"
local cover_size = 56 -- pt

return function(anchor, control)
	anchor:set({ popup = { align = "right", horizontal = true, height = cover_size + 16 } })
	local popup = "popup." .. anchor.name

	local cover = SBAR.add("item", "spotify.cover", {
		position = popup,
		width = cover_size,
		icon = { drawing = false },
		label = { drawing = false },
		background = {
			drawing = true,
			height = cover_size,
			corner_radius = 8,
			color = 0x00000000,
			border_width = 0,
			image = { string = placeholder, scale = 0.25, corner_radius = 8 },
		},
		padding_left = 10,
	})

	local function text_item(name, y, scale, color)
		return THEME.track_word(
			SBAR.add("item", "spotify.info." .. name, {
				position = popup,
				width = name == "title" and 0 or 210,
				y_offset = y,
				icon = { drawing = false },
				label = {
					string = "",
					font = LOOK.word_font(scale),
					color = color,
					max_chars = 30,
					padding_left = 10,
				},
			}),
			scale
		)
	end
	local title = text_item("title", 9, 1, COLORS.text_color)
	local sub = text_item("sub", -9, 0.8, COLORS.disabled_color)

	local buttons = {}
	local function button(name, glyph, mc, verb)
		local item = SBAR.add("item", "spotify.btn." .. name, {
			position = popup,
			icon = { string = glyph, font = { size = 18 }, padding_left = 6, padding_right = 6 },
			label = { drawing = false },
		})
		item:subscribe("mouse.clicked", function()
			control(mc, verb)
		end)
		buttons[name] = item
		return item
	end
	button("prev", "󰒮", "previous-track", "previous track")
	local play = button("play", "󰐊", "toggle-play-pause", "playpause")
	button("next", "󰒭", "next-track", "next track")
	buttons.next:set({ padding_right = 10 })

	local last_track = nil

	local function clock(seconds)
		seconds = math.max(0, math.floor(seconds or 0))
		return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
	end

	-- Reads media-control once: the fields, and (on a new track) the
	-- cover, decoded and shrunk to 4x the drawn size.
	local function refresh()
		SBAR.exec([==[media-control get 2>/dev/null | python3 -c '
import base64, datetime, json, subprocess, sys
try:
    d = json.load(sys.stdin) or {}
except Exception:
    d = {}
if d.get("bundleIdentifier") != "com.spotify.client":
    print("none"); sys.exit()
elapsed = d.get("elapsedTime") or 0
if d.get("playing") and d.get("timestamp"):
    then = datetime.datetime.fromisoformat(d["timestamp"].replace("Z", "+00:00"))
    elapsed += (datetime.datetime.now(datetime.timezone.utc) - then).total_seconds()
track = d.get("contentItemIdentifier") or d.get("title", "")
print("ok")
print(track)
print("1" if d.get("playing") else "0")
print(int(min(elapsed, d.get("duration") or elapsed)))
print(int(d.get("duration") or 0))
print(d.get("title", ""))
print(d.get("artist", ""))
art = d.get("artworkData")
if art and sys.argv[1] != track:
    with open(sys.argv[2], "wb") as f:
        f.write(base64.b64decode(art))
    subprocess.run(["sips", "-Z", "224", sys.argv[2]], capture_output=True)
    print("newcover")' ']==] .. (last_track or "") .. "' '" .. cover_path .. "'", function(result)
			local lines = {}
			for line in (result .. "\n"):gmatch("([^\n]*)\n") do
				table.insert(lines, line)
			end
			if lines[1] ~= "ok" then
				title:set({ label = { string = "Nothing playing in Spotify" } })
				sub:set({ label = { string = "" } })
				return
			end
			local track, playing = lines[2], lines[3] == "1"
			title:set({ label = { string = lines[6] } })
			sub:set({
				label = { string = lines[7] .. " · " .. clock(lines[4]) .. " / " .. clock(lines[5]) },
			})
			play:set({ icon = { string = playing and "󰏤" or "󰐊" } })
			-- A new track without art falls back to the placeholder.
			if lines[8] == "newcover" then
				cover:set({ background = { image = { string = cover_path } } })
			elseif track ~= last_track then
				cover:set({ background = { image = { string = placeholder } } })
			end
			last_track = track
		end)
	end

	-- The time ticks only while the popup is open.
	local function set_open(open)
		anchor:set({ popup = { drawing = open } })
		title:set({ update_freq = open and 1 or 0 })
		if open then
			refresh()
		end
	end
	title:subscribe("routine", refresh)
	anchor:subscribe("mouse.exited.global", function()
		set_open(false)
	end)
	-- A track or play-state change while open refreshes at once.
	anchor:subscribe("spotify_change", function()
		if anchor:query().popup.drawing == "on" then
			refresh()
		end
	end)

	THEME.on_change(function()
		title:set({ label = { color = COLORS.text_color } })
		sub:set({ label = { color = COLORS.disabled_color } })
		for _, item in pairs(buttons) do
			item:set({ icon = { color = COLORS.text_color } })
		end
	end)

	return {
		toggle = function()
			set_open(anchor:query().popup.drawing ~= "on")
		end,
	}
end
