#!/bin/bash
# Test script for PIP Mode
# This script tests the PIP mode functionality step by step

echo "=== PIP Mode Test Script ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Step 1: Checking if a window is focused...${NC}"
if ! niri msg --json | jq '.windows[] | select(.is_focused == true)' &>/dev/null; then
    echo -e "${RED}Error: No window is focused. Please focus a window first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Window is focused${NC}"
echo ""

echo -e "${BLUE}Step 2: Making window floating...${NC}"
niri msg action move-window-to-floating
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Window is now floating${NC}"
else
    echo -e "${RED}✗ Failed to make window floating${NC}"
    exit 1
fi
sleep 0.5
echo ""

echo -e "${BLUE}Step 3: Setting width to 33% of screen...${NC}"
niri msg action set-window-width '33%'
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Width set to 33%${NC}"
else
    echo -e "${RED}✗ Failed to set width${NC}"
    exit 1
fi
sleep 0.5
echo ""

echo -e "${BLUE}Step 4: Setting height to 19% (16:9 aspect ratio)...${NC}"
niri msg action set-window-height '19%'
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Height set to 19% (16:9 ratio)${NC}"
else
    echo -e "${RED}✗ Failed to set height${NC}"
    exit 1
fi
sleep 0.5
echo ""

echo -e "${BLUE}Step 5: Moving to bottom-right corner (67%, 81%)...${NC}"
niri msg action move-floating-window --x '67%' --y '81%'
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Moved to bottom-right corner${NC}"
else
    echo -e "${RED}✗ Failed to move window${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}=== PIP Mode Enabled Successfully ===${NC}"
echo ""
echo "Press any key to return window to tiling mode..."
read -n 1 -s
echo ""

echo -e "${BLUE}Returning window to tiling mode...${NC}"
niri msg action move-window-to-tiling
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Window returned to tiling mode${NC}"
else
    echo -e "${RED}✗ Failed to return to tiling${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=== Test Complete ===${NC}"
