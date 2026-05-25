let
  # Your personal SSH key (for editing secrets)
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL+GEANHFLqzCD6r4tLtkgAxoy+YEGt+lF6HFtApUuTV donkeykongreimer@gmail.com";

  # Laptop's SSH host key (for decryption on the laptop)
  # Replace with actual laptop host key: cat /etc/ssh/ssh_host_ed25519_key.pub
  laptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID5TIg5X66lTGEdTxCx+1V/C8I3wdxCfysDp07lcwdgP root@pigs-laptop";
in {
  # Secrets for laptop
  "tailscale-auth-key.age".publicKeys = [ user laptop ];
}
