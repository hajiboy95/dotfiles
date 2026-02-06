#!/usr/bin/env bash

volume_slider=(
  script="$PLUGIN_DIR/volume.sh"
  updates=on
  label.drawing=off
  icon.drawing=off
  slider.highlight_color="$ACCENT_COLOR"
  slider.background.height=5
  slider.background.corner_radius=3
  slider.background.color="$BACKGROUND"
  slider.knob=􀀁
  slider.knob.drawing=off
)

volume_icon=(
  click_script="$PLUGIN_DIR/volume_click.sh"
  padding_left=0
  padding_right=0
  icon="$VOLUME_100"
  icon.width=0
  icon.align=left
  label.align=left
)

sketchybar --add slider volume right            \
           --set volume "${volume_slider[@]}"   \
           --subscribe volume volume_change     \
                              mouse.clicked     \
                              mouse.entered     \
                              mouse.exited      \
                                                \
           --add item volume_icon right         \
           --set volume_icon "${volume_icon[@]}"
