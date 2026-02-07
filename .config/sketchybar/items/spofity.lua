local config_dir = os.getenv("CONFIG_DIR")
local album_placeholder = config_dir .. "/data/album_placeholder.jpg"
SBAR.add("event", "spotify_change", "com.spotify.client.PlaybackStateChanged")
-- -----------------------------------------------------------------------------
-- INTERNAL CONFIG (No external requires needed!)
-- -----------------------------------------------------------------------------

local popup_width = 200

-- -----------------------------------------------------------------------------
-- 1. BAR ITEM (The Anchor)
-- -----------------------------------------------------------------------------
local spotify_anchor = SBAR.add("item", "spotify.anchor", {
	position = "right",
	icon = {
		string = "",
	},
	label = { drawing = false },
	popup = {
		align = "center",
		width = popup_width,
		background = {},
	},
})

-- -----------------------------------------------------------------------------
-- 2. POPUP: COVER ART
-- -----------------------------------------------------------------------------
local cover = SBAR.add("item", {
	position = "popup." .. spotify_anchor.name,
	icon = { drawing = false },
	label = { drawing = false },
	background = {
		image = {
			string = "/tmp/spotify_cover.jpg",
			scale = 0.15,
			drawing = true,
			y_offset = -5,
		},
		padding_left = popup_width / 4,
		padding_right = popup_width / 4,
		color = COLORS.transparent,
	},
	align = "center",
})

-- -----------------------------------------------------------------------------
-- 3. POPUP: TEXT INFO
-- -----------------------------------------------------------------------------
local title = SBAR.add("item", {
	position = "popup." .. spotify_anchor.name,
	icon = { drawing = false },
	label = {
		string = "Waiting...",
		width = popup_width,
		align = "center",
	},
})

local artist = SBAR.add("item", {
	position = "popup." .. spotify_anchor.name,
	icon = { drawing = false },
	label = {
		string = "",
		font = { size = 13 },
		width = popup_width,
		align = "center",
	},
})

local album = SBAR.add("item", {
	position = "popup." .. spotify_anchor.name,
	icon = { drawing = false },
	label = {
		string = "",
		font = { size = 11 },
		width = popup_width,
		align = "center",
	},
})

-- -----------------------------------------------------------------------------
-- 4. LOGIC
-- -----------------------------------------------------------------------------

local function update_state()
	-- Use lowercase sbar unless you've aliased it
	SBAR.exec(
		[[osascript -e '
        if application "Spotify" is running then
            tell application "Spotify"
                set t to name of current track
                set a to artist of current track
                set al to album of current track
                set u to artwork url of current track
                return t & "|" & a & "|" & al & "|" & u
            end tell
        else
            return "stopped"
        end' | tr -d '\n']],
		function(result) -- added tr to clean newlines
			if result == "stopped" or result == "" or result == nil then
				spotify_anchor:set({ drawing = false })
				return
			end

			-- Improved Lua splitting logic
			local fields = {}
			for field in string.gmatch(result, "([^|]*)") do
				table.insert(fields, field)
			end

			local t, a, al, u = fields[1], fields[2], fields[3], fields[4]
			if not t or t == "" then
				return
			end

			-- Update Content
			spotify_anchor:set({ drawing = true })
			title:set({ label = { string = t } }) -- ensure label is a table if using helper
			artist:set({ label = { string = a } })
			album:set({ label = { string = al } })

			-- Update Image
			if u and u ~= "" then
				SBAR.exec("curl -s -L --max-time 3 '" .. u .. "' -o /tmp/spotify_cover.jpg", function()
					cover:set({ background = { image = { string = "/tmp/spotify_cover.jpg" } } })
				end)
			else
				cover.set({ background = { image = { string = album_placeholder } } })
			end
		end
	)
end

-- -----------------------------------------------------------------------------
-- 6. DYNAMIC UPDATING
-- -----------------------------------------------------------------------------

-- 1. When mouse enters: Update immediately, then start 1-second polling
spotify_anchor:subscribe("mouse.entered", function()
	update_state()
	spotify_anchor:set({
		popup = { drawing = true },
		update_freq = 1, -- Poll every second while hovering
	})
end)

-- 2. When mouse leaves: Stop polling and hide popup
spotify_anchor:subscribe("mouse.exited.global", function()
	spotify_anchor:set({
		popup = { drawing = false },
		update_freq = 0, -- Stop polling to save CPU
	})
end)

-- 3. The "Routine" event is what triggers based on update_freq
spotify_anchor:subscribe("spotify_change", update_state)

-- 4. Initial check on load
update_state()
