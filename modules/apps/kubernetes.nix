{ config, lib, pkgs, ... }:
let
  # kubeconfigs, one sops file per cluster. Add new ones with `sops kube <name>`.
  kubeconfigsDir = "${config.users.users.timic.home}/.nixos-secrets/kube";
  kubeconfigs = [ "vanaheim" ];
in
{
  sops.secrets = lib.listToAttrs (map (cluster: {
    name = "kube/${cluster}";
    value = {
      sopsFile = "${kubeconfigsDir}/${cluster}.yaml";
      key = "config";
      owner = "timic";
    };
  }) kubeconfigs);

  home-manager.users.timic = { config, osConfig, lib, ... }: {
    # Before saving, kubectl locks every listed file by creating <file>.lock beside it. /run/secrets
    # isn't writable, so kubectl gets symlinks in ~/.kube/sops/ instead.
    home.file = lib.listToAttrs (map (cluster: {
      name = ".kube/sops/${cluster}";
      value.source = config.lib.file.mkOutOfStoreSymlink osConfig.sops.secrets."kube/${cluster}".path;
    }) kubeconfigs);

    # kubectl merges every listed file, and writes context switches and new contexts to the first
    # one that exists. The secrets are read-only, so ~/.kube/config goes first and always exists.
    # Exported per shell rather than per session, so a new cluster shows up without logging out.
    programs.bash.initExtra = ''
      export KUBECONFIG="$HOME/.kube/config${lib.concatMapStrings (cluster: ":$HOME/.kube/sops/${cluster}") kubeconfigs}"
    '';
    home.activation.kubeconfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [[ ! -e $HOME/.kube/config ]]; then
        run install -D -m 600 /dev/null "$HOME/.kube/config"
      fi
    '';
  };

  environment.systemPackages = with pkgs; [ kubectl kubernetes-helm k9s ];
}
