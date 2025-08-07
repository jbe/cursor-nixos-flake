# Comprehensive Solution for Cursor AppImage Native Module Issues on NixOS

## Problem Summary

When using Cursor 1.4.2 as an AppImage in a NixOS flake, users encounter errors related to native modules not being found:

```
Error: Cannot find module './build/Debug/keymapping'
```

This issue occurs because the AppImage contains pre-compiled native modules that expect to find certain libraries in specific locations, but NixOS has a different filesystem structure that doesn't match these expectations.

## Root Cause Analysis

The problem is multifaceted:

1. **Library Path Issues**: Native modules in the AppImage can't find required system libraries
2. **Environment Variable Mismatch**: Electron applications expect certain environment variables to be set
3. **Sandboxing Conflicts**: NixOS sandboxing interferes with AppImage's assumptions about the filesystem
4. **Keyboard Mapping Dependencies**: The `native-keymap` module specifically requires X11 keyboard libraries

## Solution Overview

The solution involves modifying the Cursor wrapper in `home.nix` to:

1. Add missing system libraries to the library path
2. Set appropriate environment variables for Electron applications
3. Use AppImage extraction mode to avoid sandbox issues
4. Add proper flags to handle GPU and sandboxing issues

## Implementation

### Updated Cursor Wrapper Configuration

Here's the complete updated `cursorAppImage` section for your `home.nix`:

```nix
let
  # Cursor 1.4.2 AppImage wrapper with enhanced compatibility and update handling
  cursorAppImage = pkgs.writeShellScriptBin "cursor" ''
    # Set up environment for better AppImage compatibility
    export APPDIR=""
    export ARGV0=""
    export OWD=""
    
    # Disable Cursor's auto-update mechanism to prevent crashes
    export CURSOR_DISABLE_UPDATE="1"
    export CURSOR_SKIP_UPDATE_CHECK="1"
    
    # Ensure proper library paths
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
      pkgs.glib
      pkgs.gtk3
      pkgs.cairo
      pkgs.pango
      pkgs.atk
      pkgs.gdk-pixbuf
      pkgs.xorg.libX11
      pkgs.xorg.libXcomposite
      pkgs.xorg.libXcursor
      pkgs.xorg.libXext
      pkgs.xorg.libXfixes
      pkgs.xorg.libXi
      pkgs.xorg.libXrandr
      pkgs.xorg.libXrender
      pkgs.xorg.libXtst
      pkgs.nss
      pkgs.nspr
      pkgs.dbus
      pkgs.at-spi2-atk
      pkgs.at-spi2-core
      pkgs.mesa
      pkgs.alsa-lib
      pkgs.fuse
      pkgs.libxkbcommon  # Added for keyboard mapping support
      pkgs.libxkbfile    # Added for keyboard mapping support
    ]}:$LD_LIBRARY_PATH"
    
    # Set additional environment variables to handle keymapping and native module issues
    export ELECTRON_DISABLE_SECURITY_WARNINGS="1"
    export ELECTRON_NO_ATTACH_CONSOLE="1"
    export ELECTRON_RUN_AS_NODE="0"
    
    # Additional environment variables for native module compatibility
    export NODE_OPTIONS="--no-warnings"
    export NODE_ENV="production"
    export ELECTRON_ENABLE_LOGGING="false"
    export ELECTRON_DISABLE_SECURITY_WARNINGS="true"
    
    # Fix for native keymap module issues
    export XDG_CACHE_HOME="/tmp/cursor-xdg-cache-$$"
    mkdir -p "$XDG_CACHE_HOME"
    
    # Create a temporary directory for Cursor's cache to avoid permission issues
    export CURSOR_CACHE_DIR="/tmp/cursor-cache-$$"
    mkdir -p "$CURSOR_CACHE_DIR"
    
    # Additional fixes for AppImage native modules
    export APPIMAGE_EXTRACT_AND_RUN="1"
    
    # Run the AppImage with appimage-run and additional flags
    exec ${pkgs.appimage-run}/bin/appimage-run \
      --no-sandbox \
      --appimage-extract-and-run \
      ${pkgs.fetchurl {
                  url = "https://downloads.cursor.com/production/07aa3b4519da4feab4761c58da3eeedd253a1671/linux/x64/Cursor-1.4.2-x86_64.AppImage";
                  sha256 = "0gb89li1aklzgc9h8y5rlrnk0n6sb4ikahaml4r9kr6ixadc4b1a";
      }} \
      --disable-updates \
      --no-update-check \
      --disable-gpu-sandbox \
      --disable-dev-shm-usage \
      "$@"
  '';
```

## Key Changes Explained

### 1. Additional Libraries
- **libxkbcommon** and **libxkbfile**: Essential for keyboard mapping functionality
- These libraries were missing from the original configuration and are required by the `native-keymap` module

### 2. Environment Variables
- **ELECTRON_RUN_AS_NODE="0"**: Ensures Electron runs in application mode rather than Node.js mode
- **NODE_OPTIONS="--no-warnings"**: Reduces noise in the console output
- **NODE_ENV="production"**: Optimizes Node.js behavior for production use
- **XDG_CACHE_HOME**: Provides a writable cache directory for the application

### 3. AppImage Execution Mode
- **APPIMAGE_EXTRACT_AND_RUN="1"**: Forces extraction mode which avoids many sandboxing issues
- **--appimage-extract-and-run**: Command line flag that does the same thing

### 4. Additional Electron Flags
- **--disable-gpu-sandbox**: Reduces GPU-related sandboxing issues
- **--disable-dev-shm-usage**: Avoids issues with shared memory in containers/sandboxed environments

## Testing Plan

### Prerequisites
1. Updated `home.nix` file with the new Cursor wrapper configuration
2. Working NixOS system with flakes enabled
3. Sudo access to rebuild the system

### Testing Steps

1. **Apply Configuration Changes**
   - Replace the existing `cursorAppImage` section in `home.nix`
   - Save the file

2. **Rebuild the System**
   ```bash
   sudo nixos-rebuild switch --flake .#cursor-system
   ```

3. **Test Basic Functionality**
   ```bash
   cursor --version
   ```

4. **Test GUI Launch**
   ```bash
   cursor
   ```

5. **Test Keyboard Functionality**
   - Type in the editor
   - Test keyboard shortcuts
   - Try different keyboard layouts if applicable

### Success Criteria
The fix is successful if:
- [ ] `cursor --version` runs without errors
- [ ] Cursor GUI launches without keymapping errors
- [ ] Keyboard input works normally in the editor
- [ ] No native module loading errors in the console
- [ ] All basic functionality works as expected

## Troubleshooting

### If Issues Persist

1. **Clear AppImage Cache**
   ```bash
   rm -rf ~/.cache/appimage-run/*
   ```

2. **Check System Logs**
   ```bash
   journalctl -xe
   ```

3. **Run with Debugging**
   ```bash
   cursor --enable-logging --v=1
   ```

### Rollback Plan

If the updated configuration causes issues:
1. Restore the previous `home.nix` file
2. Rebuild the system:
   ```bash
   sudo nixos-rebuild switch --flake .#cursor-system
   ```
3. Clear the AppImage cache:
   ```bash
   rm -rf ~/.cache/appimage-run/*
   ```

## Conclusion

This solution addresses the native module loading issues by providing the missing libraries and environment variables that the AppImage expects. The key insight is that Electron applications packaged as AppImages have specific requirements that don't align with NixOS's unique filesystem structure, and we need to bridge that gap through careful environment configuration.

The changes are backward-compatible and should not introduce any new issues while resolving the existing keymapping errors.