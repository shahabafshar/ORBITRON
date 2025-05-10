#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check if orbitron.sh exists
if [ ! -f "orbitron.sh" ]; then
    echo -e "${RED}Error: orbitron.sh not found${NC}"
    exit 1
fi

# Make orbitron.sh executable if it isn't already
if [ ! -x "orbitron.sh" ]; then
    chmod +x orbitron.sh
fi

# Run orbitron
echo -e "${GREEN}Starting ORBITRON...${NC}"
./orbitron.sh 