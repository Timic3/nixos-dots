{ config, inputs, lib, pkgs, ... }:
let
  # Outside the repo, since it's public. sops-nix reads the files when the system activates.
  secretsDir = "${config.users.users.timic.home}/.nixos-secrets";

  # Private ssh hosts, one sops file each in ssh/hosts/. Add new ones with `sops ssh-host <alias>`.
  sshHosts = [ "alfheim" "vanaheim" ];
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = "${secretsDir}/secrets.yaml";
    validateSopsFiles = false;  # Only works on files in the Nix store
    age.keyFile = "${config.users.users.timic.home}/.config/sops/age/keys.txt";

    secrets = lib.listToAttrs (map (host: {
      name = "ssh-hosts/${host}";
      value = {
        sopsFile = "${secretsDir}/ssh/hosts/${host}.yaml";
        key = "config";
        owner = "timic";
      };
    }) sshHosts);
  };

  environment.systemPackages = with pkgs; [ sops age ];
}
