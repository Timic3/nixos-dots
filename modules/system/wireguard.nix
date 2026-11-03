{ config, lib, pkgs, ... }:
let
  # wg-quick configs, one sops file per interface.
  tunnelsDir = ../../secrets/wireguard;
  tunnels = lib.optionals (builtins.pathExists tunnelsDir)
    (lib.fileset.toList (lib.fileset.fileFilter (file: file.hasExt "yaml") tunnelsDir));
  interfaceOf = file: lib.removeSuffix ".yaml" (baseNameOf file);
in
{
  sops.secrets = lib.listToAttrs (map (file: {
    name = "wireguard/${interfaceOf file}";
    value = {
      sopsFile = file;
      key = "config";
    };
  }) tunnels);

  # On demand: sudo systemctl start wg-quick-<interface>
  networking.wg-quick.interfaces = lib.listToAttrs (map (file: {
    name = interfaceOf file;
    value = {
      configFile = config.sops.secrets."wireguard/${interfaceOf file}".path;
      autostart = false;
    };
  }) tunnels);

  environment.systemPackages = [ pkgs.wireguard-tools ];
}
