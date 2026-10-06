-- ==========================================================
-- SPOTIFY MINI PLAYER (popup on left click)
-- ==========================================================
-- A card: the cover (with a progress line; click opens the song in
-- Spotify); right of it the title, "artist · elapsed / length" and
-- Spotify's volume; at the right, previous / play-pause / next. Everything but the volume comes from media-control while
-- Spotify is the now-playing source; the time ticks while the popup
-- is open. The cover is fetched in the background on every track
-- change, so the popup opens with it already in place.

local config_dir = os.getenv("CONFIG_DIR")
local cover_base = (os.getenv("TMPDIR") or "/tmp/") .. "sketchybar_spotify_cover_"
-- Stored at cover_px, like the decoded covers, so both draw at cover_size.
local placeholder = config_dir .. "/data/album_placeholder.jpg"
local cover_size = 64 -- pt
local inset = 12 -- pt, around the cover and at the right edge
local cover_radius = 10 -- pt; the popup's is this plus inset
local cover_px = cover_size * 4 -- decoded size (sharp on Retina)

return function(anchor, control)
	anchor:set({
		popup = {
			align = "center",
			horizontal = true,
			height = cover_size + 2 * inset,
			background = { corner_radius = cover_radius + inset },
		},
	})
	local popup = "popup." .. anchor.name

	local cover = SBAR.add("item", "spotify.cover", {
		position = popup,
		width = cover_size,
		icon = { drawing = false },
		label = { drawing = false },
		background = {
			drawing = true,
			height = cover_size,
			corner_radius = cover_radius,
			color = 0x00000000,
			border_width = 0,
			border_color = COLORS.accent_color,
			image = { string = placeholder, scale = cover_size / cover_px, corner_radius = cover_radius },
		},
		padding_left = inset,
	})

	-- Track position: a thin line along the cover's bottom edge. It
	-- overlaps the cover (negative padding), which takes no clicks, so
	-- it steals none.
	local progress_inset = 6 -- pt, from the cover's sides and bottom
	local progress = SBAR.add("slider", "spotify.progress", cover_size - 2 * progress_inset, {
		position = popup,
		padding_left = progress_inset - cover_size,
		padding_right = progress_inset,
		y_offset = -(cover_size / 2 - progress_inset),
		label = { drawing = false },
		icon = { drawing = false },
		slider = {
			highlight_color = COLORS.accent_color,
			background = { height = 3, corner_radius = 1.5, color = 0x80000000 },
			knob = { drawing = false },
		},
	})

	-- Click the cover: show the track in Spotify. Hover: an accent
	-- border, as sketchybar has no hand cursor.
	cover:subscribe("mouse.clicked", function()
		SBAR.exec([[pgrep -xq Spotify && open "$(osascript -e 'tell application "Spotify" to spotify url of current track')"]])
	end)
	cover:subscribe("mouse.entered", function()
		cover:set({ background = { border_width = 2, border_color = COLORS.accent_color } })
	end)
	cover:subscribe("mouse.exited", function()
		cover:set({ background = { border_width = 0 } })
	end)

	-- The two text lines. Width 0, so the volume below starts at the
	-- same x; no mouse handlers, as the items added later take the
	-- clicks where their windows overlap.
	local function text_item(name, y, scale, color)
		return THEME.track_word(
			SBAR.add("item", "spotify.info." .. name, {
				position = popup,
				width = 0,
				y_offset = y,
				icon = { drawing = false },
				label = {
					string = "",
					font = LOOK.word_font(scale),
					color = color,
					max_chars = name == "title" and 14 or nil,
					padding_left = inset,
				},
			}),
			scale
		)
	end
	local title = text_item("title", 24, 1, COLORS.text_color)
	local sub = text_item("sub", 5, 0.8, COLORS.disabled_color)

	-- Under the text: the speaker and Spotify's volume.
	local volume_y = -20
	local speaker_width = 20 -- pt
	local slider_width = 100 -- pt


	-- Spotify's own volume. With Spotify Connect it is the remote
	-- device's volume, which the Mac volume does not reach. Spotify's
	-- AppleScript only, and never while Spotify is closed (a `tell`
	-- to a closed app launches it).
	local speaker = SBAR.add("item", "spotify.volume.icon", {
		position = popup,
		y_offset = volume_y,
		padding_left = inset,
		icon = {
			string = "󰕾",
			font = { size = 13 },
			color = COLORS.disabled_color,
			width = speaker_width,
			padding_left = 0,
			padding_right = 0,
		},
		label = { drawing = false },
	})
	local volume = SBAR.add("slider", "spotify.volume", slider_width, {
		position = popup,
		y_offset = volume_y,
		padding_right = 10,
		label = { drawing = false },
		icon = { drawing = false },
		slider = {
			highlight_color = COLORS.accent_color,
			background = {
				height = 4,
				corner_radius = 2,
				color = LOOK.with_alpha(COLORS.disabled_color, 0x40),
			},
			knob = { drawing = false },
		},
	})
	-- The last volume above 0, for the speaker's unmute.
	local current_volume, unmuted_volume = 0, 50
	local function show_volume(percent)
		percent = math.max(0, math.min(100, math.floor(tonumber(percent) or 0)))
		current_volume = percent
		if percent > 0 then
			unmuted_volume = percent
		end
		volume:set({ slider = { percentage = percent } })
		speaker:set({ icon = { string = percent == 0 and "󰝟" or "󰕾" } })
	end
	-- Runs an AppleScript statement inside `tell application "Spotify"`
	-- and shows the volume it leaves.
	local function volume_script(statement)
		SBAR.exec(
			"pgrep -xq Spotify && osascript -e 'tell application \"Spotify\"' -e '"
				.. statement
				.. "' -e 'sound volume' -e 'end tell'",
			function(result)
				if tonumber(result) then
					show_volume(result)
				end
			end
		)
	end
	local function read_volume()
		volume_script("sound volume")
	end
	volume:subscribe("mouse.clicked", function(env)
		local percent = tonumber(env.PERCENTAGE)
		if percent then
			show_volume(percent)
			volume_script("set sound volume to " .. math.floor(percent))
		end
	end)
	-- Click the speaker: mute, or back to the volume before.
	speaker:subscribe("mouse.clicked", function()
		local target = current_volume > 0 and 0 or unmuted_volume
		volume_script("set sound volume to " .. target)
	end)
	-- Scroll on the speaker or the slider: 5% steps.
	local function on_scroll(env)
		local delta = tonumber(env.SCROLL_DELTA) or 0
		if delta ~= 0 then
			volume_script("set sound volume to (sound volume) " .. (delta > 0 and "+ 5" or "- 5"))
		end
	end
	volume:subscribe("mouse.scrolled", on_scroll)
	speaker:subscribe("mouse.scrolled", on_scroll)
	speaker:subscribe("mouse.entered", function()
		speaker:set({ icon = { color = COLORS.text_color } })
	end)
	speaker:subscribe("mouse.exited", function()
		speaker:set({ icon = { color = COLORS.disabled_color } })
	end)

	-- The transport, a column of its own at the right, vertically
	-- centred. Added last: it shares no x range with the volume, and
	-- wins the clicks over the text it overlaps.
	-- size: glyph pt, width: slot pt (play is the larger one). Hover
	-- lays a faint round background behind the button.
	local buttons = {}
	local function button(name, glyph, size, width, mc, verb)
		local height = width + 4 -- hover background
		local item = SBAR.add("item", "spotify.btn." .. name, {
			position = popup,
			icon = {
				string = glyph,
				font = { size = size },
				width = width,
				align = "center",
				padding_left = 0,
				padding_right = 0,
			},
			label = { drawing = false },
			background = { drawing = false, height = height, corner_radius = height / 2, border_width = 0 },
		})
		item:subscribe("mouse.clicked", function()
			control(mc, verb)
		end)
		item:subscribe("mouse.entered", function()
			item:set({ background = { drawing = true, color = LOOK.with_alpha(COLORS.text_color, 0x1A) } })
		end)
		item:subscribe("mouse.exited", function()
			item:set({ background = { drawing = false } })
		end)
		buttons[name] = item
		return item
	end
	button("prev", "󰒮", 18, 24, "previous-track", "previous track")
	local play = button("play", "󰐊", 24, 30, "toggle-play-pause", "playpause")
	button("next", "󰒭", 18, 24, "next-track", "next track")
	-- Play / pause turns accent while paused, as a "resume" cue.
	local is_playing = false
	local function paint_play()
		play:set({
			icon = {
				string = is_playing and "󰏤" or "󰐊",
				color = is_playing and COLORS.text_color or COLORS.accent_color,
			},
		})
	end
	buttons.next:set({ padding_right = inset })

	-- last_track: the playing track. cover_track: the track whose art
	-- is on screen. Spotify often publishes the art a moment after the
	-- track, so cover_track lags and the read is retried until it
	-- catches up.
	local last_track, cover_track = nil, nil
	-- Two cover files in turn: a new path makes sketchybar load the
	-- image again instead of drawing the one it cached for the path.
	local cover_slot = 0

	-- Shortens the artist, not the whole line, so the time always
	-- shows. Cuts on a UTF-8 character boundary.
	local function cut(text, max)
		if (utf8.len(text) or #text) <= max then
			return text
		end
		local at = utf8.offset(text, max)
		return at and (text:sub(1, at - 1) .. "…") or text
	end

	local function clock(seconds)
		seconds = math.max(0, math.floor(seconds or 0))
		return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
	end

	-- Reads media-control once: the fields, and (while the art on
	-- screen is not this track's) the cover, decoded and shrunk to
	-- cover_px.
	local function refresh()
		local cover_path = cover_base .. (1 - cover_slot) .. ".jpg"
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
    subprocess.run(["sips", "-Z", sys.argv[3], sys.argv[2]], capture_output=True)
    print("newcover")' ']==] .. (cover_track or "") .. "' '" .. cover_path .. "' " .. cover_px, function(result)
			local lines = {}
			for line in (result .. "\n"):gmatch("([^\n]*)\n") do
				table.insert(lines, line)
			end
			if lines[1] ~= "ok" then
				last_track = nil
				title:set({ label = { string = "Nothing playing in Spotify" } })
				sub:set({ label = { string = "" } })
				progress:set({ slider = { percentage = 0 } })
				return
			end
			local track, playing = lines[2], lines[3] == "1"
			title:set({ label = { string = lines[6] } })
			sub:set({
				label = { string = cut(lines[7], 10) .. " · " .. clock(lines[4]) .. " / " .. clock(lines[5]) },
			})
			local length = tonumber(lines[5]) or 0
			progress:set({
				slider = { percentage = length > 0 and math.floor(100 * (tonumber(lines[4]) or 0) / length) or 0 },
			})
			is_playing = playing
			paint_play()
			-- A new track without art (yet) shows the placeholder.
			if lines[8] == "newcover" then
				cover_slot = 1 - cover_slot
				cover_track = track
				cover:set({ background = { image = { string = cover_path } } })
			elseif track ~= last_track and track ~= cover_track then
				cover:set({ background = { image = { string = placeholder } } })
			end
			last_track = track
		end)
	end

	-- Ticks every second: while open it moves the time; while closed
	-- it re-reads every 2 s, and only while the playing track's art
	-- has not arrived yet.
	local is_open = false
	local closed_tick = 0
	title:set({ update_freq = 1 })
	title:subscribe("routine", function()
		if is_open then
			refresh()
			return
		end
		closed_tick = closed_tick + 1
		if closed_tick % 2 == 0 and last_track and cover_track ~= last_track then
			refresh()
		end
	end)

	local function set_open(open)
		is_open = open
		anchor:set({ popup = { drawing = open } })
		if open then
			refresh()
			read_volume()
		end
	end
	anchor:subscribe("mouse.exited.global", function()
		set_open(false)
	end)
	refresh()

	THEME.on_change(function()
		title:set({ label = { color = COLORS.text_color } })
		sub:set({ label = { color = COLORS.disabled_color } })
		for _, item in pairs(buttons) do
			item:set({ icon = { color = COLORS.text_color } })
		end
		paint_play()
		speaker:set({ icon = { color = COLORS.disabled_color } })
		progress:set({ slider = { highlight_color = COLORS.accent_color } })
		cover:set({ background = { border_color = COLORS.accent_color } })
		volume:set({
			slider = {
				highlight_color = COLORS.accent_color,
				background = { color = LOOK.with_alpha(COLORS.disabled_color, 0x40) },
			},
		})
	end)

	return {
		toggle = function()
			set_open(not is_open)
		end,
		-- Called by the anchor on a track or play-state change and on
		-- its 10 s re-read (which catches Spotify Connect), even while
		-- closed, so the cover is ready before the popup opens.
		refresh = refresh,
	}
end
