# Quick Start Guide

Get Cursor 1.3.9 running on NixOS in minutes!

## Prerequisites

- NixOS system with flakes enabled
- Git installed

## Quick Setup

1. **Clone and enter the repository:**
   ```bash
   git clone <your-repo-url>
   cd cursor-flake
   ```

2. **Customize the username** (optional):
   - Edit `home.nix` and change `home.username = "liam";` to your username
   - Edit `configuration.nix` and change `users.users.liam` to your username

3. **Deploy to your system:**
   ```bash
   sudo nixos-rebuild switch --flake .#cursor-system
   ```

4. **Launch Cursor:**
   - From applications menu: Look for "Cursor"
   - From terminal: Run `cursor`

## What You Get

- ✅ **Cursor 1.3.9**: Latest AI-first code editor
- ✅ **Development Environment**: Node.js, Python, Rust, Git
- ✅ **Modern Shell**: Zsh with Starship prompt
- ✅ **CLI Tools**: ripgrep, fd, bat, eza, fzf, tmux
- ✅ **Desktop Integration**: GNOME with proper launcher

## Testing

To test before deploying:
```bash
# Build the system (takes a few minutes)
nix build .#nixosConfigurations.cursor-system.config.system.build.vm

# Run in VM (optional)
./result/bin/run-cursor-system-vm
```

## Troubleshooting

- **Cursor won't start**: Make sure you have FUSE support enabled
- **Permission issues**: Check that your user is in the correct groups
- **Build fails**: Run `nix flake check` to validate the configuration

## Next Steps

- Customize your development environment in `home.nix`
- Add your own packages to the configuration
- Check the full README.md for detailed documentation 