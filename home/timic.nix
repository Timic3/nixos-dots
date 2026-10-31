{ config, pkgs, inputs, ... }:
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
  };

  services.ssh-agent.enable = true;
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "github.com" = {
        IdentityFile = "~/.ssh/timic-github";
        IdentitiesOnly = true;
      };
    };
  };

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

  programs.bash = {
    enable = true;
    shellAliases = {
      nixos-switch = "sudo nixos-rebuild switch --flake ~/.nixos-dots#nixos";
      nixos-update = "nix flake update --flake ~/.nixos-dots";
    };
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
