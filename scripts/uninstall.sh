#!/bin/bash

# Cosmic Byte Firestorm - Uninstallation Script
# Removes the installed binary from /usr/local/bin

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}[*] $1${NC}"
}

print_error() {
    echo -e "${RED}[!] $1${NC}"
}

print_info() {
    echo -e "${YELLOW}[*] $1${NC}"
}

echo "Uninstalling Cosmic Byte Firestorm Controller..."
echo ""

# Check if binary exists
if [ ! -f /usr/local/bin/cosmic-mouse ]; then
    print_error "cosmic-mouse is not installed in /usr/local/bin"
    exit 1
fi

# Remove binary
print_info "Removing /usr/local/bin/cosmic-mouse..."

if sudo rm -f /usr/local/bin/cosmic-mouse; then
    print_success "Uninstalled cosmic-mouse from /usr/local/bin"
else
    print_error "Uninstallation failed"
    exit 1
fi

echo ""
print_info "Your profile at ~/.cosmic_profile.yaml was NOT deleted"

# Ask if user wants to remove profile
if [ -f ~/.cosmic_profile.yaml ]; then
    echo ""
    read -p "$(echo -e ${YELLOW}"Do you want to remove your profile? (y/N): "${NC})" -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm ~/.cosmic_profile.yaml
        print_success "Profile removed"
    else
        print_info "Profile kept at ~/.cosmic_profile.yaml"
    fi
fi

echo ""
print_success "Uninstallation complete!"
