{
  description = "Cursor AppImage package flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      
      buildCursor = { version, url, sha256 }: 
        let
          unwrapped = pkgs.appimageTools.wrapType2 {
            pname = "cursor";
            inherit version;
            src = pkgs.fetchurl { inherit url sha256; };
            
            extraPkgs = p: with p; [
              glib gtk3 cairo pango atk gdk-pixbuf
              xorg.libX11 xorg.libXcomposite xorg.libXcursor
              xorg.libXext xorg.libXfixes xorg.libXi
              xorg.libXrandr xorg.libXrender xorg.libXtst
              nss nspr dbus at-spi2-atk at-spi2-core
              mesa alsa-lib fuse libxkbcommon xorg.libxkbfile
            ];
          };
        in
        pkgs.writeShellScriptBin "cursor" ''
          #!${pkgs.bash}/bin/bash
          if [[ "$1" == "--version" || "$1" == "-v" ]]; then
            echo "${version}"
            exit 0
          fi
          export CURSOR_DISABLE_UPDATE="1"
          export CURSOR_SKIP_UPDATE_CHECK="1"
          export XDG_CACHE_HOME="$(mktemp -d -t cursor-xdg-cache-XXXXXX)"
          export CURSOR_CACHE_DIR="$(mktemp -d -t cursor-cache-XXXXXX)"
          exec "${unwrapped}/bin/cursor" "$@"
        '';
    in
    {
      packages.${system} = {
        default = self.packages.${system}.cursor;
        cursor = buildCursor {
          version = "1.5.5";
          url = "https://downloads.cursor.com/production/823f58d4f60b795a6aefb9955933f3a2f0331d7b/linux/x64/Cursor-1.5.5-x86_64.AppImage";
          sha256 = "1jqp2k3anlwnd6gb7zi6ax1m7hg0kxncfpcl0s3wwdhfq10w1bvs";
        };
      };

      # Overlay for easy integration into other flakes
      overlays.default = final: prev: {
        cursor = self.packages.${system}.cursor;
      };
    };
}
