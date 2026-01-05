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
        # Extract version from URL like: .../Cursor-2.3.21-x86_64.AppImage
        echo "$redirect_url" | grep -o 'Cursor-[0-9]\+\.[0-9]\+\.[0-9]\+' | sed 's/Cursor-//'
    else
        echo "Error: Could not get redirect URL" >&2
        return 1
    fi
}

# Function to get current version from flake.nix
get_current_version() {
    grep -o 'version = "[^"]*"' "$FLAKE_FILE" | head -1 | cut -d'"' -f2
}

# Function to get download info for a specific architecture
get_download_info() {
    local version="$1"
    local arch="$2"
    local api_arch
    
    if [[ "$arch" == "x86_64-linux" ]]; then
        api_arch="linux-x64"
    else
        api_arch="linux-arm64"
    fi
    
    local api_url="https://api2.cursor.sh/updates/download/golden/$api_arch/cursor/$version"
    local actual_url
    actual_url=$(curl -s -I "$api_url" | grep -i location | cut -d' ' -f2 | tr -d '\r\n')
    
    if [[ -z "$actual_url" ]]; then
        echo "Error: Could not get actual download URL for $arch" >&2
        return 1
    fi
    
    echo "$actual_url"
}

# Function to escape special characters for sed replacement
escape_sed() {
    printf '%s\n' "$1" | sed -e 's/[\/&]/\\&/g'
}

# Function to update flake.nix using sed
update_flake() {
    local version="$1"
    
    echo "Fetching download URLs for version $version..."
    
    local x64_url
    local arm64_url
    x64_url=$(get_download_info "$version" "x86_64-linux") || { echo "Failed to get x86_64 URL"; exit 1; }
    arm64_url=$(get_download_info "$version" "aarch64-linux") || { echo "Failed to get aarch64 URL"; exit 1; }
    
    echo "x86_64 URL: $x64_url"
    echo "aarch64 URL: $arm64_url"
    
    # Get SHA256 hashes for both architectures
    local x64_sha256
    local arm64_sha256
    
    if command -v nix-prefetch-url >/dev/null 2>&1; then
        echo "Fetching SHA256 for x86_64..."
        x64_sha256=$(nix-prefetch-url --type sha256 "$x64_url") || { echo "Failed to fetch x86_64 hash"; exit 1; }
        echo "Fetching SHA256 for aarch64..."
        arm64_sha256=$(nix-prefetch-url --type sha256 "$arm64_url") || { echo "Failed to fetch aarch64 hash"; exit 1; }
    else
        echo "Error: nix-prefetch-url not found" >&2
        exit 1
    fi
    
    echo "x86_64 SHA256: $x64_sha256"
    echo "aarch64 SHA256: $arm64_sha256"
    
    # Create backup
    cp "$FLAKE_FILE" "$FLAKE_FILE.backup"
    
    # Escape URLs for sed
    local x64_url_escaped
    local arm64_url_escaped
    x64_url_escaped=$(escape_sed "$x64_url")
    arm64_url_escaped=$(escape_sed "$arm64_url")
    
    # Update version (first occurrence only, in the let block)
    if ! sed -i "s/^\([[:space:]]*version = \)\"[^\"]*\";/\1\"$version\";/" "$FLAKE_FILE"; then
        echo "Error: Failed to update version" >&2
        cp "$FLAKE_FILE.backup" "$FLAKE_FILE"
        exit 1
    fi
    
    # Update x86_64-linux URL (inside x86_64-linux block)
    if ! sed -i "/x86_64-linux = {/,/};/s|url = \"[^\"]*\";|url = \"$x64_url_escaped\";|" "$FLAKE_FILE"; then
        echo "Error: Failed to update x86_64 URL" >&2
        cp "$FLAKE_FILE.backup" "$FLAKE_FILE"
        exit 1
    fi
    
    # Update x86_64-linux SHA256
    if ! sed -i "/x86_64-linux = {/,/};/s/sha256 = \"[^\"]*\";/sha256 = \"$x64_sha256\";/" "$FLAKE_FILE"; then
        echo "Error: Failed to update x86_64 sha256" >&2
        cp "$FLAKE_FILE.backup" "$FLAKE_FILE"
        exit 1
    fi
    
    # Update aarch64-linux URL (inside aarch64-linux block)
    if ! sed -i "/aarch64-linux = {/,/};/s|url = \"[^\"]*\";|url = \"$arm64_url_escaped\";|" "$FLAKE_FILE"; then
        echo "Error: Failed to update aarch64 URL" >&2
        cp "$FLAKE_FILE.backup" "$FLAKE_FILE"
        exit 1
    fi
    
    # Update aarch64-linux SHA256
    if ! sed -i "/aarch64-linux = {/,/};/s/sha256 = \"[^\"]*\";/sha256 = \"$arm64_sha256\";/" "$FLAKE_FILE"; then
        echo "Error: Failed to update aarch64 sha256" >&2
        cp "$FLAKE_FILE.backup" "$FLAKE_FILE"
        exit 1
    fi
    
    # Verify the updates were applied
    if ! grep -q "version = \"$version\"" "$FLAKE_FILE"; then
        echo "Error: Version update verification failed" >&2
        cp "$FLAKE_FILE.backup" "$FLAKE_FILE"
        exit 1
    fi
    
    if ! grep -q "$x64_sha256" "$FLAKE_FILE"; then
        echo "Error: x86_64 sha256 update verification failed" >&2
        cp "$FLAKE_FILE.backup" "$FLAKE_FILE"
        exit 1
    fi
    
    if ! grep -q "$arm64_sha256" "$FLAKE_FILE"; then
        echo "Error: aarch64 sha256 update verification failed" >&2
        cp "$FLAKE_FILE.backup" "$FLAKE_FILE"
        exit 1
    fi
    
    echo "Updated flake.nix with version $version"
}

# Function to test the flake
test_flake() {
    echo "Testing flake..."
    if command -v nix >/dev/null 2>&1; then
        if ! nix flake check; then
            echo "Error: Flake check failed" >&2
            cp "$FLAKE_FILE.backup" "$FLAKE_FILE"
            exit 1
        fi
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
        target_version=$(get_latest_version) || { echo "Failed to get latest version"; exit 1; }
        echo "Latest version: $target_version"
    fi
    
    # Check if update is needed
    if [[ "$target_version" == "$current_version" ]]; then
        echo "No update needed. Current version is up to date."
        if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
            echo "CURSOR_VERSION_INFO=no_update" >> "$GITHUB_OUTPUT"
        fi
        exit 0
    fi
    
    echo "Update needed: $current_version -> $target_version"
    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
        echo "CURSOR_VERSION_INFO=updated:$current_version:$target_version" >> "$GITHUB_OUTPUT"
    fi
    
    # Check if running in CI/GitHub Actions (auto-confirm)
    if [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        echo "Running in CI mode, auto-confirming update..."
        REPLY="y"
    else
        read -p "Do you want to proceed with the update? (y/N): " -n 1 -r
        echo
    fi
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        update_flake "$target_version"
        test_flake
        echo "Update completed successfully!"
        if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
            echo "CURSOR_VERSION_INFO=completed:$current_version:$target_version" >> "$GITHUB_OUTPUT"
        fi
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
    
    if ! command -v sed >/dev/null 2>&1; then
        missing_deps+=("sed")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "Error: Missing required dependencies: ${missing_deps[*]}" >&2
        exit 1
    fi
}

# Run main function
check_dependencies
main "$@"
