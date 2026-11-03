{ config, lib, pkgs, ... }:
let
  # wg-quick configs, one sops file per interface.
  tunnelsDir = "${config.users.users.timic.home}/.nixos-secrets/wireguard";
  tunnels = [ "vanaheim" ];
in
{
  sops.secrets = lib.listToAttrs (map (interface: {
    name = "wireguard/${interface}";
    value = {
      sopsFile = "${tunnelsDir}/${interface}.yaml";
      key = "config";
    };
  }) tunnels);

  # On demand: sudo systemctl start wg-quick-<interface>
  networking.wg-quick.interfaces = lib.genAttrs tunnels (interface: {
    configFile = config.sops.secrets."wireguard/${interface}".path;
    autostart = false;
  });

  environment.systemPackages = [ pkgs.wireguard-tools ];
}
