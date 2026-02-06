#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Forward Clipboard Text + Input to ChatGPT
# @raycast.mode compact

# Optional parameters:
# @raycast.icon icons/gpt.png
# @raycast.argument1 { "type": "text", "placeholder": "Add Query..." }

# Read copied selection (assumes user pressed Cmd+C before running)
selected_text=$(pbpaste)
user_input="$1"

# Combine content with two line breaks
final_content="${user_input}

${selected_text}"

# URL encode the combined text
url_encoded=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.stdin.read()))" <<< "$final_content")

# Open ChatGPT in Zen with prefilled prompt
open -a Zen "https://chatgpt.com?hint=search&q=${url_encoded}"
