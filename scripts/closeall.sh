#!/usr/bin/env bash

APPS=(
    "qsynth"
    "qtractor"
    "guitarix"
    "calfjackhost"
)

echo "Closing audio applications..."

for APP in "${APPS[@]}"; do
    if pgrep -x "$APP" > /dev/null; then
        echo "Stopping $APP..."
        pkill -TERM -x "$APP"
    else
        echo "$APP not running."
    fi
done

sleep 2

for APP in "${APPS[@]}"; do
    if pgrep -x "$APP" > /dev/null; then
        echo "Force killing $APP..."
        pkill -KILL -x "$APP"
    fi
done

echo "Done."
