#!/bin/bash

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEQUENCER_FILE="$PROJECT_DIR/sequencer/sequencer.qtr"
AMPS_DIR="$PROJECT_DIR/amps"
RACKS_DIR="$PROJECT_DIR/racks"


echo "Launching Jack control..."
qjackctl &

echo "Launching Qtractor..."
qtractor "$SEQUENCER_FILE" &

echo "Launching Guitarix (amp sim)..."
if [[ -d "$AMPS_DIR" ]]; then
    for AMP_FILE in "$AMPS_DIR"/*; do
        [[ -f "$AMP_FILE" ]] || continue
        echo "Launching Guitarix for $(basename "$AMP_FILE")..."
        guitarix -f "$AMP_FILE" &
    done
fi
echo "Launching Calfjackhost (effects rack)..."
if [[ -d "$RACKS_DIR" ]]; then
    for RACK_FILE in "$RACKS_DIR"/*; do
        [[ -f "$RACK_FILE" ]] || continue
        echo "Launching Calfjackhost for $(basename "$RACK_FILE")..."
        calfjackhost -l "$RACK_FILE" &
    done
fi

echo "Launching QSynth..."
qsynth &

echo "All tools launched. JACK connections not yet made."

echo "Loading hardware config..."
source interfaces.conf
