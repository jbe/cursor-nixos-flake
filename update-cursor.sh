#!/usr/bin/env bash

set -euo pipefail

# Script to manually update Cursor version in the flake
# Usage: ./update-cursor.sh [version]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_FILE="$SCRIPT_DIR/flake.nix"

# Function to get latest version from API redirect
get_latest_version() {
    # Get the redirect URL and extract version from the AppImage filename
    local redirect_url
    redirect_url=$(curl -s -I "https://api2.cursor.sh/updates/download/golden/linux-x64/cursor/latest" | grep -i location | cut -d' ' -f2 | tr -d '\r\n')
    
    if [[ -n "$redirect_url" ]]; then
        # Extract version from URL like: .../Cursor-1.7.39-x86_64.AppImage
        echo "$redirect_url" | grep -o 'Cursor-[0-9]\+\.[0-9]\+\.[0-9]\+' | sed 's/Cursor-//'
    else
        echo "Error: Could not get redirect URL"
        return 1
    fi
}

# Function to get current version from flake.nix
get_current_version() {
    grep -o 'version = "[^"]*"' "$FLAKE_FILE" | head -1 | cut -d'"' -f2
}

# Function to update flake.nix
update_flake() {
    local version="$1"
    local appimage_url="https://api2.cursor.sh/updates/download/golden/linux-x64/cursor/$version"
    
    echo "Fetching AppImage from: $appimage_url"
    
    # Get the actual download URL by following redirects
    local actual_url
    actual_url=$(curl -s -I "$appimage_url" | grep -i location | cut -d' ' -f2 | tr -d '\r\n')
    
    if [[ -z "$actual_url" ]]; then
        echo "Error: Could not get actual download URL"
        return 1
    fi
    
    echo "Actual download URL: $actual_url"
    
    # Get SHA256 hash
    local sha256
    if command -v nix-prefetch-url >/dev/null 2>&1; then
        sha256=$(nix-prefetch-url --type sha256 "$actual_url")
    else
        echo "Warning: nix-prefetch-url not found. You'll need to update the SHA256 manually."
        sha256="0000000000000000000000000000000000000000000000000000"
    fi
    
    echo "SHA256: $sha256"
    
    # Create backup
    cp "$FLAKE_FILE" "$FLAKE_FILE.backup"
    
    # Update flake.nix - be more specific to avoid replacing nixpkgs URL
    sed -i "s/version = \"[^\"]*\"  # Will be updated by GitHub Actions/version = \"$version\"/" "$FLAKE_FILE"
    sed -i "/buildCursor = {/,/};/s|url = \"[^\"]*\"|url = \"$actual_url\"|" "$FLAKE_FILE"
    sed -i "/buildCursor = {/,/};/s/sha256 = \"[^\"]*\"/sha256 = \"$sha256\"/" "$FLAKE_FILE"
    
    echo "Updated flake.nix with version $version"
}

# Function to test the flake
test_flake() {
    echo "Testing flake..."
    if command -v nix >/dev/null 2>&1; then
        nix flake check
        echo "Flake check passed!"
    else
        echo "Warning: nix command not found. Skipping flake check."
    fi
}

# Main logic
main() {
    local target_version="${1:-}"
    
    echo "Cursor Flake Updater"
    echo "==================="
    
    # Get current version
    local current_version
    current_version=$(get_current_version)
    echo "Current version: $current_version"
    
    # Determine target version
    if [[ -n "$target_version" ]]; then
        echo "Target version: $target_version"
    else
        echo "Fetching latest version..."
        target_version=$(get_latest_version)
        echo "Latest version: $target_version"
    fi
    
    # Check if update is needed
    if [[ "$target_version" == "$current_version" ]]; then
        echo "No update needed. Current version is up to date."
        exit 0
    fi
    
    echo "Update needed: $current_version -> $target_version"
    read -p "Do you want to proceed with the update? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        update_flake "$target_version"
        test_flake
        echo "Update completed successfully!"
        echo "You can now commit the changes:"
        echo "  git add flake.nix"
        echo "  git commit -m \"Update Cursor to version $target_version\""
    else
        echo "Update cancelled."
    exit 1
fi
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "Error: Missing required dependencies: ${missing_deps[*]}"
        echo "Please install them and try again."
    exit 1
fi
}

# Run main function
check_dependencies
main "$@"