#!/usr/bin/env bash
# not all global variables are forwarded, without exporting utf-8
# one get Warning: Malformed UTF-8 string
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Usage: clipboard_sketchybar.sh <storage_dir> <max_items>
STORAGE_DIR="${1:-$HOME/.config/sketchybar/data}"
MAX_ITEMS="${2:-5}"
CLIPBOARD_FILE="$STORAGE_DIR/.clipboard_storage.json"
PYTHON_SCRIPT="$HOME/.config/sketchybar/plugins/clipboard_json.py"
EMPTY_CLIPBOARD_MESSAGE="nothing has been copied"
mkdir -p "$STORAGE_DIR"
touch "$CLIPBOARD_FILE"

# Handle mouse events for popup
case "$SENDER" in
  "mouse.entered")
    sketchybar --set "$NAME" popup.drawing=on
    exit 0
    ;;
  "mouse.exited"|"mouse.exited.global")
    sketchybar --set "$NAME" popup.drawing=off
    exit 0
    ;;
esac

# Call Python to update clipboard file if needed
python3 "$PYTHON_SCRIPT" "$CLIPBOARD_FILE" "$MAX_ITEMS"
clipboardHasChanged=$?

# Query the item and check if it exists
query_output=$(sketchybar --query clipboard.popup.0 2>&1)
item_exists=true

if echo "$query_output" | grep -q "item 'clipboard.popup.0' not found"; then
  item_exists=false
  echo "No clipboard popup exists, initializing clipboard-popups"
fi

if ! $item_exists || [[ $clipboardHasChanged -eq 0 ]]; then
  # Remove old items
  for ((i=0; i<MAX_ITEMS; i++)); do
    sketchybar --remove "clipboard.popup.$i" 2>/dev/null
  done

  # Read clipboard items
  clipboard_items=()
  while IFS= read -r -d '' line; do
    clipboard_items+=("$line")
  done < <(python3 "$PYTHON_SCRIPT" "$CLIPBOARD_FILE" "$MAX_ITEMS" --print)

  if [[ ${#clipboard_items[@]} -eq 0 ]]; then
    sketchybar --add item clipboard.popup.0 popup.clipboard \
      --set clipboard.popup.0 \
      icon="Clipboard:" \
      label="$EMPTY_CLIPBOARD_MESSAGE"
  else
    for i in "${!clipboard_items[@]}"; do
      c="${clipboard_items[$i]}"
      display_label=$(echo "$c" | tr '\n' '⏎' | sed 's/⏎$//' | cut -c1-120)
      printf -v safely_quoted_c '%q' "$c"
      full_click_script="printf '%s' ${safely_quoted_c} | pbcopy; sketchybar --set \"$NAME\" popup.drawing=off"

      sketchybar --add item clipboard.popup."$i" popup.clipboard \
        --set clipboard.popup."$i" \
        icon="􀊄" \
        icon.font="Hack Nerd Font:Bold:12.0" \
        label="$display_label" \
        click_script="$full_click_script" \
        drawing=on \
        label.width=120 \
        background.corner_radius=12 \
        background.padding_left=12 \
        background.padding_right=12 \
        background.drawing=off
    done
  fi
else
  echo "Popup exists and clipboard unchanged — no update needed."
fi
