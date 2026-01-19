#!/bin/bash

# Cosmic Byte Firestorm - Cross-Platform Binary Build Script
# Builds standalone binaries for Linux, Windows, and macOS

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$PROJECT_ROOT/dist"
BUILD_DIR="$PROJECT_ROOT/build"
ENTRY_POINT="$PROJECT_ROOT/run.py"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_success() {
    echo -e "${GREEN}[*] $1${NC}"
}

print_error() {
    echo -e "${RED}[!] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

print_info() {
    echo -e "${BLUE}[*] $1${NC}"
}

check_python() {
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed"
        exit 1
    fi
    print_success "Python 3 found: $(python3 --version)"
}

check_venv() {
    if [ ! -d "$PROJECT_ROOT/.venv" ]; then
        print_warning "Virtual environment not found, creating one..."
        python3 -m venv "$PROJECT_ROOT/.venv"
        print_success "Virtual environment created"
    else
        print_success "Virtual environment found"
    fi
}

install_dependencies() {
    print_info "Installing dependencies..."
    source "$PROJECT_ROOT/.venv/bin/activate"

    pip install --upgrade pip > /dev/null 2>&1
    pip install -r "$PROJECT_ROOT/requirements.txt" > /dev/null 2>&1
    pip install pyinstaller > /dev/null 2>&1

    print_success "Dependencies installed"
}

clean_build_dirs() {
    print_info "Cleaning previous build artifacts..."

    rm -rf "$DIST_DIR"
    rm -rf "$BUILD_DIR"
    rm -f "$PROJECT_ROOT"/*.spec

    mkdir -p "$DIST_DIR"

    print_success "Build directories cleaned"
}

build_linux() {
    print_header "Building Linux Binary"

    source "$PROJECT_ROOT/.venv/bin/activate"

    # Change to project root before building
    cd "$PROJECT_ROOT"

    pyinstaller \
        --onefile \
        --name cosmic-mouse-linux \
        --distpath "$DIST_DIR" \
        --workpath "$BUILD_DIR" \
        --clean \
        --noconfirm \
        "$ENTRY_POINT"

    if [ -f "$DIST_DIR/cosmic-mouse-linux" ]; then
        chmod +x "$DIST_DIR/cosmic-mouse-linux"
        print_success "Linux binary built successfully"
        print_info "Location: $DIST_DIR/cosmic-mouse-linux"

        # Get file size
        SIZE=$(du -h "$DIST_DIR/cosmic-mouse-linux" | cut -f1)
        print_info "Size: $SIZE"
    else
        print_error "Linux binary build failed"
        return 1
    fi
}

build_windows() {
    print_header "Building Windows Binary"

    source "$PROJECT_ROOT/.venv/bin/activate"

    # Change to project root before building
    cd "$PROJECT_ROOT"

    pyinstaller \
        --onefile \
        --name cosmic-mouse-windows \
        --distpath "$DIST_DIR" \
        --workpath "$BUILD_DIR" \
        --clean \
        --noconfirm \
        "$ENTRY_POINT"

    # PyInstaller automatically adds .exe on Windows, but when cross-compiling we need to rename
    if [ -f "$DIST_DIR/cosmic-mouse-windows" ]; then
        mv "$DIST_DIR/cosmic-mouse-windows" "$DIST_DIR/cosmic-mouse-windows.exe" 2>/dev/null || true
        print_success "Windows binary built successfully"
        print_info "Location: $DIST_DIR/cosmic-mouse-windows.exe"

        SIZE=$(du -h "$DIST_DIR/cosmic-mouse-windows.exe" 2>/dev/null | cut -f1 || echo "N/A")
        print_info "Size: $SIZE"
    elif [ -f "$DIST_DIR/cosmic-mouse-windows.exe" ]; then
        print_success "Windows binary built successfully"
        print_info "Location: $DIST_DIR/cosmic-mouse-windows.exe"

        SIZE=$(du -h "$DIST_DIR/cosmic-mouse-windows.exe" | cut -f1)
        print_info "Size: $SIZE"
    else
        print_warning "Windows binary build may require Windows OS or Wine"
        print_info "To build for Windows, run this script on Windows or use Wine"
    fi
}

build_macos() {
    print_header "Building macOS Binary"

    source "$PROJECT_ROOT/.venv/bin/activate"

    # Change to project root before building
    cd "$PROJECT_ROOT"

    pyinstaller \
        --onefile \
        --name cosmic-mouse-macos \
        --distpath "$DIST_DIR" \
        --workpath "$BUILD_DIR" \
        --clean \
        --noconfirm \
        "$ENTRY_POINT"

    if [ -f "$DIST_DIR/cosmic-mouse-macos" ]; then
        chmod +x "$DIST_DIR/cosmic-mouse-macos"
        print_success "macOS binary built successfully"
        print_info "Location: $DIST_DIR/cosmic-mouse-macos"

        SIZE=$(du -h "$DIST_DIR/cosmic-mouse-macos" | cut -f1)
        print_info "Size: $SIZE"
    else
        print_warning "macOS binary build may require macOS"
        print_info "To build for macOS, run this script on macOS"
    fi
}

create_readme() {
    print_info "Creating distribution README..."

    cat > "$DIST_DIR/README.txt" << 'EOF'
Cosmic Byte Firestorm Controller - Binary Distribution
========================================================

This directory contains pre-built binaries for different platforms:

- cosmic-mouse-linux       : Linux (x86_64)
- cosmic-mouse-windows.exe : Windows (x86_64)
- cosmic-mouse-macos       : macOS (x86_64 / ARM64)

Installation:
-------------

Linux:
  sudo cp cosmic-mouse-linux /usr/local/bin/cosmic-mouse
  sudo chmod +x /usr/local/bin/cosmic-mouse

Windows:
  1. Copy cosmic-mouse-windows.exe to a directory in your PATH
  2. Rename to cosmic-mouse.exe (optional)
  3. Run with administrator privileges

macOS:
  sudo cp cosmic-mouse-macos /usr/local/bin/cosmic-mouse
  sudo chmod +x /usr/local/bin/cosmic-mouse

Usage:
------

Run: sudo cosmic-mouse --help

For full documentation, see: https://github.com/electrondefuser/cbfirestorm

Note: USB access requires administrator/root privileges on all platforms.

EOF

    print_success "Distribution README created"
}

show_summary() {
    print_header "Build Summary"

    echo ""
    echo "Built binaries in: $DIST_DIR"
    echo ""

    if [ -f "$DIST_DIR/cosmic-mouse-linux" ]; then
        SIZE=$(du -h "$DIST_DIR/cosmic-mouse-linux" | cut -f1)
        echo -e "  ${GREEN}[*]${NC} Linux:   cosmic-mouse-linux       ($SIZE)"
    else
        echo -e "  ${RED}[!]${NC} Linux:   Not built"
    fi

    if [ -f "$DIST_DIR/cosmic-mouse-windows.exe" ]; then
        SIZE=$(du -h "$DIST_DIR/cosmic-mouse-windows.exe" | cut -f1)
        echo -e "  ${GREEN}[*]${NC} Windows: cosmic-mouse-windows.exe ($SIZE)"
    else
        echo -e "  ${YELLOW}[!]${NC} Windows: Not built (requires Windows or Wine)"
    fi

    if [ -f "$DIST_DIR/cosmic-mouse-macos" ]; then
        SIZE=$(du -h "$DIST_DIR/cosmic-mouse-macos" | cut -f1)
        echo -e "  ${GREEN}[*]${NC} macOS:   cosmic-mouse-macos       ($SIZE)"
    else
        echo -e "  ${YELLOW}[!]${NC} macOS:   Not built (requires macOS)"
    fi

    echo ""
    print_info "Note: Cross-platform builds work best when run on the target OS"
    echo ""
}

main() {
    print_header "Cosmic Byte Firestorm - Binary Builder"

    echo ""
    print_info "Project root: $PROJECT_ROOT"
    print_info "Distribution: $DIST_DIR"
    echo ""

    check_python
    check_venv
    install_dependencies
    clean_build_dirs

    echo ""

    # Detect current platform and build native first
    PLATFORM=$(uname -s)
    case "$PLATFORM" in
        Linux*)
            build_linux
            echo ""
            build_windows || true
            echo ""
            build_macos || true
            ;;
        Darwin*)
            build_macos
            echo ""
            build_linux || true
            echo ""
            build_windows || true
            ;;
        MINGW*|MSYS*|CYGWIN*)
            build_windows
            echo ""
            build_linux || true
            echo ""
            build_macos || true
            ;;
        *)
            print_warning "Unknown platform: $PLATFORM"
            print_info "Attempting Linux build..."
            build_linux
            ;;
    esac

    echo ""
    create_readme

    # Clean up spec files
    rm -f "$PROJECT_ROOT"/*.spec

    echo ""
    show_summary

    print_success "Build process completed!"
}

# Run main function
main
