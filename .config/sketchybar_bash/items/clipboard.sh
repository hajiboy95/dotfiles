#!/usr/bin/env bash
sketchybar --add item clipboard right \
           --set clipboard script="$PLUGIN_DIR/clipboard.sh"\
                        updates=on \
                        update_freq=1 \
                        icon=􁕜
sketchybar --subscribe clipboard mouse.entered mouse.exited mouse.exited.global
