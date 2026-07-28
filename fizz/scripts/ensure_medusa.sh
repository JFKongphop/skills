#!/usr/bin/env bash
# ensure_medusa.sh — Ensure Medusa is installed. Auto-installs via Homebrew if missing.
# Usage: ensure_medusa.sh
# Exit 0 on success, exit 1 if install fails.

set -euo pipefail

# 1. Check if medusa is already installed
if command -v medusa &>/dev/null; then
    MEDUSA_VERSION=$(medusa --version 2>&1 | head -1)
    echo "Medusa detected: $MEDUSA_VERSION"
    exit 0
fi

echo "Medusa not found in PATH — attempting auto-install..."

# 2. Try Homebrew (macOS / Linux with brew)
if command -v brew &>/dev/null; then
    echo "Installing via Homebrew: brew install trailofbits/tools/medusa"
    brew tap trailofbits/tools 2>&1 || true
    brew install medusa
    if command -v medusa &>/dev/null; then
        MEDUSA_VERSION=$(medusa --version 2>&1 | head -1)
        echo "Medusa installed: $MEDUSA_VERSION"
        exit 0
    fi
fi

# 3. Try Go install as fallback
if command -v go &>/dev/null; then
    GO_VERSION=$(go version 2>&1 | awk '{print $3}')
    echo "Homebrew unavailable or failed — trying Go install ($GO_VERSION)..."
    go install github.com/crytic/medusa@latest
    # go installs to GOPATH/bin — make sure it's on PATH
    GOBIN="${GOPATH:-$HOME/go}/bin"
    export PATH="$PATH:$GOBIN"
    if command -v medusa &>/dev/null; then
        MEDUSA_VERSION=$(medusa --version 2>&1 | head -1)
        echo "Medusa installed via Go: $MEDUSA_VERSION"
        echo "NOTE: Add $GOBIN to your PATH permanently to use medusa outside this session."
        exit 0
    fi
fi

# 4. Nothing worked — give manual instructions
echo ""
echo "ERROR: Could not auto-install Medusa."
echo ""
echo "Install manually:"
echo "  brew install trailofbits/tools/medusa"
echo ""
echo "Or see the official guide:"
echo "  https://secure-contracts.com/program-analysis/medusa/docs/src/getting_started/installation.html"
exit 1
