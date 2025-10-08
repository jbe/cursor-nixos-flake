#!/usr/bin/env bash

set -euo pipefail

# Test script to verify the Cursor flake setup
echo "Testing Cursor Flake Setup"
echo "========================="

# Check if we're in the right directory
if [[ ! -f "flake.nix" ]]; then
    echo "Error: flake.nix not found. Please run this script from the flake directory."
    exit 1
fi

# Test 1: Check flake syntax
echo "1. Testing flake syntax..."
if command -v nix >/dev/null 2>&1; then
    if nix flake check --no-build; then
        echo "   ✓ Flake syntax is valid"
    else
        echo "   ✗ Flake syntax error"
        exit 1
    fi
else
    echo "   ⚠ Skipping flake check (nix not available)"
fi

# Test 2: Check update script
echo "2. Testing update script..."
if [[ -f "update-cursor.sh" && -x "update-cursor.sh" ]]; then
    echo "   ✓ Update script exists and is executable"
    
    # Test script help
    if ./update-cursor.sh --help 2>/dev/null || ./update-cursor.sh -h 2>/dev/null; then
        echo "   ✓ Update script help works"
    else
        echo "   ⚠ Update script help not available (this is normal)"
    fi
else
    echo "   ✗ Update script missing or not executable"
    exit 1
fi

# Test 3: Check GitHub Actions workflow
echo "3. Testing GitHub Actions workflow..."
if [[ -f ".github/workflows/update-cursor.yml" ]]; then
    echo "   ✓ GitHub Actions workflow exists"
    
    # Basic YAML syntax check
    if command -v yamllint >/dev/null 2>&1; then
        if yamllint .github/workflows/update-cursor.yml >/dev/null 2>&1; then
            echo "   ✓ Workflow YAML syntax is valid"
        else
            echo "   ⚠ Workflow YAML syntax issues (yamllint not available or found issues)"
        fi
    else
        echo "   ⚠ Skipping YAML validation (yamllint not available)"
    fi
else
    echo "   ✗ GitHub Actions workflow missing"
    exit 1
fi

# Test 4: Check API connectivity
echo "4. Testing API connectivity..."
if command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    if curl -s --max-time 10 "https://api2.cursor.sh/updates/check/golden/linux-x64-deb/cursor" | jq -r '.version' >/dev/null 2>&1; then
        echo "   ✓ Cursor API is accessible"
    else
        echo "   ⚠ Cursor API not accessible (this might be temporary)"
    fi
else
    echo "   ⚠ Skipping API test (curl or jq not available)"
fi

# Test 5: Check current version
echo "5. Checking current version..."
CURRENT_VERSION=$(grep -o 'version = "[^"]*"' flake.nix | head -1 | cut -d'"' -f2)
echo "   Current version: $CURRENT_VERSION"

# Test 6: Check if SHA256 is placeholder
echo "6. Checking SHA256 hash..."
CURRENT_SHA256=$(grep -o 'sha256 = "[^"]*"' flake.nix | head -1 | cut -d'"' -f2)
if [[ "$CURRENT_SHA256" == "0000000000000000000000000000000000000000000000000000" ]]; then
    echo "   ⚠ SHA256 is placeholder - needs to be updated"
else
    echo "   ✓ SHA256 appears to be set"
fi

echo ""
echo "Test Summary"
echo "============"
echo "Setup appears to be mostly correct!"
echo ""
echo "Next steps:"
echo "1. Run './update-cursor.sh' to get the correct SHA256 hash"
echo "2. Commit and push your changes to enable GitHub Actions"
echo "3. Check the Actions tab in GitHub to see if the workflow runs"
echo ""
echo "For manual testing:"
echo "- nix build .#cursor --dry-run"
echo "- nix run .#cursor --version"
