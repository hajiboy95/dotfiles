#!/usr/bin/env bash

## ─────────────────────────────────────────────────────────────────────────────
## Displays the Keyboard Layout Input Source.
## ─────────────────────────────────────────────────────────────────────────────
_SSDF_SB_INPUT_SOURCE=$(defaults read com.apple.HIToolbox AppleCurrentKeyboardLayoutInputSourceID)
case "${_SSDF_SB_INPUT_SOURCE}" in
  "com.apple.keylayout.ABC") _SSDF_SB_KEYBOARD_LAYOUT="EN"            ;;   # US English
  "com.apple.inputmethod.Kotoeri.Japanese") _SSDF_SB_KEYBOARD_LAYOUT="JP" ;; # Japanese
  "com.apple.keylayout.German") _SSDF_SB_KEYBOARD_LAYOUT="DE"        ;;   # German
  *) _SSDF_SB_KEYBOARD_LAYOUT="??"                                   ;;   # Default to ?? for unkown
esac

sketchybar --set "$NAME" label="${_SSDF_SB_KEYBOARD_LAYOUT}"
