#!/usr/bin/env bash

set -euo pipefail

REPO="Geyvra/GevyraCLI"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="gevyra"

echo "Installing Gevyra CLI..."

# Check required commands
for command in curl uname; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Error: '$command' is required."
        exit 1
    fi
done

# Detect architecture
ARCH="$(uname -m)"

case "$ARCH" in
    x86_64)
        ASSET="Gevyra-linux-amd64"
        ;;
    aarch64|arm64)
        ASSET="Gevyra-linux-arm64"
        ;;
    *)
        echo "Error: unsupported architecture: $ARCH"
        exit 1
        ;;
esac

DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/${ASSET}"

echo "Detected architecture: $ARCH"
echo "Downloading Gevyra CLI..."

# Create temporary file
TMP_FILE="$(mktemp)"

cleanup() {
    rm -f "$TMP_FILE"
}

trap cleanup EXIT

curl -fL --progress-bar "$DOWNLOAD_URL" -o "$TMP_FILE"

# Check installation directory
if [ ! -d "$INSTALL_DIR" ]; then
    sudo mkdir -p "$INSTALL_DIR"
fi

# Install binary
sudo install -m 755 "$TMP_FILE" "$INSTALL_DIR/$BINARY_NAME"

echo ""
echo "✓ Gevyra CLI installed successfully."
echo ""
echo "Run:"
echo "  gevyra --help"
echo ""

# Verify installation
if command -v "$BINARY_NAME" >/dev/null 2>&1; then
    echo "Version:"
    "$BINARY_NAME" --version 2>/dev/null || true
else
    echo "Note: '$INSTALL_DIR' may not be in your PATH."
    echo "You can run: $INSTALL_DIR/$BINARY_NAME"
fi