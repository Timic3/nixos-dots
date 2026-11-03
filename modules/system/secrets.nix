{ config, inputs, lib, pkgs, ... }:
let
  # Private ssh hosts, one sops file each. Git drops the folder when it's empty, hence the check.
  sshHostsDir = ../../secrets/ssh/hosts;
  sshHosts = lib.optionals (builtins.pathExists sshHostsDir)
    (lib.fileset.toList (lib.fileset.fileFilter (file: file.hasExt "yaml") sshHostsDir));
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "${config.users.users.timic.home}/.config/sops/age/keys.txt";

    secrets = lib.listToAttrs (map (file: {
      name = "ssh-hosts/${lib.removeSuffix ".yaml" (baseNameOf file)}";
      value = {
        sopsFile = file;
        key = "config";
        owner = "timic";
      };
    }) sshHosts);
  };

  environment.systemPackages = with pkgs; [ sops age ];
}
