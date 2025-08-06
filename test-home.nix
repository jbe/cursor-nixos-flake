{ config, pkgs, lib, ... }:

{
  home.username = "user";
  home.homeDirectory = "/home/user";
  home.stateVersion = "23.11";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Add development tools to home packages
  home.packages = with pkgs; [
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

  # Environment variables
  home.sessionVariables = {
    EDITOR = "nano";
    VISUAL = "nano";
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