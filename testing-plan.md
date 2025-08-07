# Testing Plan for Cursor AppImage Fix

## Overview

This document outlines the steps to test the updated Cursor AppImage wrapper configuration to ensure the native module loading issues are resolved.

## Prerequisites

1. The updated `home.nix` file with the new Cursor wrapper configuration
2. A working NixOS system with flakes enabled
3. Sudo access to rebuild the system

## Testing Steps

### 1. Apply the Configuration Changes

1. Open your `home.nix` file
2. Replace the existing `cursorAppImage` section with the updated version from `cursor-fix-solution.md`
3. Save the file

### 2. Rebuild the System

```bash
# Navigate to your flake directory
cd /path/to/cursor-flake

# Rebuild the system with the updated configuration
sudo nixos-rebuild switch --flake .#cursor-system
```

Expected output:
- The build should complete without errors
- You should see the new Cursor package being built

### 3. Test Basic Functionality

```bash
# Test that Cursor can be invoked
cursor --version
```

Expected output:
- Should display the Cursor version (1.4.2)
- No error messages about missing modules

### 4. Test GUI Launch

```bash
# Launch Cursor GUI
cursor
```

Expected behavior:
- Cursor should launch without the keymapping errors
- The application should be responsive
- No console errors about native modules

### 5. Test Keyboard Functionality

Within the Cursor application:
1. Try typing in the editor
2. Test different keyboard layouts if applicable
3. Use keyboard shortcuts (Ctrl+C, Ctrl+V, etc.)

Expected behavior:
- Keyboard input should work normally
- No lag or errors when typing
- Keyboard shortcuts should function correctly

### 6. Test Project Operations

1. Open an existing project or create a new one
2. Try basic file operations (create, edit, save)
3. Test the AI features if available

Expected behavior:
- All operations should work without errors
- No crashes or unexpected behavior

### 7. Verify Environment Variables

```bash
# Check that environment variables are set correctly
printenv | grep -E "(CURSOR|ELECTRON|NODE)"
```

Expected output:
- Should show the environment variables we added
- Values should match what we specified in the configuration

### 8. Clean Cache Test

```bash
# Clear AppImage cache to test fresh start
rm -rf ~/.cache/appimage-run/*

# Restart Cursor
cursor --version
```

Expected behavior:
- Should work correctly even with cleared cache
- No errors about missing modules

## Success Criteria

The fix is considered successful if:

1. [ ] `cursor --version` runs without errors
2. [ ] Cursor GUI launches without keymapping errors
3. [ ] Keyboard input works normally in the editor
4. [ ] No native module loading errors in the console
5. [ ] All basic functionality works as expected
6. [ ] Application remains stable during extended use

## Troubleshooting

If issues persist after applying the fix:

1. Check the system logs:
   ```bash
   journalctl -xe
   ```

2. Try running with additional debugging:
   ```bash
   cursor --enable-logging --v=1
   ```

3. Verify the AppImage is being extracted correctly:
   ```bash
   ls -la ~/.cache/appimage-run/
   ```

4. Check library dependencies:
   ```bash
   ldd ~/.cache/appimage-run/*/usr/lib/libkeymapping.so
   ```

## Rollback Plan

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

## Additional Validation

Once the basic tests pass, perform these additional checks:

1. [ ] Test in a fresh terminal session
2. [ ] Test after system reboot
3. [ ] Test with different projects and file types
4. [ ] Verify no performance degradation