#!/bin/bash

list_inputs() {
    jack_lsp -p | awk '
    /^[^[:space:]]/ {port=$0}
    /properties: input/ {print port}
    '
}

list_outputs() {
    jack_lsp -p | awk '
    /^[^[:space:]]/ {port=$0}
    /properties: output/ {print port}
    '
}


PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEQUENCER_FILE="$PROJECT_DIR/sequencer/sequencer.qtr"
AMPS_DIR="$PROJECT_DIR/amps"
RACKS_DIR="$PROJECT_DIR/racks"


echo "Launching Jack control..."
qjackctl &

echo "Launching Qtractor..."
qtractor "$SEQUENCER_FILE" &

echo "Waiting for Qtractor guitar buses to appear..."

until jack_lsp -p | awk '
BEGIN {IGNORECASE=1}
/^[^[:space:]]/ {port=$0}
/properties: input/ && port ~ /qtractor/ && port ~ /guitar/ {found=1}
END {exit !found}
'; do
    sleep 0.5
done

echo "Qtractor guitar buses detected."

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

echo "Waiting for calf studio gear to appear..."

until jack_lsp -p | awk '
BEGIN {IGNORECASE=1}
/^[^[:space:]]/ {port=$0}
/properties: input/ && port ~ /calf/ && port ~ /studio/ {found=1}
END {exit !found}
'; do
    sleep 0.5
done

echo "Launching QSynth..."
qsynth &

echo "All tools launched. JACK connections not yet made."

echo "Loading hardware config..."
source interfaces.conf

echo "Connecting guitar interface to qtractor..."
jack_lsp -p |
awk '
BEGIN {IGNORECASE=1}
/^[^[:space:]]/ {port=$0}
/properties: input/ && port ~ /qtractor/ && port ~ /guitar/ {print port}
' |
while IFS= read -r PORT; do
    echo "Connecting $GUITAR_PORT → $PORT"
    jack_connect "$GUITAR_PORT" "$PORT"
done

echo "Connecting Qtractor mono outputs to headphones..."
jack_lsp -p |
awk '
BEGIN {IGNORECASE=1}
/^[^[:space:]]/ {port=$0}
/properties: output/ && port ~ /qtractor/ && port ~ /guitar/ {print port}
' |
while IFS= read -r PORT; do
    echo "Connecting $PORT → $HP_L"
    jack_connect "$PORT" "$HP_L"
    echo "Connecting $PORT → $HP_R"
    jack_connect "$PORT" "$HP_R"
done

jack_lsp -p |
awk '
BEGIN {IGNORECASE=1}
/^[^[:space:]]/ {port=$0}
/properties: output/ && port ~ /qtractor/ && port ~ /vocal/ {print port}
' |
while IFS= read -r PORT; do
    echo "Connecting $PORT → $HP_L"
    jack_connect "$PORT" "$HP_L"
    echo "Connecting $PORT → $HP_R"
    jack_connect "$PORT" "$HP_R"
done


jack_lsp -p |
awk '
BEGIN {IGNORECASE=1}
/^[^[:space:]]/ {port=$0}
/properties: output/ && port ~ /qtractor/ && port ~ /synth/ {print port}
' |
while IFS= read -r PORT; do
    echo "Connecting $PORT → $HP_L"
    jack_connect "$PORT" "$HP_L"
    echo "Connecting $PORT → $HP_R"
    jack_connect "$PORT" "$HP_R"
done

# TODO
echo "TODO connect qtractor and qsynth outputs to monitoring headphones programmatically"

echo "Connecting microphone to Qtractor vocal bus..."

VOCAL_PORT=$(jack_lsp -p | awk '
BEGIN {IGNORECASE=1}
/^[^[:space:]]/ {port=$0}
/properties: input/ && port ~ /qtractor/ && port ~ /vocal/ {print port; exit}
')

if [ -z "$VOCAL_PORT" ]; then
    echo "Error: No Qtractor input port found with 'vocal' in the name."
    exit 1
fi

if ! jack_lsp -c | grep -q "$MIC_PORT.*$VOCAL_PORT"; then
    echo "Connecting $MIC_PORT → $VOCAL_PORT"
    jack_connect "$MIC_PORT" "$VOCAL_PORT"
else
    echo "Connection already exists: $MIC_PORT → $VOCAL_PORT"
fi

echo "Wiring up rack..."
python scripts/wire-calf.py

echo "Done."



