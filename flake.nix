{
  description = "NixOS configuration with Cursor AppImage";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }: {
    nixosConfigurations = {
      cursor-system = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.user = import ./home.nix;
          }
        ];
      };
      test-system = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./test-configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.user = import ./test-home.nix;
          }
        ];
      };
    };
    
    # Expose the Cursor package directly (build it explicitly instead of relying on list indices)
    packages.x86_64-linux.cursor =
      let
        system = "x86_64-linux";
        pkgs = import nixpkgs { inherit system; };
        cursorVersion = "1.5.1";
        unwrapped = pkgs.appimageTools.wrapType2 {
          pname = "cursor";
          version = cursorVersion;
          src = pkgs.fetchurl {
            url = "https://downloads.cursor.com/production/99e3b1b4d8796e167e72823eadc66ac2d51fd40c/linux/x64/Cursor-1.5.1-x86_64.AppImage";
            sha256 = "0lj34g0dq561qc6h8ab8bmkp59dz0rvxbrag105pzcy7jdaxa0nn";
          };
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
      pkgs.writeShellScriptBin "cursor" ''
        #!${pkgs.bash}/bin/bash
        if [[ "$1" == "--version" || "$1" == "-v" ]]; then
          echo "${cursorVersion}"
          exit 0
        fi
        export CURSOR_DISABLE_UPDATE="1"
        export CURSOR_SKIP_UPDATE_CHECK="1"
        export XDG_CACHE_HOME="$(mktemp -d -t cursor-xdg-cache-XXXXXX)"
        export CURSOR_CACHE_DIR="$(mktemp -d -t cursor-cache-XXXXXX)"
        exec "${unwrapped}/bin/cursor" "$@"
      '';
  };
} 