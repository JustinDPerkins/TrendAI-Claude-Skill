#!/bin/bash
# TrendAI TMAS Installer
# Downloads and installs the TMAS CLI for the current platform

set -e

INSTALL_DIR="${TMAS_INSTALL_DIR:-$HOME/.local/bin}"

# Detect platform and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Map architecture names
case "$ARCH" in
    x86_64|amd64)
        ARCH="x86_64"
        ;;
    arm64|aarch64)
        ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Map OS names
case "$OS" in
    darwin)
        OS_NAME="Darwin"
        EXT="zip"
        ;;
    linux)
        OS_NAME="Linux"
        EXT="tar.gz"
        ;;
    mingw*|msys*|cygwin*)
        OS_NAME="Windows"
        EXT="zip"
        ;;
    *)
        echo "Unsupported operating system: $OS"
        exit 1
        ;;
esac

DOWNLOAD_URL="https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/latest/tmas-cli_${OS_NAME}_${ARCH}.${EXT}"

echo "Platform: ${OS_NAME} ${ARCH}"
echo "Download URL: ${DOWNLOAD_URL}"
echo "Install directory: ${INSTALL_DIR}"

# Create install directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Download
TEMP_FILE="/tmp/tmas-download.${EXT}"
echo "Downloading TMAS..."
curl -L "$DOWNLOAD_URL" -o "$TEMP_FILE"

# Extract
echo "Extracting..."
if [ "$EXT" = "zip" ]; then
    unzip -o "$TEMP_FILE" -d "$INSTALL_DIR"
else
    tar -xzf "$TEMP_FILE" -C "$INSTALL_DIR"
fi

# Make executable
chmod +x "$INSTALL_DIR/tmas"

# Cleanup
rm -f "$TEMP_FILE"

echo ""
echo "TMAS installed successfully to: $INSTALL_DIR/tmas"
echo ""

# Check if in PATH
if command -v tmas &> /dev/null; then
    echo "TMAS is in your PATH"
    tmas version
else
    echo "Add $INSTALL_DIR to your PATH to use tmas from anywhere:"
    echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
fi
