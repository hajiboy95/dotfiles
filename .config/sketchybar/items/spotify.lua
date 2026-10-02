-- ==========================================================
-- SPOTIFY INDICATOR (Inline)
-- ==========================================================
-- Driven by Spotify's own PlaybackStateChanged notification, whose
-- payload already carries the state, title and artist, so a change
-- costs no AppleScript round trip. AppleScript runs only for the
-- initial read and for clicks, and never while Spotify is closed
-- (a `tell` to a closed app can launch it).

local max_chars = 30 -- Truncate the "title - artist" label past this

local app_icon = require("helpers.app_font")
local logo = app_icon(":spotify:", "\u{f1bc}", DEFAULT_ITEM.icon.font.size * 1.2)

local spotify_anchor = SBAR.add("item", "spotify", {
	position = "right",
	update_freq = 10, -- notices a quit Spotify (no event for that)
	icon = {
		font = logo.font or { size = DEFAULT_ITEM.icon.font.size * 1.2 },
		string = logo.string,
		color = COLORS.disabled_color,
	},
	label = { string = "Spotify", y_offset = 0, font = LOOK.word_font() },
})
THEME.track_word(spotify_anchor)

-- Its own pill, like the other groups.
SBAR.add("bracket", "spotify.bracket", { spotify_anchor.name }, {
	background = { drawing = true },
})

-- Cuts on a UTF-8 character boundary, so an umlaut or emoji is never
-- split into garbage.
local function truncate(text)
	if (utf8.len(text) or #text) <= max_chars then
		return text
	end
	local cut = utf8.offset(text, max_chars + 1)
	return cut and (text:sub(1, cut - 1) .. "…") or text
end

-- state: "Playing" | "Paused" | anything else is idle: the logo
-- alone, dimmed, and a click opens Spotify.
local last = {}
local function render(state, title, artist)
	last = { state, title, artist }
	if state ~= "Playing" and state ~= "Paused" then
		spotify_anchor:set({
			label = { drawing = false },
			icon = {
				string = logo.string,
				color = COLORS.disabled_color,
				padding_right = DEFAULT_ITEM.icon.padding_left,
			},
		})
		return
	end
	local text = (title and title ~= "") and title or "Spotify"
	if artist and artist ~= "" then
		text = text .. " - " .. artist
	end
	local playing = state == "Playing"
	spotify_anchor:set({
		label = {
			drawing = true,
			string = truncate(text),
			-- Accent = "the active thing", as in KiwiDesk's Space Bar;
			-- plain information elsewhere stays text_color.
			color = playing and COLORS.accent_color or COLORS.disabled_color,
		},
		icon = {
			string = logo.string,
			color = playing and COLORS.accent_color or COLORS.disabled_color,
			padding_right = DEFAULT_ITEM.icon.padding_right,
		},
	})
end

-- Reads the player once: media-control (macOS Now Playing, needs no
-- Automation permission) when Spotify is the now-playing source; a
-- running Spotify that is not counts as paused with no title.
local function read_player()
	SBAR.exec(
		[[if ! pgrep -xq Spotify; then echo Stopped; exit; fi
		media-control get 2>/dev/null | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin) or {}
except Exception:
    d = {}
if d.get("bundleIdentifier") == "com.spotify.client":
    state = "Playing" if d.get("playing") else "Paused"
    print(state); print(d.get("title", "")); print(d.get("artist", ""))
else:
    print("Paused")']],
		function(result)
			local state, title, artist = result:match("^([^\n]*)\n?([^\n]*)\n?([^\n]*)")
			render(state, title, artist)
		end
	)
end

SBAR.add("event", "spotify_change", "com.spotify.client.PlaybackStateChanged")
spotify_anchor:subscribe("spotify_change", function(env)
	local info = env.INFO
	if type(info) == "table" and info["Player State"] then
		render(info["Player State"], info["Name"], info["Artist"])
	else
		read_player() -- Payload not parsed: ask instead.
	end
end)

-- A Spotify command: through media-control while Spotify is the
-- now-playing source (no permission needed), otherwise Spotify's own
-- AppleScript, so it never acts on another app's media. Spotify closed:
-- it opens Spotify.
local function control(mc, verb)
	SBAR.exec(
		"if ! pgrep -xq Spotify; then open -a Spotify; "
			.. "elif media-control get 2>/dev/null | grep -q '\"com.spotify.client\"'; then media-control "
			.. mc
			.. '; else osascript -e \'tell application "Spotify" to '
			.. verb
			.. "'; fi"
	)
end

-- Left click: play/pause. Right click: the mini player (cover, time,
-- previous / play-pause / next).
local player = require("items.spotify_popup")(spotify_anchor, control)
spotify_anchor:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "right" then
		player.toggle()
	else
		control("toggle-play-pause", "playpause")
	end
end)

-- Quitting Spotify posts no change on every version, so a cheap
-- pgrep every 10 s (and on wake) turns the item back to idle.
spotify_anchor:subscribe({ "routine", "system_woke" }, function()
	SBAR.exec("pgrep -xq Spotify || echo closed", function(result)
		if result:find("closed") then
			render("Stopped")
		end
	end)
end)

read_player()

THEME.on_change(function()
	render(last[1], last[2], last[3])
end)
