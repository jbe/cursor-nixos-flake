#!/usr/bin/env bash

# Script to update the SHA256 hash for Cursor AppImage
# Run this script to get the correct hash and update home.nix

set -e

echo "Fetching SHA256 hash for Cursor 1.3.9 AppImage..."
echo ""

# Get the hash
HASH=$(nix-prefetch-url https://downloads.cursor.com/production/54c27320fab08c9f5dd5873f07fca101f7a3e076/linux/x64/Cursor-1.3.9-x86_64.AppImage)

echo "SHA256 hash: $HASH"
echo ""
echo "Please update the hash in home.nix:"
echo "Replace the placeholder hash with:"
echo "sha256 = \"$HASH\";"
echo ""
echo "You can do this manually or run:"
echo "sed -i 's/sha256 = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\";/sha256 = \"$HASH\";/' home.nix"
echo ""

# Optionally update the file automatically
read -p "Do you want to update home.nix automatically? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sed -i "s/sha256 = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\";/sha256 = \"$HASH\";/" home.nix
    echo "Updated home.nix with the correct hash!"
else
    echo "Please update home.nix manually with the hash above."
fi 