#!/usr/bin/env bash

WIDTH=100

detail_on() {
  sketchybar --animate tanh 30 --set volume slider.width=$WIDTH
}

detail_off() {
  sketchybar --animate tanh 30 --set volume slider.width=0
}

toggle_detail() {
  INITIAL_WIDTH=$(sketchybar --query volume | jq -r ".slider.width")
  if [ "$INITIAL_WIDTH" -eq "0" ]; then
    detail_on
  else
    detail_off
  fi
}

toggle_devices() {
  which SwitchAudioSource >/dev/null || exit 0
  # shellcheck disable=SC1091
  source "$HOME/.config/sketchybar/colors.sh"

  args=(--remove '/volume.device\.*/' --set "$NAME" popup.drawing=toggle)
  COUNTER=0

  CURRENT="$(SwitchAudioSource -t output -c)"
  DEVICE_LIST="$(SwitchAudioSource -a -t output)"

  # If current device (e.g., AirPlay) is not in the list, prepend it
  if ! grep -Fxq "$CURRENT" <<< "$DEVICE_LIST"; then
    DEVICE_LIST="$CURRENT"$'\n'"$DEVICE_LIST"
  fi

  while IFS= read -r device; do
    COLOR="$DISABLED_COLOR"
    if [ "${device}" = "$CURRENT" ]; then
      COLOR="$ACCENT_COLOR"
    fi

    args+=(--add item volume.device."$COUNTER" popup."$NAME" \
           --set volume.device."$COUNTER" \
                 label="${device}" \
                 label.color="$COLOR" \
                 click_script="SwitchAudioSource -s \"${device}\" && sketchybar --set /volume.device\\.*/ label.color=$DISABLED_COLOR --set \$NAME label.color=$ACCENT_COLOR --set $NAME popup.drawing=off")
    COUNTER=$((COUNTER+1))
  done <<< "$DEVICE_LIST"

  sketchybar -m "${args[@]}" > /dev/null
}


if [ "$BUTTON" = "right" ] || [ "$MODIFIER" = "shift" ]; then
  toggle_devices
else
  toggle_detail
fi
