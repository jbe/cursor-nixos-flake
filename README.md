# Cursor Flake

A NixOS flake that provides a complete development environment with Cursor 1.3.9 (AI-first code editor) as an AppImage.

## Features

- **Cursor 1.3.9**: Latest version of the AI-first code editor
- **AppImage Support**: Full AppImage compatibility with proper desktop integration
- **Development Tools**: Complete development environment with Node.js, Python, Rust, and more
- **Modern Shell**: Zsh with Starship prompt and useful aliases
- **Desktop Environment**: GNOME with essential utilities
- **Git Integration**: Pre-configured Git with modern defaults

## Prerequisites

- NixOS system with flakes enabled
- At least 8GB RAM recommended
- 20GB free disk space

## Installation

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd cursor-flake
```

### 2. Update the SHA256 Hash (if needed)

The current configuration uses the working Cursor 1.3.9 download URL. If you need to update to a newer version, run:

```bash
./update-cursor-hash.sh
```

This will automatically update the hash in `home.nix` with the correct value.

### 3. Customize Configuration

Edit the following files to match your system:

- `configuration.nix`: System-wide settings
- `home.nix`: User-specific settings (change username from "liam" to your username)
- `hardware-configuration.nix`: Hardware-specific settings (run `nixos-generate-config` on your target system)

### 4. Build and Switch

```bash
# Build the configuration
sudo nixos-rebuild build --flake .#cursor-system

# Switch to the new configuration
sudo nixos-rebuild switch --flake .#cursor-system
```

### 5. First Boot Setup

After the first boot:

1. Log in as the configured user
2. Cursor will be available in the applications menu
3. You can also launch it from the terminal with `cursor`

## Configuration

### Cursor Settings

The flake includes pre-configured Cursor settings in `~/.config/Cursor/User/settings.json`:

- Modern font (JetBrains Mono with ligatures)
- Dark theme
- Optimized editor settings
- Cursor AI features enabled

### Development Environment

The flake includes:

- **Languages**: Node.js 20, Python 3, Rust
- **Tools**: Git, ripgrep, fd, bat, exa, fzf, tmux
- **Shell**: Zsh with Starship prompt
- **Terminal**: Alacritty

### Customization

To customize the configuration:

1. **Add packages**: Edit `home.nix` and add to `home.packages`
2. **Change shell**: Modify the shell configuration in `home.nix`
3. **Update Cursor settings**: Edit the settings in `home.nix`
4. **System packages**: Add to `environment.systemPackages` in `configuration.nix`

## Troubleshooting

### AppImage Issues

If Cursor doesn't run properly:

1. Check if AppImage support is enabled:
   ```bash
   ls /proc/sys/fs/binfmt_misc/
   ```

2. Reinstall AppImage support:
   ```bash
   sudo nixos-rebuild switch --flake .#cursor-system
   ```

### Permission Issues

If you encounter permission issues:

1. Ensure the user is in the correct groups:
   ```bash
   groups
   ```

2. Add user to additional groups if needed in `configuration.nix`

### Update Cursor

To update to a newer version of Cursor:

1. Update the version number in `home.nix`
2. Update the download URL if needed
3. Update the SHA256 hash
4. Rebuild the system

## File Structure

```
cursor-flake/
├── flake.nix                 # Main flake definition
├── configuration.nix         # NixOS system configuration
├── home.nix                  # Home Manager user configuration
├── hardware-configuration.nix # Hardware-specific settings
└── README.md                 # This file
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the configuration
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:

1. Check the troubleshooting section
2. Search existing issues
3. Create a new issue with detailed information

## Acknowledgments

- Cursor team for the excellent AI-first editor
- NixOS community for the amazing package management system
- Home Manager for user configuration management 