#!/bin/bash

# Cosmic Byte Firestorm - Installation Script
# Installs the pre-built binary to /usr/local/bin

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$PROJECT_ROOT/dist"

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

echo "Installing Cosmic Byte Firestorm Controller..."
echo ""

# Detect platform and select appropriate binary
PLATFORM=$(uname -s)
BINARY_NAME=""

case "$PLATFORM" in
    Linux*)
        BINARY_NAME="cosmic-mouse-linux"
        ;;
    Darwin*)
        BINARY_NAME="cosmic-mouse-macos"
        ;;
    *)
        print_error "Unsupported platform: $PLATFORM"
        exit 1
        ;;
esac

BINARY_PATH="$DIST_DIR/$BINARY_NAME"

# Check if binary exists
if [ ! -f "$BINARY_PATH" ]; then
    print_error "Binary not found: $BINARY_PATH"
    echo ""
    print_info "Please build the binary first:"
    echo "  cd $PROJECT_ROOT"
    echo "  ./scripts/build_binaries.sh"
    exit 1
fi

# Install binary
print_info "Installing $BINARY_NAME to /usr/local/bin/cosmic-mouse..."

if sudo cp "$BINARY_PATH" /usr/local/bin/cosmic-mouse; then
    sudo chmod 755 /usr/local/bin/cosmic-mouse
    print_success "Installed cosmic-mouse to /usr/local/bin"
else
    print_error "Installation failed"
    exit 1
fi

echo ""
echo "Usage Examples:"
echo "  sudo cosmic-mouse rgb set-effect breathing_1"
echo "  sudo cosmic-mouse dpi set-mode 2"
echo "  cosmic-mouse profile show"
echo ""
echo "Profile location: ~/.cosmic_profile.yaml"
echo ""
print_success "Installation complete!"
