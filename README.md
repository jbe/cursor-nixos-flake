# Cursor NixOS Flake

A NixOS flake that provides Cursor (AI-first code editor) as an AppImage with enhanced compatibility for NixOS systems.

## Features

- **Cursor 1.5.1**: Latest version of the AI-first code editor
- **Enhanced AppImage Support**: Optimized for NixOS with proper library paths and environment setup
- **Easy Integration**: Can be used as a standalone system or integrated into existing NixOS flakes
- **Development Tools**: Complete development environment with modern tools
- **Modern Shell**: Zsh with Starship prompt and useful aliases

## Quick Start

### Option 1: Use as a Standalone System

```bash
# Clone the repository
git clone https://github.com/thinktankmachine/cursor-nixos-flake
cd cursor-nixos-flake

# Build and switch to the configuration
sudo nixos-rebuild switch --flake .#cursor-system
```

### Option 2: Integrate into Existing NixOS Flake

Add to your `/etc/nixos/flake.nix`:

```nix
{
  inputs = {
    # ... your existing inputs
    cursor-flake = {
      url = "github:thinktankmachine/cursor-nixos-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { nixpkgs, home-manager, cursor-flake, ... }: {
    nixosConfigurations.your-system = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # ... your existing modules
        {
          home-manager.users.your-username = { pkgs, ... }: {
            home.packages = with pkgs; [
              # ... your existing packages
            ] ++ [
              # Add Cursor from the flake
              cursor-flake.packages.x86_64-linux.cursor
            ];
          };
        }
      ];
    };
  };
}
```

Then rebuild:
```bash
sudo nix flake update
sudo nixos-rebuild switch --flake .#your-system
```

## Usage

After installation, Cursor will be available:

- **Applications Menu**: Look for "Cursor" in your desktop environment
- **Terminal**: Run `cursor` from any terminal
- **Command Line**: Use `cursor --version` to verify installation

## Updating Cursor

When a new version of Cursor is released, follow these steps to update the flake:

### Step 1: Find the New Download URL

1. Go to [Cursor's download page](https://cursor.sh/)
2. Find the Linux AppImage download link
3. Copy the URL (it will look like: `https://downloads.cursor.com/production/[hash]/linux/x64/Cursor-[version]-x86_64.AppImage`)

### Step 2: Update the Flake

1. **Update the URL in `home.nix`**:
   ```nix
   # Find this section in home.nix
   cursorAppImage = pkgs.writeShellScriptBin "cursor" ''
     # ... environment setup ...
     
     # Run the AppImage with appimage-run
     exec ${pkgs.appimage-run}/bin/appimage-run ${pkgs.fetchurl {
       url = "https://downloads.cursor.com/production/[NEW_HASH]/linux/x64/Cursor-[NEW_VERSION]-x86_64.AppImage";
       sha256 = "OLD_HASH_HERE"; # This will be updated in the next step
     }} "$@"
   '';
   ```

2. **Update the SHA256 hash**:
   ```bash
   # Run the update script (it will fetch the new URL and update the hash)
   ./update-cursor-hash.sh
   ```

3. **Test the build**:
   ```bash
   # Test that the flake builds correctly
   nix build .#packages.x86_64-linux.cursor
   ```

4. **Update your system**:
   ```bash
   # If using standalone system
   sudo nixos-rebuild switch --flake .#cursor-system
   
   # If integrated into main system
   cd /etc/nixos
   sudo nix flake update
   sudo nixos-rebuild switch --flake .#your-system
   ```

### Step 3: Verify the Update

```bash
# Check the version
cursor --version

# Launch Cursor to ensure it works
cursor
```

### Step 4: Commit and Push (Optional)

```bash
# Commit the changes
git add .
git commit -m "Update Cursor to version [NEW_VERSION]"
git push origin main
```

## Configuration

### Customizing the Cursor Wrapper

The Cursor AppImage wrapper in `home.nix` includes enhanced compatibility settings:

```nix
cursorAppImage = pkgs.writeShellScriptBin "cursor" ''
  # Set up environment for better AppImage compatibility
  export APPDIR=""
  export ARGV0=""
  export OWD=""
  
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
  ]}:$LD_LIBRARY_PATH"
  
  # Run the AppImage with appimage-run
  exec ${pkgs.appimage-run}/bin/appimage-run ${pkgs.fetchurl {
    url = "https://downloads.cursor.com/production/[hash]/linux/x64/Cursor-[version]-x86_64.AppImage";
    sha256 = "[hash]";
  }} "$@"
'';
```

### Adding Additional Packages

To add more development tools, edit `home.nix`:

```nix
home.packages = with pkgs; [
  # Existing packages...
  
  # Add your packages here
  nodejs_20
  python3
  rustc
  cargo
  # ... more packages
];
```

## Troubleshooting

### Common Issues

#### 1. AppImage Won't Run

**Symptoms**: `bwrap: Can't chdir to /etc/nixos: No such file or directory`

**Solution**: Run Cursor from your home directory, not from system directories:
```bash
cd ~
cursor
```

#### 2. Keymapping Errors

**Symptoms**: `Error: Cannot find module './build/Debug/keymapping'`

**Solution**: These are cosmetic errors and don't prevent Cursor from working. The enhanced wrapper includes additional environment variables to reduce these errors.

#### 3. Update Mechanism Crashes

**Symptoms**: Cursor crashes when trying to update, shows "update available" but fails to install

**Solution**: The enhanced wrapper disables Cursor's auto-update mechanism to prevent crashes. To update Cursor, use the flake's update process instead:

```bash
# Update to a new version
./update-cursor-hash.sh
sudo nixos-rebuild switch --flake .#your-system
```

#### 4. Library Loading Issues

**Symptoms**: Various library-related errors

**Solution**: The enhanced wrapper includes all necessary libraries. If issues persist, try:
```bash
# Rebuild the system
sudo nixos-rebuild switch --flake .#your-system

# Clear AppImage cache
rm -rf ~/.cache/appimage-run/*
```

#### 5. Git Authentication Issues

**Symptoms**: `fatal: Authentication failed`

**Solution**: Ensure your remote uses SSH:
```bash
git remote set-url origin git@github.com:username/repo.git
```

### Testing the Flake

You can test the flake without affecting your system:

```bash
# Build the VM image
nix build .#nixosConfigurations.cursor-system.config.system.build.vm

# Run the VM
./result/bin/run-cursor-system-vm
```

## File Structure

```
cursor-flake/
├── flake.nix                 # Main flake definition with outputs
├── configuration.nix         # NixOS system configuration
├── home.nix                  # Home Manager configuration with Cursor wrapper
├── hardware-configuration.nix # Hardware-specific settings
├── update-cursor-hash.sh     # Script to update Cursor hash
├── test-configuration.nix    # Minimal test configuration
├── test-home.nix            # Minimal test home configuration
└── README.md                # This documentation
```

## Development

### Adding Features

1. **New packages**: Add to `home.packages` in `home.nix`
2. **System changes**: Modify `configuration.nix`
3. **User settings**: Update `home.nix` configuration

### Testing Changes

```bash
# Test the flake syntax
nix flake check

# Test building the package
nix build .#packages.x86_64-linux.cursor

# Test the full system
nix build .#nixosConfigurations.cursor-system.config.system.build.vm
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Test thoroughly: `nix flake check`
5. Commit: `git commit -m "Add feature description"`
6. Push: `git push origin feature-name`
7. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

- **Issues**: [GitHub Issues](https://github.com/thinktankmachine/cursor-nixos-flake/issues)
- **Discussions**: [GitHub Discussions](https://github.com/thinktankmachine/cursor-nixos-flake/discussions)

## Acknowledgments

- [Cursor](https://cursor.sh/) team for the excellent AI-first editor
- [NixOS](https://nixos.org/) community for the amazing package management system
- [Home Manager](https://github.com/nix-community/home-manager) for user configuration management 