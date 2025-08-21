#!/usr/bin/env bash

# Script to update the SHA256 hash for Cursor AppImage
# This script helps you update the Cursor version and hash in the flake

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [[ ! -f "home.nix" ]]; then
    print_error "This script must be run from the cursor-flake directory"
    exit 1
fi

print_info "Cursor AppImage Hash Updater"
echo ""

# Get current URL from home.nix
CURRENT_URL=$(grep -o 'https://downloads\.cursor\.com/[^"]*' home.nix | head -1)

if [[ -z "$CURRENT_URL" ]]; then
    print_error "Could not find Cursor download URL in home.nix"
    exit 1
fi

print_info "Current URL: $CURRENT_URL"

# Extract version from URL
CURRENT_VERSION=$(echo "$CURRENT_URL" | grep -o 'Cursor-[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1 | sed 's/Cursor-//')

if [[ -z "$CURRENT_VERSION" ]]; then
    print_warning "Could not extract version from URL, using 'unknown'"
    CURRENT_VERSION="unknown"
fi

print_info "Current version: $CURRENT_VERSION"
echo ""

# If a URL argument is provided, use it and skip prompts; otherwise, fallback to interactive flow
if [[ $# -ge 1 ]]; then
    NEW_URL="$1"
    print_info "Using provided URL: $NEW_URL"

    # Extract new version from provided URL
    NEW_VERSION=$(echo "$NEW_URL" | grep -o 'Cursor-[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1 | sed 's/Cursor-//')
    if [[ -z "$NEW_VERSION" ]]; then
        print_warning "Could not extract version from provided URL"
        NEW_VERSION="unknown"
    fi
    print_info "New version: $NEW_VERSION"

    # Update the URL in home.nix
    sed -i "s|$CURRENT_URL|$NEW_URL|g" home.nix
    print_success "Updated URL in home.nix"

    # Update the version field in home.nix if present and we have a parsed version
    if [[ "$NEW_VERSION" != "unknown" ]]; then
        CURRENT_VERSION_IN_FILE=$(grep -o 'version = "[^"]*"' home.nix | head -1 | sed 's/version = "//;s/"//')
        if [[ -n "$CURRENT_VERSION_IN_FILE" ]]; then
            sed -i "s|version = \"$CURRENT_VERSION_IN_FILE\";|version = \"$NEW_VERSION\";|" home.nix
            print_success "Updated version in home.nix"
        fi
    fi

    URL_TO_HASH="$NEW_URL"
else
    # Ask user if they want to update to a new version
    read -p "Do you want to update to a new version? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        print_info "To update to a new version:"
        echo "1. Go to https://cursor.sh/"
        echo "2. Download the Linux AppImage"
        echo "3. Copy the download URL"
        echo "4. Paste it below"
        echo ""
        
        read -p "Enter the new Cursor download URL: " NEW_URL
        
        if [[ -z "$NEW_URL" ]]; then
            print_error "No URL provided"
            exit 1
        fi
        
        # Extract new version
        NEW_VERSION=$(echo "$NEW_URL" | grep -o 'Cursor-[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1 | sed 's/Cursor-//')
        
        if [[ -z "$NEW_VERSION" ]]; then
            print_warning "Could not extract version from new URL"
            NEW_VERSION="unknown"
        fi
        
        print_info "New version: $NEW_VERSION"
        
        # Update the URL in home.nix
        sed -i "s|$CURRENT_URL|$NEW_URL|g" home.nix
        print_success "Updated URL in home.nix"

        # Update the version field in home.nix if present and we have a parsed version
        if [[ "$NEW_VERSION" != "unknown" ]]; then
            CURRENT_VERSION_IN_FILE=$(grep -o 'version = "[^"]*"' home.nix | head -1 | sed 's/version = "//;s/"//')
            if [[ -n "$CURRENT_VERSION_IN_FILE" ]]; then
                sed -i "s|version = \"$CURRENT_VERSION_IN_FILE\";|version = \"$NEW_VERSION\";|" home.nix
                print_success "Updated version in home.nix"
            fi
        fi
        
        URL_TO_HASH="$NEW_URL"
    else
        URL_TO_HASH="$CURRENT_URL"
    fi
fi

echo ""
print_info "Fetching SHA256 hash for AppImage..."
echo "URL: $URL_TO_HASH"
echo ""

# Get the hash
print_info "Downloading and computing hash (this may take a moment)..."
HASH=$(nix-prefetch-url "$URL_TO_HASH")

if [[ -z "$HASH" ]]; then
    print_error "Failed to get hash"
    exit 1
fi

echo ""
print_success "SHA256 hash: $HASH"
echo ""

# Find the current hash in home.nix
CURRENT_HASH=$(grep -o 'sha256 = "[^"]*"' home.nix | head -1 | sed 's/sha256 = "//;s/"//')

if [[ -z "$CURRENT_HASH" ]]; then
    print_warning "Could not find current hash in home.nix"
    print_info "Please manually update the hash in home.nix:"
    echo "sha256 = \"$HASH\";"
else
    print_info "Current hash: $CURRENT_HASH"
    print_info "New hash: $HASH"
    echo ""
    
    if [[ "$CURRENT_HASH" == "$HASH" ]]; then
        print_success "Hash is already up to date!"
    else
        # Update the hash in home.nix
        sed -i "s/sha256 = \"$CURRENT_HASH\";/sha256 = \"$HASH\";/" home.nix
        print_success "Updated hash in home.nix"
    fi
fi

echo ""
print_info "Next steps:"
echo "1. Test the build: nix build .#packages.x86_64-linux.cursor"
echo "2. Update your system: sudo nixos-rebuild switch --flake .#your-system"
echo "3. Test Cursor: cursor --version"
echo ""

print_success "Hash update complete!" 