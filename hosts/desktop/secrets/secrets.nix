let
  # Your personal SSH key (for editing secrets)
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL+GEANHFLqzCD6r4tLtkgAxoy+YEGt+lF6HFtApUuTV donkeykongreimer@gmail.com";

  # Desktop's SSH host key (for decryption on the desktop)
  # Replace with actual desktop host key: cat /etc/ssh/ssh_host_ed25519_key.pub
  # Using laptop key as placeholder — replace after first deploy
  desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEr877uNZJR3mXHJbcTuKamKvaJwobHt04vgmN666bhp root@pigs-desktop";
in {
  # Secrets for desktop
  "searxng-secret.age".publicKeys = [ user desktop ];
  "grafana-secret.age".publicKeys = [ user desktop ];
  "porkbun-api-key.age".publicKeys = [ user desktop ];
  "porkbun-secret-key.age".publicKeys = [ user desktop ];
  "tailscale-auth-key.age".publicKeys = [ user desktop ];
}
