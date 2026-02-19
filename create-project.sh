#!/bin/bash

create_tab() {
    local TEMPLATE_NAME="$1"
    local OUTPUT_NAME="$2"

    local TAB_TEMPLATE_FOLDER="$TEMPLATES/$TEMPLATE_NAME"
    local TAB_COPY="$PROJECT_DIR/$(basename "$TAB_TEMPLATE_FOLDER")"

    cp -r "$TAB_TEMPLATE_FOLDER" "$TAB_COPY"

    local CONTENT_XML="$TAB_COPY/content.xml"
    if [[ -f "$CONTENT_XML" ]]; then
        sed -i "s|\$BPM|$BPM|g" "$CONTENT_XML"
    else
        echo "Error: content.xml not found in $TAB_COPY"
        exit 1
    fi

    zip -r "$PROJECT_DIR/$OUTPUT_NAME" -j "$TAB_COPY"/* >/dev/null 2>&1
    rm -rf "$TAB_COPY"
}

PREPOP="$HOME/Music/"
TEMPLATES="templates"
TAB_GUITAR_NAME="guitar.tg"
TAB_BASS_NAME=""

read -e -i "$PREPOP" -p "Enter the project directory: " PROJECT_DIR
read -rp "Enter the project tempo (BPM): " BPM

mkdir -p "$PROJECT_DIR"

echo "Creating sequencer (qtractor) file with default instruments..."

SEQUENCER_TEMPLATE_FILE="$TEMPLATES/sequencer.qtr"
SEQUENCER_FOLDER="$PROJECT_DIR/sequencer"
mkdir -p "$SEQUENCER_FOLDER"
DEST_SEQUENCER_FILE="$SEQUENCER_FOLDER/sequencer.qtr"
cp "$SEQUENCER_TEMPLATE_FILE" "$DEST_SEQUENCER_FILE"

sed -i "s|\$DIRECTORY|$SEQUENCER_FOLDER|g" "$DEST_SEQUENCER_FILE"
sed -i "s|\$BPM|$BPM|g" "$DEST_SEQUENCER_FILE"

echo "Creating default guitar (drop D) and bass tablature..."

create_tab "guitar_tab" "guitar.tg"
create_tab "bass_tab" "bass.tg"

echo "Project created in '$PROJECT_DIR' with tempo $BPM BPM."
