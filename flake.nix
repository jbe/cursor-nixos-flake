{
  description = "NixOS configuration with Cursor 1.4.3 AppImage";

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
    
    # Expose the Cursor package directly
    packages.x86_64-linux.cursor = 
      let
        cursorConfig = self.nixosConfigurations.cursor-system.config.home-manager.users.user.home.packages;
        cursorPackage = builtins.elemAt cursorConfig 12; # Cursor is at index 12
      in
      cursorPackage;
  };
} 