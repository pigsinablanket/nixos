{ lib, ... }:

{
  nixpkgs = {
    overlays = [];
    config = {
      allowUnfree = true;
    };
  };

  nix = {
    settings = {
      experimental-features = "nix-command flakes";

      substituters = [
       "https://nix-community.cachix.org"
       "https://cache.nixos.org/"
       # "https://cache.saumon.network/proxmox-nixos"
      ];

      trusted-public-keys = [
       "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
       # "proxmox-nixos:nveXDuVVhFDRFx8Dn19f1WDEaNRJjPrF2CPD2D+m1ys="
      ];
    };
  };
}
