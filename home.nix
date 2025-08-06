{ config, pkgs, lib, ... }:

let
  # Cursor 1.3.9 AppImage wrapper with enhanced compatibility
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
      url = "https://downloads.cursor.com/production/54c27320fab08c9f5dd5873f07fca101f7a3e076/linux/x64/Cursor-1.3.9-x86_64.AppImage";
      sha256 = "076ijp033xjg09aqjhjm6sslvq0hsjga35840m3br722lqpi6jfj";
    }} "$@"
  '';
in
{
  home.username = "liam";
  home.homeDirectory = "/home/liam";
  home.stateVersion = "23.11";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Add Cursor to home packages
  home.packages = with pkgs; [
    cursorAppImage
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
    userName = "Liam";
    userEmail = "liam@example.com";
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