{
  lib,
  inputs,
  system,
  config,
  ...
}:
let
  proxmox-nixos = inputs.proxmox-nixos;
in
{
  imports = [
    proxmox-nixos.nixosModules.proxmox-ve
  ];
  options.services.proxmox = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Proxmox VE";
    };
  };
  config = lib.mkIf config.services.proxmox.enable {
    services.proxmox-ve = {
      enable = true;
      ipAddress = "192.168.0.1";
    };

    nixpkgs.overlays = [
      proxmox-nixos.overlays."x86_64-linux"
    ];

    environment.etc."/network/interfaces".text = ''
      auto vmbr0
      iface vmbr0 inet manual
        bridge-ports none
        bridge-stp off
        bridge-fd 0
  '';


  };
}
