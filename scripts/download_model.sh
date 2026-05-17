#!/bin/bash
# Download Gemma 4 E2B model for Gemma-SOS (2.46 GB)
# Usage: bash scripts/download_model.sh
#
# The model is from litert-community on Hugging Face:
# https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm
#
# Gemma 4 requires .litertlm format (NOT .task format).
# The .task file in assets/models/ is for older Gemma3n models.

MODEL_DIR="assets/models"
MODEL_FILE="gemma-4-E2B-it.litertlm"
MODEL_URL="https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm"

echo "[*] Downloading Gemma 4 E2B model (2.46 GB)..."
echo "[*] Source: $MODEL_URL"
echo ""

# Create directory if needed
mkdir -p "$MODEL_DIR"

# Download with progress
if command -v curl &> /dev/null; then
    echo "[*] Using curl..."
    curl -L -o "$MODEL_DIR/$MODEL_FILE" "$MODEL_URL" --progress-bar
elif command -v wget &> /dev/null; then
    echo "[*] Using wget..."
    wget -O "$MODEL_DIR/$MODEL_FILE" "$MODEL_URL" --progress=bar:force
else
    echo "[!] Neither curl nor wget found. Install one and retry."
    exit 1
fi

# Verify
if [ -f "$MODEL_DIR/$MODEL_FILE" ]; then
    SIZE=$(du -h "$MODEL_DIR/$MODEL_FILE" | cut -f1)
    echo "[+] Model downloaded: $MODEL_DIR/$MODEL_FILE ($SIZE)"
else
    echo "[!] Download failed."
    exit 1
fi

echo ""
echo "To push to Android device via ADB:"
echo "  adb push $MODEL_DIR/$MODEL_FILE /sdcard/Download/"
echo ""
echo "Or keep in assets/ for automatic loading."
