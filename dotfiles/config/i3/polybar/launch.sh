#!/usr/bin/env bash

# This gets the directory where the ACTUAL script sits, even if called from elsewhere
DIR="$(dirname "$(readlink -f "$0")")"

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch the bar using the absolute path to the config
polybar -q main -c "$DIR/config.ini" >/dev/null 2>&1 &
