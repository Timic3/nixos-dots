{ config, inputs, pkgs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "${config.users.users.timic.home}/.config/sops/age/keys.txt";
  };

  environment.systemPackages = with pkgs; [ sops age ];
}
