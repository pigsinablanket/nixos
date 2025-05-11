{
  description = "System level configuration flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    proxmox-nixos,
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
    };

    #desktop =

    # Available through 'home-manager switch --flake .#pigs@laptop'
    homeConfigurations = {
      "pigs@laptop" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [./home-manager/home.nix];
      };
    };

  };
}
