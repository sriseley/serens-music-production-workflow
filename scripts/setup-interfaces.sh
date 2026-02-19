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

select_port() {
    prompt="$1"
    ports="$2"

    echo "$ports" | fzf --prompt="$prompt > "
}

echo "Saving port config..."
cat > "$PROJECT_DIR/interfaces.conf" <<EOF
GUITAR_PORT="$GUITAR_PORT"
MIC_PORT="$MIC_PORT"
HP_L="$HP_L"
HP_R="$HP_R"
EOF
