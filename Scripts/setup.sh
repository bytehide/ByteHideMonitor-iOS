#!/bin/bash

# ByteHide Monitor - SPM Setup
#
# One-command setup for Swift Package Manager users.
# Adds the build phase and disables sandbox automatically.
#
# Usage (from your Xcode project directory):
#   bash <(curl -sL https://raw.githubusercontent.com/bytehide/ByteHideMonitor-iOS/main/Scripts/setup.sh)
#
# Or if you have the repo locally:
#   bash Scripts/setup.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}ByteHide Monitor - SPM Setup${NC}"
echo ""

# ─── Check Ruby ─────────────────────────────────────────────────────────────

if ! command -v ruby &> /dev/null; then
    echo -e "${RED}Ruby not found. macOS should have Ruby pre-installed.${NC}"
    exit 1
fi

# ─── Check/install xcodeproj gem ────────────────────────────────────────────

if ! ruby -e "require 'xcodeproj'" 2>/dev/null; then
    echo -e "${YELLOW}Installing xcodeproj gem (required to modify Xcode project)...${NC}"
    gem install xcodeproj --no-document 2>/dev/null || {
        echo -e "${YELLOW}Permission denied. Trying with sudo...${NC}"
        sudo gem install xcodeproj --no-document
    }
    echo -e "${GREEN}xcodeproj gem installed${NC}"
else
    echo -e "${GREEN}xcodeproj gem found${NC}"
fi

# ─── Download and run setup script ──────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null)" && pwd 2>/dev/null || echo "")"
LOCAL_RB="${SCRIPT_DIR}/setup-spm.rb"

# Also check parent directory (if running from ios/)
if [ ! -f "$LOCAL_RB" ]; then
    LOCAL_RB="${SCRIPT_DIR}/../setup-spm.rb"
fi

if [ -f "$LOCAL_RB" ]; then
    echo -e "${GREEN}Using local setup script${NC}"
    ruby "$LOCAL_RB" "$@"
else
    echo -e "${BLUE}Downloading setup script...${NC}"
    REMOTE_URL="https://raw.githubusercontent.com/bytehide/ByteHideMonitor-iOS/main/Scripts/setup-spm.rb"
    TEMP_RB="/tmp/bytehide-setup-$$.rb"
    curl -sL "$REMOTE_URL" -o "$TEMP_RB"

    if [ ! -s "$TEMP_RB" ]; then
        echo -e "${RED}Failed to download setup script${NC}"
        rm -f "$TEMP_RB"
        exit 1
    fi

    ruby "$TEMP_RB" "$@"
    rm -f "$TEMP_RB"
fi
