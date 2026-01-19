#!/bin/bash

# Cosmic Byte Firestorm - Project Cleanup Script
# Removes all build artifacts, caches, and temporary files

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

cleanup_python_cache() {
    print_info "Removing Python cache files..."

    local count=0

    # Remove __pycache__ directories
    while IFS= read -r -d '' dir; do
        rm -rf "$dir"
        ((count++))
    done < <(find . -type d -name "__pycache__" ! -path "*/.venv/*" -print0 2>/dev/null)

    # Remove .pyc files
    while IFS= read -r -d '' file; do
        rm -f "$file"
        ((count++))
    done < <(find . -type f -name "*.pyc" ! -path "*/.venv/*" -print0 2>/dev/null)

    # Remove .pyo files
    while IFS= read -r -d '' file; do
        rm -f "$file"
        ((count++))
    done < <(find . -type f -name "*.pyo" ! -path "*/.venv/*" -print0 2>/dev/null)

    if [ $count -gt 0 ]; then
        print_success "Removed $count Python cache files/directories"
    else
        print_info "No Python cache files found"
    fi
}

cleanup_build_artifacts() {
    print_info "Removing build artifacts..."

    local removed=()

    # Remove build directories
    if [ -d "build" ]; then
        rm -rf "build"
        removed+=("build/")
    fi

    if [ -d "bin" ]; then
        rm -rf "bin"
        removed+=("bin/")
    fi

    if [ -d "dist" ]; then
        rm -rf "dist"
        removed+=("dist/")
    fi

    # Remove .egg-info directories
    while IFS= read -r -d '' dir; do
        rm -rf "$dir"
        removed+=("$(basename "$dir")")
    done < <(find . -maxdepth 2 -type d -name "*.egg-info" -print0 2>/dev/null)

    # Remove PyInstaller spec files
    while IFS= read -r -d '' file; do
        rm -f "$file"
        removed+=("$(basename "$file")")
    done < <(find . -maxdepth 1 -type f -name "*.spec" -print0 2>/dev/null)

    if [ ${#removed[@]} -gt 0 ]; then
        print_success "Removed build artifacts: ${removed[*]}"
    else
        print_info "No build artifacts found"
    fi
}

cleanup_venv() {
    if [ -d ".venv" ]; then
        print_warning "Virtual environment found at .venv/"
        read -p "$(echo -e ${YELLOW}"Do you want to remove it? (y/N): "${NC})" -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf ".venv"
            print_success "Virtual environment removed"
        else
            print_info "Keeping virtual environment"
        fi
    else
        print_info "No virtual environment found"
    fi
}

cleanup_ide_files() {
    print_info "Removing IDE and editor files..."

    local removed=()

    # VS Code
    if [ -d ".vscode" ]; then
        rm -rf ".vscode"
        removed+=(".vscode/")
    fi

    # PyCharm / IntelliJ
    if [ -d ".idea" ]; then
        rm -rf ".idea"
        removed+=(".idea/")
    fi

    # Vim swap files
    while IFS= read -r -d '' file; do
        rm -f "$file"
        removed+=("$(basename "$file")")
    done < <(find . -type f \( -name "*.swp" -o -name "*.swo" -o -name "*~" \) -print0 2>/dev/null)

    # macOS files
    while IFS= read -r -d '' file; do
        rm -f "$file"
        removed+=("$(basename "$file")")
    done < <(find . -type f -name ".DS_Store" -print0 2>/dev/null)

    if [ ${#removed[@]} -gt 0 ]; then
        print_success "Removed IDE files: ${removed[*]}"
    else
        print_info "No IDE files found"
    fi
}

cleanup_logs() {
    print_info "Removing log files..."

    local count=0

    while IFS= read -r -d '' file; do
        rm -f "$file"
        ((count++))
    done < <(find . -type f \( -name "*.log" -o -name "*.log.*" \) ! -path "*/.venv/*" -print0 2>/dev/null)

    if [ $count -gt 0 ]; then
        print_success "Removed $count log files"
    else
        print_info "No log files found"
    fi
}

show_summary() {
    print_header "Cleanup Summary"

    echo ""
    print_info "Project root: $(pwd)"
    echo ""

    # Calculate current directory size
    if command -v du &> /dev/null; then
        SIZE=$(du -sh . 2>/dev/null | cut -f1)
        print_info "Current project size: $SIZE"
    fi

    echo ""
    print_success "Cleanup completed!"
    echo ""
    print_info "Kept: source files, README.md, PROTOCOL.md, scripts/"

    if [ -d ".venv" ]; then
        print_info "Kept: .venv/ (use --venv flag to remove)"
    fi

    echo ""
}

show_help() {
    cat << EOF
Cosmic Byte Firestorm - Cleanup Script

Usage: $0 [OPTIONS]

Options:
    --all       Clean everything including virtual environment
    --venv      Remove virtual environment (.venv/)
    --help      Show this help message

Without options, cleans build artifacts, cache files, and IDE files
but keeps the virtual environment.

EOF
}

main() {
    print_header "Cosmic Byte Firestorm - Project Cleanup"

    echo ""
    print_info "Project root: $PROJECT_ROOT"

    # Change to project root directory
    cd "$PROJECT_ROOT" || {
        print_error "Failed to change to project root: $PROJECT_ROOT"
        exit 1
    }

    print_info "Working directory: $(pwd)"
    echo ""

    # Verify we're in the right place
    if [ ! -f "setup.py" ] || [ ! -d "cosmic" ]; then
        print_error "Not in project root! Expected to find setup.py and cosmic/ directory"
        exit 1
    fi

    # Parse arguments
    CLEAN_VENV=false

    for arg in "$@"; do
        case $arg in
            --all)
                CLEAN_VENV=true
                ;;
            --venv)
                CLEAN_VENV=true
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $arg"
                show_help
                exit 1
                ;;
        esac
    done

    cleanup_python_cache
    echo ""

    cleanup_build_artifacts
    echo ""

    cleanup_ide_files
    echo ""

    cleanup_logs
    echo ""

    if [ "$CLEAN_VENV" = true ]; then
        if [ -d ".venv" ]; then
            rm -rf ".venv"
            print_success "Virtual environment removed"
            echo ""
        fi
    else
        cleanup_venv
        echo ""
    fi

    show_summary
}

# Run main function
main "$@"
