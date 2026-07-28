#!/usr/bin/env bash
# ensure_echidna.sh — Ensure Echidna is installed. Auto-installs via Homebrew if missing.
# Usage: ensure_echidna.sh
# Exit 0 on success, exit 1 if install fails.

set -euo pipefail

# 1. Check if echidna is already installed
if command -v echidna &>/dev/null; then
    ECHIDNA_VERSION=$(echidna --version 2>&1 | head -1)
    echo "Echidna detected: $ECHIDNA_VERSION"
    exit 0
fi

echo "Echidna not found in PATH — attempting auto-install..."

# 2. Try Homebrew (macOS / Linux with brew)
if command -v brew &>/dev/null; then
    echo "Installing via Homebrew: brew install echidna"
    brew install echidna
    if command -v echidna &>/dev/null; then
        ECHIDNA_VERSION=$(echidna --version 2>&1 | head -1)
        echo "Echidna installed: $ECHIDNA_VERSION"
        exit 0
    fi
fi

# 3. Try prebuilt binary from GitHub releases (Linux x86_64 / macOS ARM fallback)
ECHIDNA_VERSION_TAG="v2.2.4"
MACHINE=$(uname -m)
OS=$(uname -s)
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

if [[ "$OS" == "Darwin" ]]; then
    BINARY_URL="https://github.com/crytic/echidna/releases/download/${ECHIDNA_VERSION_TAG}/echidna-${ECHIDNA_VERSION_TAG}-macOS.tar.gz"
elif [[ "$OS" == "Linux" && "$MACHINE" == "x86_64" ]]; then
    BINARY_URL="https://github.com/crytic/echidna/releases/download/${ECHIDNA_VERSION_TAG}/echidna-${ECHIDNA_VERSION_TAG}-ubuntu22.tar.gz"
else
    BINARY_URL=""
fi

if [[ -n "$BINARY_URL" ]] && command -v curl &>/dev/null; then
    echo "Homebrew unavailable or failed — downloading prebuilt binary from GitHub..."
    TMPDIR_ECHIDNA=$(mktemp -d)
    curl -sSL "$BINARY_URL" -o "$TMPDIR_ECHIDNA/echidna.tar.gz"
    tar -xzf "$TMPDIR_ECHIDNA/echidna.tar.gz" -C "$TMPDIR_ECHIDNA"
    # The archive contains the echidna binary at the root
    BINARY_PATH=$(find "$TMPDIR_ECHIDNA" -name "echidna" -type f | head -1)
    if [[ -n "$BINARY_PATH" ]]; then
        cp "$BINARY_PATH" "$INSTALL_DIR/echidna"
        chmod +x "$INSTALL_DIR/echidna"
        export PATH="$PATH:$INSTALL_DIR"
        rm -rf "$TMPDIR_ECHIDNA"
        if command -v echidna &>/dev/null; then
            ECHIDNA_VERSION=$(echidna --version 2>&1 | head -1)
            echo "Echidna installed from prebuilt binary: $ECHIDNA_VERSION"
            echo "NOTE: Add $INSTALL_DIR to your PATH permanently to use echidna outside this session."
            exit 0
        fi
    fi
    rm -rf "$TMPDIR_ECHIDNA"
fi

# 4. Nothing worked — give manual instructions
echo ""
echo "ERROR: Could not auto-install Echidna."
echo ""
echo "Install manually:"
echo "  brew install echidna"
echo ""
echo "Or see the official guide:"
echo "  https://secure-contracts.com/program-analysis/echidna/introduction/installation.html"
exit 1
