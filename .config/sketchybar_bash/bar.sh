#!/usr/bin/env bash

bar=(
  position=top
  height=32
  # margin=12
  # y_offset=10
  # corner_radius=16
  blur_radius=10
  color="$BAR_COLOR"
)

sketchybar --bar "${bar[@]}"
