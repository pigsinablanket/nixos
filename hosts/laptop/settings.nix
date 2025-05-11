{ pkgs, ... }:

{
  imports = [
    ./hardware.nix

    ../../modules/gui/steam.nix
    ../../modules/gui/xmonad.nix
    ../../modules/services/docker.nix
    ../../modules/services/mediawiki.nix
    ../../modules/services/proxmox.nix
    ../../modules/services/ssh.nix
    ../../modules/system/boot.nix
    ../../modules/system/core.nix
    ../../modules/system/nix.nix
    ../../modules/system/users.nix
    ../../modules/system/zswap.nix
  ];

  programs.ssh = {
    extraConfig = "
      Host pigsdekstop
        Hostname 192.168.1.140
        Port 22
        User pigs
    ";
    knownHosts = {
      pigsdesktop = {
        extraHostNames = [ "192.168.1.140" ];
        publicKeyFile = ./pigs-desktop.pub;
      };
    };

  };

  networking.hostName = "pigs-laptop";
  networking.interfaces.wlan0.useDHCP = true;

  zswap.enable = true;

  services.proxmox.enable = true;

  # nfs
  boot.supportedFilesystems = [ "nfs" ];
  fileSystems."/mnt/pigs" = {
    device = "192.168.1.140:/pigs";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=60" ];
  };


  services.libinput = {
    enable = true;
    touchpad.tapping = false;
    touchpad.naturalScrolling = false;
    touchpad.scrollMethod = "twofinger";
    touchpad.disableWhileTyping = true;
    touchpad.clickMethod = "clickfinger";
  };

  # display
  services.xserver = {
    dpi = 110;

    videoDrivers = [ "nvidia" ];

    config = ''
      Section "Device"
          Identifier  "Intel Graphics"
          Driver      "modesetting"
          Option      "TearFree"        "true"
          Option      "SwapbuffersWait" "true"
          BusID       "PCI:0:2:0"
      EndSection

      Section "Device"
          Identifier "nvidia"
          Driver "nvidia"
          BusID "PCI:1:0:0"
          Option "AllowEmptyInitialConfiguration"
      EndSection
    '';
    screenSection = ''
      Option         "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
      Option         "AllowIndirectGLXProtocol" "off"
      Option         "TripleBuffer" "on"
    '';
  };

  hardware.nvidia.prime = {
    sync.enable = true;
    nvidiaBusId = "PCI:1:0:0";
    intelBusId = "PCI:0:2:0";
  };

  hardware.nvidia.package = pkgs.linuxPackages.nvidia_x11_legacy470;
  nixpkgs.config.nvidia.acceptLicense = true;

  system.stateVersion = "24.11";
}
