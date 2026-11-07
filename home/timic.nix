{ config, osConfig, lib, pkgs, inputs, ... }:
let
  configs = "${config.home.homeDirectory}/.nixos-config";
  link = path: config.lib.file.mkOutOfStoreSymlink "${configs}/${path}";

  sopsFunction = ''
    # Makes `sops ssh-host ...` and `sops kube ...` run their helpers; anything else reaches sops unchanged
    sops() {
      case $1 in
        ssh-host) shift; sops-ssh-host "$@" ;;
        kube) shift; sops-kube "$@" ;;
        *) command sops "$@" ;;
      esac
    }
  '';

  # Git status in Starship's symbols, e.g. " [!?⇡]": = conflicts, $ stash, ✘ deleted, ! modified,
  # + staged, ? untracked, ⇡⇣⇕ ahead/behind/diverged
  gitStatus = lib.concatStrings [
    ''{{ $s := "" }}''
    ''{{ if gt (add .Working.Unmerged .Staging.Unmerged) 0 }}{{ $s = print $s "=" }}{{ end }}''
    ''{{ if gt .StashCount 0 }}{{ $s = print $s "$" }}{{ end }}''
    ''{{ if gt .Working.Deleted 0 }}{{ $s = print $s "✘" }}{{ end }}''
    ''{{ if gt .Working.Modified 0 }}{{ $s = print $s "!" }}{{ end }}''
    ''{{ if .Staging.Changed }}{{ $s = print $s "+" }}{{ end }}''
    ''{{ if gt .Working.Untracked 0 }}{{ $s = print $s "?" }}{{ end }}''
    ''{{ if and (gt .Ahead 0) (gt .Behind 0) }}{{ $s = print $s "⇕" }}''
    ''{{ else if gt .Ahead 0 }}{{ $s = print $s "⇡" }}''
    ''{{ else if gt .Behind 0 }}{{ $s = print $s "⇣" }}{{ end }}''
    ''{{ if $s }} <red><b>[{{ $s }}]</b></>{{ end }}''
  ];

  # Commands with an oh-my-posh tooltip, from every module that adds one
  ompTips = lib.concatMap (tooltip: tooltip.tips) (config.programs.oh-my-posh.settings.tooltips or [ ]);
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

  # Shared by bash and zsh
  home.shellAliases = let
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
    nixos-switch = "sudo nixos-rebuild switch --flake ~/.nixos-dots#nixos";
    nixos-update = "nix flake update --flake ~/.nixos-dots";
    k = "kubectl";
    kctx = "kubectl config use-context";
  } // lib.listToAttrs (map (name: lib.nameValuePair "g${name}" "git ${name}") gitShortcuts);

  # Login shell. zsh rather than bash because oh-my-posh tooltips need a shell that can redraw the
  # prompt while typing.
  programs.zsh = {
    enable = true;
    # Aliases complete on their own in zsh (it expands them before completing)
    initContent = ''
      ${sopsFunction}

      setopt interactive_comments  # Allow `# comments` on the command line, like bash

      # Ctrl+Left/Right move by word, like bash
      bindkey '^[[1;5C' forward-word
      bindkey '^[[1;5D' backward-word

      # oh-my-posh only shows a tooltip after the space that follows its command ("k "). This shows it
      # as soon as the first word is one (on "k"), by checking before every redraw, and also catches
      # history recall and deletions. Uses oh-my-posh internals (_omp_get_prompt, _omp_tooltip_command),
      # so sharing its state keeps its own space handler from rendering the same tooltip twice.
      _tooltip_tips=(${lib.escapeShellArgs ompTips})
      _tooltip_on_redraw() {
        setopt local_options no_shwordsplit
        local cmd=''${''${(MS)BUFFER##[[:graph:]]*}%%[[:space:]]*}
        [[ $cmd == "$_omp_tooltip_command" ]] && return
        local was_tip=''${_tooltip_tips[(Ie)$_omp_tooltip_command]}
        _omp_tooltip_command=$cmd
        if (( ''${_tooltip_tips[(Ie)$cmd]} || was_tip )); then
          RPROMPT=$(_omp_get_prompt tooltip --command="$cmd")
          zle .reset-prompt
        fi
      }
      autoload -Uz add-zle-hook-widget
      add-zle-hook-widget line-pre-redraw _tooltip_on_redraw
    '';
  };

  # Kept configured for when bash is started by hand
  programs.bash = {
    enable = true;
    initExtra = ''
      ${sopsFunction}

      # Tab completion for every alias
      source ${pkgs.complete-alias}/bin/complete_alias
      complete -F _complete_alias ${lib.concatStringsSep " " (lib.attrNames config.programs.bash.shellAliases)}
    '';
  };

  # Prompt, styled after Starship's defaults: timic@nixos in ~/dir on  master [!?] took 3s
  # Tooltips (segments shown only while typing a command) are added by the modules that need them.
  programs.oh-my-posh = {
    enable = true;
    settings = {
      version = 3;
      final_space = true;
      blocks = [
        {
          type = "prompt";
          alignment = "left";
          newline = true;  # Blank line between prompts
          segments = [
            {
              type = "session";
              style = "plain";
              template = "<yellow><b>{{ .UserName }}</b></>@<green><b>{{ .HostName }}</b></> in ";
            }
            {
              type = "path";
              style = "plain";
              options = { style = "agnoster_short"; max_depth = 3; folder_icon = "…"; display_root = true; };
              template = "<cyan><b>{{ .Path }}</b></> ";
            }
            {
              type = "git";
              style = "plain";
              options.fetch_status = true;
              template = "on <magenta><b>{{ .HEAD }}</b></>${gitStatus} ";
            }
            {
              type = "nix-shell";
              style = "plain";
              template = ''{{ if ne .Type "unknown" }}via <blue><b>❄️ {{ .Type }}</b></> {{ end }}'';
            }
            {
              type = "executiontime";
              style = "plain";
              options = { threshold = 2000; style = "austin"; };
              template = "took <yellow><b>{{ .FormattedMs }}</b></> ";
            }
          ];
        }
        {
          type = "prompt";
          alignment = "left";
          newline = true;
          segments = [{
            type = "text";
            style = "plain";
            foreground = "green";
            foreground_templates = [ "{{ if gt .Code 0 }}red{{ end }}" ];  # Red after a failed command
            template = "<b>❯</b>";
          }];
        }
      ];
    };
  };

  xdg.configFile."hypr".source = link "hypr";
  xdg.configFile."dms".source = link "dms";
  xdg.configFile."Code/User/settings.json".source = link "vscode/settings.json";
  xdg.configFile."Code/User/keybindings.json".source = link "vscode/keybindings.json";
}
