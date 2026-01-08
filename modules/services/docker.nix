{ pkgs, lib, config, ... }:

{
  virtualisation.docker = {
    enable = true;

    # # Use the rootless mode - run Docker daemon as non-root user
  #   rootless = {
  #     enable = true;
  #     setSocketVariable = true;
  #   };
  };
}
