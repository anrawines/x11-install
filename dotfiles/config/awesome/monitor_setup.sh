#!/bin/bash

# Define monitor names from xrandr
INTERNAL="eDP"
EXTERNAL="HDMI-A-0"

# Check if external monitor is connected
if xrandr | grep -q "$EXTERNAL connected"; then
    # External connected: Use ONLY external
    xrandr --output "$INTERNAL" --off --output "$EXTERNAL" --auto --primary
else
    # External disconnected: Use ONLY internal
    xrandr --output "$EXTERNAL" --off --output "$INTERNAL" --auto --primary
fi

# Optional: Refresh wallpaper or restart awesome if needed
# echo 'awesome.restart()' | awesome-client
