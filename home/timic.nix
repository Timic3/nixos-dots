{ config, osConfig, lib, pkgs, inputs, ... }:
let
  configs = "${config.home.homeDirectory}/.nixos-config";
  link = path: config.lib.file.mkOutOfStoreSymlink "${configs}/${path}";
in
{
  imports = [ inputs.dank-pinentry.homeModules.default ];

  home.username = "timic";
  home.homeDirectory = "/home/timic";
  home.stateVersion = "26.05";  # Do not edit!

  home.pointerCursor = {
    enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "Timotej";
      email = "github@timotej.dev";
    };
    signing = {
      key = "8C53AD94F33CCEFC";
      signByDefault = true;  # Signs commits and tags
    };
    includes = [ { path = "${inputs.gitalias}/gitalias.txt"; } ];  # Aliases (git a, git s, git l, ...)
  };

  services.ssh-agent.enable = true;
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "hosts/*" ];
    settings = {
      "github.com" = {
        IdentityFile = "~/.ssh/keys/timic-github";
        IdentitiesOnly = true;
      };
      # Fix server not having colors due to kitty's xterm-kitty terminfo
      "*".SetEnv.TERM = "xterm-256color";
    };
  };

  home.file = lib.mapAttrs'
    (name: secret: lib.nameValuePair ".ssh/hosts/${lib.removePrefix "ssh-hosts/" name}" {
      source = config.lib.file.mkOutOfStoreSymlink secret.path;
    })
    (lib.filterAttrs (name: _: lib.hasPrefix "ssh-hosts/" name) osConfig.sops.secrets);

  home.packages = [
    (pkgs.writeShellApplication {
      name = "sops-ssh-host";
      runtimeInputs = [ pkgs.sops ];
      text = builtins.readFile ../scripts/sops/ssh-host.sh;
    })
    (pkgs.writeShellApplication {
      name = "sops-kube";
      runtimeInputs = [ pkgs.sops pkgs.yq-go ];
      text = builtins.readFile ../scripts/sops/kube.sh;
    })
  ];

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentry.package = config.programs.dank-pinentry.package;  # Password prompt window
  };

  programs.dank-pinentry = {
    enable = true;
    ui = "dms";
    installPlugin = false;
  };

  programs.bash = let
    # Basic GitAlias aliases that also get a g<alias> shell alias (gs → git s)
    gitShortcuts = [
      "a" "aa" "ap"
      "b"
      "c" "ca" "cam" "cane" "cm"
      "co" "cob" "sw" "swc"
      "cp"
      "d" "ds"
      "f" "p" "pf" "pr"
      "l" "lo" "lg"
      "m"
      "rb" "rbi" "rba" "rbc"
      "s" "ss" "ssb"
    ];
  in {
    enable = true;
    shellAliases = {
      nixos-switch = "sudo nixos-rebuild switch --flake ~/.nixos-dots#nixos";
      nixos-update = "nix flake update --flake ~/.nixos-dots";
      k = "kubectl";
      kctx = "kubectl config set-context";
    } // lib.listToAttrs (map (name: lib.nameValuePair "g${name}" "git ${name}") gitShortcuts);
    initExtra = ''
      # Makes `sops ssh-host ...` and `sops kube ...` run their helpers; anything else reaches sops unchanged
      sops() {
        case $1 in
          ssh-host) shift; sops-ssh-host "$@" ;;
          kube) shift; sops-kube "$@" ;;
          *) command sops "$@" ;;
        esac
      }

      # Tab completion for every alias above
      source ${pkgs.complete-alias}/bin/complete_alias
      complete -F _complete_alias ${lib.concatStringsSep " " (lib.attrNames config.programs.bash.shellAliases)}
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      username = {
        show_always = true;
        format = "[$user]($style)@";
      };
      hostname = {
        ssh_only = false;
        format = "[$hostname]($style) in ";
      };
    };
  };

  xdg.configFile."hypr".source = link "hypr";
  xdg.configFile."dms".source = link "dms";
  xdg.configFile."Code/User/settings.json".source = link "vscode/settings.json";
  xdg.configFile."Code/User/keybindings.json".source = link "vscode/keybindings.json";
}
