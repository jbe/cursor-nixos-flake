{ config, pkgs, lib, ... }:

let
  # A robust Nix-native wrapper for the Cursor AppImage using appimageTools
  cursor =
    let
      # First, unpack the AppImage and wrap it with the correct libraries
      unwrapped = pkgs.appimageTools.wrapType2 {
        pname = "cursor";
        version = "1.4.3";
        src = pkgs.fetchurl {
          url = "https://downloads.cursor.com/production/e50823e9ded15fddfd743c7122b4724130c25df8/linux/x64/Cursor-1.4.3-x86_64.AppImage";
          sha256 = "042x8363gn6yam0hnc8aibaj7m86fyyaldfiswhzv25bgs5cwdvg";
        };

        # All the libraries needed by Cursor, which will be added to the RPATH
        extraPkgs = p: with p; [
          glib
          gtk3
          cairo
          pango
          atk
          gdk-pixbuf
          xorg.libX11
          xorg.libXcomposite
          xorg.libXcursor
          xorg.libXext
          xorg.libXfixes
          xorg.libXi
          xorg.libXrandr
          xorg.libXrender
          xorg.libXtst
          nss
          nspr
          dbus
          at-spi2-atk
          at-spi2-core
          mesa
          alsa-lib
          fuse
          libxkbcommon
          xorg.libxkbfile
        ];
      };
    in
    # Then, create a final wrapper script to set the necessary environment variables
    pkgs.writeShellScriptBin "cursor" ''
      #!${pkgs.bash}/bin/bash
      # Set environment variables for compatibility
      export CURSOR_DISABLE_UPDATE="1"
      export CURSOR_SKIP_UPDATE_CHECK="1"
      
      # Create temporary directories to avoid permission issues
      export XDG_CACHE_HOME="$(mktemp -d -t cursor-xdg-cache-XXXXXX)"
      export CURSOR_CACHE_DIR="$(mktemp -d -t cursor-cache-XXXXXX)"
      
      # Execute the unwrapped Cursor application, passing all arguments
      exec "${unwrapped}/bin/cursor" "$@"
    '';

in
{
  home.username = "user";
  home.homeDirectory = "/home/user";
  home.stateVersion = "23.11";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Add Cursor to home packages
  home.packages = with pkgs; [
    cursor
    # Additional development tools
    nodejs_20
    python3
    rustc
    cargo
    # Terminal improvements
    starship
    zsh
    # Git tools
    git-crypt
    git-lfs
    # Additional utilities
    ripgrep
    fd
    bat
    eza
    fzf
    tmux
  ];

  # Shell configuration
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "eza -la";
      la = "eza -a";
      cat = "bat";
      find = "fd";
      grep = "rg";
    };
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      prompt_order = [ "directory" "git_branch" "git_status" "nodejs" "rust" "python" "cmd_duration" "line_break" "$all" ];
    };
  };

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "your.email@example.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # VS Code settings (for Cursor compatibility)
  home.file.".config/Code/User/settings.json".text = builtins.toJSON {
    "editor.fontSize" = 14;
    "editor.fontFamily" = "'JetBrains Mono', 'Fira Code', Consolas, 'Courier New', monospace";
    "editor.fontLigatures" = true;
    "editor.tabSize" = 2;
    "editor.insertSpaces" = true;
    "editor.rulers" = [ 80 120 ];
    "editor.minimap.enabled" = false;
    "workbench.colorTheme" = "Default Dark+";
    "workbench.iconTheme" = "material-icon-theme";
    "terminal.integrated.fontSize" = 14;
    "terminal.integrated.fontFamily" = "'JetBrains Mono', 'Fira Code', Consolas, 'Courier New', monospace";
  };

  # Cursor-specific settings
  home.file.".config/Cursor/User/settings.json".text = builtins.toJSON {
    "editor.fontSize" = 14;
    "editor.fontFamily" = "'JetBrains Mono', 'Fira Code', Consolas, 'Courier New', monospace";
    "editor.fontLigatures" = true;
    "editor.tabSize" = 2;
    "editor.insertSpaces" = true;
    "editor.rulers" = [ 80 120 ];
    "editor.minimap.enabled" = false;
    "workbench.colorTheme" = "Default Dark+";
    "workbench.iconTheme" = "material-icon-theme";
    "terminal.integrated.fontSize" = 14;
    "terminal.integrated.fontFamily" = "'JetBrains Mono', 'Fira Code', Consolas, 'Courier New', monospace";
    "cursor.chat.enabled" = true;
    "cursor.chat.autoComplete" = true;
  };

  # Environment variables
  home.sessionVariables = {
    EDITOR = "cursor";
    VISUAL = "cursor";
    BROWSER = "firefox";
  };

  # XDG directories
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "$HOME/Desktop";
      documents = "$HOME/Documents";
      download = "$HOME/Downloads";
      music = "$HOME/Music";
      pictures = "$HOME/Pictures";
      publicShare = "$HOME/Public";
      templates = "$HOME/Templates";
      videos = "$HOME/Videos";
    };
  };
}