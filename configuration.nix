{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable AppImage support
  boot.binfmt.emulatedSystems = [ ];

  # Networking
  networking.networkmanager.enable = true;
  networking.hostName = "cursor-system";

  # Time zone
  time.timeZone = "UTC";

  # Internationalisation
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # X11 and Desktop Environment
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Enable sound with pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # User configuration
  users.users.liam = {
    isNormalUser = true;
    description = "Liam";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    # Set explicit password (password: cursor)
    hashedPassword = "$6$thkdqD1PCLUj6X9i$iPEOKRohaybp7XMYpyb7Zjd.Gdcl/weC732CYMlQ4ql7YDY8CLmSIqSUeH/efSnW.Wq9ICn2T5P5RSOqTqNlF0";
    packages = with pkgs; [
      # Essential tools
      git
      wget
      curl
      unzip
      # AppImage support
      appimage-run
      # Development tools
      gcc
      gnumake
      # Terminal
      alacritty
      # File manager
      nautilus
    ];
  };

  # Allow unfree packages (needed for some AppImages)
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
    # AppImage utilities
    appimage-run
    # Desktop utilities
    gnome-tweaks
    gnome-software
    # System utilities
    htop
    neofetch
    # Media support
    ffmpeg
    vlc
  ];

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "23.11";
} 