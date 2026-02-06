#!/usr/bin/env bash

sketchybar --add item timer right \
           --set timer icon=􀐱   \
                       label.padding_left=0 \
                       label.padding_right=0 \
                       script="$PLUGIN_DIR/pomodoro_timer.sh" \
                       --subscribe timer mouse.clicked mouse.entered mouse.exited mouse.exited.global

for timer in "5" "10" "25"; do
sketchybar --add item "timer.${timer}" popup.timer \
           --set "timer.${timer}" \
                   label="${timer} Minutes" \
                   icon.padding_left=0 \
                   icon.padding_right=0 \
                   padding_left=8 \
                   padding_right=8 \
                   click_script="$PLUGIN_DIR/pomodoro_timer.sh $((timer * 60)); sketchybar -m --set timer popup.drawing=off"
done
