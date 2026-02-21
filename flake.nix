{
  description = "System level configuration flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-darwin,
    vpn-confinement,
    ...
  } @ inputs: let
    inherit (self) outputs;
  in {
    nixosConfigurations = {
      # Available through 'nixos-rebuild switch --flake ~/nixos#laptop'
      laptop = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./hosts/laptop/settings.nix
        ];
      };

      desktop = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./hosts/desktop/settings.nix
          vpn-confinement.nixosModules.default
        ];
      };
    };

    darwinConfigurations = {
      "Daniels-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./hosts/macbook/darwin.nix
          home-manager.darwinModules.home-manager {
            home-manager = {
              # include the home-manager module
              users.dreimer = import ./home-manager/home.nix;
            };
            system.primaryUser = "dreimer";
            users.users.dreimer.home = "/Users/dreimer";
          }
        ];
        specialArgs = { inherit inputs; };
      };
    };

    # Available through 'home-manager switch --flake .#pigs'
    homeConfigurations = {
      "pigs" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [./home-manager/home.nix];
      };
    };

  };

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
       "https://cache.nixos.org/"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}
