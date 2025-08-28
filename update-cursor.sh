#!/usr/bin/env bash

# Simple script to update Cursor version in a package-only flake

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if we're in the right directory
if [[ ! -f "flake.nix" ]]; then
    print_error "This script must be run from the cursor-flake directory"
    exit 1
fi

print_info "Cursor Package Flake Updater"
echo ""

# Get current version and URL
CURRENT_VERSION=$(grep -o 'version = "[^"]*"' flake.nix | head -1 | sed 's/version = "//;s/"//')
CURRENT_URL=$(grep -o 'https://downloads\.cursor\.com/[^"]*' flake.nix | head -1)
CURRENT_HASH=$(grep -o 'sha256 = "[^"]*"' flake.nix | head -1 | sed 's/sha256 = "//;s/"//')

print_info "Current version: ${CURRENT_VERSION:-unknown}"
print_info "Current URL: $CURRENT_URL"
echo ""

# Handle input
if [[ $# -ge 1 ]]; then
    if [[ "$1" =~ ^https:// ]]; then
        NEW_URL="$1"
        NEW_VERSION=$(echo "$NEW_URL" | grep -o 'Cursor-[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1 | sed 's/Cursor-//')
    else
        NEW_VERSION="$1"
        read -p "Enter the full download URL for version $NEW_VERSION: " NEW_URL
    fi
else
    read -p "Enter new version (e.g., 1.5.6) or full URL: " INPUT
    if [[ "$INPUT" =~ ^https:// ]]; then
        NEW_URL="$INPUT"
        NEW_VERSION=$(echo "$NEW_URL" | grep -o 'Cursor-[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1 | sed 's/Cursor-//')
    else
        NEW_VERSION="$INPUT"
        read -p "Enter the full download URL: " NEW_URL
    fi
fi

if [[ -z "$NEW_URL" || -z "$NEW_VERSION" ]]; then
    print_error "Invalid input"
    exit 1
fi

print_info "New version: $NEW_VERSION"
print_info "New URL: $NEW_URL"
echo ""

# Get hash
print_info "Fetching SHA256 hash..."
HASH=$(nix-prefetch-url "$NEW_URL")

if [[ -z "$HASH" ]]; then
    print_error "Failed to get hash"
    exit 1
fi

print_success "SHA256 hash: $HASH"
echo ""

# Update flake.nix
print_info "Updating flake.nix..."

# Update version
sed -i "s|version = \"[^\"]*\";|version = \"$NEW_VERSION\";|" flake.nix
print_success "Updated version"

# Update URL
sed -i "s|$CURRENT_URL|$NEW_URL|g" flake.nix
print_success "Updated URL"

# Update hash
sed -i "s|sha256 = \"$CURRENT_HASH\";|sha256 = \"$HASH\";|" flake.nix
print_success "Updated hash"

# Test build
print_info "Testing build..."
if nix build .#cursor; then
    print_success "Build successful!"
    
    if [[ -x "./result/bin/cursor" ]]; then
        BUILT_VERSION=$(./result/bin/cursor --version 2>/dev/null || echo "unknown")
        print_info "Built version: $BUILT_VERSION"
        
        if [[ "$BUILT_VERSION" == "$NEW_VERSION" ]]; then
            print_success "Version verification passed!"
        else
            print_warning "Version mismatch: expected $NEW_VERSION, got $BUILT_VERSION"
        fi
        
        # Check that icon and desktop entry were installed
        if [[ -f "./result/share/pixmaps/cursor.png" ]]; then
            print_success "Icon successfully extracted and installed!"
        else
            print_warning "Icon not found - might not display properly in desktop"
        fi
        
        if [[ -f "./result/share/applications/cursor.desktop" ]]; then
            print_success "Desktop entry created!"
        else
            print_warning "Desktop entry not found"
        fi
    fi
else
    print_error "Build failed!"
    exit 1
fi

echo ""
print_info "Package updated successfully!"
print_info "To use in your system: rebuild your main NixOS configuration"
print_success "Update complete!"
