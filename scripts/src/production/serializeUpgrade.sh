#!/bin/bash

# Try to locate the Sui binary dynamically
SUI_BIN_PATH="./sui"

active_address=$("${SUI_BIN_PATH}" client active-address)
echo "Active Sui address: ${active_address}" 

if [[ ! -x "${SUI_BIN_PATH}" ]]; then
    # If not in the current directory, check common paths
    if command -v sui &> /dev/null; then
        SUI_BIN_PATH=$(command -v sui)
    elif [[ -x "/usr/local/bin/sui" ]]; then
        SUI_BIN_PATH="/usr/local/bin/sui"
    else
        echo "Error: Sui binary not found. Please check your workflow or local setup." >&2
        exit 1
    fi
fi

# Define paths for the Move files and output
BASE_DIR=$(pwd)
MOVE_PATH="$BASE_DIR/../../../memefi_coin"
TX_OUTPUT_DIR="$BASE_DIR/../../tx"
TX_OUTPUT_FILE="${TX_OUTPUT_DIR}/upgrade-tx-data.txt"

# Create the output directory and file if they don't exist
mkdir -p "$TX_OUTPUT_DIR"
touch "$TX_OUTPUT_FILE"

upgrade_res=$("${SUI_BIN_PATH}" client upgrade \
    --upgrade-capability "$UPGRADE_CAP" \
    --serialize-unsigned-transaction "$MOVE_PATH" )

# Process the result and save to the output file
echo "${upgrade_res}" | sed 's/Raw tx_bytes to execute: //g' > "$TX_OUTPUT_FILE"