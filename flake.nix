{
  description = "System level configuration flake";

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs = {
    self,
    nixpkgs,
    unstable,
    home-manager,
    nix-darwin,
    vpn-confinement,
    llm-agents,
    ...
  } @ inputs: let
    inherit (self) outputs;
    system = "x86_64-linux";
    unstablePkgs = import unstable {
      inherit system;
      config.allowUnfree = true;
    };
    llmAgentPkgs = llm-agents.packages.${system};
  in {
    nixosConfigurations = {
      # Available through 'nixos-rebuild switch --flake ~/nixos#laptop'
      laptop = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs;
        };
        modules = [
          ./hosts/laptop/settings.nix
        ];
      };

      desktop = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs;
          unstable = unstablePkgs;
          llmAgent = llmAgentPkgs;
        };
        modules = [
          inputs.disko.nixosModules.disko
         ./hosts/desktop/settings.nix
          # ./hosts/desktop/disko-storage.nix
          ./hosts/desktop/disko-media.nix
          ./hosts/desktop/disko-fast.nix
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
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };
}
