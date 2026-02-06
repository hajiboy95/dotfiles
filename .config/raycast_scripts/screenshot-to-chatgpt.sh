#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Screenshot to ChatGPT
# @raycast.mode compact

# Optional parameters:
# @raycast.icon icons/gpt.png

# Documentation:
# @raycast.description Take a screenshot and open ChatGPT to paste it.

# Create temp file path for screenshot
TMPFILE=$(mktemp /tmp/screenshot_XXXXXX.png)

# Take interactive screenshot with no sound and save to temp file
screencapture -ix "$TMPFILE"

# Check if file exists and is non-empty (user didn't cancel)
if [ -s "$TMPFILE" ]; then
  # Optionally copy it to clipboard (if you want)
  # pbcopy < "$TMPFILE"  # For images this may not work properly

  # Open Zen with ChatGPT URL
  open -a Zen "https://chatgpt.com?hint=search&q=" &

  echo "Screenshot saved to $TMPFILE. Paste it into ChatGPT."

  # Cleanup: remove the temp screenshot if you want
  rm "$TMPFILE"

  exit 0
else
  echo "Screenshot cancelled or no file created."
  rm -f "$TMPFILE"
  exit 1
fi
